defmodule Bonfire.UI.Reactions.Feeds.BookmarkActivityTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Bookmarks
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Posts

  setup do
    account = fake_account!()
    me = fake_user!(account)
    alice = fake_user!(account)
    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me, alice: alice}
  end

  test "As a user I want to see a bookmarked post in my bookmarks feed", %{
    alice: alice
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", html_body: "bookmarkable post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, _bookmark} = Bookmarks.bookmark(bob, post)

    conn(user: bob, account: account2)
    |> visit("/feed/bookmarks")
    |> assert_has(".activity", text: "bookmarkable post")
  end

  test "As a user, when I bookmark an activity, the button state should change", %{
    alice: alice
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(alice, bob)

    attrs = %{
      post_content: %{summary: "summary", html_body: "bookmarkable post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    conn(user: bob, account: account2)
    |> visit("/feed/local")
    |> within("[data-object_id='#{post.id}']", fn session ->
      session
      |> refute_has("[data-id='bookmark_action'][aria-pressed]")
      |> click_button("Bookmark")
      |> assert_has("[data-id='bookmark_action'][aria-pressed]")
    end)
  end

  test "As a user, when I remove a bookmark, the button state should change back", %{
    alice: alice
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(alice, bob)

    attrs = %{
      post_content: %{summary: "summary", html_body: "bookmarkable post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    # Bookmark via UI click, then unbookmark
    conn(user: bob, account: account2)
    |> visit("/feed/local")
    |> within("[data-object_id='#{post.id}']", fn session ->
      session
      |> click_button("Bookmark")
      |> assert_has("[data-id='bookmark_action'][aria-pressed]")
      |> click_button("Remove bookmark")
      |> refute_has("[data-id='bookmark_action'][aria-pressed]")
    end)
  end
end
