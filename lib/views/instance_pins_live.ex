defmodule Bonfire.UI.Reactions.InstancePinsLive do
  @moduledoc """
  Page view for activities pinned to the instance.
  """

  use Bonfire.UI.Common.Web, :surface_live_view_child

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(_params, _session, socket) do
    widget_title = e(socket.assigns, :widget_title, l("Instance Pins"))

    {:ok,
     socket
     |> assign_new(:no_header, fn -> false end)
     |> assign_new(:without_sidebar, fn -> nil end)
     |> assign_new(:without_secondary_widgets, fn -> false end)
     |> assign_new(:sidebar_widgets, fn -> [] end)
     |> assign_new(:force_static, fn -> false end)
     |> assign(
       page: "instance_pins",
       selected_tab: :instance_pins,
       widget_title: widget_title,
       page_title: widget_title
     )}
  end
end
