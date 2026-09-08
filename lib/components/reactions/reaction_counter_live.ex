defmodule Bonfire.UI.Reactions.ReactionCounterLive do
  @moduledoc "A reaction total that opens its people list when nonzero."
  use Bonfire.UI.Common.Web, :stateless_component

  prop reaction, :atom, required: true, values: [:boost, :like, :quote]
  prop count, :integer, default: 0
  prop thread_id, :string, required: true
  prop parent_id, :any, default: nil

  @doc false
  def render(assigns) do
    {role, title, label} =
      case assigns.reaction do
        :boost -> {"boosts", l("Boosted by"), lp("%{count} Boost", "%{count} Boosts", assigns.count, count: assigns.count)}
        :like -> {"likes", l("Liked by"), lp("%{count} Like", "%{count} Likes", assigns.count, count: assigns.count)}
        :quote -> {"quotes", l("Quoted by"), lp("%{count} Quote", "%{count} Quotes", assigns.count, count: assigns.count)}
      end

    assigns
    |> assign(role: role, title: title, label: label)
    |> render_sface()
  end
end
