local function entity_id(entity)
  return entity.surface.name .. "|" .. entity.position.x .. "|" .. entity.position.y .. "|" .. entity.direction
end

local supported_types = {
  ["assembling-machine"] = {
    {},
    {display = {"iaai.input"}, inventory = defines.inventory.assembling_machine_input},
    {display = {"iaai.output"}, inventory = defines.inventory.assembling_machine_output},
    {display = {"iaai.modules"}, inventory = defines.inventory.assembling_machine_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.assembling_machine_trash},
    {display = {"iaai.rejected"}, inventory = defines.inventory.assembling_machine_dump},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["furnace"]            = {
    {},
    {display = {"iaai.input"}, inventory = defines.inventory.furnace_source},
    {display = {"iaai.output"}, inventory = defines.inventory.furnace_result},
    {display = {"iaai.modules"}, inventory = defines.inventory.furnace_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.furnace_trash},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["lab"]                = {
    {},
    {display = {"iaai.input"}, inventory = defines.inventory.lab_input},
    {display = {"iaai.modules"}, inventory = defines.inventory.lab_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.furnace_trash},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["rocket-silo"]        = {
    {},
    {display = {"iaai.rocket-inventory"}, inventory = defines.inventory.rocket_silo_rocket},
    {display = {"iaai.input"}, inventory = defines.inventory.rocket_silo_input},
    {display = {"iaai.output"}, inventory = defines.inventory.rocket_silo_output},
    {display = {"iaai.modules"}, inventory = defines.inventory.rocket_silo_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.rocket_silo_trash},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["cargo-landing-pad"]  = {
    {},
    {display = {"iaai.main-inventory"}, inventory = defines.inventory.cargo_landing_pad_main},
    {display = {"iaai.trash"}, inventory = defines.inventory.cargo_landing_pad_trash},
  },
  ["space-platform-hub"] = {
    {},
    {display = {"iaai-main-inventory"}, inventory = defines.inventory.hub_main},
    {display = {"iaai.trash"}, inventory = defines.inventory.hub_trash},
  },
  ["logistic-container"] = {
    {},
    {display = {"iaai.main-inventory"}, inventory = defines.inventory.chest},
    {display = {"iaai.trash"}, inventory = defines.inventory.logistic_container_trash},
  },
  ["mining-drill"]       = {
    {},
    {display = {"iaai.modules"}, inventory = defines.inventory.mining_drill_modules},
  },
}
local function get_pickup_target(inserter)
  if inserter.pickup_target then
    return inserter.pickup_target
  end
  for _, target in pairs(inserter.surface.find_entities_filtered {position = inserter.pickup_position}) do
    if supported_types[target.type] then
      return target
    end
  end
end

local function get_drop_target(inserter)
  if inserter.drop_target then
    return inserter.drop_target
  end
  for _, target in pairs(inserter.surface.find_entities_filtered {position = inserter.drop_position}) do
    if supported_types[target.type] then
      return target
    end
  end
end

local function get_selection_index(entity_type, inventory_defines)
  for i, inventory in pairs(supported_types[entity_type]) do
    if inventory.inventory == inventory_defines then
      return i
    end
  end
end

local drop_down_items = {}
for entity_type, inventories in pairs(supported_types) do
  drop_down_items[entity_type] = {"Default"}
  for _, inventory in pairs(inventories) do
    table.insert(drop_down_items[entity_type], inventory.display)
  end
end

local function on_gui_opened(event)
  local inserter = event.entity
  if not inserter then return end
  if inserter.type ~= "inserter" then return end
  local player = game.players[event.player_index]
  local anchor = {
    gui      = defines.relative_gui_type.inserter_gui,
    position = defines.relative_gui_position.right,
  }
  if player.gui.relative["inserter_frame_input"] then
    player.gui.relative["inserter_frame_input"].destroy()
  end
  if player.gui.relative["inserter_frame_output"] then
    player.gui.relative["inserter_frame_output"].destroy()
  end
  inserter.name_tag = "inserter-" .. event.player_index
  local pickup_target = get_pickup_target(inserter)
  if pickup_target then
    local selection_index = 1
    if pickup_target.name == "ii-proxy-container" then
      selection_index = get_selection_index(pickup_target.proxy_target_entity.type, pickup_target.proxy_target_inventory)
      pickup_target = pickup_target.proxy_target_entity
    end
    if supported_types[pickup_target.type] then
      local input_frame = player.gui.relative.add {type = "frame", name = "inserter_frame_input", anchor = anchor, caption = "Pickup inventory"}
      input_frame.add {
        type           = "drop-down",
        name           = "inserter_pickup_inventory",
        items          = drop_down_items[pickup_target.type],
        selected_index = selection_index,
      }
    end
  end
  local drop_target = get_drop_target(inserter)
  if drop_target then
    local selection_index = 1
    if drop_target.name == "ii-proxy-container" then
      selection_index = get_selection_index(drop_target.proxy_target_entity.type, drop_target.proxy_target_inventory)
      drop_target = drop_target.proxy_target_entity
    end
    if supported_types[drop_target.type] then
      local output_frame = player.gui.relative.add {type = "frame", name = "inserter_frame_output", anchor = anchor, caption = "Drop inventory"}
      output_frame.add {
        type           = "drop-down",
        name           = "inserter_drop_inventory",
        items          = drop_down_items[drop_target.type],
        selected_index = selection_index,
      }
    end
  end
end

local function set_inserter_inventory(inserter, target, inventory, pickup, proxy_container)
  local target_position
  local id = entity_id(inserter)
  if pickup then
    target_position = inserter.pickup_position
  else
    target_position = inserter.drop_position
  end

  if inventory and get_selection_index(target.type, inventory) then
    if not proxy_container then
      proxy_container = target.surface.create_entity {position = target_position, name = "ii-proxy-container", force = target.force, create_build_effect_smoke = false, snap_to_grid = false}
    end
    proxy_container.proxy_target_entity = target
    proxy_container.proxy_target_inventory = inventory
    if pickup then
      inserter.pickup_target = proxy_container
    else
      inserter.drop_target = proxy_container
    end
  else
    if proxy_container then
      proxy_container.destroy()
    end
  end
  if not storage.inventory_inserters[id] then
    storage.inventory_inserters[id] = {inserter = inserter}
  end
  if pickup then
    storage.inventory_inserters[id].pickup_inventory = inventory
    storage.inventory_inserters[id].pickup_target = target
    storage.inventory_inserters[id].pickup_container = proxy_container
  else
    storage.inventory_inserters[id].drop_inventory = inventory
    storage.inventory_inserters[id].drop_target = target
    storage.inventory_inserters[id].drop_container = proxy_container

  end
end

local function on_gui_selection_state_changed(event)
  local target
  local inserter
  local pickup
  if event.element.name == "inserter_pickup_inventory" then
    inserter = game.get_entity_by_tag("inserter-" .. event.player_index)
    target = get_pickup_target(inserter)
    pickup = true
  elseif event.element.name == "inserter_drop_inventory" then
    inserter = game.get_entity_by_tag("inserter-" .. event.player_index)
    target = get_drop_target(inserter)
    pickup = false
  else
    return
  end
  local proxy_container
  if target.name == "ii-proxy-container" then
    proxy_container = target
    target = proxy_container.proxy_target_entity
  end
  local inventory = supported_types[target.type][event.element.selected_index].inventory
  set_inserter_inventory(inserter, target, inventory, pickup, proxy_container)
end

local function on_entity_settings_pasted(event)
  if event.source.type == "inserter" and event.destination.type == "inserter" then
    for _, pickup in pairs({true, false}) do
      local proxy_container
      local target = pickup and get_pickup_target(event.destination) or get_drop_target(event.destination)
      if target and target.name == "ii-proxy-container" then
        proxy_container = target
        target = proxy_container.proxy_target_entity
      end
      if target and supported_types[target.type] then
        local inventory
        local source_target

        if pickup then
          source_target = get_pickup_target(event.source)
        else
          source_target = get_drop_target(event.source)
        end

        if source_target and source_target.name == "ii-proxy-container" then
          inventory = source_target.proxy_target_inventory
        end
        set_inserter_inventory(event.destination, target, inventory, pickup, proxy_container)
      end
    end
  end
end

local function on_built_entity(event)
  local entity = event.entity
  if entity.type == "inserter" then
    local id = entity_id(entity)
    if storage.inventory_inserters[id] then
      storage.inventory_inserters[id].inserter = entity
      if storage.inventory_inserters[id].pickup_target then
        set_inserter_inventory(entity, storage.inventory_inserters[id].pickup_target, storage.inventory_inserters[id].pickup_inventory, true)
      end
      if storage.inventory_inserters[id].drop_target then
        set_inserter_inventory(entity, storage.inventory_inserters[id].drop_target, storage.inventory_inserters[id].drop_inventory, false)
      end
    end
  end
end

local function destroy_proxy_container(event)
  local entity = event.entity
  if not entity then return end
  if entity.type == "inserter" then
    if entity.pickup_target and entity.pickup_target.name == "ii-proxy-container" then
      entity.pickup_target.destroy()
    end
    if entity.drop_target and entity.drop_target.name == "ii-proxy-container" then
      entity.drop_target.destroy()
    end
  end
  if supported_types[entity.type] then
    local position = event.old_position or entity.position
    local box = entity.prototype.selection_box
    local area = {
      left_top     = {x = box.left_top.x + position.x, y = box.left_top.y + position.y},
      right_bottom = {x = box.right_bottom.x + position.x, y = box.right_bottom.y + position.y},
    }
    local containers = entity.surface.find_entities_filtered {name = "ii-proxy-container", area = area}
    for _, container in pairs(containers) do
      container.destroy()
    end
  end
end

local function purge_inactive_chests()
  for _, inserter_info in pairs(storage.inventory_inserters or {}) do
    if not inserter_info.inserter.valid then
      if inserter_info.pickup_container and inserter_info.pickup_container.valid then
        inserter_info.pickup_container.destroy()
      end
      if inserter_info.drop_container and inserter_info.drop_container.valid then
        inserter_info.drop_container.destroy()
      end
    end
  end
end

local function on_configuration_changed(config)
  if not storage.inventory_inserters then
    storage.inventory_inserters = {}
  end
end

script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)

script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_robot_built_entity, on_built_entity)
script.on_event(defines.events.on_space_platform_built_entity, on_built_entity)
script.on_event(defines.events.script_raised_built, on_built_entity)

script.on_event(defines.events.on_entity_died, destroy_proxy_container)
script.on_event(defines.events.on_player_rotated_entity, destroy_proxy_container)
script.on_event(defines.events.on_player_mined_entity, destroy_proxy_container)
script.on_event(defines.events.on_robot_mined_entity, destroy_proxy_container)
script.on_event(defines.events.on_space_platform_mined_entity, destroy_proxy_container)
script.on_event(defines.events.script_raised_destroy, destroy_proxy_container)
script.on_event(defines.events.script_raised_teleported, destroy_proxy_container)

script.on_nth_tick(50, purge_inactive_chests)
