defmodule Bonfire.UI.Reactions.Feeds.BoostsActivityTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Boosts
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Posts

  setup do
    account = fake_account!()
    me = fake_user!(account)
    alice = fake_user!(account)
    bob = fake_user!(account)
    carl = fake_user!(account)
    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me, alice: alice, bob: bob, carl: carl}
  end

  test "As a user when i boost a post i want to see the icon active", %{
    me: me,
    alice: alice,
    conn: conn
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _boost} = Boosts.boost(me, post)

    conn
    |> visit("/post/#{post.id}")
    |> assert_has("[data-boosted]")
  end

  test "As a user I want to see the activity total boosts", %{
    me: me,
    alice: alice,
    account: account,
    bob: bob,
    carl: carl,
    conn: conn
  } do
    if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
         current_user: alice,
         current_account: account
       ) do
      attrs = %{
        post_content: %{summary: "summary", html_body: "first post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

      assert {:ok, _boost} = Boosts.boost(bob, post)
      assert {:ok, _boost} = Boosts.boost(carl, post)
      assert {:ok, _boost} = Boosts.boost(me, post)
      assert _unboosted = Boosts.unboost(me, post)

      conn
      |> visit("/post/#{post.id}")
      |> assert_has("[data-id=boost_action]")
    end
  end

  test "As a user I want to see if I already boosted an activity", %{
    me: me,
    alice: alice,
    bob: bob,
    carl: carl,
    conn: conn
  } do
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    Process.put(:feed_live_update_many_preload_mode, :inline)

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _boost} = Boosts.boost(bob, post)
    assert {:ok, _boost} = Boosts.boost(carl, post)
    assert {:ok, _boost} = Boosts.boost(me, post)

    conn
    |> visit("/feed/local")
    |> assert_has("[data-id=boost_action]")
    |> assert_has("[data-id=boost_action]", text: "Boosted")
  end

  test "As a user, when I boost a post, I want to see the activity boosted subject", %{
    account: account,
    alice: alice,
    bob: bob
  } do
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _boost} = Boosts.boost(bob, post)

    conn(user: alice, account: account)
    |> visit("/feed")
    |> assert_has("[data-role=boosted_by]", text: bob.profile.name)
  end

  test "As a user, when I boosts a post, I want to see the activity boosted object", %{
    alice: alice,
    bob: bob,
    account: account
  } do
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _boost} = Boosts.boost(bob, post)

    conn(user: bob, account: account)
    |> visit("/feed")
    |> assert_has("[data-id=object_body]", text: "first post")
  end

  test "As a user, when I boost a post, I want to see the author of the boost", %{
    account: account,
    alice: alice,
    bob: bob
  } do
    Follows.follow(alice, bob)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _boost} = Boosts.boost(bob, post)

    conn(user: alice, account: account)
    |> visit("/feed")
    |> assert_has("[data-role=subject]", text: bob.profile.name)
  end

  test "As a user, when I unboost an activity, the counter should decrement", %{
    me: me,
    alice: alice,
    account: account,
    conn: conn
  } do
    if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
         current_user: me,
         current_account: account
       ) do
      attrs = %{
        post_content: %{summary: "summary", html_body: "first post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

      assert {:ok, _boost} = Boosts.boost(alice, post)
      assert {:ok, _boost} = Boosts.boost(me, post)

      conn
      |> visit("/post/#{post.id}")
      |> assert_has("[data-id=boost_action]", text: "Boosted (2)")
      |> click_button("[data-id=boost_action]")
      |> assert_has("[data-id=boost_action]", text: "Boost (1)")
    end
  end

  test "As a user, when I unboost an activity, the label should change to boost", %{
    me: me,
    alice: alice,
    conn: conn
  } do
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    Process.put(:feed_live_update_many_preload_mode, :inline)

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, _boost} = Boosts.boost(me, post)

    conn
    |> visit("/feed/local")
    |> assert_has("[data-id=boost_action]", text: "Boosted")
    |> click_button("Boosted")
    |> assert_has("[data-id=boost_action]", text: "Boost")
  end

  test "boost label shows Boost on an unboosted post page", %{
    me: me,
    alice: alice,
    conn: conn
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    attrs = %{
      post_content: %{summary: "summary", html_body: "a post to check boost state"}
    }

    assert {:ok, post} =
             Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    conn
    |> visit("/post/#{post.id}")
    |> refute_has("[data-boosted]")
    |> assert_has("[data-id=boost_action]", text: "Boost")
  end
end
