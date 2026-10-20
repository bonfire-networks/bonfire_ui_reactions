defmodule Bonfire.UI.Reactions.PinActionLive do
  @moduledoc "Pin or unpin `object` in a `scope` (your profile, a thread, a group or topic, your sidebar, the spotlight): an open button and a modal with one action. The wording for each scope lives in `labels/1`."
  use Bonfire.UI.Common.Web, :stateless_component

  prop object, :any, required: true
  prop pinned?, :boolean, default: nil
  prop scope, :atom, default: :profile
  prop scope_object, :string, default: nil

  @doc "Show only the icon, with the label for screen readers (as `DownloadMarkdownLive`'s `as_icon`), eg. on a pinned card"
  prop as_icon, :boolean, default: false

  @doc "The stateful component `Pins.LiveHandler` tells about the toggle (by object id), as `PinModalLive`'s `parent_component`"
  prop component, :atom, default: __MODULE__

  # used only to build a unique modal DOM id; optional (callers that omit it get a nil suffix)
  prop parent_id, :any, default: nil

  def pinned?(%{pinned?: pinned?}) when is_boolean(pinned?), do: pinned?
  def pinned?(_assigns), do: false

  @doc """
  What each scope says: the action (`pin`, `unpin`) shown on both the open button and the modal's button, the modal's title (`title`, `pinned_title`), and a line on what it does (`pin_hint`, `unpin_hint`). The spotlight's open button and title stay neutral, since its pinned state is only looked up once the modal opens (`PinModalLive`).

      iex> Bonfire.UI.Reactions.PinActionLive.labels(:group).unpin
      "Unpin from top of group"

      iex> Bonfire.UI.Reactions.PinActionLive.labels(:something_else) == Bonfire.UI.Reactions.PinActionLive.labels(:profile)
      true
  """
  def labels(:thread_answer),
    do: %{
      title: l("Mark as answer"),
      pinned_title: l("You have already marked this as an answer"),
      pin: l("Mark as answer"),
      unpin: l("Unmark as answer"),
      pin_hint: l("It will then be highlighted in the thread."),
      unpin_hint: l("You can remove it if you like")
    }

  def labels(:thread),
    do: %{
      title: l("Pin to thread"),
      pinned_title: l("This is pinned to the thread"),
      pin: l("Pin to top of thread"),
      unpin: l("Unpin from top of thread"),
      pin_hint: l("Pins will be shown at the top of the thread."),
      unpin_hint: l("Unpin to remove it from the top of the thread.")
    }

  def labels(:group),
    do: %{
      title: l("Pin to top of group"),
      pinned_title: l("This is pinned to the top of the group"),
      pin: l("Pin to top of group"),
      unpin: l("Unpin from top of group"),
      pin_hint: l("It will show at the top of the group, for everyone who can read it."),
      unpin_hint: l("Unpin to remove it from the top of the group.")
    }

  def labels(:topic),
    do: %{
      title: l("Pin to top of topic"),
      pinned_title: l("This is pinned to the top of the topic"),
      pin: l("Pin to top of topic"),
      unpin: l("Unpin from top of topic"),
      pin_hint: l("It will show at the top of the topic, for everyone who can read it."),
      unpin_hint: l("Unpin to remove it from the top of the topic.")
    }

  def labels(:sidebar),
    do: %{
      title: l("Pin this group to your sidebar"),
      pinned_title: l("This group is pinned to your sidebar"),
      pin: l("Pin to sidebar"),
      unpin: l("Unpin from sidebar"),
      pin_hint: l("It will appear in your groups sidebar for quick access."),
      unpin_hint: l("Unpin to remove this group from your sidebar (you'll stay a member).")
    }

  def labels(:instance),
    do: %{
      title: l("Pin or unpin from spotlight"),
      pinned_title: l("Pin or unpin from spotlight"),
      pin: l("Pin to spotlight"),
      unpin: l("Unpin from spotlight"),
      pin_hint: l("This will appear in the pinned widget on the dashboard for all users."),
      unpin_hint: l("Unpin to remove it from the dashboard widget.")
    }

  def labels(_profile),
    do: %{
      title: l("Pin to your profile"),
      pinned_title: l("This is pinned to your profile"),
      pin: l("Pin to your profile"),
      unpin: l("Unpin from your profile"),
      pin_hint: l("It will appear in your profile highlights tab."),
      unpin_hint: l("Unpin to remove it from your profile highlights.")
    }

  def modal_title(assigns) do
    labels = labels(assigns[:scope])
    if pinned?(assigns), do: labels.pinned_title, else: labels.title
  end
end
