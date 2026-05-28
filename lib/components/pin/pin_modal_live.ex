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

  defp pinned?(%{pinned?: pinned?}) when is_boolean(pinned?), do: pinned?
  defp pinned?(%{my_pin: my_pin}) when is_boolean(my_pin), do: my_pin

  defp pinned?(%{scope: :instance, object: object} = assigns) when not is_nil(object) do
    if module_enabled?(Bonfire.Social.Pins, assigns[:__context__]) do
      Bonfire.Social.Pins.pinned?(:instance, object)
    else
      false
    end
  end

  defp pinned?(_assigns), do: false
end
