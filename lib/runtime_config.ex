defmodule Bonfire.UI.Reactions.RuntimeConfig do
  use Bonfire.Common.Localise
  import Bonfire.Common.Modularity.DeclareHelpers

  @behaviour Bonfire.Common.ConfigModule
  def config_module, do: true

  declare_extension("Reactions",
    icon: "material-symbols:add-reaction",
    emoji: "👏",
    description: l("Likes, boosts, pins, bookmarks, etc."),
    exclude_from_nav: true
  )

  @doc """
  NOTE: you can override this default config in your app's `runtime.exs`, by placing similarly-named config keys below the `Bonfire.Common.Config.LoadExtensionsConfig.load_configs()` line
  """
  def config do
    import Config

    # config :bonfire_ui_social,
    #   modularity: :disabled

    config :bonfire, :ui,
      profile: [
        # TODO: make dynamic based on enabled modules
        sections: [
          boosts: Bonfire.UI.Reactions.ProfileBoostsLive,
          highlights: Bonfire.UI.Reactions.ProfilePinsLive
        ],
        navigation: [
          boosts: l("Boosts")
          # highlights: l("Highlights") # TODO: fix preloads
        ],
        widgets: []
      ]
  end
end
