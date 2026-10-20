defmodule Bonfire.UI.Reactions.PinnedCarouselTest do
  @moduledoc "`PinnedCarouselLive` is the one way pinned posts show: it loads the pins of its `scope` (the instance spotlight by default, or a group or topic) and shows them as the Top discussions preview in the Peek track."
  use Bonfire.UI.Reactions.ConnCase, async: false
  use Surface.LiveViewTest

  alias Bonfire.Social.Pins
  alias Bonfire.UI.Reactions.PinnedCarouselLive
  import Bonfire.Common.Enums, only: [id: 1]
  import Bonfire.Posts.Fake, only: [fake_post!: 3]

  setup do
    Process.put(:federating, false)
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

    account = fake_account!()
    admin = fake_admin!(account)

    instance_post = fake_post!(admin, "public", %{post_content: %{html_body: "in the spotlight"}})
    Pins.pin(admin, instance_post, :instance)

    # `:reset` takes no DB, so it still works once the test's sandbox is gone
    on_exit(fn -> Pins.list_spotlight_activities(cache: :reset) end)

    # a scope other than the instance: pins work the same whoever holds them, so the admin's own stand in for a group's
    for body <- ["pinned to another scope", "also pinned there", "a third pin"] do
      {:ok, _} = Pins.pin(admin, fake_post!(admin, "public", %{post_content: %{html_body: body}}), id(admin))
    end

    %{admin: admin}
  end

  defp carousel(context, overrides) do
    assigns =
      Map.merge(
        %{
          scope: :instance,
          scope_object: nil,
          title: nil,
          visible_items: 1,
          __context__: %{current_user: context.admin}
        },
        overrides
      )

    render_surface do
      ~F"""
      <PinnedCarouselLive
        id="pins"
        scope={@scope}
        scope_object={@scope_object}
        title={@title}
        visible_items={@visible_items}
        __context__={@__context__}
      />
      """
    end
  end

  defp scoped_pins(context, overrides \\ %{}),
    do: carousel(context, Map.merge(%{scope: :group, scope_object: context.admin}, overrides))

  test "it shows its scope's pins, not the spotlight's", context do
    html = scoped_pins(context)

    assert html =~ "pinned to another scope"
    refute html =~ "in the spotlight"
  end

  test "by default it's the spotlight, as the same cards, under its label", context do
    doc = carousel(context, %{title: "Spotlight"}) |> Floki.parse_document!()

    assert Floki.find(doc, "[data-role=widget-heading]") |> Floki.text() =~ "Spotlight"
    assert Floki.find(doc, "[data-role=pinned_card]") |> Floki.text() =~ "in the spotlight"
  end

  # the Top discussions preview: a reply count where the like and boost buttons would be
  test "each pin previews its post as Top discussions does", context do
    doc = scoped_pins(context) |> Floki.parse_document!()

    assert [_ | _] =
             Floki.find(doc, "[data-role=pinned_card] [data-role=discussion_preview_actions]")
  end

  test "the spotlight's cards show who else is in the thread", context do
    post = fake_post!(context.admin, "public", %{post_content: %{html_body: "a spotlit discussion"}})

    {:ok, _} =
      Bonfire.Posts.publish(
        current_user: fake_user!(fake_account!()),
        post_attrs: %{reply_to_id: id(post), post_content: %{html_body: "<p>a reply</p>"}},
        boundary: "public"
      )

    Pins.pin(context.admin, post, :instance)

    doc = carousel(context, %{title: "Spotlight"}) |> Floki.parse_document!()

    assert [_ | _] = Floki.find(doc, "[data-role=pinned_card] [data-role=thread_participants]")
  end

  # its parent re-renders it often: only a new scope, or a pin or unpin (`reload`), loads the pins and decides who may unpin again
  test "it loads its pins once per scope, and again when told to reload", _context do
    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        loaded_for: Pins.instance_scope_id(),
        entries: [],
        can_unpin: true
      }
    }

    assert {:ok, %{assigns: %{entries: [], can_unpin: true}}} =
             PinnedCarouselLive.update(%{scope: :instance, scope_object: nil}, socket)

    assert {:ok, %{assigns: %{entries: [_ | _]}}} =
             PinnedCarouselLive.update(%{scope: :instance, scope_object: nil, reload: true}, socket)
  end

  test "several pins get dots, and arrows only from the sm breakpoint up", context do
    doc = scoped_pins(context) |> Floki.parse_document!()

    assert length(Floki.find(doc, "[data-role=carousel_dot]")) == 3

    arrow_classes =
      doc
      |> Floki.find("button[data-carousel-scroll]")
      |> Floki.attribute("class")
      |> Enum.join(" ")

    assert arrow_classes =~ "hidden"
    assert arrow_classes =~ "sm:flex"
  end

  test "visible_items sets how many whole cards show from the sm breakpoint up", context do
    style =
      scoped_pins(context, %{visible_items: 3})
      |> Floki.parse_document!()
      |> Floki.find("[data-carousel-card]")
      |> Floki.attribute("style")
      |> List.first()

    assert style =~ Bonfire.UI.Common.CarouselLive.card_width(3)
  end

  test "two carousels on one page have distinct tracks, and each one's arrows control its own",
       context do
    other = fake_user!(fake_account!())

    for body <- ["someone else's pin", "and another"] do
      {:ok, _} = Pins.pin(other, fake_post!(other, "public", %{post_content: %{html_body: body}}), id(other))
    end

    assigns = %{admin: context.admin, other: other, __context__: %{current_user: context.admin}}

    html =
      render_surface do
        ~F"""
        <PinnedCarouselLive id="group_pins" scope={:group} scope_object={@admin} __context__={@__context__} />
        <PinnedCarouselLive id="topic_pins" scope={:topic} scope_object={@other} __context__={@__context__} />
        """
      end

    doc = Floki.parse_document!(html)

    assert [_] = Floki.find(doc, "#group_pins-track")
    assert [_] = Floki.find(doc, "#topic_pins-track")

    assert Floki.attribute(doc, "[data-carousel-scroll]", "aria-controls")
           |> Enum.uniq()
           |> Enum.sort() == ["group_pins-track", "topic_pins-track"]
  end

  # an instance can switch pins off (the standard `:modularity` key), as its sibling pin components respect
  test "shows no pins when Pins is disabled", context do
    Process.put([:bonfire_social, Bonfire.Social.Pins, :modularity], :disabled)

    doc = scoped_pins(context) |> Floki.parse_document!()

    assert Floki.find(doc, "[data-role=pinned_card]") == []
  end

  test "a pinned post's image shows in its card", context do
    media = Bonfire.Social.Fake.upload_media(:images, context.admin)
    post = fake_post!(context.admin, "public", %{post_content: %{html_body: "a pin with a picture"}, uploaded_media: [media]})
    {:ok, _} = Pins.pin(context.admin, post, id(context.admin))

    doc = scoped_pins(context, %{visible_items: 3}) |> Floki.parse_document!()

    assert [_ | _] = Floki.find(doc, "[data-role=pinned_card] [data-id=article_media]")
  end
end
