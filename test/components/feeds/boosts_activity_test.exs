defmodule Bonfire.UI.Reactions.Feeds.BoostsActivityTest do
  use Bonfire.UI.Reactions.ConnCase, async: true

  alias Bonfire.Social.Fake
  alias Bonfire.Me.Users
  alias Bonfire.Social.Boosts
  alias Bonfire.Social.Likes
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
        post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

      assert {:ok, boost} = Boosts.boost(bob, post)
      assert {:ok, boost} = Boosts.boost(carl, post)
      assert {:ok, boost} = Boosts.boost(me, post)
      assert unboosted = Boosts.unboost(me, post)

      conn
      |> visit("/post/#{post.id}")
      |> assert_has("[data-id=boost_action]")

      # |> assert_has("[data-id=boost_action]", text: "Boost (2)")
    end
  end

  test "As a user I want to see if I already boosted an activity", %{
    me: me,
    alice: alice,
    account: account,
    bob: bob,
    carl: carl,
    conn: conn
  } do
    attrs = %{
      post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
    }

    Bonfire.Common.Config.put(:feed_live_update_many_preloads, :inline)
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, boost} = Boosts.boost(bob, post)
    assert {:ok, boost} = Boosts.boost(carl, post)
    assert {:ok, boost} = Boosts.boost(me, post)

    conn
    |> visit("/feed/local")
    |> assert_has("[data-id=boost_action]")
    |> assert_has("[data-id=boost_action]", text: "Boosted")
  end

  test "As a user, when I boost a post, I want to see the activity boosted subject" do
    account = fake_account!()
    alice = fake_user!(account)
    account2 = fake_account!()
    bob = fake_user!(account2)

    attrs = %{
      post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, boost} = Boosts.boost(bob, post)
    feed = Bonfire.Social.FeedActivities.my_feed(alice)
    # |> IO.inspect
    fp = feed.edges |> List.first()
    # conn = conn(user: alice, account: account)
    # next = "/feed/local"
    # {view, doc} = floki_live(conn, next)
    # open_browser(view)
    assert doc =
             render_stateful(Bonfire.UI.Social.ActivityLive, %{
               id: "activity",
               activity: fp.activity
             })

    assert doc
           |> Floki.parse_fragment()
           ~> Floki.find("[data-role=boosted_by]")
           |> Floki.text() =~ bob.profile.name
  end

  test "As a user, when I boosts a post, I want to see the activity boosted object" do
    alice = fake_user!()
    bob = fake_user!()

    attrs = %{
      post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, boost} = Boosts.boost(bob, post)
    feed = Bonfire.Social.FeedActivities.my_feed(bob)
    # |> IO.inspect
    fp = feed.edges |> List.first()

    assert doc =
             render_stateful(Bonfire.UI.Social.ActivityLive, %{
               id: "activity",
               activity: fp.activity
             })

    assert doc
           # |> Floki.parse_fragment
           # ~> Floki.find("div.object_body")
           |> Floki.text() =~ "first post"
  end

  test "As a user, when I boost a post, I want to see the author of the boost" do
    alice = fake_user!("alice")
    bob = fake_user!("bob")
    # bob follows alice
    Follows.follow(alice, bob)

    attrs = %{
      post_content: %{summary: "summary", name: "test post by alice", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    assert {:ok, boost} = Boosts.boost(bob, post)

    feed = Bonfire.Social.FeedActivities.my_feed(alice)
    # |> IO.inspect
    fp = feed.edges |> List.first()

    assert doc =
             render_stateful(Bonfire.UI.Social.ActivityLive, %{
               id: "activity",
               activity: fp.activity
             })

    assert doc
           |> Floki.parse_fragment()
           ~> Floki.find("[data-id=subject]")
           |> List.first()
           |> Floki.text() =~ bob.profile.name
  end

  test "As a user, when I boost an activity, the counter should increment" do
    # Create alice user
    account = fake_account!()
    alice = fake_user!(account)

    # Create bob user
    account2 = fake_account!()
    bob = fake_user!(account2)

    if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
         current_user: bob,
         current_account: account2
       ) do
      # bob follows alice
      Follows.follow(bob, alice)

      attrs = %{
        post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

      assert {:ok, boost} = Boosts.boost(alice, post)

      assert {:ok, boost} = Boosts.boost(bob, post)

      feed = Bonfire.Social.FeedActivities.my_feed(bob)
      # |> IO.inspect
      fp = feed.edges |> List.first()

      assert doc =
               render_stateful(Bonfire.UI.Social.ActivityLive, %{
                 id: "activity",
                 activity: fp.activity
               })

      assert doc
             |> Floki.parse_fragment()
             ~> Floki.find("[data-id=boost_action]")
             |> Floki.text() =~ "Boosted (2)"
    end
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
        post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

      assert {:ok, boost} = Boosts.boost(alice, post)

      assert {:ok, boost} = Boosts.boost(me, post)
      assert unboosted = Boosts.unboost(me, post)

      conn
      |> visit("/post/#{post.id}")
      |> assert_has("[data-id=boost_action]")
      |> assert_has("[data-id=boost_action]", text: "Boost (1)")
    end
  end

  test "As a user, when I unboost an activity, the label should change to boost", %{
    me: me,
    alice: alice,
    conn: conn
  } do
    attrs = %{
      post_content: %{summary: "summary", name: "test post name", html_body: "first post"}
    }

    Bonfire.Common.Config.put(:feed_live_update_many_preloads, :inline)
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, boost} = Boosts.boost(me, post)
    assert unboosted = Boosts.unboost(me, post)

    conn
    |> visit("/feed/local")
    |> assert_has("[data-id=boost_action]", text: "Boost")
  end
end
