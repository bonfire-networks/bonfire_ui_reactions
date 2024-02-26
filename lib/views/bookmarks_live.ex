defmodule Bonfire.UI.Reactions.BookmarksLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  declare_nav_link(l("Bookmarks"),
    page: "bookmarks",
    href: "/bookmarks",
    icon: "carbon:bookmark",
    icon_active: "carbon:bookmark-filled"
  )

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.UserRequired]}

  def mount(_params, _session, socket) do
    current_user = current_user_required!(socket)

    # %{edges: feed, page_info: page_info} =
    #   Bonfire.Social.Bookmarks.list_my(current_user: current_user)

    # |> debug()

    {:ok,
     socket
     |> assign(
       nav_items: Bonfire.Common.ExtensionModule.default_nav(),
       feed: nil,
       page_info: nil,
       page_title: "Bookmarks",
       showing_within: :bookmarks,
       loading: false,
       page: "bookmarks",
       feed_name: :bookmarks,
       feed_title: l("Bookmarks")
     )}
  end

  # def handle_params(%{"tab" => tab} = _params, _url, socket) do
  #   {:noreply,
  #    assign(socket,
  #      selected_tab: tab
  #    )}
  # end

  # def handle_params(%{} = _params, _url, socket) do
  #   {:noreply,
  #    assign(socket,
  #      current_user: Fake.user_live()
  #    )}
  # end
end
