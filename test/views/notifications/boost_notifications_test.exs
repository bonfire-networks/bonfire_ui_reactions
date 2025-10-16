defmodule Bonfire.Social.Notifications.Boosts.Test do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Fake
  alias Bonfire.Social.Boosts
  alias Bonfire.Posts

  setup do
    account = fake_account!()
    me = fake_user!(account)
    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me}
  end

  describe "boost notifications" do
    test "show boosts on my posts (even from people I'm not following) in my notifications", %{
      me: me,
      account: account,
      conn: conn
    } do
      # Create a post
      attrs = %{post_content: %{html_body: "epic html post"}}
      assert {:ok, post} = Posts.publish(current_user: me, post_attrs: attrs, boundary: "public")

      # Someone else boosts the post
      booster = fake_user!()
      # TODO: should use the UI to boost instead of the context function
      Boosts.boost(booster, post)

      # Visit notifications and check that the boost appears
      conn
      |> visit("/notifications")
      |> assert_has("article", text: "epic html post")
      |> assert_has("article", text: booster.profile.name)
      |> assert_has("article", text: "boosted")
    end
  end
end

# defmodule Bonfire.Social.Notifications.Boosts.Test do
#   use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
#   alias Bonfire.Social.Fake
#   alias Bonfire.Social.Boosts
#   alias Bonfire.Posts

#   describe "show" do
#     test "boosts on my posts (even from people I'm not following) in my notifications" do
#       some_account = fake_account!()
#       someone = fake_user!(some_account)

#       attrs = %{post_content: %{html_body: "<p>here is an epic html post</p>"}}

#       assert {:ok, post} =
#                Posts.publish(current_user: someone, post_attrs: attrs, boundary: "public")

#       booster = fake_user!()

#       Boosts.boost(booster, post)

#       conn = conn(user: someone, account: some_account)
#       next = "/notifications"
#       # |> IO.inspect
#       {view, doc} = floki_live(conn, next)
#       assert feed = Floki.find(doc, "[data-id=feed]")
#       assert Floki.text(feed) =~ "epic html post"
#       assert Floki.text(feed) =~ booster.profile.name
#       assert Floki.text(feed) =~ "boosted"
#     end
#   end
# end
