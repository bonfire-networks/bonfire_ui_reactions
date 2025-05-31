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

  defp scoped(%{"scope" => "profile"}) do
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

    with {:ok, current_user} <- current_user_or_remote_interaction(socket, l("pin"), object),
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
    with _ <-
           Bonfire.Social.Pins.unpin(
             current_user_required!(socket),
             id,
             scoped(params)
           ) do
      after_pin(id, false, params, socket)
    end
  end

  defp after_pin(object, pinned?, params, socket) do
    ComponentID.send_updates(
      e(params, "component", Bonfire.UI.Reactions.PinActionLive),
      uid(object),
      my_pin: pinned?
    )

    {:noreply,
     socket
     |> assign_flash(:info, if(pinned?, do: l("Pinned!"), else: l("Unpinned")))}
  end

  # defp list_my_pinned(current_user, objects) when is_list(objects) do
  #   Cache.cached_preloads_for_objects("my_pin:#{uid(current_user)}:", objects, fn list_of_ids -> do_list_my_pinned(current_user, list_of_ids) end)
  # end

  # defp do_list_my_pinned(current_user, list_of_ids)
  #      when is_list(list_of_ids) and length(list_of_ids) > 0 do
  #   Bonfire.Social.Pins.get!(current_user, list_of_ids, preload: false)
  #   |> Map.new(fn l -> {e(l, :edge, :object_id, nil), true} end)
  # end

  # defp do_list_my_pinned(_, _objects), do: %{}
end
