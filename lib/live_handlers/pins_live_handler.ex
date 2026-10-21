defmodule Bonfire.Social.Pins.LiveHandler do
  use Bonfire.UI.Common.Web, :live_handler
  import Untangle

  # pin in LV stateful
  def handle_event(
        "pin",
        %{"direction" => "up", "id" => id} = params,
        %{assigns: %{object: %{id: id} = object}} = socket
      ) do
    do_pin(object, params, socket)
  end

  # pin in LV
  def handle_event("pin", %{"direction" => "up", "id" => id} = params, socket) do
    do_pin(id, params, socket)
  end

  # pin in form
  def handle_event("pin", %{"direction" => "up", "object_id" => id} = params, socket) do
    do_pin(id, params, socket)
  end

  # unpin in LV
  def handle_event("pin", %{"direction" => "down", "id" => id} = params, socket) do
    do_unpin(id, params, socket)
  end

  def handle_event("pin", %{"direction" => "down", "object_id" => id} = params, socket) do
    do_unpin(id, params, socket)
  end

  defp scoped(%{"scope" => "instance"}) do
    :instance
  end

  defp scoped(%{"scope" => scope}) when scope in ["profile", "sidebar"] do
    nil
  end

  defp scoped(%{"scope" => scope}) when is_binary(scope) do
    uid(scope)
  end

  defp scoped(_) do
    nil
  end

  #   defp scoped(%{"scope"=> scope}) do
  #       maybe_to_atom(scope)
  #       |> debug()
  # end

  def do_pin(object, params, socket) do
    scope = scoped(params)

    with {:ok, current_user} <- current_user_or_remote_interaction(socket, "pin", object),
         {:ok, _pin} <-
           Bonfire.Social.Pins.pin(current_user, object, scope,
             object_creator: e(socket, :assigns, :creator, nil)
           ) do
      after_pin(object, true, params, socket)
    else
      {:error,
       %Ecto.Changeset{
         errors: [
           pinner_id: {"has already been taken", _}
         ]
       }} ->
        debug("previously pinned, but UI didn't know")
        after_pin(object, true, params, socket)

      {:error, e} ->
        error(e)

      other ->
        debug(other)
        other
    end
  end

  def do_unpin(id, params, socket) do
    case Bonfire.Social.Pins.unpin(current_user_required!(socket), id, scoped(params)) do
      {:error, e} -> {:noreply, assign_error(socket, e)}
      _ -> after_pin(id, false, params, socket)
    end
  end

  defp after_pin(object, pinned?, params, socket) do
    scope = scoped(params)

    ComponentID.send_updates(
      e(params, "component", Bonfire.UI.Reactions.PinActionLive),
      uid(object),
      pinned?: pinned?,
      # which of a post menu's pin rows changed (`PermittedActionsLive`)
      pin_scope: scope
    )

    Bonfire.UI.Common.OpenModalLive.close()

    {:noreply,
     socket
     |> assign_flash(:info, if(pinned?, do: l("Pinned!"), else: l("Unpinned")))}
  end

  @doc "A scope's pins changed (`Bonfire.Social.Pins.pins_topic/1`): reload what this process shows for that kind of pin; a reorder (`:unknown`) may touch either."
  def handle_info(
        {:pins_changed, %{scope_id: scope_id, object_id: object_id, kind: kind}},
        socket
      ) do
    case kind do
      :post ->
        reload_carousel(scope_id)
        {:noreply, socket}

      :group ->
        reload_group_pins(object_id, socket)

      :unknown ->
        reload_carousel(scope_id)
        reload_group_pins(object_id, socket)
    end
  end

  defp reload_carousel(scope_id),
    do:
      ComponentID.send_updates(Bonfire.UI.Reactions.PinnedCarouselLive, scope_id, reload: true)

  defp reload_group_pins(object_id, socket) do
    # the sidebar registers under its user, in PersistentLive's process (it subscribes from there)
    if user_id = current_user_id(socket),
      do:
        ComponentID.send_updates(Bonfire.UI.Groups.SidebarGroupsLive, user_id, %{
          reload_pins: true
        })

    # the ⋯ menu reads the group's pins with the page, so the page reloads them; a no-op on any other page
    maybe_apply(Bonfire.Classify.LiveHandler, :handle_info, [{:refresh_pins, object_id}, socket],
      fallback_return: {:noreply, socket}
    )
  end
end
