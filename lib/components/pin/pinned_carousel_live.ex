defmodule Bonfire.UI.Reactions.PinnedCarouselLive do
  use Bonfire.UI.Common.Web, :stateless_component

  # TODO: dedup with Bonfire.UI.Reactions.WidgetInstancePinnedCarouselLive

  prop pins, :list, default: []
  prop title, :string, default: ""
  # prop object_types, :any, default: []
end
