defmodule Bonfire.Social.Bookmarks.LiveHandlerTest do
  @moduledoc "Bookmarking is for what I may read. The delegated `bookmark` event is sent by the browser with just an id, so the server has to check that I can read it."
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
  import Phoenix.LiveViewTest, only: [live: 2, render_hook: 3]

  alias Bonfire.Social.Bookmarks

  setup do
    Process.put(:federating, false)

    author = fake_user!(fake_account!())
    account = fake_account!()
    me = fake_user!(account)
    reader = fake_user!(fake_account!())

    {:ok, private_post} =
      Bonfire.Posts.publish(
        current_user: author,
        post_attrs: %{post_content: %{html_body: "<p>only for the author</p>"}},
        boundary: "mentions"
      )

    {:ok, public_post} =
      Bonfire.Posts.publish(
        current_user: author,
        post_attrs: %{post_content: %{html_body: "<p>for everyone</p>"}},
        boundary: "public"
      )

    {:ok, view, _html} = live(conn(user: me, account: account), "/@" <> author.character.username)

    %{
      me: me,
      reader: reader,
      author: author,
      private_post: private_post,
      public_post: public_post,
      view: view
    }
  end

  test "I cannot bookmark a post I cannot read", %{
    me: me,
    reader: reader,
    private_post: private_post,
    public_post: public_post,
    view: view
  } do
    refute Bonfire.Boundaries.can?(reader, :read, private_post),
           "control: a user like me cannot read it"

    render_hook(view, "Bonfire.Social.Bookmarks:bookmark", %{
      "direction" => "up",
      "id" => public_post.id
    })

    assert Bookmarks.bookmarked?(me, public_post), "control: bookmarking a readable post works"

    render_hook(view, "Bonfire.Social.Bookmarks:bookmark", %{
      "direction" => "up",
      "id" => private_post.id
    })

    refute Bookmarks.bookmarked?(me, private_post)
  end
end
