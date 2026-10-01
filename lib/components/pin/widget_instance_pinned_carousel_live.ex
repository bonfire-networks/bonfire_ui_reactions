defmodule Bonfire.UI.Reactions.WidgetInstancePinnedCarouselLive do
  use Bonfire.UI.Common.Web, :stateful_component

  alias Bonfire.UI.Reactions.InstancePins

  # TODO: dedup with Bonfire.UI.Reactions.PinnedCarouselLive

  prop title, :string, default: nil
  prop title_class, :css_class, default: nil
  prop wrapper_class, :css_class, default: nil
  prop object_types, :any, default: []
  prop entries, :any, default: []
  prop hide_scroll_buttons, :boolean, default: false
  prop visible_items, :number, default: nil

  @doc "Render nothing (rather than the \"nothing in the spotlight\" placeholder) when there are no pins, e.g. for guests who can't pin anything."
  prop hide_empty, :boolean, default: false

  @doc "Optional line under the title."
  prop subtitle, :string, default: nil

  @doc "Extra classes for the title, subtitle, and prev/next buttons."
  prop heading_class, :css_class, default: nil
  prop subtitle_class, :css_class, default: nil
  prop button_class, :css_class, default: "border-secondary"

  @doc "Extra classes for the horizontal scroll container (eg. padding so the first card starts on a page gutter)."
  prop carousel_class, :css_class, default: nil

  @doc "Override the classes of each carousel card."
  prop card_class, :css_class,
    default: "rounded-box border-hair bg-base-100 border-secondary p-card"

  # on small screens we always show fewer items so cards stay legible; @visible_items applies from the `sm:` breakpoint up
  prop visible_items_mobile, :number, default: 1.5

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # shared cached loader (see InstancePins.list_activities/1), same as the vertical pinned widget
    {:ok, assign(socket, entries: InstancePins.list_activities())}
  end

  @doc "Busts + recomputes the cache and reloads in place — stateful, so the fresh list shows without a page reload."
  def handle_event("reset_instance_pinned", _params, socket) do
    {:noreply, assign(socket, entries: InstancePins.list_activities(cache: :refresh))}
  end

  @doc """
  Returns the carousel item width for the requested number of initially visible items.
  """
  def carousel_item_width(nil), do: "70%"

  def carousel_item_width(visible_items) when is_number(visible_items) and visible_items > 0 do
    gap_rem = 0.75

    "calc((100% - #{(visible_items - 1) * gap_rem}rem) / #{visible_items})"
  end

  def carousel_item_width(_), do: "70%"
end
