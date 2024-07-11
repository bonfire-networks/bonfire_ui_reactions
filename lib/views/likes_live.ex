defmodule Bonfire.UI.Reactions.LikesLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  declare_nav_link(l("Likes"),
    page: "likes",
    href: "/likes",
    icon: "mingcute:fire-line",
    icon_active: "mingcute:fire-fill"
  )

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.UserRequired]}

  def mount(_params, _session, socket) do
    current_user = current_user_required!(socket)

    # %{edges: feed, page_info: page_info} =
    #   Bonfire.Social.Likes.list_my(current_user: current_user)
    # |> debug()

    {:ok,
     socket
     |> assign(
       nav_items: Bonfire.Common.ExtensionModule.default_nav(),
       feed: nil,
       feed_id: :likes,
       page_info: nil,
       page_title: l("Likes"),
       showing_within: :likes,
       loading: false,
       page: "likes",
       feed_name: :likes,
       feed_title: l("Likes")
     )}
  end

end
