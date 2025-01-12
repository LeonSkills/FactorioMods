function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

local function initialize(player)
  if not storage.mouse_position_data then
    storage.mouse_position_data = {}
  end
  if not storage.mouse_position_data[player.index] then
    storage.mouse_position_data[player.index] = {
      entities     = {},
      is_searching = false
    }
  end
end

local function set_entity(player, entity)
  table.insert(storage.mouse_position_data[player.index].entities, entity)
end

local function clear_entities(player)
  if not storage.mouse_position_data or not storage.mouse_position_data[player.index] then return end
  for _, entity in pairs(storage.mouse_position_data[player.index].entities or {}) do
    if entity and entity.valid then
      entity.destroy {raise_destroy = false}
    end
  end
  storage.mouse_position_data[player.index].entities = {entity_to_ignore}
end

local function is_searching(player)
  if not storage.mouse_position_data or not storage.mouse_position_data[player.index] then return false end
  return storage.mouse_position_data[player.index].is_searching
end

local function set_searching(player, value)
  initialize(player)
  storage.mouse_position_data[player.index].is_searching = value
end

local function reset_data(player)
  if not storage.mouse_position_data or not storage.mouse_position_data[player.index] then return end
  clear_entities(player)
  set_searching(player, false)
end

local function subdivide(player, position, size)
  initialize(player)
  local pow_size = math.pow(3, size)
  for _, x in pairs({-pow_size, 0, pow_size}) do
    for _, y in pairs({-pow_size, 0, pow_size}) do
      -- util.log("Create entity at ", x, y, "with size", size)
      local entity = player.surface.create_entity {
        name                = "alt-alt-invisible-selectable-" .. size,
        position            = {position.x + x, position.y + y},
        force               = "neutral",
        player              = player,
        raise_built         = false,
        render_player_index = player.index
      }
      entity.destructible = false
      set_entity(player, entity)
    end
  end
end

local function start_search(player)
  if is_searching(player) then return end
  initialize(player)
  set_searching(player, true)
  subdivide(player, player.position, 4)
end

local function find_mouse(player)
  local selected = player.selected
  if not selected then
    return false
  end -- check if it's our object, if so continue subdividing
  if string.starts(selected.name, "alt-alt-invisible-selectable-") then
    local size = tonumber(string.sub(selected.name, -1))
    if size == 0 then
      local position = selected.position
      reset_data(player)
      player.selected = nil
      return position
    end
    subdivide(player, selected.position, size - 1)
    player.selected = nil
    return false
  else
    -- some other entity is found
    -- reset the data and return that entity
    reset_data(player)
    return selected.position
  end
end

return {
  find_mouse   = find_mouse,
  start_search = start_search,
  reset_data   = reset_data,
}