defmodule Bonfire.UI.Reactions.InstancePins do
  @moduledoc """
  Loading helpers for instance-pinned activities.
  """

  @doc """
  Lists activities pinned to the instance, preloaded for activity rendering.
  """
  def list_activities do
    case Bonfire.Social.Pins.list_instance_pins_activities(
           paginate?: false,
           preload: [:feed_by_subject, :feed_postload]
         ) do
      %{edges: [_ | _] = edges} -> edges
      _ -> []
    end
  end
end
