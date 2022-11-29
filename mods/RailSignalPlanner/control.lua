local build_graph = require("scripts/create_signal_chain")
local mark_rail_direction = require("scripts/mark_rail_direction")
local place_signals = require("scripts/place_signals")
local change_signals = require("scripts/change_signals")
local ghostify = require("scripts/ghostify")
require("gui/signal_tool_gui")

local function remove_ghosts(entities)
  for i, entity in pairs(entities) do
    if entity.type == "entity-ghost" and (entity.ghost_type == "rail-signal" or entity.ghost_type == "rail-chain-signal") then
      entity.destroy()
      entities[i] = nil
    end
  end
end

local function on_player_selected_area(event, alt_mode)
  local item = event.item
  if item == "rail-signal-planner" then
    local entities = event.entities
    local player = game.players[event.player_index]

    remove_ghosts(entities)
    -- create a chain of signals where signals can be placed
    local signal_chain, rails = build_graph(entities, player)
    -- For each rail decide if signals are placed on the left or right or both
    local cur_signals = mark_rail_direction(signal_chain, entities, player, alt_mode)
    -- place signals
    place_signals(signal_chain, cur_signals,  player)
    -- change signals, checking overlaps
    change_signals(rails, signal_chain, player)
    -- restore signals based on their original signal
    ghostify(signal_chain, player)
  end
end

script.on_event(defines.events.on_player_selected_area, function(event)
		on_player_selected_area(event, false)
	end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
		on_player_selected_area(event, true)
	end)

-- when dropping a rail signal planner, just delete it
script.on_event(defines.events.on_player_dropped_item, function(event)
		if event.entity ~= nil and event.entity.stack ~= nil and event.entity.stack.name == "rail-signal-planner" then
			event.entity.stack.clear()
		end
	end)

-- toggle rail block visualisation when player holds the planner
-- don't toggle it off if it was on when the player first took the planner in hand
script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  local player = game.players[event.player_index]
  local cursor = player.cursor_stack
  if not global.planner_info then
    global.planner_info = {}
  end
  if not global.planner_info[event.player_index] then
    global.planner_info[event.player_index] = {}
  end
  local planner_info = global.planner_info[event.player_index]
  if cursor.valid_for_read and cursor.name == "rail-signal-planner" then
    if not planner_info.is_holding_planner then
      planner_info.was_showing_blocks = player.game_view_settings.show_rail_block_visualisation
      planner_info.is_holding_planner = true
    end
    player.game_view_settings.show_rail_block_visualisation = true
  else
    if planner_info.is_holding_planner then
      player.game_view_settings.show_rail_block_visualisation = planner_info.was_showing_blocks
      planner_info.is_holding_planner = false
    end
  end
end)