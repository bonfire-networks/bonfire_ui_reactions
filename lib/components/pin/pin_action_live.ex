defmodule Bonfire.UI.Reactions.PinActionLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop object, :any, required: true
  prop pinned?, :boolean, default: nil
  prop class, :css_class, default: "btn btn-ghost btn-circle btn-sm"
  prop scope, :atom, default: :profile
  prop scope_object, :string, default: nil
  # prop showing_within, :atom, default: nil

  def pinned?(assigns), do: assigns[:pinned?] == true

  def modal_title(assigns) do
    case assigns[:scope] do
      :thread_answer ->
        if pinned?(assigns),
          do: l("You have already marked this as an answer"),
          else: l("Mark as answer")

      :thread ->
        if pinned?(assigns),
          do: l("This is pinned to the thread"),
          else: l("Pin to thread")

      :instance ->
        if pinned?(assigns),
          do: l("This is pinned to the instance"),
          else: l("Pin to instance")

      _ ->
        if pinned?(assigns),
          do: l("This is pinned to your profile"),
          else: l("Pin to your profile")
    end
  end
end
