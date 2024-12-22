local util = require("__AlternativeAltMode__/scripts/util.lua")
local constants = require("__AlternativeAltMode__/scripts/constants")

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
    util.rotate_around_point(offset, {x=0, y=0}, entity.direction/16)
  end
  return {
    entity = entity,
    offset = offset
  }
end

local function determine_sprite_position(entity, center, index, num_columns, num_rows, scale, use_orientation)
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

local function draw_text_sprite(
        player, entity, text, target, scale, color, draw_background, background_tint, alignment, vertical_alignment
)
  if not scale then
    scale = 1
  end
  if not color then
    color = {1, 1, 1}
  end
  if not background_tint then
    background_tint = {0, 0, 0}
  end
  if not alignment then
    alignment = "center"
  end
  if not vertical_alignment then
    vertical_alignment = "middle"
  end
  if draw_background then
    local bg_sprite = rendering.draw_sprite {
      sprite       = 'alt-alt-entity-info-white-background',
      players      = {player},
      target       = target,
      surface      = entity.surface,
      x_scale      = scale * 0.75,
      y_scale      = scale * 0.75,
      tint         = background_tint,
      time_to_live = constants.time_to_live
    }
    table.insert(storage[player.index], bg_sprite)
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
    time_to_live       = constants.time_to_live
  }
  table.insert(storage[player.index], text_sprite)
end

local function draw_sprite(player, entity, main_sprite, target, scale, text, quality, do_not_draw_background)
  if not target then return end
  local tint = {0, 0, 0}
  if quality then
    if quality.name ~= "normal" and quality.color then
      tint = quality.color
    end
  end
  if not do_not_draw_background then
    local bg_sprite = rendering.draw_sprite {sprite = 'alt-alt-entity-info-white-background', players = {player}, target = target, surface = entity.surface, x_scale = scale, y_scale = scale, tint = tint, time_to_live = constants.time_to_live}
    table.insert(storage[player.index], bg_sprite)
  end
  if main_sprite then
    local sprite_main = rendering.draw_sprite {sprite = main_sprite, players = {player}, target = target, surface = entity.surface, x_scale = scale, y_scale = scale, time_to_live = constants.time_to_live}
    table.insert(storage[player.index], sprite_main)
  end
  if text then
    local text_scale = text.scale or scale
    if text.right_bottom then
      local target_text = {entity = entity, offset = {x = target.offset.x + scale * 0.5, y = target.offset.y + scale * 0.25}}
      local text_sprite = rendering.draw_text {text = text.right_bottom, players = {player}, target = target_text, surface = entity.surface, scale = text_scale, color = {1, 1, 1}, alignment = "right", vertical_alignment = "middle", time_to_live = constants.time_to_live}
      table.insert(storage[player.index], text_sprite)
    end
    if text.left_bottom then
      local target_text = {entity = entity, offset = {x = target.offset.x - scale * 0.8, y = target.offset.y + scale * 0.33}}
      local text_sprite = rendering.draw_text {text = text.left_bottom, players = {player}, target = target_text, surface = entity.surface, scale = text_scale * 1.25, color = {1, 1, 1}, alignment = "left", vertical_alignment = "middle", time_to_live = constants.time_to_live}
      table.insert(storage[player.index], text_sprite)
    end
    if text.right_top then
      local target_text = {entity = entity, offset = {x = target.offset.x + scale * 0.5, y = target.offset.y - scale * 0.25}}
      local text_sprite = rendering.draw_text {text = text.right_top, players = {player}, target = target_text, surface = entity.surface, scale = text_scale, color = {1, 1, 1}, alignment = "right", vertical_alignment = "middle", time_to_live = constants.time_to_live}
      table.insert(storage[player.index], text_sprite)
    end
    if text.left_top then
      local target_text = {entity = entity, offset = {x = target.offset.x - scale * 0.5, y = target.offset.y - scale * 0.25}}
      local text_sprite = rendering.draw_text {text = text.right_top, players = {player}, target = target_text, surface = entity.surface, scale = text_scale, color = {1, 1, 1}, alignment = "right", vertical_alignment = "middle", time_to_live = constants.time_to_live}
      table.insert(storage[player.index], text_sprite)
    end
  end
  if quality and quality.draw_sprite_by_default then
    local sprite
    if quality.name then
      sprite = "quality." .. quality.name
    else
      sprite = "virtual-signal.signal-any-quality"
    end
    local target_quality = {entity = entity, offset = {x = target.offset.x - scale * 0.25, y = target.offset.y + scale * 0.25}}
    local quality_sprite = rendering.draw_sprite {sprite = sprite, players = {player}, target = target_quality, surface = entity.surface, x_scale = scale / 2, y_scale = scale / 2, time_to_live = constants.time_to_live}
    table.insert(storage[player.index], quality_sprite)
  end
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
    local red_target = {entity = entity, offset = {x = target.offset.x - scale / 3, y = target.offset.y - scale / 3}}
    local red_sprite = rendering.draw_circle {radius = 0.1 * scale, filled = true, players = {player}, target = red_target, surface = entity.surface, color = {1, 0, 0}, time_to_live = constants.time_to_live}
    table.insert(storage[player.index], red_sprite)
  end
  if on_green and not on_red then
    local green_target = {entity = entity, offset = {x = target.offset.x - scale / 3, y = target.offset.y - scale / 3}}
    local green_sprite = rendering.draw_circle {radius = 0.1 * scale, filled = true, players = {player}, target = green_target, surface = entity.surface, color = {0, 1, 0}, time_to_live = constants.time_to_live}
    table.insert(storage[player.index], green_sprite)
  end
end

local function draw_signal_constant(player, entity, constant, target)
  constant = constant or 0
  local scale = 2 / math.max(2, util.number_length(constant))
  local bg_sprite = rendering.draw_sprite {sprite = 'alt-alt-entity-info-white-background', players = {player}, target = target, surface = entity.surface, x_scale = 0.43, y_scale = 0.45, tint = {0, 0, 0}, time_to_live = constants.time_to_live}
  table.insert(storage[player.index], bg_sprite)
  local text_sprite = rendering.draw_text {text = util.localise_number(constant), players = {player}, target = target, surface = entity.surface, scale = scale, color = {1, 1, 1}, alignment = "center", vertical_alignment = "middle", time_to_live = constants.time_to_live}
  table.insert(storage[player.index], text_sprite)
end

local function draw_module_like(player, entity, sprites, scale, y_ratio, use_direction)
  -- y_ratio is the ratio of which the height of the entity where the modules are drawn
  -- For crafting machines and turrets this is 2/5
  -- Beacons get the whole width
  if not y_ratio then
    y_ratio = 1
  end
  -- Modules we only draw on the bottom third of the entity
  local entity_box = prototypes.entity[entity.name].selection_box
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
    draw_sprite(player, entity, sprite.sprite, target, scale, {}, sprite.quality)
  end
end

return {
  draw_sprite               = draw_sprite,
  draw_text_sprite          = draw_text_sprite,
  determine_sprite_position = determine_sprite_position,
  draw_signal_id_sprite     = draw_signal_id_sprite,
  draw_signal_constant      = draw_signal_constant,
  draw_module_like          = draw_module_like,
}