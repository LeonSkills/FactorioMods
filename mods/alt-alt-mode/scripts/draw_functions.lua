local util = require("__alt-alt-mode__/scripts/util.lua")

local function remove_all_sprites(player)
  if storage[player.index] then
    for _, sprite in pairs(storage[player.index]) do
      if sprite.valid then
        sprite.destroy()
      end
    end
    storage[player.index] = nil
  end
end

local function remove_radius_indicator(player)
  if not storage.change_radius_events then
    storage.change_radius_events = {}
  elseif storage.change_radius_events[player.index] then
    local old_render = rendering.get_object_by_id(storage.change_radius_events[player.index])
    if old_render then
      old_render.destroy()
    end
  end
end

local function draw_radius_indicator(player, position, radius, time_to_live)
  if not position and storage.last_known_position then
    position = storage.last_known_position[player.index]
  end
  if not position then return end
  if not radius then
    radius = settings.get_player_settings(player)["alt-alt-radius"].value
  end
  if not time_to_live then
    time_to_live = settings.global["alt-alt-update-interval"].value + 30
  end

  local render = rendering.draw_circle {
    radius       = math.max(radius, 0.2),
    color        = {0, 0.05, 0.05, 0.05},
    filled       = true,
    target       = position,
    surface      = player.surface,
    players      = {player},
    time_to_live = time_to_live,
    render_layer = "wires-above",
  }
  remove_radius_indicator(player)

  storage.change_radius_events[player.index] = render.id
end

local function determine_offset(index, num_columns, num_rows, scale)
  local x = (index - 1) % num_columns
  local y = math.floor((index - 1) / num_columns)
  if y >= num_rows then return end
  local pos_x = (x - (num_columns - 1) / 2) * scale
  local pos_y = (y - (num_rows - 1) / 2) * scale
  return {x = pos_x, y = pos_y}
end

local function get_target(entity, center, offset, use_direction)
  offset = {
    x = center.x + offset.x,
    y = center.y + offset.y
  }
  if use_direction then
    util.rotate_around_point(offset, {x = 0, y = 0}, entity.direction / 16)
  end
  return {
    entity = entity,
    offset = offset
  }
end

local function determine_sprite_position(entity, center, index, num_columns, num_rows, scale, use_orientation)
  if num_columns <= 0 or num_rows <= 0 or scale == nil then return end
  local x = (index - 1) % num_columns
  local y = math.floor((index - 1) / num_columns)
  if y >= num_rows then return end
  local pos_x = ((num_columns - 1) / 2 - x) * scale
  local pos_y = ((num_rows - 1) / 2 - y) * scale
  local target = {x = pos_x, y = pos_y}
  if use_orientation and entity.orientation ~= 0 then
    util.rotate_around_point(target, {x = 0, y = 0}, entity.orientation)
  end
  target = {
    entity = entity,
    offset = {
      x = center.x - entity.position.x - target.x,
      y = center.y - entity.position.y - target.y
    }
  }
  return target
end

local function draw_background(player, entity, target, scale, tint)
  if not tint then
    tint = {0, 0, 0}
  end
  local bg_sprite = rendering.draw_sprite {
    sprite       = 'alt-alt-entity-info-white-background',
    players      = {player},
    target       = target,
    surface      = entity.surface,
    x_scale      = scale,
    y_scale      = scale,
    tint         = tint,
    time_to_live = settings.global["alt-alt-update-interval"].value + 30,
    render_layer = "fluid-visualization",
  }
  table.insert(storage[player.index], bg_sprite)
end

local function draw_request_background(player, entity, target, scale)
  scale = scale or 1
  local bg_sprite = rendering.draw_sprite {
    sprite       = 'alt-alt-item-request-symbol',
    players      = {player},
    target       = target,
    surface      = entity.surface,
    x_scale      = scale,
    y_scale      = scale,
    tint         = tint,
    time_to_live = settings.global["alt-alt-update-interval"].value + 30,
    render_layer = "fluid-visualization",
  }
  table.insert(storage[player.index], bg_sprite)
end

local function draw_text_sprite(
        player, entity, text, target, scale, color, background_scale, background_tint, alignment, vertical_alignment
)
  if not scale then
    scale = 1
  end
  if not color then
    color = {1, 1, 1}
  end
  if not alignment then
    alignment = "center"
  end
  if not vertical_alignment then
    vertical_alignment = "middle"
  end
  if background_scale then
    draw_background(player, entity, target, background_scale * 0.45, background_tint)
  end
  local text_sprite = rendering.draw_text {
    text               = text,
    players            = {player},
    target             = target,
    surface            = entity.surface,
    scale              = scale,
    color              = color,
    alignment          = alignment,
    vertical_alignment = vertical_alignment,
    time_to_live       = settings.global["alt-alt-update-interval"].value + 30,
    render_layer       = "wires-above",
  }
  table.insert(storage[player.index], text_sprite)
end

local function draw_sub_text(player, entity, text, target, text_scale, x_offset, y_offset, alignment, vertical_alignment)
  if not text then return end
  local target_text = {entity = entity, offset = {x = target.offset.x + x_offset, y = target.offset.y + y_offset}}
  local text_sprite = rendering.draw_text {
    text               = text,
    players            = {player},
    target             = target_text,
    surface            = entity.surface,
    scale              = text_scale,
    color              = {1, 1, 1},
    alignment          = alignment or "center",
    vertical_alignment = vertical_alignment or "middle",
    time_to_live       = settings.global["alt-alt-update-interval"].value + 30,
    render_layer       = "wires-above"
  }
  table.insert(storage[player.index], text_sprite)
end

local function draw_sprite(player, entity, main_sprite, target, scale, text, quality_prototype, background_type)
  if not target then return end
  if not scale then return end
  local tint = {0, 0, 0}
  if quality_prototype and settings.get_player_settings(player)["alt-alt-show-quality-background"].value then
    if quality_prototype.name ~= "normal" and quality_prototype.color then
      tint = quality_prototype.color
    end
  end
  local show_badge = settings.get_player_settings(player)["alt-alt-show-quality-badge"].value
  if not background_type or background_type == "normal" then
    draw_background(player, entity, target, scale, tint)
  elseif background_type == "proxy" then
    draw_request_background(player, entity, target, scale * 2)
    show_badge = true
  end
  if main_sprite then
    local sprite_main = rendering.draw_sprite {
      sprite       = main_sprite,
      players      = {player},
      target       = target,
      surface      = entity.surface,
      x_scale      = scale,
      y_scale      = scale,
      time_to_live = settings.global["alt-alt-update-interval"].value + 30,
      render_layer = "wires-above",
    }
    table.insert(storage[player.index], sprite_main)
  end
  if text then
    local text_scale = text.scale or scale
    draw_sub_text(player, entity, text.right_bottom, target, text_scale, scale * 0.5, scale * 0.33, "right", "middle")
    draw_sub_text(player, entity, text.left_bottom, target, text_scale, -scale * 0.5, scale * 0.33, "left", "middle")
    draw_sub_text(player, entity, text.right_top, target, text_scale, scale * 0.5, -scale * 0.33, "right", "middle")
    draw_sub_text(player, entity, text.left_top, target, text_scale, -scale * 0.5, -scale * 0.33, "left", "middle")
  end
  if quality_prototype and quality_prototype.draw_sprite_by_default and show_badge then
    local sprite
    if quality_prototype.name then
      sprite = "quality." .. quality_prototype.name
    else
      sprite = "virtual-signal.signal-any-quality"
    end
    local target_quality = {entity = entity, offset = {x = target.offset.x - scale * 0.25, y = target.offset.y + scale * 0.25}}
    local quality_sprite = rendering.draw_sprite {
      sprite       = sprite,
      players      = {player},
      target       = target_quality,
      surface      = entity.surface,
      x_scale      = scale / 2,
      y_scale      = scale / 2,
      time_to_live = settings.global["alt-alt-update-interval"].value + 30,
      render_layer = "wires-above"
    }
    table.insert(storage[player.index], quality_sprite)
  end
end

local function draw_signal_wire_colour_indicator(player, entity, target, scale, colour)
  local sprite_target = {entity = entity, offset = {x = target.offset.x - scale / 3, y = target.offset.y - scale / 3}}
  local sprite = rendering.draw_circle {
    radius       = 0.1 * scale,
    filled       = true,
    players      = {player},
    target       = sprite_target,
    surface      = entity.surface,
    color        = colour,
    time_to_live = settings.global["alt-alt-update-interval"].value + 30,
    render_layer = "wires-above"
  }
  table.insert(storage[player.index], sprite)
end

local function draw_signal_id_sprite(player, entity, signal, target, scale, text, on_red, on_green)
  if not target then return end
  local quality
  if signal.quality then
    quality = prototypes.quality[signal.quality]
  end
  local signal_type = signal.type or "item"
  if signal_type == "virtual" then
    signal_type = "virtual-signal"
  end
  local signal_sprite = signal_type .. "." .. signal.name
  draw_sprite(player, entity, signal_sprite, target, scale, text, quality, false)
  if on_red and not on_green then
    draw_signal_wire_colour_indicator(player, entity, target, scale, {1, 0, 0})
  end
  if on_green and not on_red then
    draw_signal_wire_colour_indicator(player, entity, target, scale, {0, 1, 0})
  end
end

local function draw_signal_constant(player, entity, constant, target)
  constant = constant or 0
  local text = util.localise_number(constant)
  local scale = 2 / math.max(2, util.number_length(constant))
  draw_text_sprite(player, entity, text, target, scale, nil, 0.8)
end

local function draw_module_like(player, entity, sprites, scale, y_ratio, use_direction)
  -- y_ratio is the ratio of which the height of the entity where the modules are drawn
  -- For crafting machines and turrets this is 2/5
  -- Beacons get the whole width
  -- Modules we only draw on the bottom third of the entity
  if not y_ratio then
    y_ratio = 1
  end
  local name = entity.name
  if name == "entity-ghost" then
    name = entity.ghost_name
  end
  local entity_box = prototypes.entity[name].selection_box
  local box = {
    left_top     = {
      x = entity_box.left_top.x,
      y = entity_box.right_bottom.y - math.max(1, (entity_box.right_bottom.y - entity_box.left_top.y) * y_ratio)
    },
    right_bottom = entity_box.right_bottom
  }
  -- rendering.draw_rectangle{surface=entity.surface, color={1,1,1}, width=1, left_top=box.left_top, right_bottom=box.right_bottom, time_to_live=500}
  local width = box.right_bottom.x - box.left_top.x
  local height = box.right_bottom.y - box.left_top.y
  local center = util.box_center(box)
  local max_items_per_row = math.floor(width / scale)
  local max_items_per_column = math.floor(height / scale)
  local max_items = max_items_per_row * max_items_per_column
  local num_items = math.min(#sprites, max_items)
  local num_rows = math.ceil(num_items / max_items_per_row)
  local num_columns = num_items / num_rows
  for index = 1, num_items do
    local sprite = sprites[index]
    local offset = determine_offset(sprite.index or index, num_columns, num_rows, scale)
    local target = get_target(entity, center, offset, use_direction)
    draw_sprite(player, entity, sprite.sprite, target, scale, {}, sprite.quality, sprite.background_type)
    if sprite.count and sprite.count > 1 then
      local text = util.localise_number(sprite.count)
      draw_sub_text(player, entity, text, target, scale, scale * 0.5, scale * 0.33, "right", "middle")
    end
  end
end

return {
  draw_radius_indicator     = draw_radius_indicator,
  remove_radius_indicator   = remove_radius_indicator,
  remove_all_sprites        = remove_all_sprites,
  draw_sprite               = draw_sprite,
  draw_text_sprite          = draw_text_sprite,
  determine_sprite_position = determine_sprite_position,
  draw_signal_id_sprite     = draw_signal_id_sprite,
  draw_signal_constant      = draw_signal_constant,
  draw_module_like          = draw_module_like,
  draw_request_background   = draw_request_background
}