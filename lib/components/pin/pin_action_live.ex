defmodule Bonfire.UI.Reactions.PinActionLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop object, :any, required: true
  prop pinned?, :boolean, default: nil
  prop my_pin, :boolean, default: nil
  prop class, :css_class, default: "btn btn-ghost btn-circle btn-sm"
  prop scope, :atom, default: :profile
  prop scope_object, :string, default: nil
  # used only to build a unique modal DOM id; optional (callers that omit it get a nil suffix)
  prop parent_id, :any, default: nil
  # prop showing_within, :atom, default: nil

  def pinned?(%{pinned?: pinned?}) when is_boolean(pinned?), do: pinned?
  def pinned?(%{my_pin: my_pin}) when is_boolean(my_pin), do: my_pin

  def pinned?(_assigns), do: false

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
        # neutral: instance pin-state isn't preloaded, it's resolved in the modal
        l("Pin or unpin from spotlight")

      :sidebar ->
        if pinned?(assigns),
          do: l("This group is pinned to your sidebar"),
          else: l("Pin this group to your sidebar")

      _ ->
        if pinned?(assigns),
          do: l("This is pinned to your profile"),
          else: l("Pin to your profile")
    end
  end
end
