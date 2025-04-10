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
  end
end
