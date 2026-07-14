defmodule Bonfire.UI.Reactions.InstancePinsLive do
  @moduledoc """
  Page view for activities pinned to the instance.
  """

  use Bonfire.UI.Common.Web,
      {:surface_live_view_child, layout: {Bonfire.UI.Common.LayoutView, :iframe}}

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(raw_params, session, socket) do
    widget_title = e(socket.assigns, :widget_title, l("Instance Pins"))
    params = socket.assigns[:current_params] || (is_map(raw_params) && raw_params) || %{}

    socket =
      socket
      |> Bonfire.UI.Common.ThemeHelper.setup_embed(e(params, "theme", nil), true)
      |> assign_new(:live_action, fn -> nil end)
      # only the embed controller sets embed_variant (via the session, since conn assigns don't
      # reach a controller-rendered LiveView), so nil = the in-app routes
      |> assign_new(:embed_variant, fn -> embed_variant_from_session(session) end)

    {:ok,
     socket
     |> assign(
       page: "instance_pins",
       selected_tab: :instance_pins,
       # layout choice: embeds pass embed_variant, the in-app route uses live_action
       variant:
         socket.assigns[:embed_variant] ||
           if(socket.assigns[:live_action] == :carousel, do: :carousel),
       widget_title: widget_title,
       page_title: widget_title
     )
     |> maybe_assign_embed_link_target()}
  end

  defp embed_variant_from_session(%{"embed_variant" => "carousel"}), do: :carousel
  defp embed_variant_from_session(%{"embed_variant" => "list"}), do: :list
  defp embed_variant_from_session(_), do: nil

  # in embeds, links must escape the iframe: LinkLive & co read link_target from
  # context, and the iframe layout reads it (same mechanism as `:go`) to rewrite
  # rich-text links (mentions/hashtags) that LiveView would otherwise navigate
  # inside the iframe
  defp maybe_assign_embed_link_target(%{assigns: %{embed_variant: embed_variant}} = socket)
       when not is_nil(embed_variant),
       do: assign_global(socket, :link_target, "_blank")

  defp maybe_assign_embed_link_target(socket), do: socket
end
