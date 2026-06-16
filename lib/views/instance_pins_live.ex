defmodule Bonfire.UI.Reactions.InstancePinsLive do
  @moduledoc """
  Page view for activities pinned to the instance.
  """

  use Bonfire.UI.Common.Web,
      {:surface_live_view_child, layout: {Bonfire.UI.Common.LayoutView, :iframe}}

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(raw_params, _session, socket) do
    widget_title = e(socket.assigns, :widget_title, l("Instance Pins"))
    params = socket.assigns[:current_params] || (is_map(raw_params) && raw_params) || %{}

    {:ok,
     socket
     |> Bonfire.UI.Common.ThemeHelper.setup_embed(e(params, "theme", nil), true)
     |> assign_new(:live_action, fn -> nil end)
     |> assign_new(:embed_variant, fn -> :list end)
     |> assign(
       page: "instance_pins",
       selected_tab: :instance_pins,
       widget_title: widget_title,
       page_title: widget_title
     )}
  end
end
