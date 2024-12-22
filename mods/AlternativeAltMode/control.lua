require("__AlternativeAltMode__/scripts/control_logic.lua")
require("__AlternativeAltMode__/scripts/util.lua")
local constants = require("__AlternativeAltMode__/scripts/constants")
local entity_info = require("__AlternativeAltMode__/scripts/draw_entity_info")

local function on_selected_entity_changed(event)
  local player = game.players[event.player_index]
  entity_info.show_alt_info_for_player(player)
end

local function on_tick(event)
  for _, player in pairs(game.players) do
    entity_info.show_alt_info_for_player(player)
  end
end

local function on_toggled_alt_mode(event)
  if not storage.alt_mode_status then
    storage.alt_mode_status = {}
  end
  local cur_status = storage.alt_mode_status[event.player_index]
  local player = game.players[event.player_index]
  if not cur_status then
    if player.game_view_settings.show_entity_info then
      storage.alt_mode_status[event.player_index] = "on"
    else
      storage.alt_mode_status[event.player_index] = "off"
    end
    cur_status = storage.alt_mode_status[event.player_index]
  end
  if cur_status == "off" then
    storage.alt_mode_status[event.player_index] = "alt-alt"
    player.game_view_settings.show_entity_info = false
  elseif cur_status == "alt-alt" then
    if settings.get_player_settings(player)["alt-alt-turn-off-completely"].value then
      storage.alt_mode_status[event.player_index] = "off"
      player.game_view_settings.show_entity_info = false
    else
      storage.alt_mode_status[event.player_index] = "on"
      player.game_view_settings.show_entity_info = true
    end
  elseif cur_status == "on" then
    storage.alt_mode_status[event.player_index] = "off"
    player.game_view_settings.show_entity_info = false
  end
  entity_info.show_alt_info_for_player(game.players[event.player_index])

end

script.on_event(defines.events.on_player_rotated_entity, on_selected_entity_changed)
script.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)
script.on_nth_tick(constants.time_to_live, on_tick)

script.on_event(defines.events.on_player_toggled_alt_mode, on_toggled_alt_mode)