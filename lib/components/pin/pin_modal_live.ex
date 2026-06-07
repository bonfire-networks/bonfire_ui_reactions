defmodule Bonfire.UI.Reactions.PinModalLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object, :any, required: true
  prop pinned?, :boolean, default: nil
  prop my_pin, :boolean, default: nil
  prop scope, :atom, default: :profile
  prop scope_object, :string, default: nil
  prop parent_component, :atom, default: Bonfire.UI.Reactions.PinActionLive

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(pinned?: pinned?(assigns))}
  end

  # Resolved from the DB lazily on open (no feed-level preload). Only an explicit
  # `true` prop short-circuits — a nil/false `:boolean` prop must not, or the DB
  # query is skipped and an already-pinned object wrongly shows "Pin".
  defp pinned?(%{pinned?: true}), do: true
  defp pinned?(%{my_pin: true}), do: true

  defp pinned?(%{scope: :instance, object: object} = assigns) when not is_nil(object) do
    if module_enabled?(Bonfire.Social.Pins, assigns[:__context__]) do
      Bonfire.Social.Pins.pinned?(:instance, object)
    else
      false
    end
  end

  defp pinned?(_assigns), do: false
end
