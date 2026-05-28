defmodule Bonfire.UI.Reactions.EmbedInstancePinsController do
  use Bonfire.UI.Common.Web, :controller

  def index(conn, _),
    do:
      conn
      |> assign(
        widget_title: l("Featured content"),
        no_header: true,
        without_sidebar: true,
        without_secondary_widgets: true,
        sidebar_widgets: [],
        force_static: true
      )
      |> live_render(Bonfire.UI.Reactions.InstancePinsLive,
        layout: {Bonfire.UI.Common.LayoutView, :iframe}
      )
end
