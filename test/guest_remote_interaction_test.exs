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
end
