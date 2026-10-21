defmodule Bonfire.UI.Reactions.ReactionLists.LiveHandler do
  @moduledoc """
  Shares pagination and profile preloading between the discussion's reaction modals.
  """
  use Bonfire.UI.Common.Web, :live_handler

  @doc false
  def handle_event("load_more", _, socket) do
    case Bonfire.UI.Common.LoadMoreLive.end_cursor(socket.assigns.page_info) do
      nil -> {:noreply, socket}
      cursor -> {:noreply, load_people(socket, cursor)}
    end
  end

  @doc "Loads visible reactions to an object (or quotes in its thread), keeping each person once across pages."
  def load_people(socket, cursor \\ nil) do
    %{object_id: object_id, reaction: reaction} = socket.assigns

    {context, extract_person} =
      case reaction do
        :boost -> {Bonfire.Social.Boosts, & &1.edge.subject}
        :like -> {Bonfire.Social.Likes, & &1.edge.subject}
        :quote -> {Bonfire.Social.Quotes, & &1.created.creator}
      end

    filters = if reaction == :quote, do: [in_thread: object_id], else: [objects: object_id]

    %{edges: reactions, page_info: page_info} =
      context.list_paginated(filters,
        current_user: current_user(socket),
        preload: :subject,
        paginate?: true,
        limit: 20,
        after: cursor
      )

    new_people =
      reactions
      |> Enum.map(extract_person)
      |> repo().maybe_preload(profile: [:icon], character: [:peered])

    people =
      (if(cursor, do: socket.assigns.people, else: []) ++ new_people)
      |> Enum.uniq_by(&id/1)

    assign(socket, people: people, page_info: page_info, loaded_key: {object_id, reaction})
  end
end
