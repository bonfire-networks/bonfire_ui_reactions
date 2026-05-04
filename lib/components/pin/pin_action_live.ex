defmodule Bonfire.UI.Reactions.PinActionLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop object, :any, required: true
  prop pinned?, :boolean, default: nil
  prop class, :css_class, default: "btn btn-ghost btn-circle btn-sm"
  prop scope, :atom, default: :profile
  prop scope_object, :string, default: nil
  # prop showing_within, :atom, default: nil

  def pinned?(assigns) do
    assigns[:pinned?] ||
      (current_user_id(assigns[:__context__]) && check_pinned?(assigns))
  end

  defp check_pinned?(%{scope: :instance, object: object}),
    do: Bonfire.Social.Pins.pinned?(:instance, object)

  defp check_pinned?(%{scope: scope, scope_object: scope_object, object: object})
       when scope in [:thread, :thread_answer],
       do: Bonfire.Social.Pins.pinned?(scope_object || scope, object)

  defp check_pinned?(%{object: object} = assigns),
    do: Bonfire.Social.Pins.pinned?(current_user(assigns[:__context__]), object)

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
