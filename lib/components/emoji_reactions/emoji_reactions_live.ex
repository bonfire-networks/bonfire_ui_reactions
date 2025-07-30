defmodule Bonfire.UI.Reactions.EmojiReactionsLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :any
  prop creator, :any, default: nil
  # prop showing_within, :atom, default: nil
  prop parent_id, :any, default: nil
  # prop object_type, :any
  # prop object_boundary, :any, default: nil
  # prop like_count, :any, default: 0
  # prop label, :string, default: nil
  # prop my_like, :any, default: nil

  # def update(assigns, socket) do
  #   custom_emojis =
  #     Bonfire.Files.EmojiUploader.list(assigns(socket))
  #     |> Enum.map(fn {shortcode, emoji} ->
  #       %{
  #         id: emoji.id,
  #         name: e(emoji, :label, nil),
  #         shortcodes: [shortcode],
  #         url: e(emoji, :url, nil) || Media.emoji_url(emoji)
  #       }
  #     end)
  #     |> Jason.encode!()

  #   {:ok, assign(socket, custom_emojis: custom_emojis || [])}
  # end

  # def handle_event("get_custom_emojis", _params, socket) do
  #   custom_emojis =
  #     Bonfire.Files.EmojiUploader.list(assigns(socket))
  #     |> Enum.map(fn {shortcode, emoji} ->
  #       %{
  #         name: e(emoji, :label, nil),
  #         shortcodes: [shortcode],
  #         url: e(emoji, :url, nil) || Media.emoji_url(emoji)
  #       }
  #     end)

  #   {:reply, %{custom_emojis: custom_emojis}, socket}
  # end
end
