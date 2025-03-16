local types = require("__any-inventory-inserters__/scripts/supported-types.lua")
local util = require("__any-inventory-inserters__/scripts/util.lua")

local inserter_logic = {}

inserter_logic.get_supported_entity_at_position = function(surface, position)
  local targets = surface.find_entities_filtered {type = types.supported_types_filter, position = position}
  if #targets > 0 then
    return targets[1]
  end
  local ghost_targets = surface.find_entities_filtered {type = "entity-ghost", ghost_type = types.supported_types_filter, position = position}
  if #ghost_targets > 0 then
    return ghost_targets[1]
  end
end

inserter_logic.get_inserter_info = function(inserter)
  local id = util.get_entity_id(inserter)
  local info = storage.inventory_inserters[id]
  if not info then
    info = {pickup = {}, drop = {}}
  end
  if not info.pickup.main_target or not info.pickup.main_target.valid then
    info.pickup.main_target = inserter_logic.get_supported_entity_at_position(inserter.surface, inserter.pickup_position)
  end
  if not info.drop.main_target or not info.drop.main_target.valid then
    info.drop.main_target = inserter_logic.get_supported_entity_at_position(inserter.surface, inserter.drop_position)
  end
  return info
end

inserter_logic.create_proxy_chests = function(inserter)
  if inserter.type ~= "inserter" then return end
  local info = inserter_logic.get_inserter_info(inserter)
  if not info then return end
  info.inserter = inserter
  if info.pickup.inventory then
    if not info.pickup.proxy or not info.pickup.proxy.valid then
      info.pickup.proxy = inserter.surface.create_entity {name = "ii-proxy-container", position = inserter.pickup_position, force = inserter.force, raise_built = false, create_build_effect_smoke = false}
      storage.proxy_containers[info.pickup.proxy.unit_number] = {
        type     = "pickup",
        inserter = inserter,
        proxy    = info.pickup.proxy
      }
    end
    info.pickup.proxy.proxy_target_inventory = info.pickup.inventory
    if not info.pickup.main_target or not info.pickup.main_target.valid then
      info.pickup.main_target = inserter_logic.get_supported_entity_at_position(inserter.surface, inserter.pickup_position)
    end
    info.pickup.proxy.proxy_target_entity = info.pickup.main_target
    inserter.pickup_target = info.pickup.proxy
  elseif info.pickup.proxy then
    info.pickup.proxy.destroy()
    info.pickup.proxy = nil
  end
  if info.drop.inventory then
    if not info.drop.proxy or not info.drop.proxy.valid then
      info.drop.proxy = inserter.surface.create_entity {name = "ii-proxy-container", position = inserter.drop_position, force = inserter.force, raise_built = false, create_build_effect_smoke = false}
      storage.proxy_containers[info.drop.proxy.unit_number] = {
        type     = "drop",
        inserter = inserter,
        proxy    = info.drop.proxy,
      }
    end
    info.drop.proxy.proxy_target_inventory = info.drop.inventory
    if not info.drop.main_target or not info.drop.main_target.valid then
      info.drop.main_target = inserter_logic.get_supported_entity_at_position(inserter.surface, inserter.drop_position)
    end
    info.drop.proxy.proxy_target_entity = info.drop.main_target
    inserter.drop_target = info.drop.proxy
  elseif info.drop.proxy then
    info.drop.proxy.destroy()
    info.drop.proxy = nil
  end
  if not info.drop.inventory and not info.pickup.inventory then
    local id = util.get_entity_id(inserter)
    storage.inventory_inserters[id] = nil
  end
end

inserter_logic.connect_proxy_container = function(container)
  local container_info = storage.proxy_containers[container.unit_number]
  local inserter_id = util.get_entity_id(container_info.inserter)
  local inserter_info = storage.inventory_inserters[inserter_id]
  container_info.inserter = inserter_info.inserter
  if container_info.type == "pickup" then
    container_info.inserter.pickup_target = container
  else
    container_info.inserter.drop_target = container
  end
end

inserter_logic.set_inserter_inventory = function(inserter, inventory, target_type, target, proxy_container)
  local target_position
  local id = util.get_entity_id(inserter)
  if target_type == "pickup" then
    target_position = inserter.pickup_position
  else
    target_position = inserter.drop_position
  end
  if not storage.inventory_inserters[id] then
    storage.inventory_inserters[id] = {inserter = inserter, pickup = {}, drop = {}}
  end
  local info = storage.inventory_inserters[id][target_type]
  if not inventory and info.proxy then
    inserter_logic.destroy_proxy_container(info.proxy)
  elseif info.main_target and info.main_target.valid and inventory and not types.entity_has_inventory(util.get_entity_type(info.main_target), inventory) then
    inserter_logic.destroy_proxy_container(info.proxy)
  else
    info.inventory = inventory
    info.proxy = proxy_container
    info.main_target = target
    inserter_logic.create_proxy_chests(inserter)
  end
end

inserter_logic.destroy_proxy_container = function(container)
  local container_info = storage.proxy_containers[container.unit_number]
  local inserter_id = util.get_entity_id(container_info.inserter)
  local inserter_info = storage.inventory_inserters[inserter_id]
  inserter_info[container_info.type] = {}
  storage.proxy_containers[container.unit_number] = nil
  container.destroy()
end

return inserter_logic
