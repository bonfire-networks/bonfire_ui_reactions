defmodule Bonfire.Social.Likes.LiveHandler do
  use Bonfire.UI.Common.Web, :live_handler
  import Untangle

  # with a Media as custom emoji
  def handle_event("add_reaction", %{"emoji_id" => emoji_id, "id" => id} = params, socket) do
    current_user = current_user(socket)

    with {:ok, like} <-
           Bonfire.Social.Likes.like(current_user, id,
             reaction_emoji: emoji_id,
             object_creator: e(socket, :assigns, :creator, nil)
           ),
         %{} = like <-
           e(like, :edge, nil)
           |> repo().maybe_preload([:emoji], skip_boundary_check: true) do
      {:noreply,
       socket
       |> assign(:my_like, e(like, :emoji, nil) || true)
       |> assign_flash(:info, l("Reaction sent to author"))}
    end
  end

  # with a regular emoji
  def handle_event("add_reaction", %{"emoji" => emoji, "id" => id} = params, socket) do
    current_user = current_user(socket)

    with %{} = like <-
           Bonfire.Social.Likes.like(current_user, id,
             reaction_emoji: {emoji, %{label: params["label"] || emoji}},
             object_creator: e(socket, :assigns, :creator, nil)
           )
           |> e(:edge, nil)
           |> repo().maybe_preload([emoji: [:extra_info]], skip_boundary_check: true) do
      {:noreply,
       socket
       |> assign(:my_like, e(like, :emoji, :extra_info, nil) || e(like, :emoji, nil) || true)
       |> assign_flash(:info, l("Reaction sent to author"))}
    end
  end

  # def handle_event("get_custom_emojis", _params, socket) do
  #   custom_emojis =
  #     Bonfire.Files.EmojiUploader.list(assigns(socket))
  #     |> Enum.map(fn {shortcode, emoji} ->
  #       %{
  #         name: e(emoji, :label, nil),
  #         shortcodes: [shortcode],
  #         url: e(emoji, :url, nil) || Media.emoji_url(emoji)
  #       }
  #     end)

  #   {:reply, %{custom_emoji: custom_emojis}, socket}
  # end

  # like in LV stateful
  def handle_event(
        "like",
        %{"direction" => "up"} = params,
        %{assigns: %{object: object}} = socket
      ) do
    do_like(object, params, socket)
  end

  # like in LV
  def handle_event("like", %{"direction" => "up", "id" => id} = params, socket) do
    do_like(id, params, socket)
  end

  # unlike in LV
  def handle_event("like", %{"direction" => "down", "id" => id} = params, socket) do
    with _ <- Bonfire.Social.Likes.unlike(current_user_required!(socket), id) do
      like_action(id, false, params, socket)
    end
  end

  def do_like(object, params, socket) do
    with {:ok, current_user} <- current_user_or_remote_interaction(socket, l("like"), object),
         {:ok, _like} <-
           Bonfire.Social.Likes.like(current_user, object,
             object_creator: e(socket, :assigns, :creator, nil)
           ) do
      like_action(object, true, params, socket)
      |> debug("liked")
    else
      {:error,
       %Ecto.Changeset{
         errors: [
           liker_id: {"has already been taken", _}
         ]
       }} ->
        debug("previously liked, but UI didn't know")
        like_action(object, true, params, socket)

      {:error, e} ->
        error(e)

      other ->
        other
    end
  end

  defp like_action(object, liked?, params, socket) do
    # TODO: send this to ActionsLive if using feed_live_update_many_preload_mode :async_actions
    ComponentID.send_updates(
      e(params, "component", Bonfire.UI.Reactions.LikeActionLive),
      uid(object),
      my_like: liked?
    )

    {:noreply,
     socket
     |> assign(:my_like, liked?)}
  end

  def liker_count(%{"current_count" => a}), do: a |> String.to_integer()
  def liker_count(%{current_count: a}), do: a |> String.to_integer()
  # def liker_count(%{assigns: a}), do: liker_count(a)
  # def liker_count(%{like_count: like_count}), do: liker_count(like_count)
  # def liker_count(%{liker_count: liker_count}), do: liker_count(liker_count)
  # def liker_count(liker_count) when is_integer(liker_count), do: liker_count
  def liker_count(_), do: 0

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
      previous_my_like: e(assigns, :my_like, nil),
      previous_like_count: e(assigns, :like_count, nil)
    }
  end

  defp do_preload(list_of_components, list_of_ids, current_user) do
    my_states = if current_user, do: do_list_my_liked(current_user, list_of_ids), else: %{}

    # debug(my_states, "my_likes")

    objects_counts =
      if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
           current_user: current_user
         ) do
        list_of_components
        |> Enum.map(fn %{object: object} ->
          object
        end)
        |> filter_empty([])
        |> debug("list_of_objects")
        |> repo().maybe_preload(:like_count, follow_pointers: false)
        |> Map.new(fn o -> {e(o, :id, nil), e(o, :like_count, :object_count, nil)} end)

        # |> debug("like_counts")
      end

    list_of_components
    |> Map.new(fn component ->
      {component.component_id,
       %{
         my_like: Map.get(my_states, component.object_id) || component.previous_my_like || false,
         like_count: e(objects_counts, component.object_id, nil) || component.previous_like_count
       }}
    end)
  end

  # defp list_my_liked(current_user, objects) when is_list(objects) do
  #   Cache.cached_preloads_for_objects("my_like:#{uid(current_user)}:", objects, fn list_of_ids -> do_list_my_liked(current_user, list_of_ids) end)
  # end

  defp do_list_my_liked(current_user, list_of_ids)
       when is_list(list_of_ids) and length(list_of_ids) > 0 do
    # TODO: avoid running this query if we don't have permission to like this object
    Bonfire.Social.Likes.get!(current_user, list_of_ids,
      preload: false,
      skip_boundary_check: true
    )
    # TODO: optimise these preloads
    |> repo().maybe_preload([edge: [:emoji]], skip_boundary_check: true)
    |> Enum.map(fn l -> e(l, :edge, nil) || l end)
    # current_user: current_user)
    |> repo().maybe_preload([emoji: [:extra_info]], skip_boundary_check: true)
    |> debug("preloaded?")
    |> Map.new(fn l ->
      {e(l, :object_id, nil) || e(l, :edge, :object_id, nil),
       e(l, :emoji, :extra_info, nil) || e(l, :emoji, nil) || e(l, :edge, :emoji, nil) || true}
    end)
  end

  defp do_list_my_liked(_, _objects), do: %{}
end
