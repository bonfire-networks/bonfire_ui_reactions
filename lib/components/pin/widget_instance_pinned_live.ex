defmodule Bonfire.UI.Reactions.WidgetInstancePinnedLive do
  @moduledoc """
  Vertical widget for activities pinned to the instance.
  """

  use Bonfire.UI.Common.Web, :stateless_component

  prop widget_title, :string, default: nil
  prop entries, :any, default: nil
  prop with_action, :boolean, default: true
  prop hide_when_empty, :boolean, default: true

  @doc """
  Returns explicitly provided entries, or loads the current instance pins.
  """
  def entries(nil), do: Bonfire.UI.Reactions.InstancePins.list_activities()
  def entries(entries), do: entries
end
