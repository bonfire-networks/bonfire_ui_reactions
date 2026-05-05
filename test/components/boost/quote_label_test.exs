defmodule Bonfire.UI.Reactions.Boost.QuoteAppendTest do
  @moduledoc """
  Coverage for the Mastodon-style "quote-as-widget" UX:

    * Pure unit tests for `Bonfire.Posts.prepare_post_attrs/2`'s `:append_url`
      option — the body-shaping step that puts the quoted post's URL in front
      of the publish pipeline.

    * Integration tests for the click → render → publish flow exercised by the
      `Bonfire.Social.Boosts.LiveHandler` `"quote"` event and the smart
      input's quote-card slot.
  """

  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  import Phoenix.LiveViewTest, except: [open_browser: 1, open_browser: 2]
  import Ecto.Query
  alias Bonfire.Posts

  describe "prepare_post_attrs/2 :append_url" do
    test "appends the URL to a body the user typed" do
      attrs = %{post: %{post_content: %{html_body: "my reaction"}}}
      url = "https://example.test/post/abc"

      %{post: %{post_content: %{html_body: out}}} =
        Posts.prepare_post_attrs(attrs, append_url: url)

      assert out == "my reaction\n\n" <> url
    end

    test "uses the URL alone when the user typed nothing" do
      url = "https://example.test/post/abc"

      %{post: %{post_content: %{html_body: out}}} =
        Posts.prepare_post_attrs(%{}, append_url: url)

      assert out == "\n\n" <> url
    end

    test "no-op when append_url is nil/empty/absent" do
      attrs = %{post: %{post_content: %{html_body: "hello"}}}

      assert %{post: %{post_content: %{html_body: "hello"}}} =
               Posts.prepare_post_attrs(attrs, append_url: nil)

      assert %{post: %{post_content: %{html_body: "hello"}}} =
               Posts.prepare_post_attrs(attrs, append_url: "")

      assert %{post: %{post_content: %{html_body: "hello"}}} = Posts.prepare_post_attrs(attrs, [])
    end
  end

  describe "quote widget integration" do
    setup do
      account = fake_account!()
      alice = fake_user!(account)
      me = fake_user!(account)

      {:ok, post} =
        Posts.publish(
          current_user: alice,
          post_attrs: %{post_content: %{summary: nil, html_body: "QUOTABLE_BODY_marker"}},
          boundary: "public"
        )

      conn = conn(user: me, account: account)
      {:ok, conn: conn, alice: alice, me: me, post: post}
    end

    test "submitting the composer with a quoted_url puts the URL in the published body",
         %{conn: conn, me: me, post: post} do
      # The boost handler → set/2 → PersistentLive → SmartInputContainerLive
      # message chain is async and hard to settle deterministically in tests.
      # Instead we exercise the publish path directly: a form submit with the
      # `quoted_url` field present (as the hidden input would render) MUST land
      # the URL in the published body so the existing AP-quote pipeline can
      # detect it.
      {:ok, view, _html} = live(conn, "/post/#{post.id}")
      url = Bonfire.Common.URIs.canonical_url(post)

      view
      |> element("#smart_input_form")
      |> render_submit(%{
        "post" => %{"post_content" => %{"html_body" => "my hot take"}},
        "quoted_url" => url,
        "to_boundaries" => "public"
      })

      latest =
        from(p in Bonfire.Data.Social.Post,
          join: c in assoc(p, :created),
          where: c.creator_id == ^me.id,
          order_by: [desc: p.id],
          limit: 1,
          preload: [:post_content]
        )
        |> Bonfire.Common.Repo.one!()

      assert latest.post_content.html_body =~ "my hot take"

      # Linkify rewrites local-instance URLs to markdown links pointing at the
      # internal `/discussion/<id>` path; the original post ID (which is what
      # the AP-quote pipeline keys off) must still be present.
      assert latest.post_content.html_body =~ post.id
    end
  end
end
