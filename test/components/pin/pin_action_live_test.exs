defmodule Bonfire.UI.Reactions.PinActionLiveTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.UI.Reactions.PinActionLive
  use Surface.LiveViewTest

  doctest Bonfire.UI.Reactions.PinActionLive
  alias Bonfire.Posts

  defp base_assigns(scope, overrides \\ %{}) do
    Map.merge(
      %{
        scope: scope,
        scope_object: nil,
        object: %{id: "fake_object_id"},
        pinned?: nil,
        __context__: %{}
      },
      overrides
    )
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

  describe "modal_title/1 dispatch table" do
    test "covers all scope × pinned-state combinations" do
      cases = [
        {:thread_answer, true, "You have already marked this as an answer"},
        {:thread_answer, false, "Mark as answer"},
        {:thread, true, "This is pinned to the thread"},
        {:thread, false, "Pin to thread"},
        # instance pin-state isn't preloaded here, so the title is neutral
        {:instance, true, "Pin or unpin from spotlight"},
        {:instance, false, "Pin or unpin from spotlight"},
        {:group, true, "This is pinned to the top of the group"},
        {:group, false, "Pin to top of group"},
        {:topic, true, "This is pinned to the top of the topic"},
        {:topic, false, "Pin to top of topic"},
        {:profile, true, "This is pinned to your profile"},
        {:profile, false, "Pin to your profile"},
        # unknown scope falls through to profile titles
        {:something_else, true, "This is pinned to your profile"},
        {:something_else, false, "Pin to your profile"}
      ]

      for {scope, pinned?, expected} <- cases do
        # short-circuit on prop so we don't need a DB-backed pin
        assigns = base_assigns(scope, %{pinned?: pinned?})

        assert PinActionLive.modal_title(assigns) == expected,
               "expected modal_title for scope=#{inspect(scope)}, pinned?=#{pinned?} to be #{inspect(expected)}"
      end
    end
  end

  describe "pinned?/1" do
    test "returns true when prop is true" do
      assert PinActionLive.pinned?(base_assigns(:instance, %{pinned?: true}))
      assert PinActionLive.pinned?(base_assigns(:thread, %{pinned?: true}))
      assert PinActionLive.pinned?(base_assigns(:profile, %{pinned?: true}))
    end

    test "returns false when prop is explicitly false" do
      refute PinActionLive.pinned?(base_assigns(:instance, %{pinned?: false}))
    end

    test "returns false when prop is nil or missing and there is no fallback match" do
      refute PinActionLive.pinned?(base_assigns(:instance, %{pinned?: nil}))
      refute PinActionLive.pinned?(base_assigns(:instance))
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
