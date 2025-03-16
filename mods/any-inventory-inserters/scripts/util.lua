local util = {}
util.get_entity_id = function(entity, position, direction)
  if direction == nil then
    direction = entity.direction
  end
  if position == nil then
    position = entity.position
  end
  return entity.surface.name .. "|" .. position.x .. "|" .. position.y .. "|" .. direction
end

util.get_entity_type = function(entity)
  if entity.type == "entity-ghost" then
    return entity.ghost_type
  end
  return entity.type
end

util.get_event_name = function(id)
  for k, v in pairs(defines.events) do
    if v == id then
      return k
    end
  end
end

return util