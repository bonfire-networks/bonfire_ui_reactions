defmodule Bonfire.UI.Reactions.PinActionLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop object, :any
  prop class, :css_class, default: "btn btn-ghost btn-circle btn-sm"
  prop scope, :any, default: nil
  # prop showing_within, :atom, default: nil
end
