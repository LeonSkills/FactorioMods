require("__alt-alt-mode__/scripts/control_logic.lua")
require("__alt-alt-mode__/scripts/control_settings.lua")
require("__alt-alt-mode__/tests/test_entity.lua")
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
    draw_functions.draw_radius_indicator(player, nil, nil, 60)
    storage.alt_mode_status[event.player_index] = "alt-alt"
    player.game_view_settings.show_entity_info = false
  elseif cur_status == "alt-alt" then
    draw_functions.remove_radius_indicator(player)
    draw_functions.remove_all_sprites(player)
    if settings.get_player_settings(player)["alt-alt-turn-off-completely"].value then
      storage.alt_mode_status[event.player_index] = "off"
      player.game_view_settings.show_entity_info = false
    else
      storage.alt_mode_status[event.player_index] = "on"
      player.game_view_settings.show_entity_info = true
    end
  elseif cur_status == "on" then
    draw_functions.remove_radius_indicator(player)
    draw_functions.remove_all_sprites(player)
    storage.alt_mode_status[event.player_index] = "off"
    player.game_view_settings.show_entity_info = false
  end
  player_logic.show_alt_info_for_player(game.players[event.player_index])
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
  end
  if event.setting == "alt-alt-blacklist" then
    control_settings.update_blacklist_setting(game.players[event.player_index])
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
