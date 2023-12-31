defmodule Bonfire.Social.Activities.BoostPost.Test do
  use Bonfire.UI.Reactions.ConnCase, async: true
  alias Bonfire.Social.Fake
  alias Bonfire.Posts
  alias Bonfire.Social.Boosts
  alias Bonfire.Social.Graph.Follows
  import Bonfire.Common.Enums

  describe "boost a post" do
    test "and it appears on my feed" do
      poster = fake_user!()
      content = "here is an epic html post"
      attrs = %{post_content: %{html_body: content}}

      assert {:ok, post} =
               Posts.publish(current_user: poster, post_attrs: attrs, boundary: "local")

      some_account = fake_account!()
      someone = fake_user!(some_account)
      conn = conn(user: someone, account: some_account)

      next = "/feed/local"
      # |> IO.inspect
      {view, doc} = floki_live(conn, next)

      # FIXME: we should check for the actual post, not the mere existence of one
      assert view
             |> element(".feed [data-id='boost_action]")
             |> render_click()

      # |> Floki.text() =~ "Boosted"
      # FIXME: check if boost appears instantly (websocket)

      next = "/user"
      # |> IO.inspect
      {view, doc} = floki_live(conn, next)
      assert feed = Floki.find(doc, ".feed")
      assert Floki.text(feed) =~ content
    end
  end

  describe "unboost a post" do
    test "works" do
      some_account = fake_account!()
      poster = fake_user!(some_account)
      someone = fake_user!(some_account)

      content = "here is an epic html post"
      attrs = %{post_content: %{html_body: content}}
      # poster posts
      assert {:ok, post} =
               Posts.publish(current_user: poster, post_attrs: attrs, boundary: "public")

      conn = conn(user: someone, account: some_account)

      # someone boosts
      assert {:ok, boost} = Boosts.boost(someone, post)
      assert true == Boosts.boosted?(someone, post)

      next = "/feed/local"
      # |> IO.inspect
      {view, doc} = floki_live(conn, next)

      # unboost
      assert view
             |> element("[data-id=feed] > div article button[data-id='boost_action]")
             # |> info
             |> render_click()
             |> Floki.text() =~ "Boost"

      assert false == Boosts.boosted?(someone, post)

      next = "/user"
      # |> IO.inspect
      {view, doc} = floki_live(conn, next)
      assert feed = Floki.find(doc, ".feed")
      refute Floki.text(feed) =~ content
    end
  end

  # Not relevant for alpha
  # test "As a user I want to see the activity total boosts" do
  #   # Create alice user
  #   account = fake_account!()
  #   alice = fake_user!(account)
  #   # Create bob user
  #   account2 = fake_account!()
  #   bob = fake_user!(account2)
  #   # bob follows alice
  #   Follows.follow(bob, alice)
  #   attrs = %{post_content: %{summary: "summary", name: "test post name", html_body: "<p>first post/p>"}}

  #   assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "public")
  #   assert {:ok, boost} = Boosts.boost(bob, post)

  #   conn = conn(user: bob, account: account2)
  #   next = "/feed"
  #   {view, doc} = floki_live(conn, next)
  #   activity =  doc
  #     |> Floki.find("[data-id=feed] article [data-id='boost_action]")
  #     |> List.last
  #   assert activity |> Floki.text =~ "Boosted"
  #   assert activity |> Floki.text =~ "Boosted (1)"
  # end
end
