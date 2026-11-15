defmodule Bonfire.UI.Reactions.ClientAssignImpersonationTest do
  @moduledoc "A signed-in user acts as themselves: whatever the browser sends through the global `assign` event or a component's `set` event cannot change who the server thinks is acting."
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
  import Phoenix.LiveViewTest, only: [live: 2, render_hook: 3, has_element?: 2, with_target: 2]

  alias Bonfire.Boundaries.Blocks
  alias Bonfire.Social.Likes

  setup do
    Process.put(:federating, false)

    author = fake_user!(fake_account!())
    a = fake_user!(fake_account!())
    b_account = fake_account!()
    b = fake_user!(b_account)
    victim = fake_user!(fake_account!())

    {:ok, post} =
      Bonfire.Posts.publish(
        current_user: author,
        post_attrs: %{post_content: %{html_body: "<p>for everyone</p>"}},
        boundary: "public"
      )

    %{
      author: author,
      a: a,
      b: b,
      b_account: b_account,
      victim: victim,
      post: post
    }
  end

  defp forged_user_attrs(user) do
    %{
      "current_user_id" => user.id,
      "current_user" => %{"id" => user.id},
      "assign_global" => "true"
    }
  end

  defp block(view, user),
    do: render_hook(view, "Bonfire.Boundaries.Blocks:block", %{"id" => user.id})

  test "control: my like is attributed to me", %{
    a: a,
    b: b,
    b_account: b_account,
    author: author,
    post: post
  } do
    {:ok, view, _html} =
      live(conn(user: b, account: b_account), "/@" <> author.character.username)

    refute Likes.liked?(b, post)

    render_hook(view, "Bonfire.Social.Likes:like", %{"direction" => "up", "id" => post.id})

    assert Likes.liked?(b, post), "control: liking a readable post works"
    refute Likes.liked?(a, post)
  end

  test "control: my block is attributed to me", %{
    a: a,
    b: b,
    b_account: b_account,
    author: author,
    victim: victim
  } do
    {:ok, view, _html} =
      live(conn(user: b, account: b_account), "/@" <> author.character.username)

    block(view, victim)

    assert Blocks.is_blocked?(victim, :ghost, current_user: b), "control: blocking works"
    refute Blocks.is_blocked?(victim, :ghost, current_user: a)
  end

  test "the global `assign` event cannot make me act as another user", %{
    a: a,
    b: b,
    b_account: b_account,
    author: author,
    victim: victim
  } do
    {:ok, view, _html} =
      live(conn(user: b, account: b_account), "/@" <> author.character.username)

    refute Blocks.is_blocked?(victim, :ghost, current_user: a),
           "control: the other user has not blocked them"

    render_hook(view, "assign", forged_user_attrs(a))
    block(view, victim)

    refute Blocks.is_blocked?(victim, :ghost, current_user: a)
  end

  # a plain map is refused by the locality classification, so this forges what that check accepts: a struct name (turned into an atom by `to_atoms`) and `is_local`
  test "the global `assign` event cannot make my like count as another user's, even with a forged local user",
       %{a: a, b: b, b_account: b_account, author: author, post: post} do
    {:ok, view, _html} =
      live(conn(user: b, account: b_account), "/@" <> author.character.username)

    refute Likes.liked?(a, post), "control: the other user has not liked it"

    forged = %{
      "__struct__" => "Elixir.Bonfire.Data.Identity.User",
      "id" => a.id,
      "is_local" => true
    }

    render_hook(view, "assign", %{
      "to_atoms" => "true",
      "assign_global" => "true",
      "current_user_id" => a.id,
      "current_user" => forged
    })

    # the forged user is not a real record, so the page may crash after the like was written: only the stored outcome matters
    try do
      render_hook(view, "Bonfire.Social.Likes:like", %{"direction" => "up", "id" => post.id})
    catch
      :exit, _ -> :ok
    end

    refute Likes.liked?(a, post)
  end

  test "the `set` event of the thread cannot change who is acting", %{
    a: a,
    b: b,
    b_account: b_account,
    post: post
  } do
    {:ok, view, _html} = live(conn(user: b, account: b_account), "/discussion/#{post.id}")

    thread = "#thread_#{post.id}"
    assert has_element?(view, thread), "control: the thread component is on the page"

    view |> with_target(thread) |> render_hook("set", forged_user_attrs(a))

    assigns = :sys.get_state(view.pid).socket.assigns
    refute assigns[:current_user_id] == a.id
    refute assigns[:current_user][:id] == a.id
  end
end
