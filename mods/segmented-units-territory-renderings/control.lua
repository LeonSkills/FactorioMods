local function draw_line(surface, from, to)
  local only_in_alt_mode = not settings.global["sutr-always-on"].value
  return rendering.draw_line {
    color            = {r = 1, g = 0, b = 0},
    surface          = surface,
    width            = 10,
    from             = from,
    to               = to,
    draw_on_ground   = true,
    only_in_alt_mode = only_in_alt_mode
  }
end

local function draw_rectangle(surface, chunk)
  local only_in_alt_mode = not settings.global["sutr-always-on"].value
  return rendering.draw_rectangle {
    color            = {r = 0.25, g = 0, b = 0, a = 0.1},
    surface          = surface,
    filled           = true,
    left_top         = chunk.area.left_top,
    right_bottom     = chunk.area.right_bottom,
    draw_on_ground   = true,
    only_in_alt_mode = only_in_alt_mode
  }
end

local function draw_territory(territory)
  if not storage.territory_renderings then
    storage.territory_renderings = {}
  end
  if not territory or not territory.valid then return end
  if next(territory.get_segmented_units()) == nil then return end
  local chunk_positions = {}
  local chunks = territory.get_chunks()
  for _, chunk in pairs(chunks) do
    local x = chunk.x
    local y = chunk.y
    if not storage.territory_renderings[x] then
      storage.territory_renderings[x] = {}
    end
    if not storage.territory_renderings[x][y] then
      storage.territory_renderings[x][y] = {}
    end
    if not chunk_positions[x] then
      chunk_positions[x] = {}
    end
    chunk_positions[x][y] = true
    local rectangle = draw_rectangle(territory.surface, chunk)
    table.insert(storage.territory_renderings[x][y], rectangle)
  end
  for _, chunk in pairs(chunks) do
    local x = chunk.x
    local y = chunk.y
    local has_north = chunk_positions[x] and chunk_positions[x][y - 1]
    local has_east = chunk_positions[x + 1] and chunk_positions[x + 1][y]
    local has_south = chunk_positions[x] and chunk_positions[x][y + 1]
    local has_west = chunk_positions[x - 1] and chunk_positions[x - 1][y]
    local w = 0.15
    if not has_north then
      local line = draw_line(territory.surface, {x * 32 - w, y * 32}, {(x + 1) * 32 + w, y * 32})
      table.insert(storage.territory_renderings[x][y], line)
    end
    if not has_east then
      local line = draw_line(territory.surface, {(x + 1) * 32, y * 32 - w}, {(x + 1) * 32, (y + 1) * 32 + w})
      table.insert(storage.territory_renderings[x][y], line)
    end

    if not has_south then
      local line = draw_line(territory.surface, {x * 32 - w, (y + 1) * 32}, {(x + 1) * 32 + w, (y + 1) * 32})
      table.insert(storage.territory_renderings[x][y], line)
    end
    if not has_west then
      local line = draw_line(territory.surface, {x * 32, y * 32 - w}, {x * 32, (y + 1) * 32 + w})
      table.insert(storage.territory_renderings[x][y], line)
    end

  end
end

local function remove_territory_renderings(territory)
  if not storage.territory_renderings then
    storage.territory_renderings = {}
  end
  if not territory or not territory.valid then return end
  for _, chunk in pairs(territory.get_chunks()) do
    local x = chunk.x
    local y = chunk.y
    if storage.territory_renderings[x] then
      if storage.territory_renderings[x][y] then
        for _, render_object in pairs(storage.territory_renderings[x][y]) do
          if render_object.valid then
            render_object.destroy()
          end
        end
      end
      storage.territory_renderings[x][y] = nil
      if next(storage.territory_renderings[x]) == nil then
        storage.territory_renderings[x] = nil
      end
    end
  end
end

local function on_territory_created(event)
  local territory = event.territory
  draw_territory(territory)
end

local function on_territory_destroyed(event)
  local territory = event.territory
  remove_territory_renderings(territory)
end

local function on_entity_died(event)
  local entity = event.entity
  if entity and entity.valid and entity.type == "segment" and entity.segmented_unit then
    remove_territory_renderings(entity.segmented_unit.territory)
  end
end

local function on_segment_died(event)
  local segmented_unit = event.segmented_unit
  if segmented_unit and segmented_unit.valid then
    remove_territory_renderings(segmented_unit.territory)
  end
end

local function redraw_territories()
  for _, surface in pairs(game.surfaces) do
    for _, territory in pairs(surface.get_territories()) do
      remove_territory_renderings(territory)
      draw_territory(territory)
    end
  end
end

local function on_configuration_changed(handler)
  if not storage.territory_renderings then
    storage.territory_renderings = {}
  end
  redraw_territories()
end

local function on_setting_changed(event)
  if event.setting == "sutr-always-on" then
    redraw_territories()
  end
end

script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_territory_created, on_territory_created)
script.on_event(defines.events.on_territory_destroyed, on_territory_destroyed)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.script_raised_destroy, on_entity_died)
script.on_event(defines.events.on_segmented_unit_died, on_segment_died)
script.on_event(defines.events.script_raised_destroy_segmented_unit, on_segment_died)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
