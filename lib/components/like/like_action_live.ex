defmodule Bonfire.UI.Reactions.LikeActionLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :any
  prop object, :any, default: nil
  prop creator, :any, default: nil
  prop object_type, :any
  prop object_boundary, :any, default: :skip_boundary_preload
  prop like_count, :any, default: 0
  # prop label, :string, default: nil
  prop showing_within, :atom, default: nil
  prop my_like, :any, default: nil
  prop icon, :string, default: "ph:fire-duotone"
  prop icon_pressed, :string, default: "ph:fire-fill"

  def update_many(assigns_sockets),
    do: Bonfire.Social.Likes.LiveHandler.update_many(assigns_sockets, caller_module: __MODULE__)
end
