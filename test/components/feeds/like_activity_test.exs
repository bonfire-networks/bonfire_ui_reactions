defmodule Bonfire.UI.Reactions.Feeds.LikeActivityTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Likes
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Posts

  setup do
    account = fake_account!()
    me = fake_user!(account)
    alice = fake_user!(account)
    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me, alice: alice}
  end

  test "As a user I want to see the activity total likes", %{
    alice: alice,
    account: account
  } do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    alice =
      Bonfire.Common.Utils.current_user(
        Bonfire.Common.Settings.put([:ui, :show_activity_counts], true, current_user: alice)
      )

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(bob, alice)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _like} = Likes.like(bob, post)

    conn(user: alice, account: account)
    |> visit("/feed")
    |> assert_has("[data-role=like_count]", text: "1")
  end

  test "As a user I want to see if I already liked an activity", %{
    alice: alice
  } do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(bob, alice)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, _like} = Likes.like(bob, post)

    conn(user: bob, account: account2)
    |> visit("/feed")
    |> assert_has(".activity [data-id='like_action'][aria-pressed]")
  end

  test "As a user, when I like a post, I want to see the activity liked subject", %{
    alice: alice
  } do
    account2 = fake_account!()
    bob = fake_user!(account2)
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _like} = Likes.like(bob, post)

    conn(user: bob, account: account2)
    |> visit("/feed/likes")
    |> assert_has("[data-id=subject_name]", text: alice.profile.name)
  end

  test "As a user, when I like an activity, the label should change from like to liked", %{
    alice: alice
  } do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(alice, bob)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    conn(user: bob, account: account2)
    |> visit("/feed/local")
    |> within("[data-object_id='#{post.id}']", fn session ->
      session
      |> refute_has("[data-id='like_action'][aria-pressed]")
      |> click_button("Like")
      |> assert_has("[data-id='like_action'][aria-pressed]")
    end)
  end

  test "As a user, when I unlike an activity, the label should change from liked to like", %{
    alice: alice
  } do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(bob, alice)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _like} = Likes.like(bob, post)

    conn(user: bob, account: account2)
    |> visit("/feed/local")
    |> within("[data-object_id='#{post.id}']", fn session ->
      session
      |> assert_has("[data-id='like_action'][aria-pressed]")
      |> click_button("Like")
      |> refute_has("[data-id='like_action'][aria-pressed]")
    end)
  end

  test "like toggle works on a post page", %{alice: alice} do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a post to like on its page"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    conn(user: bob, account: account2)
    |> visit("/post/#{post.id}")
    |> refute_has("[data-id='like_action'][aria-pressed]")
    |> click_button("Like")
    |> assert_has("[data-id='like_action'][aria-pressed]")
  end
end
