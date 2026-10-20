defmodule Bonfire.UI.Reactions.InstancePinsLive do
  @moduledoc """
  Page view for activities pinned to the instance.
  """

  use Bonfire.UI.Common.Web,
      {:surface_live_view_child, layout: {Bonfire.UI.Common.LayoutView, :iframe}}

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(raw_params, session, socket) do
    widget_title = l("Instance Pins")
    params = socket.assigns[:current_params] || (is_map(raw_params) && raw_params) || %{}

    socket =
      socket
      |> Bonfire.UI.Common.ThemeHelper.setup_embed(e(params, "theme", nil), true)
      # only the embed controller sets it, through the session: conn assigns don't reach a controller-rendered LiveView
      |> assign_new(:embed?, fn -> session["embed"] == true end)

    {:ok,
     socket
     |> assign(
       page: "instance_pins",
       selected_tab: :instance_pins,
       # how many cards show from the `sm` breakpoint up
       visible_items: visible_items(params["items"]),
       widget_title: widget_title,
       page_title: widget_title
     )
     |> maybe_assign_embed_link_target()}
  end

  @doc """
  How many whole cards the carousel shows from the `sm` breakpoint up: `?items=`, between 1 and 4, else 3.

      iex> Bonfire.UI.Reactions.InstancePinsLive.visible_items("2")
      2

      iex> Bonfire.UI.Reactions.InstancePinsLive.visible_items("9")
      4

      iex> Bonfire.UI.Reactions.InstancePinsLive.visible_items(nil)
      3
  """
  def visible_items(items),
    do: (Bonfire.Common.Types.maybe_to_pos_integer(items) || 3) |> min(4)

  # in embeds, links must escape the iframe: LinkLive & co read link_target from
  # context, and the iframe layout reads it (same mechanism as `:go`) to rewrite
  # rich-text links (mentions/hashtags) that LiveView would otherwise navigate
  # inside the iframe
  defp maybe_assign_embed_link_target(%{assigns: %{embed?: true}} = socket),
    do: assign_global(socket, :link_target, "_blank")

  defp maybe_assign_embed_link_target(socket), do: socket
end
