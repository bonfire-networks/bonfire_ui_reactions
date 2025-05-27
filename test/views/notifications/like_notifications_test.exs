defmodule Bonfire.Social.Notifications.Likes.Test do
  use Bonfire.UI.Reactions.ConnCase, async: true
  alias Bonfire.Social.Fake
  alias Bonfire.Social.Likes
  alias Bonfire.Posts

  describe "show" do
    @tag :skip_ci
    test "likes on my posts (even from people I'm not following) in my notifications" do
      some_account = fake_account!()
      someone = fake_user!(some_account)

      attrs = %{post_content: %{html_body: "<p>here is an epic html post</p>"}}

      assert {:ok, post} =
               Posts.publish(current_user: someone, post_attrs: attrs, boundary: "public")

      liker = fake_user!()

      Likes.like(liker, post)

      conn = conn(user: someone, account: some_account)
      next = "/notifications"
      # |> IO.inspect
      {view, doc} = floki_live(conn, next)
      assert feed = Floki.find(doc, "[data-id=feed]")
      assert Floki.text(feed) =~ "epic html post"
      assert Floki.text(feed) =~ liker.profile.name
      assert Floki.text(feed) =~ "liked"
    end

    @tag :skip_ci
    test "emoji reactions on my posts from other users show in my notifications" do
      # Create the post author
      author_account = fake_account!()
      author = fake_user!(author_account)

      # Create a post
      attrs = %{post_content: %{html_body: "<p>here is a post to react to</p>"}}

      assert {:ok, post} =
               Posts.publish(current_user: author, post_attrs: attrs, boundary: "public")

      # Create another user who will react
      reactor = fake_user!()

      # Add an emoji reaction (using a standard emoji)
      emoji = "🎉"
      emoji_label = "celebrate"

      assert {:ok, reaction} =
        Likes.like(reactor, post, reaction_emoji: {emoji, %{label: emoji_label}})

      # Load the author's notifications page

      conn = conn(user: author, account: author_account)
      conn
      |> visit("/notifications")
      |> PhoenixTest.open_browser()
      |> assert_has("article", text: "post to react to")
      |> assert_has("article", text: reactor.profile.name)
      |> assert_has("span", text: "🎉")

    end

    @tag :skip_ci
    test "multiple emoji reactions from different users show correctly in notifications" do
      # Create the post author
      author_account = fake_account!()
      author = fake_user!(author_account)

      # Create a post
      attrs = %{post_content: %{html_body: "<p>popular post</p>"}}

      assert {:ok, post} =
               Posts.publish(current_user: author, post_attrs: attrs, boundary: "public")

      # Create multiple users who will react
      reactor1 = fake_user!()
      reactor2 = fake_user!()
      reactor3 = fake_user!()

      # Add different emoji reactions
      assert {:ok, _} = Likes.like(reactor1, post, reaction_emoji: {"👍", %{label: "thumbs up"}})
      assert {:ok, _} = Likes.like(reactor2, post, reaction_emoji: {"❤️", %{label: "heart"}})
      assert {:ok, _} = Likes.like(reactor3, post, reaction_emoji: {"😂", %{label: "laugh"}})

      # Load the author's notifications page
      conn = conn(user: author, account: author_account)
      next = "/notifications"

      {view, doc} = floki_live(conn, next)

      # Check that all reactions appear
      assert feed = Floki.find(doc, "[data-id=feed]")
      feed_html = Floki.raw_html(feed)

      # All three reactions should be visible
      assert feed_html =~ "👍" || feed_html =~ "thumbs up"
      assert feed_html =~ "❤️" || feed_html =~ "heart"
      assert feed_html =~ "😂" || feed_html =~ "laugh"

      # All reactor names should appear
      assert Floki.text(feed) =~ reactor1.profile.name
      assert Floki.text(feed) =~ reactor2.profile.name
      assert Floki.text(feed) =~ reactor3.profile.name
    end
  end
end
