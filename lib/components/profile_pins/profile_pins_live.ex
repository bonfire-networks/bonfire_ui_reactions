defmodule Bonfire.UI.Reactions.ProfilePinsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  # prop page_title, :string, required: true
  # prop page, :string, required: true
  prop selected_tab, :any, default: "highlights"
  # prop smart_input, :boolean, required: true
  # prop smart_input_opts, :map, default: %{}
  # prop search_placeholder, :string
  # prop feed_title, :string
  prop user, :map
  # prop feed, :list
  # prop feed_filters, :any, default: nil
  # prop page_info, :any
  # prop permalink, :string, default: nil
  # prop showing_within, :atom, default: nil
  # prop follows_me, :atom, default: false
  # prop loading, :boolean, default: false
  prop hide_filters, :boolean, default: false
  prop feed_component_id, :any, default: nil

  slot header
  slot widget
end
