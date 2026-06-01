// Standalone bundle for emoji-picker-element, lazily imported by the reactions
// hook (emoji_reactions_live.hooks.js) on first picker open. This keeps its
// ~37kb out of the main app bundle loaded on every page — it only loads if a
// user actually opens a reaction picker (and never if reactions are disabled).
//
// The side-effect import registers the <emoji-picker> custom element (guarded
// internally against double-define); Database is re-exported for the favourites
// tracking the reactions hook does.
import 'emoji-picker-element';
export { default as Database } from 'emoji-picker-element/database';
