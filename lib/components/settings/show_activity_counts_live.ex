defmodule Bonfire.UI.Reactions.ShowActivityCountsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop scope, :any, default: nil

  declare_settings_component("Show number of likes / boosts",
    icon: "fluent:people-team-16-filled",
    description:
      "You will see the number of reactions to activities (may not indicate the real amount for federated posts)"
  )
end
