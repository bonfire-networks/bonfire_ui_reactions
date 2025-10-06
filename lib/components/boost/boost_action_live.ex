defmodule Bonfire.UI.Reactions.BoostActionLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :any
  prop object, :any, default: nil
  prop creator, :any, default: nil
  prop object_type, :any
  prop object_boundary, :any, default: nil
  prop boost_count, :any
  prop showing_within, :atom
  prop my_boost, :any, default: nil
  prop parent_id, :any, default: nil
  # prop quote_permission, :any, default: nil

  def update_many(assigns_sockets),
    do: Bonfire.Social.Boosts.LiveHandler.update_many(assigns_sockets, caller_module: __MODULE__)

  # # Helper to use preloaded permission or fall back to checking
  # def quote_permission_or_check(nil, user, object),
  #   do: Bonfire.Social.Quotes.check_quote_permission(user, object)

  # def quote_permission_or_check(permission, _user, _object), do: permission
end
