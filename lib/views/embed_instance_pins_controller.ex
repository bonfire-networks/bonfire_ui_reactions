defmodule Bonfire.UI.Reactions.EmbedInstancePinsController do
  @moduledoc "The Spotlight's old embed addresses (`/instance/pins/embed` and `/instance/pins/carousel/embed`), which sites already embed: they redirect to the Spotlight widget's embed, with their params, at the frame's full width as before."
  use Bonfire.UI.Common.Web, :controller

  def index(conn, params) do
    query = params |> Map.put_new("width", "full") |> URI.encode_query()

    conn
    |> put_status(301)
    |> redirect(to: "/embed/widget/instance_pinned?" <> query)
  end
end
