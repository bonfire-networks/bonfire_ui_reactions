defmodule Bonfire.UI.Reactions.PinnedCarouselLive do
  @moduledoc "The one way pinned posts show: the pins of a `scope` (the instance spotlight, or a group or topic) as `PinnedCardLive`s in the shared `Bonfire.UI.Common.CarouselLive`."
  use Bonfire.UI.Common.Web, :stateful_component

  @doc "`:instance` for the spotlight, or `:group`/`:topic` for the pins of `scope_object`"
  prop scope, :atom, default: :instance
  prop scope_object, :any, default: nil

  @doc "The widget's title; \"Pinned\" when none"
  prop title, :string, default: nil

  @doc "How many whole cards show from the `sm` breakpoint up, always with the next one's edge; one below it"
  prop visible_items, :integer, default: 1

  @doc "Render nothing (rather than the \"nothing in the spotlight\" placeholder) when there are no pins"
  prop hide_empty, :boolean, default: false

  @doc "Extra classes for the outer element, the card block and the scroll container, eg. a page's own gutters"
  prop class, :css_class, default: nil
  prop wrapper_class, :css_class, default: nil
  prop carousel_class, :css_class, default: nil

  @doc "Classes for the header row and the title, as `WidgetBlockLive` takes them: its own defaults on the dashboard, a page's own elsewhere"
  prop title_class, :css_class,
    default: "pb-card text-xs font-normal uppercase tracking-wide text-base-content"

  prop heading_class, :css_class, default: nil

  data entries, :list, default: []

  @doc "Whether the viewer may unpin these, decided with the pins (instance admins for the spotlight, the group's moderators for a group or topic)"
  data can_unpin, :boolean, default: false

  # the scope id the pins were loaded for (the instance's for the spotlight): its parent re-renders it often, so only a new scope, or a pin change (`reload: true`, from `Pins.LiveHandler.handle_info/2`), loads them again
  data loaded_for, :any, default: nil

  def update(assigns, socket) do
    socket = assign(socket, Map.delete(assigns, :reload))
    %{scope: scope, scope_object: scope_object} = socket.assigns

    scope_id =
      if scope == :instance, do: Bonfire.Social.Pins.instance_scope_id(), else: id(scope_object)

    user = current_user(socket)

    cond do
      socket.assigns[:loaded_for] != scope_id ->
        # `Bonfire.Social.Pins` broadcasts the scope's pin changes with its id, and `Pins.LiveHandler` sends the reload to the carousel registered under it
        ComponentID.register_alias(__MODULE__, scope_id, socket.assigns.id)
        subscribe_to_pins(socket, socket.assigns[:loaded_for], scope_id)

        {:ok,
         assign(socket,
           entries: load(scope, scope_object, user),
           can_unpin: can_unpin?(scope, scope_object, user),
           loaded_for: scope_id
         )}

      # a pin or unpin changes the pins, not who may unpin them
      assigns[:reload] ->
        {:ok, assign(socket, entries: load(scope, scope_object, user))}

      true ->
        {:ok, socket}
    end
  end

  # a group page patching to one of its topics swaps scopes in the same process, so it stops hearing the old one's
  defp subscribe_to_pins(socket, old_scope_id, scope_id) do
    if old_scope_id, do: old_scope_id |> Bonfire.Social.Pins.pins_topic() |> PubSub.unsubscribe()

    scope_id
    |> Bonfire.Social.Pins.pins_topic()
    |> PubSub.subscribe(socket)
  end

  defp load(scope, scope_object, user) do
    if module_enabled?(Bonfire.Social.Pins, user),
      do: do_load(scope, scope_object, user),
      else: []
  end

  defp do_load(:instance, _, _user), do: Bonfire.Social.Pins.list_spotlight_activities()

  defp do_load(_scope, nil, _user), do: []

  defp do_load(_scope, scope_object, user),
    do:
      Bonfire.Social.Pins.list_pinned_activities(scope_object, current_user: user)
      |> e(:edges, [])

  defp can_unpin?(_scope, _scope_object, nil), do: false

  defp can_unpin?(:instance, _, user), do: Bonfire.Social.Pins.may_pin_in?(user, :instance)

  defp can_unpin?(_scope, nil, _user), do: false

  defp can_unpin?(_scope, scope_object, user),
    do: Bonfire.Social.Pins.may_pin_in?(user, scope_object)
end
