defmodule Bonfire.UI.Reactions.PinActionLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop object, :any, required: true
  prop pinned?, :boolean, default: nil
  prop class, :css_class, default: "btn btn-ghost btn-circle btn-sm"
  prop scope, :atom, default: :profile
  prop scope_object, :string, default: nil
  # prop showing_within, :atom, default: nil
end
