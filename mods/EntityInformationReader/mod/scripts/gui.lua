local common = require("scripts/common")
local container = require("scripts/container")
local crafting_machine = require("scripts/crafting-machine")

local function create_nothing_there_gui(flow)
  flow.add{type="label", caption={"eir-gui.nothing-there"}}
end

local function create_unsupported_type_gui(flow)
  flow.add{type="label", caption={"eir-gui.unknown-type"}}
end

local function create_combinator_gui(player, combinator)
  player.opened = nil
  local frame = player.gui.screen.add{type="frame", name="entity_info_element", direction="vertical"}
  local flow = frame.add{type="flow", direction="vertical"}
  flow.drag_target=frame
  local entity_preview = flow.add{type="entity-preview", name="entity_preview"}
  entity_preview.entity=combinator
  frame.force_auto_center()
  local entity = combinator.surface.find_entities_filtered{position=combinator.position, name="entity-information-reader", invert=true}
  if #entity == 0 then
    create_nothing_there_gui(flow)
  else
    local cb = combinator.get_control_behavior()
    entity = entity[1]
    frame.caption = entity.localised_name
    local table = flow.add{type="table", column_count=2}
    common.create_gui(cb, table)
    if entity.type == "container" or entity.type == "logistic-container" or entity.type == "infinity-container" then
      container.create_gui(cb, table)
    elseif entity.type == "furnace" or entity.type == "assembling-machine" then
      crafting_machine.create_gui(cb, table)
    elseif entity.type == "rocket-silo" then
      crafting_machine.create_gui(cb, table)
    else
      create_unsupported_type_gui(flow)
    end
  end
  player.opened = frame
end

local function on_gui_closed(event)
  local player = game.get_player(event.player_index)
  if player.gui.screen.entity_info_element then
    player.gui.screen.entity_info_element.destroy()
  end
end


local function on_gui_opened(event)
  local player = game.get_player(event.player_index)
  if event.entity and event.entity.name == "entity-information-reader" then
    create_combinator_gui(player, event.entity)
  end
end

local function on_gui_elem_changed(event)
  if string.find(event.element.name, "entity_info_choose_button") then
    local index = tonumber(string.sub(event.element.name, 27))
    local combinator = event.element.parent.parent.entity_preview.entity
    local signal
    if event.element.elem_value then
      signal = {signal=event.element.elem_value, count=0}
    end
    combinator.get_control_behavior().set_signal(index, signal)
  end
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)