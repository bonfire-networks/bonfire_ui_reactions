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
        layout: {Bonfire.UI.Common.LayoutView, :iframe}
      )
end
