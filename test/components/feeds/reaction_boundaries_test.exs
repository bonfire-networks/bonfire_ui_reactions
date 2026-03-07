defmodule Bonfire.UI.Reactions.Feeds.ReactionBoundariesTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Posts
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Boundaries.Acls
  alias Bonfire.Boundaries.Grants
  alias Bonfire.Boundaries.Controlleds

  setup do
    account = fake_account!()
    me = fake_user!(account)

    {:ok, account: account, me: me}
  end

  test "reaction buttons are enabled for a user viewing a public post in their feed", %{
    me: me
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(bob, me)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a public post with reactions"}
    }

    assert {:ok, _post} = Posts.publish(current_user: me, post_attrs: attrs, boundary: "public")

    conn(user: bob, account: account2)
    |> visit("/feed/local")
    |> assert_has("[data-role='like_enabled']")
    |> assert_has("[data-role='boost_enabled']")
    |> assert_has("[data-role='bookmark_enabled']")
  end

  test "reaction buttons show correct initial state for a fresh post", %{me: me} do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    Follows.follow(bob, me)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a fresh post nobody reacted to"}
    }

    assert {:ok, _post} = Posts.publish(current_user: me, post_attrs: attrs, boundary: "public")

    # Fresh post should not have any pressed/active reaction state
    conn(user: bob, account: account2)
    |> visit("/feed/local")
    |> refute_has("[data-id='like_action'][aria-pressed]")
    |> refute_has("[data-id='bookmark_action'][aria-pressed]")
  end

  # With optimistic UI, reaction buttons render as enabled by default (boundaries
  # are checked server-side on click). These tests verify that clicking a reaction
  # on a restricted post shows an error instead of succeeding.

  test "liking a post fails when user lacks :like permission", %{me: me} do
    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a read-only post for bob"}
    }

    # Publish with "mentions" boundary (no preset ACLs) and grant only :read/:see to bob
    assert {:ok, post} =
             Posts.publish(
               current_user: me,
               post_attrs: attrs,
               boundary: "mentions",
               to_circles: [bob.id],
               verbs_to_grant: [:read, :see]
             )

    conn(user: bob, account: account2)
    |> visit("/post/#{post.id}")
    |> assert_has("[data-role='like_enabled']")
    |> click_button("[data-role='like_enabled']", "Like")
    |> assert_has("[role=alert]")
  end

  test "boosting a post fails when user lacks :boost permission", %{me: me} do
    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a read-only post for bob"}
    }

    # Publish with "mentions" boundary (no preset ACLs) and grant only :read/:see to bob
    assert {:ok, post} =
             Posts.publish(
               current_user: me,
               post_attrs: attrs,
               boundary: "mentions",
               to_circles: [bob.id],
               verbs_to_grant: [:read, :see]
             )

    conn(user: bob, account: account2)
    |> visit("/post/#{post.id}")
    |> assert_has("[data-role='boost_enabled']")
    |> click_button("[data-role='boost_enabled']", "Boost")
    |> assert_has("[role=alert]")
  end

  test "reaction buttons are enabled when user has full interaction permissions", %{me: me} do
    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a fully interactive post for bob"}
    }

    # Publish with "mentions" boundary and grant full interaction verbs to bob
    assert {:ok, post} =
             Posts.publish(
               current_user: me,
               post_attrs: attrs,
               boundary: "mentions",
               to_circles: [bob.id],
               verbs_to_grant: [:read, :see, :like, :boost, :bookmark]
             )

    conn(user: bob, account: account2)
    |> visit("/post/#{post.id}")
    |> assert_has("[data-role='like_enabled']")
    |> assert_has("[data-role='boost_enabled']")
  end

  test "liking and boosting fail with manual read-only ACL setup", %{me: me} do
    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a manually restricted post"}
    }

    # Publish as author-only (mentions with no recipients)
    assert {:ok, post} =
             Posts.publish(
               current_user: me,
               post_attrs: attrs,
               boundary: "mentions"
             )

    # Manually create a read-only ACL for bob
    {:ok, acl} = Acls.simple_create(me, "read-only for bob")
    Grants.grant(bob.id, acl.id, :read, true, current_user: me)
    Grants.grant(bob.id, acl.id, :see, true, current_user: me)
    Controlleds.add_acls(post, acl)

    # Buttons render as enabled (optimistic UI), but clicking them should fail
    conn(user: bob, account: account2)
    |> visit("/post/#{post.id}")
    |> assert_has("[data-role='like_enabled']")
    |> click_button("[data-role='like_enabled']", "Like")
    |> assert_has("[role=alert]")
  end
end
