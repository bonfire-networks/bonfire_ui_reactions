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

    socket =
      socket
      |> Bonfire.UI.Common.ThemeHelper.setup_embed(e(params, "theme", nil), true)
      |> assign_new(:live_action, fn -> nil end)
      # only the embed controller assigns embed_variant, so nil = the in-app routes
      |> assign_new(:embed_variant, fn -> nil end)

    {:ok,
     socket
     |> assign(
       page: "instance_pins",
       selected_tab: :instance_pins,
       widget_title: widget_title,
       page_title: widget_title
     )
     |> maybe_assign_embed_link_target()}
  end

  # in embeds, links must escape the iframe: LinkLive & co read link_target from
  # context, and the iframe layout reads it (same mechanism as `:go`) to rewrite
  # rich-text links (mentions/hashtags) that LiveView would otherwise navigate
  # inside the iframe
  defp maybe_assign_embed_link_target(%{assigns: %{embed_variant: embed_variant}} = socket)
       when not is_nil(embed_variant),
       do: assign_global(socket, :link_target, "_blank")

  defp maybe_assign_embed_link_target(socket), do: socket
end
