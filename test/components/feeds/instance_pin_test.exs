defmodule Bonfire.UI.Reactions.Feeds.InstancePinTest do
  use Bonfire.UI.Reactions.ConnCase, async: false

  alias Bonfire.Social.Pins
  alias Bonfire.Posts

  describe "instance pin button visibility" do
    test "regular user does NOT see 'Pin to spotlight' on a post page", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
        click_button(session, "[data-id=pin_action]", "Unpin from spotlight")
      end)

      refute Pins.pinned?(:instance, post)
    end
  end

  describe "dashboard pinned widget" do
    test "pinned activity renders in the widget on dashboard", %{} do
      Process.put(:feed_live_update_many_preload_mode, :inline)

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

      # the Spotlight widget caches its list (6h); bust it so this freshly-pinned post shows
      # (matches what the widget's manual refresh button does)
      Bonfire.UI.Reactions.InstancePins.list_activities(cache: :reset)

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
      |> assert_has("[data-id=instance_pinned_widget]",
        text: "a pinned post visible on dashboard"
      )

      conn(user: admin, account: account)
      |> visit("/instance/pins")
      |> assert_has("[data-id=instance_pinned_widget]")
      |> assert_has("[data-id=instance_pinned_widget]",
        text: "a pinned post visible on dashboard"
      )
      |> refute_has("#pinned-carousel")
    end
  end

  describe "instance pins embed" do
    test "embed renders full width while the in-app page keeps its max width and in-tab links" do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      {:ok, post} =
        Posts.publish(
          current_user: admin,
          post_attrs: %{post_content: %{html_body: "full width embed pin"}},
          boundary: "public"
        )

      Pins.pin(admin, post, :instance)
      Bonfire.UI.Reactions.InstancePins.list_activities(cache: :reset)

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
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      {:ok, post} =
        Posts.publish(
          current_user: admin,
          post_attrs: %{post_content: %{html_body: "new tab pinned link"}},
          boundary: "public"
        )

      Pins.pin(admin, post, :instance)
      Bonfire.UI.Reactions.InstancePins.list_activities(cache: :reset)

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
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      {:ok, post} =
        Posts.publish(
          current_user: admin,
          post_attrs: %{post_content: %{html_body: "rewrite marker pin"}},
          boundary: "public"
        )

      Pins.pin(admin, post, :instance)
      Bonfire.UI.Reactions.InstancePins.list_activities(cache: :reset)

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

    test "carousel embed renders without scroll buttons" do
      Process.put(:feed_live_update_many_preload_mode, :inline)

      account = fake_account!()
      admin = fake_admin!(account)

      for body <- ["first carousel embed pin", "second carousel embed pin"] do
        {:ok, post} =
          Posts.publish(
            current_user: admin,
            post_attrs: %{post_content: %{html_body: body}},
            boundary: "public"
          )

        Pins.pin(admin, post, :instance)
      end

      Bonfire.UI.Reactions.InstancePins.list_activities(cache: :reset)

      html =
        conn()
        |> get("/instance/pins/carousel/embed")
        |> html_response(200)

      assert html =~ ~s(id="pinned-carousel")

      document = Floki.parse_document!(html)

      assert Floki.find(document, "#pinned-carousel") != []
      assert Floki.find(document, ~s(button[aria-label="Scroll left"])) == []
      assert Floki.find(document, ~s(button[aria-label="Scroll right"])) == []
    end

    test "guest poll vote CTA opens the Bonfire page in a new tab" do
      Process.put(:feed_live_update_many_preload_mode, :inline)

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
      Bonfire.UI.Reactions.InstancePins.list_activities(cache: :reset)

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
