local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local draw_functions = require("__alt-alt-mode__/scripts/draw_functions")
local control_settings = require("__alt-alt-mode__/scripts/control_settings")
local util = require("__alt-alt-mode__/scripts/util")

local function show_alt_info_for_player(player, center_position)
  local selected_entity = player.selected
  center_position = center_position or (selected_entity and selected_entity.position)
  if not center_position then return end
  if not storage.last_known_position then
    storage.last_known_position = {}
  end
  storage.last_known_position[player.index] = center_position
  storage["electric_network"] = nil
  draw_functions.remove_all_sprites(player)
  if storage.alt_mode_status and storage.alt_mode_status and storage.alt_mode_status[player.index] ~= "alt-alt" then
    return
  end
  storage[player.index] = {}
  local radius = settings.get_player_settings(player)["alt-alt-radius"].value
  if settings.get_player_settings(player)["alt-alt-radius-indicator"].value then
    draw_functions.draw_radius_indicator(player, center_position, radius)
  end
  local entity_types = control_settings.get_player_entity_types(player)
  if radius <= 0 and player.selected then
    entity_logic.show_quality_icon(player, player.selected)
    if not util.contains(entity_types, player.selected.type) then return end
    local item_requests = {}
    for _, proxy in pairs(player.surface.find_entities_filtered {type = "item-request-proxy", area=player.selected.selection_box, force = player.force}) do
      if proxy and proxy.valid and proxy.proxy_target == player.selected then
        table.insert(item_requests, proxy)
      end
    end
    entity_logic.show_alt_info_for_entity(player, player.selected, item_requests)
  else
    local proxies = {}
    for _, proxy in pairs(player.surface.find_entities_filtered {type = "item-request-proxy", position = center_position, radius = radius, force = player.force}) do
      if proxy and proxy.valid and proxy.proxy_target then
        local target_id = proxy.proxy_target.unit_number
        if target_id and not proxies[target_id] then
          proxies[target_id] = {}
        end
        table.insert(proxies[target_id], proxy)
      end
    end
    for _, entity in pairs(player.surface.find_entities_filtered {type = entity_types, position = center_position, radius = radius, force = {player.force, "neutral"}}) do
      if entity and entity.valid then
        entity_logic.show_alt_info_for_entity(player, entity, proxies[entity.unit_number])
      end
    end
    for _, entity in pairs(player.surface.find_entities_filtered {position = center_position, radius = radius, quality={quality="normal", comparator=">"}}) do
      if entity and entity.valid then
        entity_logic.show_quality_icon(player, entity)
      end
    end
  end
end

return {
  show_alt_info_for_player = show_alt_info_for_player
}