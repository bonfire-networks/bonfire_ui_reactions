defmodule Bonfire.Social.Notifications.Likes.Test do
  use Bonfire.UI.Reactions.ConnCase, async: true
  alias Bonfire.Social.Fake
  alias Bonfire.Social.Likes
  alias Bonfire.Posts
  import Bonfire.Files.Simulation

  describe "show" do
    # @tag :skip_ci
    test "likes on my posts (even from people I'm not following) in my notifications" do
      some_account = fake_account!()
      someone = fake_user!(some_account)

      attrs = %{post_content: %{html_body: "<p>here is an epic html post</p>"}}

      assert {:ok, post} =
               Posts.publish(current_user: someone, post_attrs: attrs, boundary: "public")

      liker = fake_user!()

      Likes.like(liker, post)

      conn = conn(user: someone, account: some_account)

      conn
      |> visit("/notifications")
      |> assert_has_or_open_browser("[data-id=feed] article", text: "epic html post")
      |> assert_has_or_open_browser("[data-id=feed] article", text: liker.profile.name)
      |> assert_has_or_open_browser("[data-id=feed] article", text: "liked")
    end

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
      |> assert_has_or_open_browser("article", text: "post to react to")
      |> assert_has_or_open_browser("article", text: reactor.profile.name)
      |> assert_has_or_open_browser("article [data-role='liked_by']", text: "🎉")
      |> assert_has_or_open_browser("article [data-role='liked_by']",
        text: "reacted to your activity"
      )
    end

    test "custom emoji reactions on my posts from other users show in my notifications" do
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
      label = "test custom emoji"
      shortcode = ":test:"

      {:ok, settings} =
        Bonfire.Files.EmojiUploader.add_emoji(reactor, icon_file(), label, shortcode)

      assert %{id: media_id, url: url} =
               Bonfire.Common.Settings.get([:custom_emoji, shortcode], nil, settings)

      assert {:ok, reaction} =
               Likes.like(reactor, post, reaction_media: media_id)

      # Load the author's notifications page

      conn = conn(user: author, account: author_account)

      conn
      |> visit("/notifications")
      |> assert_has_or_open_browser("article", text: "post to react to")
      |> assert_has("article", text: reactor.profile.name)
      |> assert_has_or_open_browser("article [data-role='liked_by'] img[alt*=':test:']")
      |> assert_has_or_open_browser("article [data-role='liked_by']",
        text: "reacted to your activity"
      )
    end

    test "multiple emoji reactions from different users show correctly in notifications" do
      # Create the post author
      author_account = fake_account!()
      author = fake_user!(author_account)

      # Create a post
      attrs = %{post_content: %{html_body: "<p>popular post</p>"}}

      assert {:ok, post} =
               Posts.publish(current_user: author, post_attrs: attrs, boundary: "public")

      # Create multiple users who will react
      reactor1 = fake_user!(author_account)
      reactor2 = fake_user!(author_account)

      label = "test custom emoji"
      shortcode = ":test:"

      {:ok, settings} =
        Bonfire.Files.EmojiUploader.add_emoji(reactor2, icon_file(), label, shortcode)

      assert %{id: media_id, url: url} =
               Bonfire.Common.Settings.get([:custom_emoji, shortcode], nil, settings)

      # Add different emoji reactions
      assert {:ok, _} = Likes.like(reactor1, post, reaction_emoji: {"👍", %{label: "thumbs up"}})
      assert {:ok, _} = Likes.like(reactor2, post, reaction_media: media_id)

      # Load the author's notifications page
      conn = conn(user: author, account: author_account)

      conn
      |> visit("/notifications")
      # Check reactor1's name
      |> assert_has_or_open_browser("[data-id=feed] article", text: reactor1.profile.name)
      # Check reactor2's name
      |> assert_has("[data-id=feed] article", text: reactor2.profile.name)
      # Check custom emoji
      |> assert_has_or_open_browser(
        "[data-id=feed] article  [data-role='liked_by'] img[alt*=':test:']"
      )
      # Check thumbs up emoji
      |> assert_has_or_open_browser("[data-id=feed] article [data-role='liked_by']", text: "👍")
      # Check reaction verb text
      |> assert_has_or_open_browser("[data-id=feed] article [data-role='liked_by']",
        text: "reacted to your activity",
        count: 2
      )
    end
  end
end
