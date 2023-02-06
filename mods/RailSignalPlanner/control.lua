local build_graph = require("scripts/logic/build_graph")
local mark_rail_direction = require("scripts/logic/mark_rail_direction")
local place_signals = require("scripts/logic/place_signals")
local change_signals = require("scripts/logic/change_signals")
local ghostify = require("scripts/logic/ghostify")
require("scripts/compatibility")
require("gui/signal_tool_gui")
require("scripts/objects/rail")
require("scripts/shortcuts")

local function initialize_settings(player, invert_bidirectional_setting)
  Signal.unidirectional = get_setting("force_unidirectional", player)
  if invert_bidirectional_setting then
    Signal.unidirectional = not Signal.unidirectional
  end
  -- set which rails are used by which planner for the settings
  local planners = game.get_filtered_item_prototypes{{filter="type", type="rail-planner"}}
  Rail.planners = {}
  Signal.settings = {train_length = {}, rail_signal_distance = {}, rail_signal_item = {}, rail_chain_signal_item = {}}
  for _, planner in pairs(planners) do
    Rail.planners[planner.straight_rail.name] = planner.name
    Rail.planners[planner.curved_rail.name] = planner.name
    Signal.settings.rail_signal_item[planner.name] = get_setting("rail_signal_item", player, planner.name)
    local chain_signal = get_setting("rail_chain_signal_item", player, planner.name)
    if not game.entity_prototypes[chain_signal] then
      chain_signal = "rail-chain-signal"
      set_settings({["rail_chain_signal_item"] = chain_signal}, player)
    end
    Signal.settings.rail_chain_signal_item[planner.name] = chain_signal
    local rail_signal = get_setting("rail_signal_item", player, planner.name)
    if not game.entity_prototypes[rail_signal] then
      rail_signal = "rail-signal"
      set_settings({["rail_signal_item"] = rail_signal}, player)
    end
    Signal.settings.rail_signal_item[planner.name] = rail_signal
    Signal.settings.rail_signal_distance[planner.name] = get_setting("rail_signal_distance", player, planner.name)
    Signal.settings.train_length[planner.name] = get_setting("train_length", player, planner.name)
  end
  Rail.planners["straight-water-way-placed"] = "water-way" -- Cargo ships replace the rail entities..
  Rail.planners["curved-water-way-placed"] = "water-way" -- Cargo ships replace the rail entities..
end

local function build_signals(rails, player, using_rail_planner, invert_bidirectional_setting)
  if #rails == 0 then return end
  initialize_settings(player, invert_bidirectional_setting)

  -- create a chain of signals where signals can be placed
  build_graph(rails, player)

  -- For each rail decide if signals are placed on the left or right or both
  local succeeded = mark_rail_direction(player, rails[#rails])
  if not succeeded then
    if using_rail_planner and get_setting("force_build_rails", player) == false then
      for _, rail in pairs(rails) do
        if rail.valid then
          player.mine_entity(rail, false)
        end
      end
    end
    ghostify(player, false)
    Rail.all_rails = {}
    Signal.all_signals = {}
    return
  end
  -- place signals
  place_signals()
  -- change signals, checking overlaps
  change_signals(player)
  -- restore signals and rails based on their original signal
  ghostify(player, using_rail_planner)

  Rail.all_rails = {}
  Signal.all_signals = {}
end

local built_rails = {}
local function on_built_entity(event)
  local player = game.players[event.player_index]
  local entity = event.created_entity
  if entity.type == "straight-rail" or entity.type == "curved-rail" then
    if not get_setting("place_signals_with_rail_planner", player) then return end
    if built_rails[event.player_index] == nil then
      built_rails[event.player_index] = {}
    end
    table.insert(built_rails[event.player_index], {entity=entity, position=entity.position, direction=entity.direction, type=entity.type, surface=entity.surface})
  end
end

local function remove_disconnected_signals(player, rails)
  local min_x, min_y, max_x, max_y
  local surface
  for _, rail in pairs(rails) do
    if rail.valid then
      surface = surface or rail.surface
      min_x = min_x and math.min(min_x, rail.position.x) or rail.position.x
      min_y = min_y and math.min(min_y, rail.position.y) or rail.position.y
      max_x = max_x and math.max(max_x, rail.position.x) or rail.position.x
      max_y = max_y and math.max(max_y, rail.position.y) or rail.position.y
    end
  end
  if not min_x then return end
  local signals = surface.find_entities_filtered{area={{min_x-4, min_y-4},{max_x+4, max_y+4}}, type={"rail-signal", "rail-chain-signal"}, force=player.force, to_be_deconstructed=false}
  for _, signal in pairs(signals) do
    if #signal.get_connected_rails() == 0 then
      signal.order_deconstruction(player.force, player)
    end
  end
end

local function check_changed_rails(rails)
  -- some mods (cargo ships) change the rail type when they are build
  local new_rails = {}
  for _, rail in pairs(rails) do
    if not rail.entity.valid then
      local new_rail = rail.surface.find_entities_filtered{type=rail.type, position=rail.position, direction=rail.direction}
      new_rail = #new_rail == 1 and new_rail[1]
      table.insert(new_rails, new_rail)
    end
    table.insert(new_rails, rail.entity)
  end
  return new_rails
end

local function on_tick(event)
  for player_index, rails in pairs(built_rails) do
    -- remove any signals that have become disconnected
    local player = game.players[player_index]
    rails = check_changed_rails(rails)
    remove_disconnected_signals(player, rails)
    build_signals(rails, game.players[player_index], true)
  end
  built_rails = {}
end

script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_tick, on_tick)

-- functionality when selecting items with the tool

local function on_player_selected_area(event, alt_mode)
  local item = event.item
  if item == "rail-signal-planner" then
    local rails = {}
    for _, entity in pairs(event.entities) do
      if entity.type == "straight-rail" or entity.type == "curved-rail" then
        table.insert(rails, entity)
      end
    end
    local player = game.players[event.player_index]
    build_signals(rails, player, false, alt_mode)
  end
end

local function on_player_reverse_selected_area(event)
  local item = event.item
  if item ~= "rail-signal-planner" then return end
  local player = game.players[event.player_index]
  if not player then return end
  for _, signal in pairs(event.entities) do
    signal.cancel_deconstruction(player.force, player)
    signal.cancel_upgrade(player.force, player)
    if signal.type == "entity-ghost" then
      signal.destroy{raise_destroy=true}
    end
  end
end

local function on_player_alt_reverse_selected_area(event)
  local item = event.item
  if item ~= "rail-signal-planner" then return end
  local player = game.players[event.player_index]
  if not player then return end
  for _, signal in pairs(event.entities) do
    signal.cancel_upgrade(player.force, player)
    if signal.type == "entity-ghost" then
      signal.destroy{raise_destroy=true}
    else
      signal.order_deconstruction(player.force, player)
    end
  end
end

script.on_event(defines.events.on_player_selected_area, function(event)
  on_player_selected_area(event, false)
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
  on_player_selected_area(event, true)
end)

script.on_event(defines.events.on_player_reverse_selected_area, on_player_reverse_selected_area)
script.on_event(defines.events.on_player_alt_reverse_selected_area, on_player_alt_reverse_selected_area)

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