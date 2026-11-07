defmodule Bonfire.UI.Reactions.StatefulActionsTest do
  @moduledoc """
  Liking and boosting with the activity actions rendered as stateful components: what an instance gets with a feed preload mode other than the default `:async_actions` (here `:async_total`). Each button sends its event to its own component, which must know what it is about.
  """
  use Bonfire.UI.Reactions.ConnCase, async: false
  @moduletag :ui

  import Phoenix.LiveViewTest
  import Bonfire.Posts.Fake, only: [fake_post!: 3]

  setup do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :async_total)

    account = fake_account!()
    me = fake_user!(account)

    post =
      fake_post!(fake_user!(), "public", %{post_content: %{html_body: "<p>worth a like</p>"}})

    {:ok, conn: conn(user: me, account: account), me: me, post: post}
  end

  test "Like likes the post", %{conn: conn, me: me, post: post} do
    {:ok, view, _html} = live(conn, "/discussion/#{post.id}")

    view
    |> element("[data-role=like_enabled]")
    |> render_click()

    assert Bonfire.Social.Likes.liked?(me, post)
  end

  test "Bookmark bookmarks the post", %{conn: conn, me: me, post: post} do
    {:ok, view, _html} = live(conn, "/discussion/#{post.id}")

    view
    |> element("[data-role=bookmark_enabled]")
    |> render_click()

    assert Bonfire.Social.Bookmarks.bookmarked?(me, post)
  end

  test "Boost boosts the post", %{conn: conn, me: me, post: post} do
    {:ok, view, _html} = live(conn, "/discussion/#{post.id}")

    view
    |> element("[data-role=boost_enabled]")
    |> render_click()

    assert Bonfire.Social.Boosts.boosted?(me, post)
  end
end
