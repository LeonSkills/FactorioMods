require("gui/signal_tool_gui")
require("scripts/settings")

local function on_open_menu(event)
  toggle_signal_ui(event.player_index)
end

local function destroy_planner(event)
  if not event.player_index then return end
  local player = game.players[event.player_index]
  if player.cursor_stack and player.cursor_stack.valid and player.cursor_stack.name == "rail-signal-planner" then
    player.cursor_stack.clear()
  end
end

script.on_event({"rsp-open-menu"}, on_open_menu)
script.on_event({"rsp-toggle-place-signals-with-planner"}, toggle_place_signals_with_planner)
script.on_event({"rsp-toggle-unidirectional"}, toggle_unidirectional)
script.on_event("rsp-drop-planner", destroy_planner)
