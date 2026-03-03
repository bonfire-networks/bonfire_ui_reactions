defmodule Bonfire.UI.Reactions.Feeds.PinActivityTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Pins
  alias Bonfire.Posts

  setup do
    account = fake_account!()
    me = fake_user!(account)
    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me}
  end

  test "As a user, I can pin a reply in a thread and it persists", %{
    me: me
  } do
    # Create a thread (root post)
    attrs = %{
      post_content: %{summary: "thread root", html_body: "original discussion post"}
    }

    assert {:ok, post} = Posts.publish(current_user: me, post_attrs: attrs, boundary: "public")

    # Create a reply
    reply_attrs = %{
      post_content: %{html_body: "great reply worth pinning"},
      reply_to_id: post.id
    }

    assert {:ok, reply} =
             Posts.publish(current_user: me, post_attrs: reply_attrs, boundary: "public")

    # Pin the reply to the thread (federation may raise, but pin is created)
    try do
      Pins.pin(me, reply, post.id)
    rescue
      _ -> :ok
    end

    # Verify the pin persists
    assert Pins.pinned?(post.id, reply)
  end

  test "As a user, I can unpin a reply from a thread", %{
    me: me
  } do
    # Create a thread (root post)
    attrs = %{
      post_content: %{summary: "thread root", html_body: "another discussion post"}
    }

    assert {:ok, post} = Posts.publish(current_user: me, post_attrs: attrs, boundary: "public")

    # Create a reply
    reply_attrs = %{
      post_content: %{html_body: "reply to unpin"},
      reply_to_id: post.id
    }

    assert {:ok, reply} =
             Posts.publish(current_user: me, post_attrs: reply_attrs, boundary: "public")

    # Pin the reply
    try do
      Pins.pin(me, reply, post.id)
    rescue
      _ -> :ok
    end

    assert Pins.pinned?(post.id, reply)

    # Unpin the reply
    Pins.unpin(me, reply, post.id)

    # Verify it's no longer pinned
    refute Pins.pinned?(post.id, reply)
  end

  test "As a user, the thread page loads correctly with a reply", %{
    conn: conn,
    me: me
  } do
    Process.put(:feed_live_update_many_preload_mode, :inline)

    attrs = %{
      post_content: %{summary: "thread root", html_body: "discussion starter"}
    }

    assert {:ok, post} = Posts.publish(current_user: me, post_attrs: attrs, boundary: "public")

    reply_attrs = %{
      post_content: %{html_body: "a thoughtful reply"},
      reply_to_id: post.id
    }

    assert {:ok, _reply} =
             Posts.publish(current_user: me, post_attrs: reply_attrs, boundary: "public")

    # Thread page should render without errors and show both post and reply
    conn
    |> visit("/post/#{post.id}")
    |> assert_has("article", text: "discussion starter")
    |> assert_has("article", text: "a thoughtful reply")
  end
end
