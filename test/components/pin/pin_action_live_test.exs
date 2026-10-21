defmodule Bonfire.UI.Reactions.PinActionLiveTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.UI.Reactions.PinActionLive
  use Surface.LiveViewTest

  doctest Bonfire.UI.Reactions.PinActionLive
  alias Bonfire.Posts

  defp base_assigns(scope, overrides \\ %{}) do
    Map.merge(%{scope: scope, pinned?: nil}, overrides)
  end

  # one button for every scope's modal, so pin and unpin always carry the same hooks and the scope's own wording
  describe "PinButtonLive" do
    test "offers to unpin when pinned, and to pin when not, with the scope's wording" do
      for {pinned?, data_id, direction, label} <- [
            {true, "unpin_action", "down", "Unpin from top of thread"},
            {false, "pin_action", "up", "Pin to top of thread"}
          ] do
        assigns = %{pinned?: pinned?}

        html =
          render_surface do
            ~F"""
            <Bonfire.UI.Reactions.PinButtonLive object={%{id: "a_post"}} scope={:thread} scope_object="a_thread" pinned?={@pinned?} component={Bonfire.UI.Reactions.PinActionLive} />
            """
          end

        [button] = html |> Floki.parse_document!() |> Floki.find("button[data-id=#{data_id}]")
        assert Floki.attribute(button, "phx-value-direction") == [direction]
        assert Floki.attribute(button, "phx-value-scope") == ["a_thread"]
        assert Floki.text(button) =~ label
      end
    end
  end

  describe "modal_title/1" do
    test "a scope's title follows its pinned state, but the spotlight's stays neutral" do
      assert PinActionLive.modal_title(base_assigns(:thread, %{pinned?: true})) ==
               "This is pinned to the thread"

      assert PinActionLive.modal_title(base_assigns(:thread, %{pinned?: false})) == "Pin to thread"

      # the spotlight's pinned state isn't preloaded here
      for pinned? <- [true, false] do
        assert PinActionLive.modal_title(base_assigns(:instance, %{pinned?: pinned?})) ==
                 "Pin or unpin from spotlight"
      end
    end
  end

  describe "pinned?/1" do
    test "only an explicit true counts as pinned" do
      assert PinActionLive.pinned?(base_assigns(:instance, %{pinned?: true}))
      refute PinActionLive.pinned?(base_assigns(:instance, %{pinned?: false}))
      refute PinActionLive.pinned?(base_assigns(:instance, %{pinned?: nil}))
      refute PinActionLive.pinned?(%{scope: :instance})
    end
  end

  describe "rendered modal — title_text wiring" do
    @tag :todo
    # Depends on `Bonfire.Social.Pins` being enabled
    test "open button shows scope label and modal <h3> renders the title_text", %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      me = fake_user!(account)

      {:ok, post} =
        Posts.publish(
          current_user: me,
          post_attrs: %{post_content: %{html_body: "thread root for ui test"}},
          boundary: "public"
        )

      {:ok, _reply} =
        Posts.publish(
          current_user: me,
          post_attrs: %{
            post_content: %{html_body: "ui test reply"},
            reply_to_id: post.id
          },
          boundary: "public"
        )

      session =
        conn(user: me, account: account)
        |> visit("/post/#{post.id}")
        |> assert_has("article", text: "ui test reply")

      # the open-modal button for the :thread scope is rendered with the
      # un-pinned label (we have not pinned anything)
      session
      |> assert_has("[data-role=open_modal]", text: "Pin to top of thread")

      # clicking the button opens the global modal and copies the
      # PinActionLive assigns (including title_text) into it. assert that
      # the modal <h3> title shows the value from modal_title/1.
      session
      |> click_button("[data-role=open_modal]", "Pin to top of thread")
      |> assert_has("h3.modal-title", text: "Pin to thread")
    end
  end
end
