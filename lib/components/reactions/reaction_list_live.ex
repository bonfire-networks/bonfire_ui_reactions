defmodule Bonfire.UI.Reactions.ReactionListLive do
  @moduledoc """
  Loads the people behind the discussion's reaction totals only when its modal opens.
  """
  use Bonfire.UI.Common.Web, :stateful_component

  prop thread_id, :string, required: true
  prop reaction, :atom, default: :boost, values: [:boost, :like, :quote]
  data people, :list, default: []
  data page_info, :any, default: nil
  data loaded_key, :any, default: nil

  @doc false
  def render(assigns) do
    {list_role, person_role, label, empty_label} =
      case assigns.reaction do
        :boost -> {"booster_list", "booster", l("People who boosted"), l("No visible boosts yet.")}
        :like -> {"liker_list", "liker", l("People who liked"), l("No visible likes yet.")}
        :quote -> {"quoter_list", "quoter", l("People who quoted"), l("No visible quotes yet.")}
      end

    assigns
    |> assign(list_role: list_role, person_role: person_role, label: label, empty_label: empty_label)
    |> render_sface()
  end

  @doc false
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if socket.assigns.loaded_key == {socket.assigns.thread_id, socket.assigns.reaction} do
      {:ok, socket}
    else
      {:ok, Bonfire.UI.Reactions.ReactionLists.LiveHandler.load_people(socket)}
    end
  end
end
