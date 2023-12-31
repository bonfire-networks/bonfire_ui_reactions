defmodule Bonfire.UI.Reactions.Routes do
  def declare_routes, do: nil

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

        live("/bookmarks", Bonfire.UI.Reactions.BookmarksLive, :bookmarks,
          as: Bonfire.Data.Social.Bookmark
        )

        # live("/likes", Bonfire.UI.Social.FeedsLive, :likes, as: Bonfire.Data.Social.Like)
        live("/likes", Bonfire.UI.Reactions.LikesLive, :likes, as: Bonfire.Data.Social.Like)
      end

      # pages you need an account to view
      scope "/", Bonfire.UI.Reactions do
        pipe_through(:browser)
        pipe_through(:account_required)
      end
    end
  end
end
