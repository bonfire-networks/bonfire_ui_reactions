defmodule Bonfire.UI.Reactions.WidgetInstancePinnedCarouselLive do
  use Bonfire.UI.Common.Web, :stateful_component

  alias Bonfire.UI.Reactions.InstancePins

  # TODO: dedup with Bonfire.UI.Reactions.PinnedCarouselLive

  prop title, :string, default: nil
  prop object_types, :any, default: []
  prop entries, :any, default: []

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # shared cached loader (see InstancePins.list_activities/1), same as the vertical pinned widget
    {:ok, assign(socket, entries: InstancePins.list_activities())}
  end

  @doc "Busts + recomputes the cache and reloads in place — stateful, so the fresh list shows without a page reload."
  def handle_event("reset_instance_pinned", _params, socket) do
    {:noreply, assign(socket, entries: InstancePins.list_activities(cache: :refresh))}
  end
end
