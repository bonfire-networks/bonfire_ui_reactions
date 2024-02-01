defmodule Bonfire.UI.Reactions.ProfileBoostsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop page_title, :string, required: true
  prop page, :string, required: true
  prop selected_tab, :string, default: "boosts"
  prop smart_input, :boolean, required: true
  prop smart_input_opts, :map, default: %{}
  prop search_placeholder, :string
  prop feed_title, :string
  prop user, :map
  prop feed, :list
  prop page_info, :any
  prop follows_me, :boolean, default: false
  prop loading, :boolean, default: false
  prop feed_component_id, :any, default: nil
  prop hide_tabs, :boolean, default: false

  slot header
end
