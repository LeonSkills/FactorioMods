require("__alt-alt-mode__/scripts/control_logic.lua")
require("__alt-alt-mode__/scripts/control_settings.lua")
local util = require("__alt-alt-mode__/scripts/util.lua")
local player_logic = require("__alt-alt-mode__/scripts/player_logic")
local mouse = require("__alt-alt-mode__/scripts/mouse_position")
local draw_functions = require("__alt-alt-mode__/scripts/draw_functions")
local control_settings = require("__alt-alt-mode__/scripts/control_settings")

local function on_selected_entity_changed(event)
  local player = game.players[event.player_index]
  -- util.log("Entity changed", player.selected and player.selected.name)
  local mouse_position = mouse.find_mouse(player)
  if mouse_position then
    player_logic.show_alt_info_for_player(player, mouse_position)
  end
end

local function on_tick(event)
  for _, player in pairs(game.players) do
    if not player.selected then
      mouse.start_search(player)
    else
      player_logic.show_alt_info_for_player(player)
    end
  end
end

local function cycle_alt_mode(player)
  local player_settings = settings.get_player_settings(player)
  local off = player_settings["alt-alt-toggle-off"].value
  local alternative = player_settings["alt-alt-toggle-alternative-alt-mode"].value
  local both = player_settings["alt-alt-toggle-vanilla-and-alternative"].value
  local vanilla = player_settings["alt-alt-toggle-vanilla"].value
  if not off and not alternative and not vanilla and not both then
    player.print("All modes are turned off, turning off alt mode completely")
    off = true
  end
  local cur_status = storage.alt_mode_status[player.index]
  if cur_status == "off" then
    cur_status = "alt-alt"
    storage.alt_mode_status[player.index] = cur_status
    if alternative then
      player.game_view_settings.show_entity_info = false
      draw_functions.draw_radius_indicator(player, nil, nil, 60)
      player_logic.show_alt_info_for_player(player)
      return
    end
  end
  if cur_status == "alt-alt" then
    cur_status = "both"
    storage.alt_mode_status[player.index] = cur_status
    if both then
      player.game_view_settings.show_entity_info = true
      draw_functions.draw_radius_indicator(player, nil, nil, 60)
      player_logic.show_alt_info_for_player(player)
      return
    end
  end
  if cur_status == "both" then
    cur_status = "vanilla"
    storage.alt_mode_status[player.index] = cur_status
    if vanilla then
      player.game_view_settings.show_entity_info = true
      return
    end
  end
  if cur_status == "vanilla" then
    cur_status = "off"
    storage.alt_mode_status[player.index] = cur_status
    if off then
      player.game_view_settings.show_entity_info = false
      return
    end
  end
  cycle_alt_mode(player)
end

local function on_toggled_alt_mode(event)
  if not storage.alt_mode_status then
    storage.alt_mode_status = {}
  end
  local cur_status = storage.alt_mode_status[event.player_index]
  local player = game.players[event.player_index]


  if not cur_status then
    if player.game_view_settings.show_entity_info then
      storage.alt_mode_status[event.player_index] = "vanilla"
    else
      storage.alt_mode_status[event.player_index] = "off"
    end
  elseif cur_status == "on" then
    storage.alt_mode_status[event.player_index] = "vanilla"
  end
  cycle_alt_mode(player)

end

local function on_configuration_changed(event)
  if event.mod_changes["alt-alt-mode"] then
    local old_version = event.mod_changes["alt-alt-mode"].old_version
    if old_version and util.compare_versions(old_version, "0.1.14") == -1 then
      print("Deregistering old on_nth_tick for mod alt-alt-mode")
      script.on_nth_tick(60, nil)
    end
    storage.update_interval = settings.global["alt-alt-update-interval"].value
    script.on_nth_tick(storage.update_interval, on_tick)
  end
end


local function on_setting_changed(event)
  if event.setting == "alt-alt-update-interval" then
    util.log("Interval changed, deregistering old on_nth_tick ")
    if storage.update_interval then
      script.on_nth_tick(storage.update_interval, nil)
    end
    storage.update_interval = settings.global["alt-alt-update-interval"].value
    script.on_nth_tick(storage.update_interval, on_tick)
    return
  elseif event.setting == "alt-alt-blacklist" then
    control_settings.update_blacklist_setting(game.players[event.player_index])
  elseif event.setting == "alt-alt-blacklist-individual" then
    control_settings.update_blacklist_setting_individual(game.players[event.player_index])
  end
end

local function on_init()
  storage.update_interval = settings.global["alt-alt-update-interval"].value
  script.on_nth_tick(storage.update_interval, on_tick)
end

local function on_load()
  script.on_nth_tick(settings.global["alt-alt-update-interval"].value, on_tick)
end

local function on_surface_change(event)
  local player = game.players[event.player_index]
  if player then
    mouse.reset_data(player)
  end
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_rotated_entity, on_selected_entity_changed)
script.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
script.on_event(defines.events.on_player_toggled_alt_mode, on_toggled_alt_mode)
script.on_event(defines.events.on_player_changed_surface, on_surface_change)
