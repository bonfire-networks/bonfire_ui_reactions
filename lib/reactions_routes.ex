defmodule Bonfire.UI.Reactions.Routes do
  @behaviour Bonfire.UI.Common.RoutesModule

  defmacro __using__(_) do
    quote do
      # pages anyone can view
      scope "/", Bonfire.UI.Reactions do
        pipe_through(:browser)
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
