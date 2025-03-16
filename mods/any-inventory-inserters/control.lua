require("__any-inventory-inserters__/scripts/gui-logic.lua")
local types = require("__any-inventory-inserters__/scripts/supported-types.lua")
local util = require("__any-inventory-inserters__/scripts/util.lua")
local inserter_logic = require("__any-inventory-inserters__/scripts/inserter-logic.lua")

local function on_init(config)
  if not storage.inventory_inserters then
    storage.inventory_inserters = {}
  end
  if not storage.proxy_containers then
    storage.proxy_containers = {}
  end
end

local function on_tick(event)
  if storage.removed_inserters then
    for _, id in pairs(storage.removed_inserters) do
      local info = storage.inventory_inserters[id]
      if info and (not info.inserter or not info.inserter.valid) then
        storage.inventory_inserters[id] = nil
      end
    end
    storage.removed_inserters = nil
  end
  if storage.fix_undo_stack then
    for _, info in pairs(storage.fix_undo_stack) do
      local player = game.players[info.player_index]
      local undo_items = player.undo_redo_stack.get_undo_item(1)
      for item_index, undo_item in pairs(undo_items) do
        if (undo_item.target
                and undo_item.type == "removed-entity"
                and undo_item.target.position
                and undo_item.target.position.x == info.position.x
                and undo_item.target.position.y == info.position.y
                and (undo_item.target.direction or 0) == info.direction
                and undo_item.target.name == info.name
                and undo_item.surface_index == info.surface_index
        )
        then
          player.undo_redo_stack.set_undo_tag(1, item_index, "pickup_inventory", info.pickup_inventory)
          player.undo_redo_stack.set_undo_tag(1, item_index, "drop_inventory", info.drop_inventory)
        end
      end
    end
    storage.fix_undo_stack = nil
  end
end

local function on_built_entity(event, previous_inserter_info)
  local entity = event.entity
  if previous_inserter_info and util.get_entity_type(entity) == "inserter" then
    inserter_logic.set_inserter_inventory(entity, previous_inserter_info.pickup.inventory, "pickup")
    inserter_logic.set_inserter_inventory(entity, previous_inserter_info.drop.inventory, "drop")
  end
  if entity.type == "inserter" then
    inserter_logic.create_proxy_chests(entity)
  elseif entity.type == "entity-ghost" and entity.ghost_type == "inserter" and entity.tags then
    inserter_logic.set_inserter_inventory(entity, entity.tags.pickup_inventory, "pickup")
    inserter_logic.set_inserter_inventory(entity, entity.tags.drop_inventory, "drop")
  elseif types.supported_types[entity.type] then
    local position = entity.position
    local box = entity.prototype.selection_box
    local area = {
      left_top     = {x = box.left_top.x + position.x, y = box.left_top.y + position.y},
      right_bottom = {x = box.right_bottom.x + position.x, y = box.right_bottom.y + position.y},
    }
    for _, container in pairs(entity.surface.find_entities_filtered {name = "ii-proxy-container", area = area}) do
      if types.entity_has_inventory(util.get_entity_type(entity), container.proxy_target_inventory) then
        -- this entity does not support the given inventory defines
        container.proxy_target_entity = entity
        inserter_logic.connect_proxy_container(container)
      else
        inserter_logic.destroy_proxy_container(container)
      end
    end
  end
end

local function add_info_to_undo_stack(entity, player_index, inserter_info)
  if not player_index then return end
  if not storage.fix_undo_stack then
    storage.fix_undo_stack = {}
  end
  table.insert(storage.fix_undo_stack, {
    player_index     = player_index,
    name             = entity.name,
    position         = entity.position,
    direction        = entity.direction,
    surface_index    = entity.surface.index,
    pickup_inventory = inserter_info.pickup.inventory,
    drop_inventory   = inserter_info.drop.inventory,
  })
end

local function on_entity_removed(event)
  local entity = event.entity
  if not entity then return end
  local position = event.old_position or entity.position
  local direction = event.previous_direction or entity.direction
  if util.get_entity_type(entity) == "inserter" then
    local id = util.get_entity_id(entity, position, direction)
    local inserter_info = storage.inventory_inserters[id]
    if inserter_info then
      local player_index = event.player_index or (entity.last_user and entity.last_user.index)
      add_info_to_undo_stack(entity, player_index, inserter_info)
      inserter_info.inserter = nil
      local pickup_proxy = inserter_info.pickup.proxy
      if pickup_proxy and pickup_proxy.valid then
        storage.proxy_containers[pickup_proxy.unit_number] = nil
        pickup_proxy.destroy()
        inserter_info.pickup.proxy = nil
      end
      local drop_proxy = inserter_info.drop.proxy
      if drop_proxy and drop_proxy.valid then
        storage.proxy_containers[drop_proxy.unit_number] = nil
        drop_proxy.destroy()
        inserter_info.drop.proxy = nil
      end
      if not storage.removed_inserters then
        storage.removed_inserters = {}
      end
      table.insert(storage.removed_inserters, id)
    end
    return inserter_info
  end
  if types.supported_types[entity.type] then
    local box = entity.prototype.selection_box
    local area = {
      left_top     = {x = box.left_top.x + position.x, y = box.left_top.y + position.y},
      right_bottom = {x = box.right_bottom.x + position.x, y = box.right_bottom.y + position.y},
    }
    local proxies = entity.surface.find_entities_filtered {name = "ii-proxy-container", area = area}
    for _, proxy in pairs(proxies) do
      local proxy_info = storage.proxy_containers[proxy.unit_number]
      if proxy_info then
        local inserter_info = storage.inventory_inserters[util.get_entity_id(proxy_info.inserter)]
        if inserter_info then
          inserter_info[proxy_info.type].main_target = nil
        end
        if proxy.proxy_target_entity == entity then
          proxy.proxy_target_entity = nil
        end
      else
        proxy.destroy()
      end
    end
  end
end

local function on_entity_settings_pasted(event)
  if util.get_entity_type(event.source) == "inserter" and util.get_entity_type(event.destination) == "inserter" then
    local source_info = storage.inventory_inserters[util.get_entity_id(event.source)]
    local pickup_inventory = source_info and source_info.pickup.inventory
    local drop_inventory = source_info and source_info.drop.inventory
    inserter_logic.set_inserter_inventory(event.destination, pickup_inventory, "pickup")
    inserter_logic.set_inserter_inventory(event.destination, drop_inventory, "drop")
  end
end

local function on_entity_changed(event)
  local previous_info = on_entity_removed(event)
  on_built_entity(event, previous_info)
end

local function on_player_setup_blueprint(event)
  local item_or_record = event.stack or event.record
  for index, entity in pairs(event.mapping.get()) do
    if entity.type == "inserter" then
      local id = util.get_entity_id(entity)
      local inserter_info = storage.inventory_inserters[id]
      if inserter_info then
        item_or_record.set_blueprint_entity_tag(index, "pickup_inventory", inserter_info.pickup.inventory)
        item_or_record.set_blueprint_entity_tag(index, "drop_inventory", inserter_info.drop.inventory)
      end
    end
  end
end

local function purge_inactive_chests(event)
  for unit_number, info in pairs(storage.proxy_containers) do
    if not info.proxy or not info.proxy.valid then
      -- game.print("Inactive chest found (proxy does not exist or is invalid)")
      storage.proxy_containers[unit_number] = nil
    elseif not info.inserter or not info.inserter.valid then
      -- game.print("Inactive chest found (inserter does not exist or is invalid)")
      info.proxy.destroy()
      storage.proxy_containers[unit_number] = nil
    end
  end
end

script.on_configuration_changed(on_init)
script.on_init(on_init)

script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
--
script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_entity_cloned, on_built_entity)
script.on_event(defines.events.on_robot_built_entity, on_built_entity)
script.on_event(defines.events.on_space_platform_built_entity, on_built_entity)
script.on_event(defines.events.script_raised_built, on_built_entity)
script.on_event(defines.events.script_raised_revive, on_built_entity)
--
script.on_event(defines.events.on_entity_died, on_entity_removed)
script.on_event(defines.events.on_player_mined_entity, on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed)
script.on_event(defines.events.on_space_platform_mined_entity, on_entity_removed)
script.on_event(defines.events.script_raised_destroy, on_entity_removed)

script.on_event(defines.events.on_player_rotated_entity, on_entity_changed)
script.on_event(defines.events.script_raised_teleported, on_entity_changed)
--
script.on_event(defines.events.on_player_setup_blueprint, on_player_setup_blueprint)
script.on_event(defines.events.on_undo_applied, on_undo_applied)
--
script.on_event(defines.events.on_tick, on_tick)
script.on_nth_tick(123456, purge_inactive_chests)
