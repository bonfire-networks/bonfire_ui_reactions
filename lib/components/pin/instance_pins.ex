defmodule Bonfire.UI.Reactions.InstancePins do
  @moduledoc """
  Loading helpers for instance-pinned activities (the "Spotlight" widget).
  """

  alias Bonfire.Common.Cache

  # 6h — instance pins are public, instance-wide data that rarely changes
  @cache_ttl 1_000 * 60 * 60 * 6

  @doc """
  Lists activities pinned to the instance, preloaded for activity rendering. Cached for 6h.
  Pass the standard `:cache` opt (`cache: :refresh` busts + recomputes — the "Spotlight" widget's
  manual refresh button).
  """
  def list_activities(opts \\ []) do
    Cache.maybe_apply_cached(
      &do_list_activities/0,
      [],
      Keyword.put_new(opts, :expire, @cache_ttl)
    )
  end

  defp do_list_activities do
    case Bonfire.Social.Pins.list_instance_pins_activities(
           paginate?: false,
           preload: [:feed_by_subject, :feed_postload]
         ) do
      %{edges: [_ | _] = edges} -> edges
      _ -> []
    end
  end
end
