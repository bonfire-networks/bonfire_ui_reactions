defmodule Bonfire.UI.Reactions.InstancePinsLive do
  @moduledoc """
  Page view for activities pinned to the instance.
  """

  use Bonfire.UI.Common.Web, :surface_live_view

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page: "instance_pins",
       selected_tab: :instance_pins,
       page_title: l("Instance Pins"),
       no_header: true,
       without_sidebar: true,
       without_secondary_widgets: true,
       sidebar_widgets: []
     )}
  end
end
