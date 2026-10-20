defmodule Bonfire.UI.Reactions.EmbedInstancePinsController do
  use Bonfire.UI.Common.Web, :controller

  def index(conn, params),
    do:
      conn
      |> assign(
        no_header: true,
        without_sidebar: true,
        without_secondary_widgets: true,
        sidebar_widgets: [],
        force_static: true
      )
      |> live_render(Bonfire.UI.Reactions.InstancePinsLive,
        layout: {Bonfire.UI.Common.LayoutView, :iframe},
        # conn assigns don't reach a controller-rendered LiveView's mount, so pass these through the session (survives the disconnected→connected remount too); `"params"` becomes its `current_params`, as for `EmbedCommentsController`
        session: %{"embed" => true, "params" => params}
      )
end
