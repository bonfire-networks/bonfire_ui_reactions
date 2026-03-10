defmodule Bonfire.UI.Reactions.Feeds.InstancePinTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Pins
  alias Bonfire.Posts

  describe "instance pin button visibility" do
    test "regular user does NOT see 'Pin to instance' on a post page", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      user = fake_user!(account)

      attrs = %{
        post_content: %{html_body: "regular user post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: user, post_attrs: attrs, boundary: "public")

      conn(user: user, account: account)
      |> visit("/post/#{post.id}")
      |> assert_has("article", text: "regular user post")
      |> refute_has("[data-id=pin_action]", text: "Pin to instance")
    end

    @tag :todo
    test "admin sees 'Pin to instance' on a post page", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{
        post_content: %{html_body: "admin pinnable post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      conn(user: admin, account: account)
      |> visit("/post/#{post.id}")
      |> assert_has("article", text: "admin pinnable post")
      |> assert_has("[data-id=pin_action]", text: "Pin to instance")
    end
  end

  describe "dashboard pinned widget" do
    test "pinned activity renders in the widget on dashboard", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{
        post_content: %{html_body: "a pinned post visible on dashboard"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      try do
        Pins.pin(admin, post, :instance)
      rescue
        _ -> :ok
      end

      assert Pins.pinned?(:instance, post)

      # Verify backend returns activities
      assert %{edges: [_ | _] = edges} = Pins.list_instance_pins_activities(current_user: admin)

      assert Enum.any?(edges, fn
               %{activity: %{object_id: object_id}} -> object_id == post.id
               _ -> false
             end)

      # Also verify it works without current_user (as widget calls it)
      assert %{edges: [_ | _]} =
               Pins.list_instance_pins_activities(
                 paginate?: false,
                 preload: [:feed_by_subject, :feed_postload]
               )

      # Verify widget renders the activity on dashboard
      conn(user: admin, account: account)
      |> visit("/dashboard")
      |> assert_has("[data-id=instance_pinned_widget]")
      |> assert_has("[data-id=instance_pinned_widget]",
        text: "a pinned post visible on dashboard"
      )
    end

    test "dashboard does not show pinned widget when no pins exist", %{} do
      account = fake_account!()
      user = fake_user!(account)

      conn(user: user, account: account)
      |> visit("/dashboard")
      |> refute_has("[data-id=instance_pinned_widget]")
    end
  end
end
