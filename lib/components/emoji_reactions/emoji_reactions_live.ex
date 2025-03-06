defmodule Bonfire.UI.Reactions.EmojiReactionsLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :any
  prop showing_within, :atom, default: nil
  prop parent_id, :any, default: nil
  # prop object_type, :any
  # prop object_boundary, :any, default: nil
  # prop like_count, :any, default: 0
  # prop label, :string, default: nil
  # prop my_like, :any, default: nil

  # def mount(socket) do
  #   custom_emojis =
  #     Bonfire.Files.EmojiUploader.list(socket)
  #     |> Enum.map(fn {shortcode, emoji} ->
  #       %{
  #         name: emoji.label,
  #         shortcodes: [shortcode],
  #         url: emoji.url
  #       }
  #     end)
  #     |> Jason.encode!()
  #   {:ok, assign(socket, custom_emojis: custom_emojis)}
  # end

  def update(assigns, socket) do
    custom_emojis =
      Bonfire.Files.EmojiUploader.list(assigns(socket))
      |> Enum.map(fn {shortcode, emoji} ->
        %{
          name: emoji.label,
          shortcodes: [shortcode],
          url: emoji.url
        }
      end)
      |> Jason.encode!()

    {:ok, assign(socket, custom_emojis: custom_emojis)}
  end

  def handle_event("get_custom_emojis", _params, socket) do
    custom_emojis =
      Bonfire.Files.EmojiUploader.list(assigns(socket))
      |> Enum.map(fn {shortcode, emoji} ->
        %{
          name: emoji.label,
          shortcodes: [shortcode],
          url: emoji.url
        }
      end)

    {:reply, %{custom_emojis: custom_emojis}, socket}
  end
end
