defmodule Bonfire.UI.Reactions.Feeds.InstancePinTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Pins
  alias Bonfire.Posts

  describe "instance pin button visibility" do
    test "regular user does NOT see 'Pin to spotlight' on a post page", %{} do
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
      |> refute_has("[data-id=pin_action]", text: "Pin to spotlight")
    end

    @tag :todo
    test "admin sees 'Pin to spotlight' on a post page", %{} do
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
      |> assert_has("[data-id=pin_action]", text: "Pin to spotlight")
    end

    test "admin sees 'Unpin from spotlight' in the modal when the post is already pinned to the spotlight",
         %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{
        post_content: %{html_body: "already instance pinned post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      Pins.pin(admin, post, :instance)
      assert Pins.pinned?(:instance, post)

      conn(user: admin, account: account)
      |> visit("/post/#{post.id}")
      |> assert_has("article", text: "already instance pinned post")
      |> assert_has("[data-role=open_modal]", text: "Pin or unpin from spotlight")
      |> click_button("[data-role=open_modal]", "Pin or unpin from spotlight")
      |> assert_has("[data-id=modal-contents]", text: "Unpin from spotlight")
    end
  end

  describe "instance pin button action (persistence)" do
    test "admin clicking 'Pin to spotlight' in the modal actually pins the post", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{post_content: %{html_body: "pin me via the UI"}}

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      refute Pins.pinned?(:instance, post)

      session =
        conn(user: admin, account: account)
        |> visit("/post/#{post.id}")
        |> click_button("[data-role=open_modal]", "Pin or unpin from spotlight")

      within(session, "[data-id=modal-contents]", fn session ->
        click_button(session, "[data-id=pin_action]", "Pin to spotlight")
      end)

      assert Pins.pinned?(:instance, post)
    end

    test "admin clicking 'Unpin from spotlight' in the modal actually unpins the post", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{post_content: %{html_body: "unpin me via the UI"}}

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      Pins.pin(admin, post, :instance)
      assert Pins.pinned?(:instance, post)

      session =
        conn(user: admin, account: account)
        |> visit("/post/#{post.id}")
        |> click_button("[data-role=open_modal]", "Pin or unpin from spotlight")

      within(session, "[data-id=modal-contents]", fn session ->
        click_button(session, "[data-id=pin_action]", "Unpin from spotlight")
      end)

      refute Pins.pinned?(:instance, post)
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

      conn(user: admin, account: account)
      |> visit("/instance/pins")
      |> assert_has("[data-id=instance_pinned_widget]")
      |> assert_has("[data-id=instance_pinned_widget]",
        text: "a pinned post visible on dashboard"
      )
      |> refute_has("#pinned-carousel")
    end

  end
end
