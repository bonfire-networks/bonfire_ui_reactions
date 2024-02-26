defmodule Bonfire.UI.Reactions.BookmarkActionLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :any
  prop object_type, :any
  prop my_bookmark, :boolean, default: false
  # prop label, :string, default: nil
  # prop showing_within, :atom, default: nil

  # done in `ActionsLive` via `Bonfire.Social.Feeds.LiveHandler` instead
  # def update_many(assigns_sockets),
  #   do: Bonfire.Social.Bookmarks.LiveHandler.update_many(assigns_sockets, caller_module: __MODULE__)
end
