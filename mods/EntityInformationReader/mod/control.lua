require("scripts/gui")
local common = require("scripts/common")
local container = require("scripts/container")

local function get_combinator(chest)
  for _, ent in pairs(chest.circuit_connected_entities.red) do
    if ent.name == "entity-information-reader" then
      return ent
    end
  end
end

local function on_built(event)
  local entity = event.entity or event.created_entity or event.destination
  if not entity or not entity.valid then
    return
  end
  if entity and entity.valid and entity.name == "entity-information-reader" then
    entity.health = 0
    local entities = entity.surface.find_entities_filtered{position=entity.position, name="entity-information-reader", type="construction-robot", invert=true}
    local connected_entity
    if #entities > 0 then
      connected_entity = entities[1]
      local sprite_id = rendering.draw_sprite{sprite="entity/entity-information-reader", target=entity, surface=entity.surface, x_scale=0.4, y_scale=0.4}
      table.insert(global.combinators, {combinator=entity, entity=connected_entity, location=entity.position, sprite=sprite_id})
      entity.get_control_behavior().enabled = true
    else
      entity.get_control_behavior().enabled = false
      global.lonely_combinators[entity.position.x..","..entity.position.y] = entity
      return
    end
  else
    local combinator = global.lonely_combinators[entity.position.x..","..entity.position.y]
    if combinator then
      if combinator.valid then
        local sprite_id = rendering.draw_sprite{sprite="entity/entity-information-reader", target=combinator, surface=entity.surface, x_scale=0.4, y_scale=0.4}
        global.lonely_combinators[entity.position.x..","..entity.position.y] = nil
        table.insert(global.combinators, {combinator=combinator, entity=entity, location=entity.position, sprite=sprite_id})
        combinator.get_control_behavior().enabled = true
      else
        global.lonely_combinators[entity.position.x..","..entity.position.y] = nil
      end
    end
  end

end

local function on_tick()
  if not global.combinators then
    global.combinators = {}
  end
  if not global.lonely_combinators then
    global.lonely_combinators = {}
  end
  for i, tbl in pairs(global.combinators) do
    if tbl.valid == false then
      if tbl.sprite ~= nil then
        rendering.destroy(tbl.sprite)
      end
      global.combinators[i] = nil
    elseif not tbl.combinator or not tbl.combinator.valid then
      if tbl.sprite ~= nil then
        rendering.destroy(tbl.sprite)
      end
      global.combinators[i] = nil
    elseif not tbl.entity or not tbl.entity.valid then
      if tbl.sprite ~= nil then
        rendering.destroy(tbl.sprite)
      end
      global.combinators[i] = nil
      tbl.combinator.get_control_behavior().enabled = false
      global.lonely_combinators[tbl.combinator.position.x..","..tbl.combinator.position.y] = tbl.combinator
    else
      local cb = tbl.combinator.get_control_behavior()
      if cb.enabled then
        local indices = {}
        for k, param in pairs(cb.parameters.parameters) do
          if param.signal.name then
            indices[param.index] = param.signal
          end
        end
        local signals = common.calc_signals(tbl.entity, indices)
        if tbl.entity.type == "container" or tbl.entity.type == "logistic-container" or tbl.entity.type == "infinity-container" then
          for k, v in pairs(container.calc_signals(tbl.entity, indices)) do
            signals[k] = v
          end
        end
        for index, count in pairs(signals) do
          local next_signal
          local cur_signal = cb.get_signal(index)
          next_signal = {signal=cur_signal.signal, count=count}
          cb.set_signal(index, next_signal)
        end
      end
    end
  end
end

script.on_event({defines.events.on_entity_cloned, defines.events.on_robot_built_entity, defines.events.on_built_entity, defines.events.script_raised_built, defines.events.script_raised_revive}, on_built)
script.on_event(defines.events.on_entity_settings_pasted, on_settings_pasted)
script.on_nth_tick(1, on_tick)
