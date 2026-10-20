defmodule Bonfire.Social.Pins.LiveHandlerTest do
  use Bonfire.UI.Reactions.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"

  alias Bonfire.Social.Pins
  alias Bonfire.Social.Pins.LiveHandler
  import Bonfire.Common.Enums, only: [id: 1]
  import Bonfire.Posts.Fake, only: [fake_post!: 3]

  setup do
    Process.put(:federating, false)

    author = fake_user!(fake_account!())
    bystander = fake_user!(fake_account!())

    root = fake_post!(author, "public", %{post_content: %{html_body: "<p>a question</p>"}})

    {:ok, reply} =
      Bonfire.Posts.publish(
        current_user: bystander,
        post_attrs: %{reply_to_id: id(root), post_content: %{html_body: "<p>an answer</p>"}},
        boundary: "public"
      )

    {:ok, _} = Pins.pin(author, reply, id(root))

    %{bystander: bystander, root: root, reply: reply}
  end

  test "a refused unpin flashes an error, not \"Unpinned\"", %{
    bystander: bystander,
    root: root,
    reply: reply
  } do
    result =
      LiveHandler.handle_event(
        "pin",
        %{"direction" => "down", "id" => id(reply), "scope" => id(root)},
        socket(bystander)
      )

    assert Pins.pinned?(id(root), reply), "control: still pinned"

    flash =
      case result do
        {:noreply, socket} -> socket.assigns.flash
        other -> flunk("expected {:noreply, socket}, got #{inspect(other)}")
      end

    refute flash["info"] == "Unpinned"
    assert flash["error"]
  end

  defp socket(user) do
    # on the struct because `assign/3` refuses the reserved `:flash`
    %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, flash: %{}}}
    |> Phoenix.Component.assign(:__context__, %{current_user: user})
  end
end
