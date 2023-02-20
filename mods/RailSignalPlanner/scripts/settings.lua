local default_settings = {
  ["selected_rail_planner"]           = "rail",
  ["place_signals_with_rail_planner"] = false,
  ["force_unidirectional"]            = false,
  ["force_build_rails"]               = true,
  ["water-way"]                       = {
    ["rail_signal_item"]       = "buoy",
    ["rail_chain_signal_item"] = "chain_buoy",
    ["train_length"]           = 20,
    ["rail_signal_distance"]   = 20
  },
  ["rail_signal_item"]                = "rail-signal",
  ["rail_chain_signal_item"]          = "rail-chain-signal",
  ["train_length"]                    = 20,
  ["rail_signal_distance"]            = 20,
}

function set_default_settings(player_index)
  global.signal_settings[player_index] = {}
  local settings = global.signal_settings[player_index]
  for i, v in pairs(default_settings) do
    settings[i] = v
  end
end

local function get_flow(player)
  if player and player.valid and player.gui.left.rail_signal_gui then
    return player.gui.left.rail_signal_gui.rail_signal_flow
  end
end

function set_settings(settings, player, additional_key)
  local global_settings = global.signal_settings[player.index]
  if additional_key then
    global_settings = global_settings[additional_key]
  end
  local gui = get_flow(player)
  for setting, value in pairs(settings) do
    if setting == "rail_signal_item" then
      local entity = game.entity_prototypes[value]
      if not entity then
        player.print({"rail-signal-tool.not-an-item", value}, {255, 100, 100})
        player.play_sound {path = "utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_signal_item.elem_value = get_setting("rail_signal_item", player, additional_key)
        end
      elseif #entity.items_to_place_this == 0 then
        player.print({"rail-signal-tool.cant-place", entity.localised_name}, {255, 100, 100})
        player.play_sound {path = "utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_signal_item.elem_value = get_setting("rail_signal_item", player, additional_key)
        end
      else
        global_settings.rail_signal_item = value
      end
    elseif setting == "rail_chain_signal_item" then
      local entity = game.entity_prototypes[value]
      if not entity then
        player.print({"rail-signal-tool.not-an-item", value}, {255, 100, 100})
        player.play_sound {path = "utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_chain_signal_item.elem_value = get_setting("rail_chain_signal_item", player, additional_key)
        end
      elseif #entity.items_to_place_this == 0 then
        player.print({"rail-signal-tool.cant-place", entity.localised_name}, {255, 100, 100})
        player.play_sound {path = "utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_chain_signal_item.elem_value = get_setting("rail_chain_signal_item", player, additional_key)
        end
      else
        global_settings.rail_chain_signal_item = value
      end
    else
      global_settings[setting] = value
    end
  end
end

function get_setting(setting, player, additional_key)
  if not global.signal_settings then
    global.signal_settings = {}
  end
  if not global.signal_settings[player.index] then
    set_default_settings(player.index)
  end
  local settings = global.signal_settings[player.index]
  if additional_key then
    if not settings[additional_key] then
      settings[additional_key] = {}
    end
    settings = settings[additional_key]
  end
  if settings[setting] == nil then
    if global.signal_settings[player.index][setting] then
      --legacy
      settings[setting] = global.signal_settings[player.index][setting]
      global.signal_settings[player.index][setting] = nil
    else
      settings[setting] = default_settings[additional_key] and default_settings[additional_key][setting] or default_settings[setting]
    end
  end
  return settings[setting]
end

function toggle_unidirectional(event)
  -- event can also be player
  local player_index = event.player_index or event.index
  local player = game.players[player_index]
  local old_value = get_setting("force_unidirectional", player)
  set_settings({force_unidirectional = not old_value}, player)
  local gui = get_flow(player)
  if gui then
    gui.toggle_table.toggle_one_directional.state = not old_value
  end
end

function toggle_place_signals_with_planner(event)
  -- event can also be player
  local player_index = event.player_index or event.index
  local player = game.players[player_index]
  local old_value = get_setting("place_signals_with_rail_planner", player)
  set_settings({place_signals_with_rail_planner = not old_value}, player)
  local gui = get_flow(player)
  if gui then
    gui.toggle_table.toggle_place_signals_with_rail_planner.state = not old_value
  end
end
