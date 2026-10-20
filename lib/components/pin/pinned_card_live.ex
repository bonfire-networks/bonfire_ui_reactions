defmodule Bonfire.UI.Reactions.PinnedCardLive do
  @moduledoc "A pinned post as a card in `PinnedCarouselLive`, for the spotlight and for groups and topics alike: the Top discussions preview (`ActivityLive` with `DiscussionPreviewActionsLive`), with an Unpin action for whoever may unpin it."
  use Bonfire.UI.Common.Web, :stateless_component

  prop activity, :any, required: true

  @doc "Who else is in the thread, for the preview's facepile (`Bonfire.Social.Threads.attach_participants/2`)"
  prop participants, :list, default: []
  prop participants_more_count, :integer, default: 0

  @doc "`:instance`, `:group` or `:topic`: where it is pinned, for the Unpin wording"
  prop scope, :atom, required: true

  @doc "The group's or topic's id; none for the spotlight, whose Unpin names the `:instance` scope itself"
  prop scope_object, :string, default: nil

  @doc "Whether the viewer may unpin it, decided once for the carousel (`Bonfire.Social.Pins.may_pin_in?/3`)"
  prop can_unpin, :boolean, default: false
end
