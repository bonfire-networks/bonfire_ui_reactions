defmodule Bonfire.UI.Reactions.GuestRemoteInteractionTest do
  @moduledoc """
  A logged-out visitor who clicks Like on a public post must be redirected to the local
  remote-interaction form (so they can react from their own fediverse server), not silently
  render in place. Single-instance twin of the redirect half of
  `bonfire_federate_activitypub/test/dance/remote_interaction_dance_test.exs`.
  """
  use Bonfire.UI.Reactions.ConnCase, async: false
  @moduletag :ui

  import Phoenix.LiveViewTest
  import Bonfire.Posts.Fake, only: [fake_post!: 3]

  test "guest Like on a public post redirects to the remote-interaction form" do
    account = fake_account!()
    author = fake_user!(account)
    Bonfire.Federate.ActivityPub.set_federating(:instance, true)
    post = fake_post!(author, "public", %{post_content: %{html_body: "<p>a public post</p>"}})

    {:ok, view, _html} = live(build_conn(), "/discussion/#{post.id}")

    assert {:error, {kind, %{to: to}}} =
             view
             |> element("[data-role=like_enabled]")
             |> render_click()

    assert kind in [:redirect, :live_redirect]
    assert to =~ "/remote_interaction"
    assert to =~ "type=like"
  end

  # a visitor with no live socket clicks with a plain request to the LiveHandler route (`bonfire_basic.js`), carrying only the button's values
  describe "without a live socket" do
    setup do
      Bonfire.Federate.ActivityPub.set_federating(:instance, true)

      post =
        fake_post!(fake_user!(fake_account!()), "public", %{
          post_content: %{html_body: "<p>a public post</p>"}
        })

      {:ok, post: post}
    end

    for {name, path} <- [
          like: "/LiveHandler/Bonfire.Social.Likes/like?direction=up",
          boost: "/LiveHandler/Bonfire.Social.Boosts/boost?"
        ] do
      test "guest #{name} is redirected to the remote-interaction form", %{post: post} do
        conn = get(build_conn(), unquote(path) <> "&id=#{post.id}")

        assert conn.status in [301, 302],
               "not redirected (#{conn.status}): " <>
                 (conn.resp_body
                  |> Floki.parse_document!()
                  |> Floki.find("main, body")
                  |> Floki.text()
                  |> String.split()
                  |> Enum.join(" ")
                  |> String.slice(0, 300))

        to = redirected_to(conn)
        assert to =~ "/remote_interaction"
        assert to =~ "type=#{unquote(name)}"
      end
    end
  end

  # a link built where the page renders, from the post it holds, so it must name the post itself
  test "guest flag link on a public post leads to the remote-interaction form, with the post's address" do
    author = fake_user!(fake_account!())
    Bonfire.Federate.ActivityPub.set_federating(:instance, true)
    post = fake_post!(author, "public", %{post_content: %{html_body: "<p>a public post</p>"}})

    {:ok, _view, html} = live(build_conn(), "/discussion/#{post.id}")

    links =
      html
      |> Floki.parse_document!()
      |> Floki.attribute("a", "href")
      |> Enum.filter(&String.contains?(&1, "/remote_interaction?type=flag"))

    assert links != [], "no flag link for a guest"

    assert Enum.all?(
             links,
             &(URI.decode_www_form(&1) =~
                 Bonfire.Common.URIs.canonical_url(post, preload_if_needed: true))
           ),
           inspect(links)
  end
end
