defmodule Bonfire.UI.Reactions.PinActionLiveTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.UI.Reactions.PinActionLive
  alias Bonfire.Social.Pins
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

  describe "modal_title/1 dispatch table" do
    test "covers all scope × pinned-state combinations" do
      cases = [
        {:thread_answer, true, "You have already marked this as an answer"},
        {:thread_answer, false, "Mark as answer"},
        {:thread, true, "This is pinned to the thread"},
        {:thread, false, "Pin to thread"},
        {:instance, true, "This is pinned to the instance"},
        {:instance, false, "Pin to instance"},
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

  describe "pinned?/1 — strictly reads the :pinned? prop, no DB fallback" do
    test "returns true when prop is true" do
      assert PinActionLive.pinned?(base_assigns(:instance, %{pinned?: true}))
      assert PinActionLive.pinned?(base_assigns(:thread, %{pinned?: true}))
      assert PinActionLive.pinned?(base_assigns(:profile, %{pinned?: true}))
    end

    test "returns false when prop is false, nil, or missing" do
      refute PinActionLive.pinned?(base_assigns(:instance, %{pinned?: false}))
      refute PinActionLive.pinned?(base_assigns(:instance, %{pinned?: nil}))
      refute PinActionLive.pinned?(base_assigns(:instance))
    end

    test "returns false even when an actual instance pin exists in the DB (no fallback)" do
      account = fake_account!()
      admin = fake_admin!(account)

      {:ok, post} =
        Posts.publish(
          current_user: admin,
          post_attrs: %{post_content: %{html_body: "instance-pinned post"}},
          boundary: "public"
        )

      try do
        Pins.pin(admin, post, :instance)
      rescue
        _ -> :ok
      end

      # sanity: the pin really exists in the DB
      assert Pins.pinned?(:instance, post)

      # but pinned?/1 only consults the prop — it does not query the DB
      refute PinActionLive.pinned?(
               base_assigns(:instance, %{
                 object: post,
                 __context__: %{current_user_id: admin.id, current_user: admin}
               })
             )

      # and an explicit `pinned?: true` prop wins, regardless of context
      assert PinActionLive.pinned?(base_assigns(:instance, %{object: post, pinned?: true}))
    end

    test "returns false for anonymous user even with prop missing" do
      refute PinActionLive.pinned?(base_assigns(:instance))
      refute PinActionLive.pinned?(base_assigns(:thread, %{scope_object: "anything"}))
      refute PinActionLive.pinned?(base_assigns(:profile))
    end
  end

  describe "rendered modal — title_text wiring" do
    @tag :todo
    # Depends on `Bonfire.Social.Pins` being enabled
    test "open button shows scope label and modal <h3> renders the title_text", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
