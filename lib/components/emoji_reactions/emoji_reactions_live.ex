defmodule Bonfire.UI.Reactions.EmojiReactionsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop object_id, :any
  prop object_type, :any
  prop object_boundary, :any, default: nil
  prop like_count, :any, default: 0
  # prop label, :string, default: nil
  # prop showing_within, :atom, default: nil
  prop my_like, :any, default: nil

  # def update_many(assigns_sockets),
  #   do: Bonfire.Social.Likes.LiveHandler.update_many(assigns_sockets, caller_module: __MODULE__)
end
