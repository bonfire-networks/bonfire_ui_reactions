defmodule Bonfire.UI.Reactions.EmbedInstancePinsController do
  use Bonfire.UI.Common.Web, :controller

  def index(conn, params), do: render_embed(conn, params, :list)

  def carousel(conn, params), do: render_embed(conn, params, :carousel)

  defp render_embed(conn, _params, embed_variant),
    do:
      conn
      |> assign(
        widget_title: l("Featured content"),
        no_header: true,
        without_sidebar: true,
        without_secondary_widgets: true,
        sidebar_widgets: [],
        force_static: true,
        embed_variant: embed_variant
      )
      |> live_render(Bonfire.UI.Reactions.InstancePinsLive,
        layout: {Bonfire.UI.Common.LayoutView, :iframe},
        # conn assigns don't reach a controller-rendered LiveView's mount, so pass the variant
        # through the session (survives the disconnected→connected remount too)
        session: %{"embed_variant" => to_string(embed_variant)}
      )
end
