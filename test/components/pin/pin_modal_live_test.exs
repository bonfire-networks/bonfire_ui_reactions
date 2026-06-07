defmodule Bonfire.UI.Reactions.PinModalLiveTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.UI.Reactions.PinModalLive
  alias Bonfire.Social.Pins
  alias Bonfire.Posts

  # Unlike the feed-level trigger, the modal resolves pin-state from the DB on open.
  defp update_assigns(post, admin, overrides) do
    Map.merge(
      %{
        scope: :instance,
        scope_object: nil,
        object: post,
        pinned?: nil,
        my_pin: nil,
        __context__: %{current_user_id: admin.id, current_user: admin}
      },
      overrides
    )
  end

  defp resolve_pinned?(assigns) do
    {:ok, socket} = PinModalLive.update(assigns, %Phoenix.LiveView.Socket{})
    socket.assigns.pinned?
  end

  setup do
    account = fake_account!()
    admin = fake_admin!(account)

    {:ok, post} =
      Posts.publish(
        current_user: admin,
        post_attrs: %{post_content: %{html_body: "instance pin modal test"}},
        boundary: "public"
      )

    {:ok, account: account, admin: admin, post: post}
  end

  describe "resolves instance pin-state on open" do
    test "is true when the object is already pinned to the instance", %{admin: admin, post: post} do
      Pins.pin(admin, post, :instance)
      # sanity: the pin really exists in the DB
      assert Pins.pinned?(:instance, post)

      assert resolve_pinned?(update_assigns(post, admin, %{}))
    end

    test "is false when the object is not pinned to the instance", %{admin: admin, post: post} do
      refute Pins.pinned?(:instance, post)

      refute resolve_pinned?(update_assigns(post, admin, %{}))
    end

    test "an explicit `pinned?: true` prop still wins without a DB lookup", %{
      admin: admin,
      post: post
    } do
      refute Pins.pinned?(:instance, post)

      assert resolve_pinned?(update_assigns(post, admin, %{pinned?: true}))
    end
  end
end
