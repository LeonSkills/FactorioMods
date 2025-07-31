local function get_player_visibility()
  local alt_mode_players = {}
  local toggled_players = {}
  if not storage.territory_renderings then return end
  for _, player in pairs(game.players) do
    if settings.get_player_settings(player)["sutr-tie-to-alt-mode"].value then
      table.insert(alt_mode_players, player)
    elseif player.is_shortcut_toggled("sutr-toggle-shortcut") then
      table.insert(toggled_players, player)
    end
  end
  return alt_mode_players, toggled_players
end

local function draw_line(surface, from, to, alt_mode_players, toggled_players)
  local alt_rendering, toggled_rendering
  alt_rendering = rendering.draw_line {
    color            = {r = 1, g = 0, b = 0},
    surface          = surface,
    width            = 10,
    from             = from,
    to               = to,
    draw_on_ground   = true,
    players          = alt_mode_players,
    only_in_alt_mode = true,
    visible          = next(alt_mode_players) ~= nil
  }
  toggled_rendering = rendering.draw_line {
    color            = {r = 1, g = 0, b = 0},
    surface          = surface,
    width            = 10,
    from             = from,
    to               = to,
    draw_on_ground   = true,
    players          = toggled_players,
    only_in_alt_mode = false,
    visible          = next(toggled_players) ~= nil
  }
  return {alt_rendering, toggled_rendering}
end

local function draw_rectangle(surface, chunk, alt_mode_players, toggled_players)
  local alt_rendering, toggled_rendering
  alt_rendering = rendering.draw_rectangle {
    color            = {r = 0.25, g = 0, b = 0, a = 0.1},
    surface          = surface,
    filled           = true,
    left_top         = chunk.area.left_top,
    right_bottom     = chunk.area.right_bottom,
    players          = alt_mode_players,
    draw_on_ground   = true,
    only_in_alt_mode = true,
    visible          = next(alt_mode_players) ~= nil
  }
  toggled_rendering = rendering.draw_rectangle {
    color            = {r = 0.25, g = 0, b = 0, a = 0.1},
    surface          = surface,
    filled           = true,
    left_top         = chunk.area.left_top,
    right_bottom     = chunk.area.right_bottom,
    players          = toggled_players,
    draw_on_ground   = true,
    only_in_alt_mode = false,
    visible          = next(toggled_players) ~= nil
  }
  return {alt_rendering, toggled_rendering}
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

local function draw_territory(territory, alt_mode_players, toggled_players)
  if not storage.territory_renderings then
    storage.territory_renderings = {}
  end
  if not alt_mode_players or not toggled_players then
    alt_mode_players, toggled_players = get_player_visibility()
  end
  remove_territory_renderings(territory)
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
    local rectangles = draw_rectangle(territory.surface, chunk, alt_mode_players, toggled_players)
    for _, rectangle in pairs(rectangles) do
      table.insert(storage.territory_renderings[x][y], rectangle)
    end
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
      local lines = draw_line(territory.surface, {x * 32 - w, y * 32}, {(x + 1) * 32 + w, y * 32}, alt_mode_players, toggled_players)
      for _, line in pairs(lines) do
        table.insert(storage.territory_renderings[x][y], line)
      end
    end
    if not has_east then
      local lines = draw_line(territory.surface, {(x + 1) * 32, y * 32 - w}, {(x + 1) * 32, (y + 1) * 32 + w}, alt_mode_players, toggled_players)
      for _, line in pairs(lines) do
        table.insert(storage.territory_renderings[x][y], line)
      end
    end

    if not has_south then
      local lines = draw_line(territory.surface, {x * 32 - w, (y + 1) * 32}, {(x + 1) * 32 + w, (y + 1) * 32}, alt_mode_players, toggled_players)
      for _, line in pairs(lines) do
        table.insert(storage.territory_renderings[x][y], line)
      end
    end
    if not has_west then
      local lines = draw_line(territory.surface, {x * 32, y * 32 - w}, {x * 32, (y + 1) * 32 + w}, alt_mode_players, toggled_players)
      for _, line in pairs(lines) do
        table.insert(storage.territory_renderings[x][y], line)
      end
    end

  end
end

local function redraw_territories()
  if not storage.territory_renderings then
    storage.territory_renderings = {}
  end
  rendering.clear("segmented-units-territory-renderings")
  local alt_mode_players, toggled_players = get_player_visibility()
  for _, surface in pairs(game.surfaces) do
    for _, territory in pairs(surface.get_territories()) do
      draw_territory(territory, alt_mode_players, toggled_players)
    end
  end
end

local function update_renderings()
  local alt_mode_players, toggled_players = get_player_visibility()
  for _, chunks in pairs(storage.territory_renderings) do
    for _, renderings in pairs(chunks) do
      for _, rendering in pairs(renderings) do
        if rendering.only_in_alt_mode then
          rendering.players = alt_mode_players
          rendering.visible = next(alt_mode_players) ~= nil
        end
        if not rendering.only_in_alt_mode then
          rendering.players = toggled_players
          rendering.visible = next(toggled_players) ~= nil
        end
      end
    end
  end
end

local function on_territory_created(event)
  local alt_mode_players, toggled_players = get_player_visibility()
  local territory = event.territory
  draw_territory(territory, alt_mode_players, toggled_players)
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

local function on_segmented_unit_created(event)
  local alt_mode_players, toggled_players = get_player_visibility()
  if event.segmented_unit and event.segmented_unit.valid then
    draw_territory(event.segmented_unit.territory, alt_mode_players, toggled_players)
  end
end

local function on_segment_died(event)
  local segmented_unit = event.segmented_unit
  if segmented_unit and segmented_unit.valid then
    remove_territory_renderings(segmented_unit.territory)
  end
end

local function on_configuration_changed(handler)
  redraw_territories()
end

local function on_setting_changed(event)
  if event.setting == "sutr-tie-to-alt-mode" then
    redraw_territories()
  end
end

local function toggle_shortcut(event)
  local player = game.players[event.player_index]
  local is_toggled = not player.is_shortcut_toggled("sutr-toggle-shortcut")
  player.set_shortcut_toggled("sutr-toggle-shortcut", is_toggled)
  if is_toggled and settings.get_player_settings(player)["sutr-tie-to-alt-mode"].value then
    local cur_settings = settings.get_player_settings(player)["sutr-tie-to-alt-mode"]
    cur_settings.value = false
    settings.get_player_settings(player)["sutr-tie-to-alt-mode"] = cur_settings
    redraw_territories()
  else
    update_renderings()
  end
end

local function on_lua_shortcut(event)
  if event.prototype_name == "sutr-toggle-shortcut" then
    toggle_shortcut(event)
  end
end

local function on_player_joined_game(event)
  redraw_territories()
end

script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_territory_created, on_territory_created)
script.on_event(defines.events.on_territory_destroyed, on_territory_destroyed)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.script_raised_destroy, on_entity_died)
script.on_event(defines.events.on_segmented_unit_died, on_segment_died)
script.on_event(defines.events.script_raised_destroy_segmented_unit, on_segment_died)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
script.on_event(defines.events.on_segmented_unit_created, on_segmented_unit_created)
script.on_event(defines.events.on_lua_shortcut, on_lua_shortcut)
script.on_event("sutr-toggle-territories", toggle_shortcut)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
