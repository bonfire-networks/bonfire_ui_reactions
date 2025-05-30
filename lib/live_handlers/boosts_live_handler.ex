defmodule Bonfire.Social.Boosts.LiveHandler do
  use Bonfire.UI.Common.Web, :live_handler
  import Untangle

  # boost in LV stateful component
  def handle_event("boost", params, %{assigns: %{object: object}} = socket) do
    do_boost(object, params, socket)
  end

  # boost in LV
  def handle_event("boost", %{"id" => id} = params, socket) do
    do_boost(id, params, socket)
  end

  # unboost in LV
  def handle_event("undo", %{"id" => id} = params, socket) do
    with {:ok, _unboost} <- Bonfire.Social.Boosts.unboost(current_user_required!(socket), id) do
      boost_action(id, false, params, socket)
    end
  end

  # boost in LV
  def do_boost(object, params, socket) do
    with {:ok, current_user} <- current_user_or_remote_interaction(socket, l("boost"), object),
         {:ok, _boost} <-
           Bonfire.Social.Boosts.boost(current_user, object,
             object_creator: e(socket, :assigns, :creator, nil)
           ) do
      boost_action(object, true, params, socket)
    end
  end

  defp boost_action(object, boost?, _params, socket) do
    # TODO: send this to ActionsLive if using feed_live_update_many_preload_mode :async_actions
    ComponentID.send_updates(
      Bonfire.UI.Reactions.BoostActionLive,
      uid(object),
      my_boost: boost?
    )

    {:noreply,
     socket
     |> assign(:my_boost, boost?)}
  end

  def update_many(assigns_sockets, opts \\ []) do
    {first_assigns, _socket} = List.first(assigns_sockets)

    update_many_async(
      assigns_sockets,
      update_many_opts(
        opts ++
          [
            id:
              e(first_assigns, :feed_name, nil) || e(first_assigns, :feed_id, nil) ||
                e(first_assigns, :thread_id, nil) || id(first_assigns)
          ]
      )
    )
  end

  def update_many_opts(opts \\ []) do
    opts ++
      [
        assigns_to_params_fn: &assigns_to_params/1,
        preload_fn: &do_preload/3
      ]
  end

  defp assigns_to_params(assigns) do
    object = e(assigns, :object, nil)

    %{
      component_id: assigns.id,
      object: object || e(assigns, :object_id, nil),
      object_id: e(assigns, :object_id, nil) || uid(object),
      previous_my_boost: e(assigns, :my_boost, nil),
      previous_boost_count: e(assigns, :boost_count, nil)
    }
  end

  defp do_preload(list_of_components, list_of_ids, current_user) do
    my_states =
      if current_user,
        do:
          Bonfire.Social.Boosts.get!(current_user, list_of_ids,
            preload: false,
            skip_boundary_check: true
          )
          |> Map.new(fn l -> {e(l, :edge, :object_id, nil), true} end),
        else: %{}

    debug(my_states, "my_boosts")

    objects_counts =
      if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
           current_user: current_user
         ) do
        list_of_components
        |> Enum.map(fn %{object: object} ->
          object
        end)
        |> filter_empty([])
        |> repo().maybe_preload(:boost_count, follow_pointers: false)
        |> Map.new(fn o -> {e(o, :id, nil), e(o, :boost_count, :object_count, nil)} end)
        |> debug("boost_counts")
      end

    list_of_components
    |> Map.new(fn component ->
      {component.component_id,
       %{
         my_boost:
           Map.get(my_states, component.object_id) || component.previous_my_boost || false,
         boost_count:
           e(objects_counts, component.object_id, nil) || component.previous_boost_count
       }}
    end)
  end
end
