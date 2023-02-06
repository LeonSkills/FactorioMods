require("gui/signal_tool_gui")
require("scripts/settings")

local function on_open_menu(event)
  toggle_signal_ui(event.player_index)
end

script.on_event({"rsp-open-menu"}, on_open_menu)
script.on_event({"rsp-toggle-place-signals-with-planner"}, toggle_place_signals_with_planner)
script.on_event({"rsp-toggle-unidirectional"}, toggle_unidirectional)
