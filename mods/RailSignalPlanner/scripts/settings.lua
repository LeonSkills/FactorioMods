local default_settings = {
  ["rail_signal_item"] = "rail-signal",
  ["rail_chain_signal_item"] = "rail-chain-signal",
  ["train_length"] = 13,
  ["rail_signal_distance"] = 8
}

function set_default_settings(player_index)
  global.signal_settings[player_index] = {}
  local settings = global.signal_settings[player_index]
  for i, v in pairs(default_settings) do
    settings[i] = v
  end
end


local function get_flow(player)
  if player and player.valid and player.gui.screen.rail_signal_gui then
    return player.gui.screen.rail_signal_gui.rail_signal_flow
  end
end


function set_settings(settings, player)
  local global_settings = global.signal_settings[player.index]
  local gui = get_flow(player)
  for setting, value in pairs(settings) do
    if setting == "rail_signal_item" then
      local item = game.item_prototypes[value]
      if not item then
        player.print({"rail-signal-tool.not-an-item", value}, {255, 100, 100})
        player.play_sound{path="utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_signal_item.elem_value = get_setting("rail_signal_item", player)
        end
      elseif not item.place_result then
        player.print({"rail-signal-tool.cant-place", item.localised_name}, {255, 100, 100})
        player.play_sound{path="utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_signal_item.elem_value = get_setting("rail_signal_item", player)
        end
      elseif item.place_result.type ~= "rail-signal" and item.place_result.type ~= "rail-chain-signal" then
        player.print({"rail-signal-tool.not-a-valid-entity", item.localised_name, {"entity-name.rail-signal"}}, {255, 100, 100})
        player.play_sound{path="utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_signal_item.elem_value = get_setting("rail_signal_item", player)
        end
      else
        global_settings.rail_signal_item = value
      end
    elseif setting == "rail_chain_signal_item" then
      local item = game.item_prototypes[value]
      if not item then
        player.print({"rail-signal-tool.not-an-item", value}, {255, 100, 100})
        player.play_sound{path="utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_chain_signal_item.elem_value = get_setting("rail_chain_signal_item", player)
        end
      elseif not item.place_result then
        player.print({"rail-signal-tool.cant-place", item.localised_name}, {255, 100, 100})
        player.play_sound{path="utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_chain_signal_item.elem_value = get_setting("rail_chain_signal_item", player)
        end
      elseif item.place_result.type ~= "rail-signal" and item.place_result.type ~= "rail-chain-signal" then
        player.print({"rail-signal-tool.not-a-valid-entity", item.localised_name, {"entity-name.rail-signal"}}, {255, 100, 100})
        player.play_sound{path="utility/cannot_build"}
        if gui then
          gui.rail_signal_table.rail_chain_signal_item.elem_value = get_setting("rail_chain_signal_item", player)
        end
      else
        global_settings.rail_chain_signal_item = value
      end
    elseif setting == "train_length" then
      global_settings.train_length = value
    elseif setting == "rail_signal_distance" then
      global_settings.rail_signal_distance = value
    end
  end
end

function get_setting(setting, player)
  if not global.signal_settings then
    global.signal_settings = {}
  end
  if not global.signal_settings[player.index] then
    set_default_settings(player.index)
  end
  if not global.signal_settings[player.index][setting] then
    global.signal_settings[player.index][setting] = default_settings[setting]
  end
  return global.signal_settings[player.index][setting]
end
