defmodule Bonfire.UI.Reactions.Feeds.LikeActivityTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

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
    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me, alice: alice}
  end

  @tag :skip
  test "As a user I want to see the activity total likes", %{
    conn: conn,
    alice: alice,
    account: account
  } do
    if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
         current_user: alice,
         current_account: account
       ) do
      # Create bob user
      account2 = fake_account!()
      bob = fake_user!(account2)

      # bob follows alice
      Follows.follow(bob, alice)

      # Alice posts a message
      attrs = %{
        post_content: %{summary: "summary", html_body: "first post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

      assert {:ok, like} = Likes.like(bob, post)

      # Visit feed and check like count
      conn(user: alice, account: account)
      |> visit("/feed")
      |> assert_has(".activity", text: "Like (1)")
    end
  end

  test "As a user I want to see if I already liked an activity", %{
    conn: conn,
    alice: alice,
    account: account
  } do
    # Create bob user
    Process.put(:feed_live_update_many_preload_mode, :inline)

    account2 = fake_account!()
    bob = fake_user!(account2)

    # bob follows alice
    Follows.follow(bob, alice)

    # Alice posts a message
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, like} = Likes.like(bob, post)

    # Visit feed and check like status
    conn(user: bob, account: account2)
    |> visit("/feed")
    # |> PhoenixTest.open_browser()
    |> assert_has(".activity [data-id='like_action']", text: "Liked")
  end

  # test "As a user, when I like an activity the counter should increment", %{conn: conn, alice: alice, account: account} do
  #   Process.put(:feed_live_update_many_preload_mode, :inline)

  #   # Create bob user
  #   account2 = fake_account!()
  #   bob = fake_user!(account2)

  #   # bob follows alice
  #   Follows.follow(bob, alice)

  #   # Alice posts a message
  #   attrs = %{
  #     post_content: %{summary: "summary",  html_body: "first post"}
  #   }

  #   assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
  #   assert {:ok, like} = Likes.like(alice, post)

  #   # Visit feed as bob
  #   conn = conn(user: bob, account: account2)
  #   Process.put([:ui, :show_activity_counts], true)
  #   conn
  #   |> visit("/feed")
  #   |> PhoenixTest.open_browser()
  #   |> assert_has(".activity [data-id='like_action']", text: "Like (1)")
  #   |> click_button("[data-id='like_action']")

  #   # The page should update with the new like count
  #   if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
  #        current_user: bob,
  #        current_account: account2
  #      ) do
  #     assert_has(conn, ".activity [data-id='like_action']", text: "Liked (2)")
  #   else
  #     assert_has(conn, ".activity [data-id='like_action']", text: "Liked")
  #   end
  # end

  test "As a user, when I like a post, I want to see the activity liked subject", %{
    conn: conn,
    account: account,
    alice: alice
  } do
    account2 = fake_account!()
    bob = fake_user!(account2)
    Process.put(:feed_live_update_many_preload_mode, :inline)

    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, like} = Likes.like(bob, post)

    conn(user: bob, account: account2)
    |> visit("/feed/likes")
    |> assert_has("[data-id=subject_name]", text: alice.profile.name)
  end

  test "As a user, when I like an activity, the label should change from like to liked", %{
    conn: conn,
    account: account,
    alice: alice
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)
    # Create bob user
    account2 = fake_account!()
    bob = fake_user!(account2)

    # bob follows alice
    Follows.follow(alice, bob)

    # Alice posts a message
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

    conn = conn(user: bob, account: account2)

    conn
    |> visit("/feed/local")
    |> assert_has("[data-id='like_action']", text: "Like")
    |> click_button("Like")
    |> assert_has("[data-id='like_action']", text: "Liked")
  end

  # test "As a user when I unlike an activity, the counter should decrement", %{conn: conn} do
  #   # Create alice user
  #   account = fake_account!()
  #   alice = fake_user!(account)

  #   # Create bob user
  #   account2 = fake_account!()
  #   bob = fake_user!(account2)

  #   if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
  #        current_user: bob,
  #        current_account: account2
  #      ) do
  #     # bob follows alice
  #     Follows.follow(bob, alice)

  #     # Alice posts a message
  #     attrs = %{
  #       post_content: %{summary: "summary",  html_body: "first post"}
  #     }

  #     assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
  #     assert {:ok, like} = Likes.like(alice, post)
  #     assert {:ok, like} = Likes.like(bob, post)

  #     conn = conn(user: bob, account: account2)

  #     conn
  #     |> visit("/feed")
  #     |> assert_has(".activity [data-id='like_action']", text: "Liked (2)")
  #     |> click_button("[data-id='like_action']")
  #     |> assert_has(".activity [data-id='like_action']", text: "Like (1)")
  #   end
  # end

  test "As a user, when I unlike an activity, the label should change from liked to like", %{
    conn: conn,
    alice: alice,
    account: account
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)
    # Create bob user
    account2 = fake_account!()
    bob = fake_user!(account2)

    # bob follows alice
    Follows.follow(bob, alice)
    Process.put(:feed_live_update_many_preload_mode, :inline)

    # Alice posts a message
    attrs = %{
      post_content: %{summary: "summary", html_body: "first post"}
    }

    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
    assert {:ok, like} = Likes.like(bob, post)

    conn = conn(user: bob, account: account2)

    conn
    |> visit("/feed/local")
    |> assert_has("[data-id='like_action']", text: "Liked")
    |> click_button("Liked")
    |> assert_has("[data-id='like_action']", text: "Like")
  end
end

# defmodule Bonfire.UI.Reactions.Feeds.LikeActivityTest do
#   use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

#   alias Bonfire.Social.Fake
#   alias Bonfire.Me.Users
#   alias Bonfire.Social.Boosts
#   alias Bonfire.Social.Likes
#   alias Bonfire.Social.Graph.Follows
#   alias Bonfire.Posts

#   @tag :skip
#   test "As a user I want to see the activity total likes" do
#     # Create alice user
#     account = fake_account!()
#     alice = fake_user!(account)

#     if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
#          current_user: alice,
#          current_account: account
#        ) do
#       # Create bob user
#       account2 = fake_account!()
#       bob = fake_user!(account2)
#       # bob follows alice
#       Follows.follow(bob, alice)

#       attrs = %{
#         post_content: %{summary: "summary",  html_body: "first post"}
#       }

#       assert {:ok, post} =
#                Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

#       assert {:ok, boost} = Likes.like(bob, post)

#       feed = Bonfire.Social.FeedActivities.my_feed(alice)
#       # |> IO.inspect
#       fp = feed.edges |> List.first()

#       assert doc =
#                render_stateful(Bonfire.UI.Social.ActivityLive, %{
#                  id: "activity",
#                  activity: fp.activity
#                })

#       assert doc
#              |> Floki.parse_fragment()
#              ~> Floki.text() =~ "Like (1)"
#     end
#   end

#   @tag :fixme
#   test "As a user I want to see if I already liked an activity" do
#     # Create alice user
#     account = fake_account!()
#     alice = fake_user!(account)
#     # Create bob user
#     account2 = fake_account!()
#     bob = fake_user!(account2)
#     # bob follows alice
#     Follows.follow(bob, alice)

#     attrs = %{
#       post_content: %{summary: "summary",  html_body: "first post"}
#     }

#     assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
#     assert {:ok, like} = Likes.like(bob, post)

#     feed = Bonfire.Social.FeedActivities.my_feed(bob)
#     # |> IO.inspect
#     fp = feed.edges |> List.first()

#     assert doc =
#              render_stateful(
#                Bonfire.UI.Social.ActivityLive,
#                %{id: "activity", activity: fp.activity},
#                %{current_user: bob}
#              )

#     assert doc
#            |> Floki.parse_fragment()
#            ~> Floki.text() =~ "Liked"
#   end

#   @tag :fixme
#   test "As a user, when I like an activity the counter should increment" do
#     # Create alice user
#     account = fake_account!()
#     alice = fake_user!(account)
#     # Create bob user
#     account2 = fake_account!()
#     bob = fake_user!(account2)
#     # bob follows alice
#     Follows.follow(bob, alice)
#     # Alice posts a message
#     attrs = %{
#       post_content: %{summary: "summary",  html_body: "first post"}
#     }

#     assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
#     assert {:ok, like} = Likes.like(alice, post)
#     assert {:ok, like} = Likes.like(bob, post)

#     feed = Bonfire.Social.FeedActivities.my_feed(bob)
#     # |> IO.inspect
#     fp = feed.edges |> List.first()

#     assert doc =
#              render_stateful(
#                Bonfire.UI.Social.ActivityLive,
#                %{id: "activity", activity: fp.activity},
#                %{current_user: bob}
#              )

#     if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
#          current_user: bob,
#          current_account: account2
#        ) do
#       assert doc
#              |> Floki.parse_fragment()
#              ~> Floki.text() =~ "Liked (2)"
#     else
#       assert doc
#              |> Floki.parse_fragment()
#              ~> Floki.text() =~ "Liked"
#     end
#   end

#   test "As a user, when I like a post, I want to see the activity liked subject" do
#     account = fake_account!()
#     alice = fake_user!(account)
#     account2 = fake_account!()
#     bob = fake_user!(account2)
#     Process.put(:feed_live_update_many_preload_mode, :inline)

#     attrs = %{
#       post_content: %{summary: "summary",  html_body: "first post"}
#     }

#     assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
#     assert {:ok, like} = Likes.like(bob, post)

#     conn = conn(user: bob, account: account)

#     conn
#     |> visit("/feed/likes")
#     |> assert_has("[data-id=subject_name]", text: alice.profile.name)
#   end

#   @tag :fixme
#   test "As a user, when I like an activity, the label should change from like to liked" do
#     # Create alice user
#     account = fake_account!()
#     alice = fake_user!(account)
#     # Create bob user
#     account2 = fake_account!()
#     bob = fake_user!(account2)
#     # bob follows alice
#     Follows.follow(bob, alice)
#     # Alice posts a message
#     attrs = %{
#       post_content: %{summary: "summary",  html_body: "first post"}
#     }

#     assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
#     assert {:ok, like} = Likes.like(bob, post)

#     feed = Bonfire.Social.FeedActivities.my_feed(bob)
#     # |> IO.inspect
#     fp = feed.edges |> List.first()

#     assert doc =
#              render_stateful(
#                Bonfire.UI.Social.ActivityLive,
#                %{id: "activity", activity: fp.activity},
#                %{current_user: bob}
#              )

#     assert doc
#            |> Floki.parse_fragment()
#            ~> Floki.text() =~ "Liked"
#   end

#   test "As a user when I unlike an activity, the counter should decrement" do
#     # Create alice user
#     account = fake_account!()
#     alice = fake_user!(account)

#     # Create bob user
#     account2 = fake_account!()
#     bob = fake_user!(account2)

#     if Bonfire.Common.Settings.get([:ui, :show_activity_counts], nil,
#          current_user: bob,
#          current_account: account2
#        ) do
#       # bob follows alice
#       Follows.follow(bob, alice)
#       # Alice posts a message
#       attrs = %{
#         post_content: %{summary: "summary",  html_body: "first post"}
#       }

#       assert {:ok, post} =
#                Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")

#       assert {:ok, like} = Likes.like(alice, post)
#       assert {:ok, like} = Likes.like(bob, post)
#       assert unlike = Likes.unlike(bob, post)

#       feed = Bonfire.Social.FeedActivities.my_feed(bob)
#       # |> IO.inspect
#       fp = feed.edges |> List.first()

#       assert doc =
#                render_stateful(Bonfire.UI.Social.ActivityLive, %{
#                  id: "activity",
#                  activity: fp.activity
#                })

#       assert doc
#              |> Floki.parse_fragment()
#              ~> Floki.text() =~ "Like (1)"
#     end
#   end

#   test "As a user, when I unlike an activity, the label should change from liked to like" do
#     # Create alice user
#     account = fake_account!()
#     alice = fake_user!(account)
#     # Create bob user
#     account2 = fake_account!()
#     bob = fake_user!(account2)
#     # bob follows alice
#     Follows.follow(bob, alice)
#     # Alice posts a message
#     Process.put(:feed_live_update_many_preload_mode, :inline)

#     attrs = %{
#       post_content: %{summary: "summary",  html_body: "first post"}
#     }

#     assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
#     assert {:ok, like} = Likes.like(alice, post)
#     assert {:ok, like} = Likes.like(bob, post)
#     assert unlike = Likes.unlike(bob, post)

#     conn = conn(user: bob, account: account2)

#     conn
#     |> visit("/feed/local")
#     |> assert_has("[data-id=feed] article [data-id='like_action']", text: "Like")
#   end
# end
