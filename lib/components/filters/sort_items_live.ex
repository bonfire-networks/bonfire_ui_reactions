defmodule Bonfire.UI.Reactions.SortItemsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop title, :string
  prop scope, :any, default: nil
  prop feed_name, :atom, default: nil
  prop event_name, :any, default: nil
  prop event_target, :any, default: nil
  prop compact, :boolean, default: false

  declare_settings_component(l("Sort by reactions"), icon: "fluent:people-team-16-filled")
end
