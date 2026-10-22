defmodule Bonfire.UI.Reactions.Feeds.InstancePinTest do
  use Bonfire.UI.Reactions.ConnCase, async: false

  alias Bonfire.Social.Pins

  doctest Bonfire.UI.Reactions.InstancePinsLive, only: [visible_items: 1]
  alias Bonfire.Posts
  import Bonfire.Posts.Fake, only: [fake_post!: 3]

  describe "instance pin button visibility" do
    test "regular user does NOT see 'Pin to spotlight' on a post page", %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      user = fake_user!(account)

      attrs = %{
        post_content: %{html_body: "regular user post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: user, post_attrs: attrs, boundary: "public")

      conn(user: user, account: account)
      |> visit("/post/#{post.id}")
      |> assert_has("article", text: "regular user post")
      |> refute_has("[data-id=pin_action]", text: "Pin to spotlight")
    end

    @tag :todo
    test "admin sees 'Pin to spotlight' on a post page", %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{
        post_content: %{html_body: "admin pinnable post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      conn(user: admin, account: account)
      |> visit("/post/#{post.id}")
      |> assert_has("article", text: "admin pinnable post")
      |> assert_has("[data-id=pin_action]", text: "Pin to spotlight")
    end

    test "admin sees 'Unpin from spotlight' in the modal when the post is already pinned to the spotlight",
         %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{
        post_content: %{html_body: "already instance pinned post"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      Pins.pin(admin, post, :instance)
      assert Pins.pinned?(:instance, post)

      conn(user: admin, account: account)
      |> visit("/post/#{post.id}")
      |> assert_has("article", text: "already instance pinned post")
      |> assert_has("[data-role=open_modal]", text: "Pin or unpin from spotlight")
      |> click_button("[data-role=open_modal]", "Pin or unpin from spotlight")
      |> assert_has("[data-id=modal-contents]", text: "Unpin from spotlight")
    end
  end

  describe "instance pin button action (persistence)" do
    test "admin clicking 'Pin to spotlight' in the modal actually pins the post", %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{post_content: %{html_body: "pin me via the UI"}}

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      refute Pins.pinned?(:instance, post)

      session =
        conn(user: admin, account: account)
        |> visit("/post/#{post.id}")
        |> click_button("[data-role=open_modal]", "Pin or unpin from spotlight")

      within(session, "[data-id=modal-contents]", fn session ->
        click_button(session, "[data-id=pin_action]", "Pin to spotlight")
      end)

      assert Pins.pinned?(:instance, post)
    end

    test "admin clicking 'Unpin from spotlight' in the modal actually unpins the post", %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{post_content: %{html_body: "unpin me via the UI"}}

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      Pins.pin(admin, post, :instance)
      assert Pins.pinned?(:instance, post)

      session =
        conn(user: admin, account: account)
        |> visit("/post/#{post.id}")
        |> click_button("[data-role=open_modal]", "Pin or unpin from spotlight")

      within(session, "[data-id=modal-contents]", fn session ->
        click_button(session, "[data-id=unpin_action]", "Unpin from spotlight")
      end)

      refute Pins.pinned?(:instance, post)
    end
  end

  describe "dashboard pinned widget" do
    test "pinned activity renders in the widget on dashboard", %{} do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      attrs = %{
        post_content: %{html_body: "a pinned post visible on dashboard"}
      }

      assert {:ok, post} =
               Posts.publish(current_user: admin, post_attrs: attrs, boundary: "public")

      try do
        Pins.pin(admin, post, :instance)
      rescue
        _ -> :ok
      end

      assert Pins.pinned?(:instance, post)

      # Verify backend returns activities
      assert %{edges: [_ | _] = edges} = Pins.list_instance_pins_activities(current_user: admin)

      assert Enum.any?(edges, fn
               %{activity: %{object_id: object_id}} -> object_id == post.id
               _ -> false
             end)

      # Also verify it works without current_user (as widget calls it)
      assert %{edges: [_ | _]} =
               Pins.list_instance_pins_activities(
                 paginate?: false,
                 preload: [:feed_by_subject, :feed_postload]
               )

      # Verify widget renders the activity on dashboard
      conn(user: admin, account: account)
      |> visit("/dashboard")
      |> assert_has("[data-id=instance_pinned_widget]")
      |> assert_has("[data-id=instance_pinned_widget] aside")
      # the dashboard's own widget heading, as Top discussions and the others have
      |> assert_has(
        "[data-id=instance_pinned_widget] [data-role=widget-header].uppercase [data-role=widget-heading]",
        text: "Spotlight"
      )
      |> assert_has("[data-id=instance_pinned_widget] [data-role=pinned_card]",
        text: "a pinned post visible on dashboard"
      )

      conn(user: admin, account: account)
      |> visit("/instance/pins")
      |> assert_has("[data-id=instance_pinned_widget]")
      # carousel only: the page has no separate list any more
      |> assert_has("#instance_pins_carousel-track [data-role=pinned_card]",
        text: "a pinned post visible on dashboard"
      )
    end
  end

  # pins that don't come through the UI (eg. a Mastodon client) must reach the spotlight too, and there's no reset button any more
  test "pinning or unpinning to the instance refreshes the spotlight's cached list, however it's done" do
    admin = fake_admin!(fake_account!())

    post = fake_post!(admin, "public", %{post_content: %{html_body: "pinned without the UI"}})

    on_exit(fn -> Bonfire.Social.Pins.list_spotlight_activities(cache: :reset) end)

    spotlit? = fn ->
      Enum.any?(
        Bonfire.Social.Pins.list_spotlight_activities(),
        &(&1.activity.object_id == post.id)
      )
    end

    # primes the cache without the post
    refute spotlit?.()

    Pins.pin(admin, post, :instance)
    assert spotlit?.()

    Pins.unpin(admin, post, :instance)
    refute spotlit?.()
  end

  # another admin, another tab or an API client: the open dashboard hears of it from `Pins`
  test "a spotlight pin made elsewhere shows on an open dashboard" do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)
    account = fake_account!()
    admin = fake_admin!(account)

    post = fake_post!(admin, "public", %{post_content: %{html_body: "spotlit from elsewhere"}})
    on_exit(fn -> Bonfire.Social.Pins.list_spotlight_activities(cache: :reset) end)

    session =
      conn(user: admin, account: account)
      |> visit("/dashboard")
      |> refute_has("[data-role=pinned_card]", text: "spotlit from elsewhere")

    Pins.pin(admin, post, :instance)

    assert_has(session, "[data-role=pinned_card]", text: "spotlit from elsewhere", timeout: 1_000)
  end

  test "unpinning from a spotlight card takes it off the open page" do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)
    account = fake_account!()
    admin = fake_admin!(account)

    post = fake_post!(admin, "public", %{post_content: %{html_body: "spotlit then unpinned"}})

    Pins.pin(admin, post, :instance)
    on_exit(fn -> Bonfire.Social.Pins.list_spotlight_activities(cache: :reset) end)

    conn(user: admin, account: account)
    |> visit("/dashboard")
    |> assert_has("[data-role=pinned_card]", text: "spotlit then unpinned")
    |> PhoenixTest.unwrap(fn view ->
      Phoenix.LiveViewTest.render_hook(view, "Bonfire.Social.Pins:pin", %{
        "direction" => "down",
        "id" => post.id,
        "scope" => "instance"
      })

      refute Phoenix.LiveViewTest.has_element?(
               view,
               "[data-role=pinned_card]",
               "spotlit then unpinned"
             )

      Phoenix.LiveViewTest.render(view)
    end)
  end

  # the cached list holds the activities, the facepile is loaded when the card renders
  test "a spotlight card's facepile shows someone who replied after the list was cached" do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)
    account = fake_account!()
    admin = fake_admin!(account)

    post = fake_post!(admin, "public", %{post_content: %{html_body: "spotlit with replies"}})

    reply = fn replier ->
      {:ok, _} =
        Posts.publish(
          current_user: replier,
          post_attrs: %{reply_to_id: post.id, post_content: %{html_body: "a reply"}},
          boundary: "public"
        )
    end

    # a facepile that isn't empty when the list is cached
    first = fake_user!(fake_account!())
    reply.(first)

    Pins.pin(admin, post, :instance)
    on_exit(fn -> Bonfire.Social.Pins.list_spotlight_activities(cache: :reset) end)

    conn(user: admin, account: account)
    |> visit("/dashboard")
    |> assert_has("[data-role=pinned_card] [data-role=thread_participants] [id*='#{first.id}']")

    later = fake_user!(fake_account!())
    reply.(later)

    conn(user: admin, account: account)
    |> visit("/dashboard")
    |> assert_has("[data-role=pinned_card] [data-role=thread_participants] [id*='#{later.id}']")
  end

  # on a real page, where the carousel learns who is looking from the page's context
  test "an instance admin can unpin from the spotlight's cards, a member can't" do
    Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)
    account = fake_account!()
    admin = fake_admin!(account)

    post = fake_post!(admin, "public", %{post_content: %{html_body: "spotlit for unpinning"}})

    Pins.pin(admin, post, :instance)

    conn(user: admin, account: account)
    |> visit("/dashboard")
    |> assert_has(
      "[data-id=instance_pinned_widget] [data-role=pinned_card] [data-role=pin_to_instance]"
    )

    member_account = fake_account!()
    member = fake_user!(member_account)

    conn(user: member, account: member_account)
    |> visit("/dashboard")
    |> assert_has("[data-id=instance_pinned_widget] [data-role=pinned_card]",
      text: "spotlit for unpinning"
    )
    |> refute_has("[data-id=instance_pinned_widget] [data-role=pin_to_instance]")
  end

  describe "instance pins embed" do
    # one way to show pins: the list embed is the carousel too, and `?items=` sets how many whole cards show
    test "both embeds render the carousel, with ?items= cards from the sm breakpoint up" do
      account = fake_account!()
      admin = fake_admin!(account)

      for body <- ["first sized embed pin", "second sized embed pin"] do
        post = fake_post!(admin, "public", %{post_content: %{html_body: body}})

        Pins.pin(admin, post, :instance)
      end

      for path <- ["/instance/pins/embed?items=3", "/instance/pins/carousel/embed?items=3"] do
        document =
          conn()
          |> get(path)
          |> html_response(200)
          |> Floki.parse_document!()

        assert [_ | _] =
                 Floki.find(document, "#instance_pins_carousel-track [data-role=pinned_card]"),
               path

        assert document
               |> Floki.find("[data-carousel-card]")
               |> Floki.attribute("style")
               |> Enum.all?(&(&1 =~ Bonfire.UI.Common.CarouselLive.card_width(3))),
               path
      end
    end

    test "embed renders full width while the in-app page keeps its max width and in-tab links" do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      post = fake_post!(admin, "public", %{post_content: %{html_body: "full width embed pin"}})

      Pins.pin(admin, post, :instance)

      embed_html =
        conn()
        |> get("/instance/pins/embed")
        |> html_response(200)

      refute embed_html =~ "max-w-[720px]"

      in_app_html =
        conn(user: admin, account: account)
        |> get("/instance/pins")
        |> html_response(200)

      assert in_app_html =~ "max-w-[720px]"

      assert in_app_html
             |> Floki.parse_document!()
             |> Floki.find(~s(a[target="_blank"])) == []
    end

    test "pinned activity links open in a new tab" do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      post = fake_post!(admin, "public", %{post_content: %{html_body: "new tab pinned link"}})

      Pins.pin(admin, post, :instance)

      links =
        conn()
        |> get("/instance/pins/embed")
        |> html_response(200)
        |> Floki.parse_document!()
        |> Floki.find(~s(a[target="_blank"]))

      assert links != []
      assert Enum.any?(links, &(Floki.attribute(&1, "rel") == ["noopener"]))

      # Escape-frame links must be plain anchors, NOT LiveView live-nav links:
      # `data-phx-link` + target="_blank" double-navigates (browser opens the new
      # tab AND LiveView redirects inside the iframe on clicks of nested elements).
      assert Enum.all?(links, &(Floki.attribute(&1, "data-phx-link") == []))
    end

    test "embed marks itself for client-side rich-text link rewriting" do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      post = fake_post!(admin, "public", %{post_content: %{html_body: "rewrite marker pin"}})

      Pins.pin(admin, post, :instance)

      embed_html = conn() |> get("/instance/pins/embed") |> html_response(200)

      # the embed opts into rewriting rich-text (mention/hashtag) links to escape
      # the iframe; the shared layout carries the rewriter script keyed on this attr
      assert embed_html =~ ~s(data-embed-links="_blank")
      assert embed_html =~ "[data-embed-links]"

      # the in-app page does NOT opt in (its links navigate in place as usual)
      in_app_html =
        conn(user: admin, account: account) |> get("/instance/pins") |> html_response(200)

      refute in_app_html =~ ~s(data-embed-links="_blank")
    end

    test "the carousel embed's track leaves vertical swipes to the page" do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      for body <- ["first carousel embed pin", "second carousel embed pin"] do
        post = fake_post!(admin, "public", %{post_content: %{html_body: body}})

        Pins.pin(admin, post, :instance)
      end

      html =
        conn()
        |> get("/instance/pins/carousel/embed")
        |> html_response(200)

      assert html =~ ~s(id="instance_pins_carousel-track")

      document = Floki.parse_document!(html)

      assert Floki.find(document, "#instance_pins_carousel-track") != []

      carousel_classes =
        document
        |> Floki.find("#instance_pins_carousel-track [class]")
        |> Enum.flat_map(&Floki.attribute(&1, "class"))
        |> Enum.flat_map(&String.split/1)

      # `touch-action: pan-x` anywhere in here would tell the browser this
      # subtree handles nothing but horizontal gestures, so a thumb swipe
      # landing on a card could no longer scroll the page. The carousel pans
      # natively in both axes instead — see `.carousel-scroll` in app.css.
      refute "touch-pan-x" in carousel_classes
      refute "!touch-pan-x" in carousel_classes

      assert document
             |> Floki.find("#instance_pins_carousel-track")
             |> Floki.attribute("class")
             |> Enum.flat_map(&String.split/1)
             |> Enum.member?("carousel-scroll")
    end

    test "guest poll vote CTA opens the Bonfire page in a new tab" do
      Process.put([:bonfire, :feed_live_update_many_preload_mode], :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      {:ok, poll} =
        Bonfire.Poll.Fake.fake_question_with_choices(
          %{
            post_content: %{html_body: "poll pinned in embed"},
            voting_dates: [
              DateTime.add(DateTime.utc_now(), -60),
              DateTime.add(DateTime.utc_now(), 3600)
            ]
          },
          [%{name: "yes"}, %{name: "no"}],
          current_user: admin,
          boundary: "public"
        )

      Pins.pin(admin, poll, :instance)

      [link] =
        conn()
        |> get("/instance/pins/embed")
        |> html_response(200)
        |> Floki.parse_document!()
        |> Floki.find("[data-role=sign-in-to-vote]")

      assert Floki.attribute(link, "target") == ["_blank"]
      assert Floki.attribute(link, "rel") == ["noopener"]

      [href] = Floki.attribute(link, "href")
      assert href == "/discussion/#{poll.id}"

      # outside the embed the same pinned poll keeps the in-app login flow
      [in_app_link] =
        conn()
        |> get("/instance/pins")
        |> html_response(200)
        |> Floki.parse_document!()
        |> Floki.find("[data-role=sign-in-to-vote]")

      assert Floki.attribute(in_app_link, "href") == ["/login"]
      assert Floki.attribute(in_app_link, "target") == []
    end
  end
end
