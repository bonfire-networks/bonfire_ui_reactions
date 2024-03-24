defmodule Bonfire.UI.Reactions.RuntimeConfig do
  use Bonfire.Common.Localise
  import Bonfire.Common.Modularity.DeclareHelpers

  @behaviour Bonfire.Common.ConfigModule
  def config_module, do: true

  declare_extension("Reactions",
    # icon: "noto:newspaper",
    # emoji: "📰",
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
        # TODO: make dynamic based on active extensions
        sections: [
          boosts: Bonfire.UI.Reactions.ProfileBoostsLive,
          highlights: Bonfire.UI.Reactions.ProfilePinsLive
        ],
        navigation: [
          boosts: l("Boosts")
        ],
        widgets: []
      ]
  end
end
