defmodule Bonfire.UI.Reactions.Routes do
  @behaviour Bonfire.UI.Common.RoutesModule

  defmacro __using__(_) do
    quote do
      # pages anyone can view
      scope "/", Bonfire.UI.Reactions do
        pipe_through(:browser)

        live("/instance/pins", InstancePinsLive, :list, as: :instance_pins)
      end

      pipeline :cacheable_pins_public do
        plug(Bonfire.UI.Common.CacheControlPlug, purgeable: true, cache_query_string: true)
      end

      # horizontal carousel variant of the spotlight, on its own URL
      scope "/", Bonfire.UI.Reactions do
        pipe_through(:browser)

        live("/instance/pins/carousel", InstancePinsLive, :carousel, as: :instance_pins_carousel)
      end

      scope "/", Bonfire.UI.Reactions do
        pipe_through([:browser_or_cacheable, :cacheable_pins_public, :iframe_embeddable])

        get("/instance/pins/embed", EmbedInstancePinsController, :index)
        get("/instance/pins/carousel/embed", EmbedInstancePinsController, :carousel)
      end

      # pages you need to view as a user
      scope "/" do
        pipe_through(:browser)
        pipe_through(:user_required)

        # live("/feed/bookmarks", Bonfire.UI.Reactions.BookmarksLive, :bookmarks,
        #   as: Bonfire.Data.Social.Bookmark
        # )

        # live("/feed/likes", Bonfire.UI.Reactions.LikesLive, :likes, as: Bonfire.Data.Social.Like)
      end

      # pages you need an account to view
      scope "/", Bonfire.UI.Reactions do
        pipe_through(:browser)
        pipe_through(:account_required)
      end
    end
  end
end
