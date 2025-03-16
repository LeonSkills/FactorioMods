local types = require("__any-inventory-inserters__/scripts/supported-types.lua")
local util = require("__any-inventory-inserters__/scripts/util.lua")
local inserter_logic = require("__any-inventory-inserters__/scripts/inserter-logic.lua")
local supported_types = types.supported_types

local drop_down_items = {}
for entity_type, inventories in pairs(supported_types) do
  drop_down_items[entity_type] = {"Default"}
  for _, inventory in pairs(inventories) do
    table.insert(drop_down_items[entity_type], inventory.display)
  end
end

local function get_selection_index(entity, inventory_defines)
  for i, inventory in pairs(supported_types[util.get_entity_type(entity)]) do
    if inventory.inventory == inventory_defines then
      return i
    end
  end
  return 1
end

local function on_gui_opened(event)
  local inserter = event.entity
  if not inserter then return end
  local anchor
  if util.get_entity_type(inserter) == "inserter" then
    anchor = {
      gui      = defines.relative_gui_type.inserter_gui,
      position = defines.relative_gui_position.right,
    }
  else
    return
  end
  local player = game.players[event.player_index]
  if player.gui.relative["inserter_frame_pickup"] then
    player.gui.relative["inserter_frame_pickup"].destroy()
  end
  if player.gui.relative["inserter_frame_drop"] then
    player.gui.relative["inserter_frame_drop"].destroy()
  end
  inserter.name_tag = "inserter-" .. event.player_index
  local inserter_info = inserter_logic.get_inserter_info(inserter)
  if inserter_info.pickup.main_target and supported_types[util.get_entity_type(inserter_info.pickup.main_target)] then
    local output_frame = player.gui.relative.add {type = "frame", name = "inserter_frame_pickup", anchor = anchor, caption = "Pickup inventory"}
    local selection_index = get_selection_index(inserter_info.pickup.main_target, inserter_info.pickup.inventory)
    output_frame.add {
      type           = "drop-down",
      name           = "inserter_pickup_inventory",
      items          = drop_down_items[util.get_entity_type(inserter_info.pickup.main_target)],
      selected_index = selection_index,
    }
  elseif inserter_info.pickup.inventory then
    local output_frame = player.gui.relative.add {type = "frame", name = "inserter_frame_pickup", anchor = anchor, caption = "Pickup inventory"}
    output_frame.add {
      type    = "button",
      caption = "Reset",
      name    = "inserter_pickup_reset",
    }
  end
  if inserter_info.drop.main_target and supported_types[util.get_entity_type(inserter_info.drop.main_target)] then
    local output_frame = player.gui.relative.add {type = "frame", name = "inserter_frame_drop", anchor = anchor, caption = "Drop inventory"}
    local selection_index = get_selection_index(inserter_info.drop.main_target, inserter_info.drop.inventory)
    output_frame.add {
      type           = "drop-down",
      name           = "inserter_drop_inventory",
      items          = drop_down_items[util.get_entity_type(inserter_info.drop.main_target)],
      selected_index = selection_index,
    }
  elseif inserter_info.drop.inventory then
    local output_frame = player.gui.relative.add {type = "frame", name = "inserter_frame_drop", anchor = anchor, caption = "Drop inventory"}
    output_frame.add {
      type    = "button",
      caption = "Reset",
      name    = "inserter_drop_reset",
    }
  end
end

local function on_gui_selection_state_changed(event)
  local target_type
  if event.element.name == "inserter_pickup_inventory" then
    target_type = "pickup"
  elseif event.element.name == "inserter_drop_inventory" then
    target_type = "drop"
  else
    return
  end
  if not target_type then return end
  local inserter = game.get_entity_by_tag("inserter-" .. event.player_index)
  if not inserter then return end
  local inserter_info = inserter_logic.get_inserter_info(inserter)
  local target = inserter_info[target_type].main_target
  if not target then return end
  local proxy_container = inserter_info[target_type].proxy
  local inventory = supported_types[util.get_entity_type(target)][event.element.selected_index].inventory
  inserter_logic.set_inserter_inventory(inserter, inventory, target_type, target, proxy_container)
end

local function on_gui_click(event)
  local target_type
  if event.element.name == "inserter_pickup_reset" then
    target_type = "pickup"
  elseif event.element.name == "inserter_drop_reset" then
    target_type = "drop"
  else
    return
  end
  local inserter = game.get_entity_by_tag("inserter-" .. event.player_index)
  if not inserter or not inserter.valid then return end
  event.element.parent.destroy()
  local id = util.get_entity_id(inserter)
  if not storage.inventory_inserters[id] then return end
  local info = storage.inventory_inserters[id][target_type]
  if info.proxy and info.proxy.valid then
    storage.proxy_containers[info.proxy.unit_number] = nil
    info.proxy.destroy()
  end
  storage.inventory_inserters[id][target_type] = {}
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)