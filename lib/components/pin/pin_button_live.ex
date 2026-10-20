defmodule Bonfire.UI.Reactions.PinButtonLive do
  @moduledoc "The one button in a pin modal (`PinActionLive`, `PinModalLive`): pin when `pinned?` is false, unpin when true, with the scope's wording (`PinActionLive.labels/1`)."
  use Bonfire.UI.Common.Web, :stateless_component

  alias Bonfire.UI.Reactions.PinActionLive

  prop object, :any, required: true
  prop scope, :atom, required: true
  prop scope_object, :string, default: nil
  prop pinned?, :boolean, default: false

  @doc "Which stateful component `Pins.LiveHandler` tells about the toggle"
  prop component, :atom, required: true
end
