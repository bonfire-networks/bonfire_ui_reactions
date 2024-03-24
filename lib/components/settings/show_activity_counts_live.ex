defmodule Bonfire.UI.Reactions.ShowActivityCountsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop scope, :any, default: nil

  declare_settings_component(l("Enable reaction counts"), icon: "fluent:people-team-16-filled")
end
