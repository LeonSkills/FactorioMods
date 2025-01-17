local util = require("__alt-alt-mode__/scripts/util.lua")
local draw_functions = require("__alt-alt-mode__/scripts/draw_functions")
local constants = require("__alt-alt-mode__/scripts/constants")
local circuit_network = require("__alt-alt-mode__/scripts/circuit_network")
local icon_draw_specification = require("__alt-alt-mode__/scripts/icon_draw_specification")
local icons_positioning = require("__alt-alt-mode__/scripts/icons_positioning")

local function get_draw_specification(entity)
  -- see https://forums.factorio.com/viewtopic.php?f=28&t=125562&p=658621
  local spec = icon_draw_specification[entity.name] or icon_draw_specification[entity.type]
  if not spec then
    local dimension = math.min(
            entity.selection_box.right_bottom.x - entity.selection_box.left_top.x,
            entity.selection_box.right_bottom.y - entity.selection_box.left_top.y
    )
    if dimension <= 1.5 then
      spec = {scale = dimension / 3}
    elseif dimension <= 2.5 then
      spec = icon_draw_specification["furnace"]
    elseif dimension <= 3.5 then
      spec = icon_draw_specification["assembling-machine"]
    elseif dimension <= 4.5 then
      spec = icon_draw_specification["electromagnetic-plant"]
    elseif dimension <= 5.5 then
      spec = icon_draw_specification["cryogenic-plant"]
    else
      spec = {scale = dimension / 3}
    end
  end
  spec = spec or {}
  local scale = spec.scale or 1
  local shift = spec.shift or {0, 0}
  local render_layer = spec.render_layer or "entity-info-icon"
  local scale_for_many = spec.scale_for_many or 1
  if render_layer == "entity-info-icon-below" then
    render_layer = "entity-info-icon"
  end
  return shift, scale, scale_for_many, render_layer
end

local function get_icons_positioning(entity, inventory_index)
  local spec = {}
  if icons_positioning[entity.name] then
    spec = icons_positioning[entity.name][inventory_index] or {}
  end
  local box = entity.prototype.selection_box
  local width = box.right_bottom.x - box.left_top.x
  local max_icons_per_row = spec.max_icons_per_row or math.floor(width / 0.75)
  local max_icon_rows = spec.max_icon_rows or math.ceil(width / 1.5)
  local scale = spec.scale or 0.5
  local shift = spec.shift or {0, 0.7}
  local separation_multiplier = spec.separation_multiplier or 1.1
  local multi_row_initial_height_modifier = spec.multi_row_initial_height_modifier or -0.1
  return max_icons_per_row, max_icon_rows, shift, scale, separation_multiplier, multi_row_initial_height_modifier
end

local function get_icons_positioning_chest_like(entity, num_items)
  local shift, draw_scale, scale_for_many, render_layer = get_draw_specification(entity)
  local max_icons_per_row = 2
  local max_icon_rows = 2

  local scale = draw_scale * 0.9
  local num_columns = 1
  local num_rows = 1
  local separation_multiplier = 0
  if num_items > 1 then
    local icon_shift = {0, -1}
    local icon_scale = 0.5
    separation_multiplier = 1.1
    local multi_row_initial_height_modifier = 1
    scale = icon_scale * scale_for_many * 0.9
    num_columns = math.min(num_items, max_icons_per_row)
    num_rows = math.min(math.ceil(num_items / num_columns), max_icon_rows)
    shift = {shift[1] + icon_shift[1], shift[2] + icon_shift[2] + multi_row_initial_height_modifier}
  end
  return shift, scale, num_columns, num_rows, separation_multiplier, render_layer
end

local function get_box_parameters(box, num_items, max_scale)
  max_scale = max_scale or constants.max_scale
  if num_items == 0 then return end
  local width = math.ceil(box.right_bottom.x - box.left_top.x)
  local height = math.ceil(box.right_bottom.y - box.left_top.y)
  if width <= 0 or height <= 0 then return end
  width = math.min(width, constants.max_size)
  height = math.min(height, constants.max_size)
  local items_per_row, items_per_column, scale = util.fill_grid_with_largest_square(width, height, num_items)
  if not scale then return end
  items_per_row = math.min(items_per_row, num_items)
  if scale < constants.min_scale then
    scale = constants.min_scale
    items_per_row = math.floor(width / scale)
    items_per_column = math.floor(height / scale)
  elseif scale > max_scale then
    scale = max_scale
  end
  scale = scale * 0.8
  return items_per_row, items_per_column, scale
end

local function get_proxy_sprites(entity, item_requests)
  if entity.type == "entity-ghost" then
    item_requests = {entity}
  end
  if not item_requests then return {} end
  local sprites = {}
  for _, proxy in pairs(item_requests or {}) do
    if proxy and proxy.valid then
      for _, item in pairs(proxy.item_requests) do
        if item and item.count > 0 then
          table.insert(sprites, {
            sprite          = "item." .. item.name,
            quality         = prototypes.quality[item.quality],
            count           = item.count,
            background_type = "proxy"
          })
        end
      end
    end
  end
  return sprites
end


local function get_module_like_inventory_sprites(inventory, text_if_1)
  local sprites = {}
  for index = 1, #inventory do
    local icon_info = inventory[index]
    if icon_info and icon_info.valid and icon_info.count > 0 then
      local sprite_info = {}
      sprite_info.sprite = "item." .. icon_info.name
      sprite_info.quality_prototype = icon_info.quality
      if icon_info.count > 1 or text_if_1 then
        sprite_info.text = {right_bottom = util.localise_number(icon_info.count)}
      end
      sprites[index] = sprite_info
    end
  end
  return sprites
end

local function draw_chest_like(player, entity, sprites)
  local num_items = #sprites
  if num_items == 0 then return end
  local shift, scale, num_columns, num_rows, separation_multiplier, render_layer = get_icons_positioning_chest_like(entity, num_items)
  for index, sprite_info in pairs(sprites) do
    local offset = util.get_target_offset(index, shift, scale, scale, num_columns, num_rows, separation_multiplier, true)
    if offset then
      local target = {entity = entity, offset = offset}
      draw_functions.draw_sprite(player, entity, sprite_info, target, scale, render_layer)
    end
  end
end

local function draw_module_like(player, entity, sprites, num_slots, inventory_define)
  local num_items = num_slots or #sprites
  if num_items == 0 then return end
  local max_icons_per_row, max_icon_rows, shift, scale, separation_multiplier, multi_row_initial_height_modifier = get_icons_positioning(entity, inventory_define)
  local num_columns = math.min(num_items, max_icons_per_row)
  local num_rows = math.min(math.ceil(num_items / num_columns), max_icon_rows)
  if num_rows > 1 then
    shift = {shift[1], shift[2] + multi_row_initial_height_modifier}
  end
  for index, sprite_info in pairs(sprites) do
    local offset = util.get_target_offset(index, shift, scale, scale / 0.9, num_columns, num_rows, separation_multiplier)
    local target = {entity = entity, offset = offset}
    draw_functions.draw_sprite(player, entity, sprite_info, target, scale)
  end
end

local function draw_inventory_contents(player, entity, contents, item_requests, use_orientation)
  local proxy_sprites = get_proxy_sprites(entity, item_requests)
  if #contents == 0 then return end
  local sprites = {}
  for i = 1, math.min(4, #contents) do
    local item = contents[i]
    local sprite_info = {}
    sprite_info.sprite = "item." .. item.name
    sprite_info.text = {right_bottom = util.localise_number(item.count)}
    sprite_info.quality_prototype = prototypes.quality[item.quality]
    sprites[i] = sprite_info
  end
  draw_chest_like(player, entity, sprites, use_orientation)
end

local function draw_modules(player, entity, item_requests, inventory_define)
  local inventory = entity.get_module_inventory() or {}
  local sprites = get_module_like_inventory_sprites(inventory, false)
  draw_module_like(player, entity, sprites, #inventory, inventory_define)
end

local function draw_beacon_info(player, entity, item_requests)
  draw_modules(player, entity, item_requests, defines.inventory.beacon_modules)
end

local function draw_lab_info(player, entity, item_requests)
  draw_modules(player, entity, item_requests, defines.inventory.lab_modules)
  local inventory = entity.get_inventory(defines.inventory.lab_input)
  local sprites = get_module_like_inventory_sprites(inventory, true)
  draw_module_like(player, entity, sprites, #inventory, defines.inventory.lab_input)
end

local function draw_cargo_wagon_info(player, entity, item_requests)
  local inventory = entity.get_inventory(defines.inventory.cargo_wagon)
  if not inventory or not inventory.valid then
    return
  end
  local contents = inventory.get_contents()
  util.sort_inventory(contents)
  local scale = #contents > 1 and 1.12 or 1.35
  local num_columns = 1
  local num_rows = math.min(4, #contents)
  local separation_multiplier = 1.12
  local selection_center = util.box_center(entity.selection_box)
  local bounding_box_center = util.box_center(entity.bounding_box)
  bounding_box_center.y = bounding_box_center.y - entity.draw_data.height
  for index = 1, math.min(4, #contents) do
    local item = contents[index]
    local sprite_info = {}
    sprite_info.sprite = "item." .. item.name
    sprite_info.text = {right_bottom = util.localise_number(item.count)}
    sprite_info.quality_prototype = prototypes.quality[item.quality]

    local offset = util.get_target_offset(index, {0, 0}, scale, scale, num_columns, num_rows, separation_multiplier, true)
    local theta = entity.draw_data.orientation
    if entity.draw_data.slope ~= 0 then
      if entity.orientation == 0.25 then
        theta = -entity.draw_data.slope
      elseif entity.orientation == 0.75 then
        theta = entity.draw_data.slope
      elseif entity.orientation == 0 then
        offset.y = offset.y + math.sin(entity.draw_data.slope)
      elseif entity.orientation == 0.5 then
        offset.y = offset.y + math.sin(entity.draw_data.slope)
      end
    end
    util.rotate_around_point(offset, {x = 0, y = 0.0}, theta)
    offset.y = offset.y - bounding_box_center.y + selection_center.y
    offset.x = offset.x - bounding_box_center.x + selection_center.x
    local target = {entity = entity, offset = offset}
    draw_functions.draw_sprite(player, entity, sprite_info, target, scale)
  end
end

local function draw_fluid_wagon_contents(player, entity)
  if entity.type == "entity-ghost" then
    return
  end
  -- cargo wagon does not have a fluid box
  local fluid = entity.get_fluid(1)
  if not fluid then return
  end
  local items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, 1)
  if not scale then
    return
  end

  local center = util.box_center(entity.selection_box)
  local prototype = prototypes.fluid[fluid.name]
  local sprite = "fluid." .. fluid.name
  local text = {right_bottom = util.localise_number(fluid.amount)}
  text.scale = 0.6
  if fluid.temperature ~= prototype.default_temperature then
    text.right_top = {"", util.localise_number(fluid.temperature), {"si-unit-degree-celsius"}}
  end
  local target = draw_functions.determine_sprite_position(
          entity, center, 1, items_per_row, items_per_column, scale / 0.8, true
  )
  draw_functions.draw_sprite(player, entity, sprite, target, scale, text, nil, false)
end

local function draw_fluid_contents(player, entity, _, no_text)
  local contents = entity.fluidbox
  if not contents then
    return
  end
  local sprites = {}
  for index = 1, #contents do
    local fluid = contents[index]
    if fluid and fluid.amount > 0 then
      local sprite_info = {
        sprite = "fluid." .. fluid.name
      }
      if not no_text then
        sprite_info.text = {right_bottom = util.localise_number(fluid.amount)}
        if fluid.temperature ~= prototypes.fluid[fluid.name].default_temperature then
          sprite_info.text.right_top = {"", util.localise_number(fluid.temperature), {"si-unit-degree-celsius"}}
        end
      end
      table.insert(sprites, sprite_info)
    end
  end
  draw_chest_like(player, entity, sprites)
end

local function get_item_filter_quality(filter)
  local text = {}
  if filter.comparator and filter.comparator ~= "=" then
    text.left_bottom = filter.comparator
  end
  local quality
  if filter.quality then
    quality = prototypes.quality[filter.quality]
  else
    quality = {color = {0, 0, 0}, draw_sprite_by_default = true}
  end
  return text, quality
end

local function draw_filters(player, entity, filters, blacklist)
  local sprites = {}
  for index, filter in pairs(filters) do
    local sprite_info = {}
    local text, quality
    if entity.type == "mining-drill" or entity.type == "entity-ghost" and entity.ghost_type == "mining-drill" then
      sprite_info.sprite = "entity." .. filter.name
    else
      text, quality = get_item_filter_quality(filter)
      sprite_info.text = text
      sprite_info.quality_prototype = quality
      sprite_info.blacklist = blacklist
      if filter.name then
        sprite_info.sprite = "item." .. filter.name
      else
        sprite_info.sprite = "quality." .. quality.name
      end
    end
    sprites[index] = sprite_info
  end
  draw_chest_like(player, entity, sprites)
end

local function get_and_draw_filters(player, entity, filter_mode, box)
  local control = entity.get_control_behavior()
  local filters = {}
  local signals
  if control and control.circuit_set_filters then
    signals = circuit_network.get_circuit_signals(entity, "item", true, false)
  end
  if signals then
    local slots_filled = 0
    for _, signal in pairs(signals) do
      if signal.signal.count > 0 then
        table.insert(filters, signal.signal.signal) -- SignalID has the same relevant attributes as Itemfilter
        slots_filled = slots_filled + 1
        if slots_filled > entity.filter_slot_count then
          break
        end
      end
    end
  elseif filter_mode ~= "none" then
    for filter_index = 1, entity.filter_slot_count do
      local filter = entity.get_filter(filter_index)
      if filter then
        table.insert(filters, filter)
      end
    end
  else
    return
  end
  if #filters == 0 then
    if filter_mode == "blacklist" or filter_mode == "none" then
      return
    end
    draw_functions.draw_blacklist_filter(player, entity, entity, 0.9)
    return
  end
  draw_filters(player, entity, filters, filter_mode == "blacklist", box)
end

local function draw_inserter_filters(player, entity)
  local filter_mode = entity.inserter_filter_mode
  if not entity.use_filters then
    filter_mode = "none"
  end
  get_and_draw_filters(player, entity, filter_mode)
end

local function draw_loader_filters(player, entity)
  local filter_mode = entity.loader_filter_mode
  get_and_draw_filters(player, entity, filter_mode)
end

local function draw_pump_filters(player, entity)
  local filter = entity.fluidbox.get_filter(1)
  if not filter then
    return
  end
  local text = {}
  if filter.minimum_temperature and filter.minimum_temperature ~= prototypes.fluid[filter.name].default_temperature then
    text.left_bottom = {"", "≥", util.localise_number(filter.minimum_temperature), {"si-unit-degree-celsius"}}
  end
  if filter.maximum_temperature and filter.maximum_temperature ~= prototypes.fluid[filter.name].max_temperature then
    text.left_top = {"", "≤", util.localise_number(filter.maximum_temperature), {"si-unit-degree-celsius"}}
  end
  local shift, scale, _, render_layer = get_draw_specification(entity)
  local target = {entity = entity, offset = shift}
  local sprite_info = {
    sprite = "fluid." .. filter.name,
    text   = text,
  }
  text.scale = scale * 0.7
  draw_functions.draw_sprite(player, entity, sprite_info, target, scale * 0.9, render_layer)
end

local function draw_pipe_contents(player, entity)
  if #entity.fluidbox == 0 then
    return
  end
  if (entity.position.x + entity.position.y) % 2 == 0 then
    -- Always draw icon when next to an underground pipe
    local pipe_connections = entity.fluidbox.get_pipe_connections(1)
    local num_connections = 0
    for _, connection in pairs(pipe_connections) do
      if connection.connection_type == "normal" and connection.target then
        if connection.target.owner.type == "pipe-to-ground" then
          goto continue
        end
        num_connections = num_connections + 1
      end
    end
    if num_connections > 0 then
      return
    end
  end
  :: continue ::
  local no_text = not settings.get_player_settings(player)["alt-alt-show-pipe-amount"].value
  return draw_fluid_contents(player, entity, nil, no_text)
end

local function draw_pipe_to_ground_contents(player, entity)
  -- Only draw icon if not connected to a regular pipe (the icon should be on the pipe in that case)
  -- or on one of the underground pipes in a pair
  if entity.direction == defines.direction.north or entity.direction == defines.direction.west then
    for index = 1, #entity.fluidbox do
      for _, connection in pairs(entity.fluidbox.get_pipe_connections(index)) do
        if connection.connection_type == "normal" and connection.target then
          if connection.target.owner.type == "pipe" or connection.target.owner.type == "infinity-pipe" then
            return
          end
        end
      end
    end
  end
  :: continue ::
  local no_text = not settings.get_player_settings(player)["alt-alt-show-pipe-amount"].value
  return draw_fluid_contents(player, entity, nil, no_text)
end

local function draw_accumulator_info(player, entity)
  if entity.type == "entity-ghost" then
    return
  end
  local text = {"", util.localise_number(entity.energy), {"si-unit-symbol-joule"}}
  local fullness = entity.energy / entity.electric_buffer_size
  local background_tint = {1 - fullness, fullness, 0}
  draw_functions.draw_text_sprite(player, entity, text, entity, 1, nil, 1, background_tint)
end

local function draw_electric_pole_info(player, entity)
  -- Cache the text per electric network so it does not have to be computed for each pole
  if entity.type == "entity-ghost" then
    return
  end
  if not storage["electric_network"] then
    storage["electric_network"] = {}
  end
  local text = storage["electric_network"][entity.electric_network_id]
  if not text then
    local stat = entity.electric_network_statistics
    local power_used = 0  -- (in Joule per tick)
    for k, _ in pairs(stat.output_counts) do
      local power_output = stat.get_flow_count {
        name            = k,
        category        = "output",
        precision_index = defines.flow_precision_index.five_seconds
      }
      power_used = power_used + power_output
    end
    text = {"", util.localise_number(power_used * 60), {"si-unit-symbol-watt"}}
    storage["electric_network"][entity.electric_network_id] = text
  end
  draw_functions.draw_text_sprite(player, entity, text, entity, 1, nil, 1)
end

local function draw_agricultural_tower_info(player, entity, item_requests)
  local inventory = entity.get_output_inventory()
  local contents = {}
  if inventory and inventory.valid then
    contents = inventory.get_contents()
    util.sort_inventory(contents)
  end
  draw_inventory_contents(player, entity, contents, item_requests)
end

local function draw_arithmetic_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local parameters = control.parameters
  local x_offset = 0.30
  local y_offset = 0.20
  local first_signal_target = {entity = entity, offset = {x = -x_offset, y = -y_offset}}
  local second_signal_target = {entity = entity, offset = {x = x_offset, y = -y_offset}}
  local output_signal_target = {entity = entity, offset = {x = 0, y = y_offset}}
  local op_target = {entity = entity, offset = {x = 0, y = -y_offset}}

  local operation = parameters.operation
  local operator_scale = 1
  if operation == "XOR" then
    operation = "⊕"
    operator_scale = 0.75
  elseif operation == "AND" then
    operation = "&"
    operator_scale = 0.75
  elseif operation == "OR" then
    operation = "|"
    operator_scale = 0.75
  elseif operation == "<<" then
    operation = "≪"
    operator_scale = 0.75
  elseif operation == ">>" then
    operation = "≫"
    operator_scale = 0.75
  end
  draw_functions.draw_text_sprite(player, entity, operation, op_target, operator_scale)
  if parameters.first_signal then
    draw_functions.draw_signal_id_sprite(player, entity, parameters.first_signal, first_signal_target, 0.45, nil,
                                         parameters.first_signal_networks.red, parameters.first_signal_networks.green)
  else
    draw_functions.draw_signal_constant(player, entity, parameters.first_constant, first_signal_target)
  end
  if parameters.second_signal then
    draw_functions.draw_signal_id_sprite(player, entity, parameters.second_signal, second_signal_target, 0.45, nil,
                                         parameters.second_signal_networks.red, parameters.second_signal_networks.green)
  else
    draw_functions.draw_signal_constant(player, entity, parameters.second_constant, second_signal_target)
  end
  if parameters.output_signal then
    local text
    -- if parameters.output_signal.name ~= "signal-each" then
    --   local count = control.get_signal_last_tick(parameters.output_signal) or 0
    --   text = {right_bottom = util.localise_number(count)}
    -- end
    draw_functions.draw_signal_id_sprite(player, entity, parameters.output_signal, output_signal_target, 0.45, text)
  end
end

local function draw_decider_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local x_offset = 0.30
  local y_offset = 0.20
  local first_signal_target = {entity = entity, offset = {x = -x_offset, y = -y_offset}}
  local second_signal_target = {entity = entity, offset = {x = x_offset, y = -y_offset}}
  local output_signal_target = {entity = entity, offset = {x = 0, y = y_offset}}
  local op_target = {entity = entity, offset = {x = 0, y = -y_offset}}
  local condition = control.get_condition(1)
  if condition then
    draw_functions.draw_text_sprite(player, entity, condition.comparator, op_target)
    if condition.first_signal then
      draw_functions.draw_signal_id_sprite(player, entity, condition.first_signal, first_signal_target, 0.45, nil, condition.first_signal_networks.red,
                                           condition.first_signal_networks.green)
    end
    if condition.second_signal then
      draw_functions.draw_signal_id_sprite(player, entity, condition.second_signal, second_signal_target, 0.45, nil, condition.second_signal_networks.red,
                                           condition.second_signal_networks.green)
    else
      draw_functions.draw_signal_constant(player, entity, condition.constant, second_signal_target)
    end
  end
  local output = control.get_output(1)
  if output and output.signal then
    local text
    local draw_red, draw_green
    if not output.copy_count_from_input then
      text = {right_bottom = util.localise_number(output.constant)}
    else
      draw_red = output.networks.red
      draw_green = output.networks.green
    end
    draw_functions.draw_signal_id_sprite(player, entity, output.signal, output_signal_target, 0.45, text, draw_red, draw_green)
  end
end

local function draw_selector_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local parameters = control.parameters
  local x_offset = 0.25
  local y_offset = 0.20
  if parameters.operation == "count" then
    local signal = parameters.count_signal
    if signal then
      local target = {entity = entity, offset = {x = 0, y = y_offset}}
      draw_functions.draw_signal_id_sprite(player, entity, signal, target, 0.45)
    end
  elseif parameters.operation == "random" then
    local target = {entity = entity, offset = {x = 0, y = y_offset}}
    draw_functions.draw_signal_constant(player, entity, parameters.random_update_interval or 0, target)
  elseif parameters.operation == "stack-size" then
  elseif parameters.operation == "rocket-capacity" then
  elseif parameters.operation == "quality-filter" then
    local target = {entity = entity, offset = {x = 0, y = y_offset}}
    local sprite_info
    if parameters.quality_filter and parameters.quality_filter.quality then
      sprite_info = {sprite = "quality." .. parameters.quality_filter.quality}
      local left_target = {entity = entity, offset = {x = -x_offset, y = y_offset}}
      target.offset.x = x_offset
      draw_functions.draw_text_sprite(
              player, entity, parameters.quality_filter.comparator, left_target, 0.75, nil, 1, nil, "left"
      )
    else
      sprite_info = {sprite = "virtual-signal.signal-any-quality"}
    end
    draw_functions.draw_sprite(player, entity, sprite_info, target, 0.45)
  elseif parameters.operation == "quality-transfer" then
    local left_target = {entity = entity, offset = {x = -x_offset, y = y_offset}}
    local right_target = {entity = entity, offset = {x = x_offset, y = y_offset}}
    if parameters.select_quality_from_signal then
      if parameters.quality_source_signal then
        draw_functions.draw_signal_id_sprite(player, entity, parameters.quality_source_signal, left_target, 0.45)
      end
    else
      local sprite_info = {sprite = "quality.normal"}
      if parameters.quality_source_static then
        sprite_info = {sprite = "quality." .. parameters.quality_source_static.name}
      end
      draw_functions.draw_sprite(player, entity, sprite_info, left_target, 0.45)
    end
    if parameters.quality_destination_signal then
      local signal = parameters.quality_destination_signal
      draw_functions.draw_signal_id_sprite(player, entity, signal, right_target, 0.45)
    end
  else
    -- select
    local left_target = {entity = entity, offset = {x = -0.35, y = y_offset}}
    local mid_target = {entity = entity, offset = {x = 0, y = y_offset}}
    local right_target = {entity = entity, offset = {x = 0.35, y = y_offset}}
    draw_functions.draw_text_sprite(player, entity, "[", left_target, 1, nil, false, nil, "left")
    if parameters.index_signal then
      draw_functions.draw_signal_id_sprite(player, entity, parameters.index_signal, mid_target, 0.75 * 0.45)
    else
      draw_functions.draw_signal_constant(player, entity, parameters.index_constant or 0, mid_target)
    end
    draw_functions.draw_text_sprite(player, entity, "]", right_target, 1, nil, false, nil, "right")
  end
end

local function draw_constant_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local signals = {}
  local num_items = 0
  local contents = {}
  for _, section in pairs(control.sections) do
    for _, signal in pairs(section.filters) do
      if signal and signal.value then
        local quality_name = signal.value.quality and signal.value.quality or ""
        local id = signal.value.name .. signal.value.type .. quality_name
        if signals[id] then
          signals[id].count = signals[id].count + signal.min
        else
          num_items = num_items + 1
          contents[num_items] = {name = signal.value.name, type = signal.value.type, quality = signal.value.quality, key = id}
          signals[id] = {signal = signal.value, count = signal.min or 0}
        end
      end
    end
  end
  util.sort_inventory(contents)
  local sprites = {}
  for _, signal in pairs(contents) do
    local sprite_info = {}
    local signal_type = signal.type
    if signal_type == "virtual" then
      signal_type = "virtual-signal"
    end
    sprite_info.sprite = signal_type .. "." .. signal.name
    sprite_info.text = {right_bottom = util.localise_number(signals[signal.key].count)}
    if signal.quality then
      sprite_info.quality_prototype = prototypes.quality[signal.quality]
    end
    table.insert(sprites, sprite_info)
  end
  draw_chest_like(player, entity, sprites)
end

local function _draw_splitter_arrows(player, entity, scale, input, left)
  local arrow_sprite = "alt-alt-indication-arrow"
  local offset
  local y_offset = -1
  local x_offset = 1
  if input then
    y_offset = 1
  end
  if left then
    x_offset = -1
  end
  offset = {x = 0.5 * scale * x_offset, y = 0.25 * scale * y_offset}
  local target = {entity = entity, offset = offset}
  if not input and entity.splitter_filter then
    target.offset.y = 0
    util.rotate_around_point(offset, {x = 0, y = 0}, entity.orientation)
    local sprite_info = {}
    if entity.splitter_filter.name then
      sprite_info.sprite = "item." .. entity.splitter_filter.name
      local text, quality = get_item_filter_quality(entity.splitter_filter)
      sprite_info.text = text
      sprite_info.quality_prototype = quality
    else
      sprite_info.sprite = "quality." .. entity.splitter_filter.quality
    end
    draw_functions.draw_sprite(player, entity, sprite_info, target, scale * 0.45)
  else
    util.rotate_around_point(offset, {x = 0, y = 0}, entity.orientation)
    local output_sprite = rendering.draw_sprite {
      sprite       = arrow_sprite,
      players      = {player},
      target       = target,
      orientation  = entity.orientation,
      surface      = entity.surface,
      x_scale      = scale * 0.65,
      y_scale      = scale * 0.65,
      time_to_live = settings.global["alt-alt-update-interval"].value + 30,
      render_layer = draw_functions.default_render_layer
    }
    table.insert(storage[player.index], output_sprite)
  end
end

local function draw_splitter_info(player, entity)
  local scale = 1
  if entity.type == "lane-splitter" then
    scale = 0.5
  end
  if entity.splitter_output_priority ~= "none" then
    _draw_splitter_arrows(player, entity, scale, false, entity.splitter_output_priority == "left")
  end
  if entity.splitter_input_priority ~= "none" then
    _draw_splitter_arrows(player, entity, scale, true, entity.splitter_input_priority == "left")
  end
end

local function draw_crafting_machine_info(player, entity, item_requests)
  local inventory_define
  if entity.type == "furnace" then
    inventory_define = defines.inventory.furnace_modules
  else
    inventory_define = defines.inventory.assembling_machine_modules
  end
  draw_modules(player, entity, item_requests, inventory_define)
  local recipe, quality = entity.get_recipe()
  if not recipe then
    return
  end
  local sprite_info = {}
  sprite_info.sprite = "recipe." .. recipe.name
  sprite_info.quality_prototype = quality
  local shift, scale, _, render_layer = get_draw_specification(entity)
  local target = {entity = entity, offset = shift}
  if target then
    draw_functions.draw_sprite(player, entity, sprite_info, target, scale * 0.9, render_layer)
    if not recipe.enabled then
      draw_functions.draw_blacklist_filter(player, entity, target, scale * 1.8, render_layer)
    end
  end
end



local function draw_rocket_silo_info(player, entity, item_requests)
  draw_modules(player, entity, item_requests, defines.inventory.rocket_silo_modules)
  local inventory = entity.get_inventory(defines.inventory.rocket_silo_rocket)
  local contents = {}
  if inventory and inventory.valid then
    contents = inventory.get_contents()
    util.sort_inventory(contents)
  end
  draw_inventory_contents(player, entity, contents)
end

local function draw_mining_drill_info(player, entity, item_requests)
  local filter_mode = entity.mining_drill_filter_mode
  draw_modules(player, entity, item_requests, defines.inventory.mining_drill_modules)
  if filter_mode == nil then
    filter_mode = "none"
  end
  local sprites = {}
  for filter_index = 1, entity.filter_slot_count do
    local filter = entity.get_filter(filter_index)
    if filter then
      local sprite_info = {}
      if prototypes.item[filter.name] then
        sprite_info.sprite = "item." .. filter.name
      else
        sprite_info.sprite = "fluid." .. filter.name
      end
      if filter_mode == "blacklist" then
        sprite_info.blacklist = true
      end
      table.insert(sprites, sprite_info)
    end
  end
  draw_chest_like(player, entity, sprites)
end

local function draw_radar_info(player, entity)
  local signals = circuit_network.get_circuit_signals(entity)

  if not signals or #signals == 0 then
    return
  end
  local items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, #signals)
  if not scale then
    return
  end
  local center = util.box_center(entity.selection_box)
  for i, signal_data in pairs(signals) do
    local signal = signal_data.signal
    local text = {right_bottom = util.localise_number(signal.count)}
    local target = draw_functions.determine_sprite_position(
            entity, center, i, items_per_row, items_per_column, scale / 0.8, false
    )
    draw_functions.draw_signal_id_sprite(player, entity, signal.signal, target, scale, text, signal_data.use_red,
                                         signal_data.use_green)
  end
end

local function draw_temperature(player, entity)
  if entity.type == "entity-ghost" then
    return
  end
  local scale = 0.5
  local target_text = entity
  local text = {"", util.localise_number(entity.temperature), {"si-unit-degree-celsius"}}
  local text_sprite = rendering.draw_text {
    text               = text,
    players            = {player},
    target             = target_text,
    surface            = entity.surface,
    scale              = scale,
    color              = {1, 1, 1},
    alignment          = "center",
    vertical_alignment = "middle",
    time_to_live       = settings.global["alt-alt-update-interval"].value + 30,
    render_layer       = "wires-above",
  }
  table.insert(storage[player.index], text_sprite)
end

local function draw_mineable_info(player, entity)
  if entity.type == "entity-ghost" then
    return end
  local prototype = prototypes.entity[entity.name]
  if not entity.minable or not prototype.mineable_properties or not prototype.mineable_properties.products then return
  end
  local num_items = #prototype.mineable_properties.products
  if num_items == 0 then
    return
  end
  local items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, num_items)
  if not scale then
    return
  end

  local center = util.box_center(entity.selection_box)
  for index, product in pairs(prototype.mineable_properties.products) do
    local amount = product.amount
    if not amount then
      amount = (product.amount_min + product.amount_max) / 2
    end
    if product.probability then
      amount = amount * product.probability
    end
    local text = {right_bottom = util.localise_number(amount)}
    local target = draw_functions.determine_sprite_position(
            entity, center, index, items_per_row, items_per_column, scale / 0.8, false
    )
    local sprite_info = {
      sprite = product.type .. "." .. product.name,
      text   = text,
      -- quality = product.quality, -- products can't have quality
    }
    draw_functions.draw_sprite(player, entity, sprite_info, target, scale)
  end
end

local function draw_turret_info(player, entity, item_requests, use_direction)
  local targets = {}
  local index = 0
  while true do
    index = index + 1
    local status, target = pcall(entity.get_priority_target, index)
    if not status then
      break end
    if target then
      table.insert(targets, target)
    end
  end
  local sprites = {}

  for i, turret_target in pairs(targets) do
    table.insert(sprites, {sprite = "entity." .. turret_target.name, index = i})
  end
  if #sprites > 0 then
    draw_module_like(player, entity, sprites, nil, nil)
  end
end

local function draw_consuming_turret_info(player, entity, item_requests, sprites)
  local name = entity.name
  if name == "entity-ghost" then
    name = entity.ghost_name
  end
  local selection_box = prototypes.entity[name].selection_box
  local use_direction = selection_box.left_top.x ~= selection_box.left_top.y
  draw_turret_info(player, entity, item_requests, use_direction)
  local box = {left_top = selection_box.left_top, right_bottom = {x = selection_box.right_bottom.x, y = 0}}
  local items_per_row, items_per_column, scale = get_box_parameters(box, #sprites)
  if not scale then
    return
  end

  local center = util.box_center(box)
  for index, sprite in pairs(sprites) do
    local text = {right_bottom = util.localise_number(sprite.count)}
    local target = draw_functions.determine_sprite_position(
            entity, center, index, items_per_row, items_per_column, scale / 0.8, false
    )
    if target then
      target.offset.x = target.offset.x + entity.position.x
      target.offset.y = target.offset.y + entity.position.y
      if use_direction then
        util.rotate_around_point(target.offset, {x = 0, y = 0}, entity.direction / 16)
      end
      draw_functions.draw_sprite(player, entity, sprite.sprite, target, scale, text, sprite.quality,
                                 sprite.background_type)
    end
  end
end

local function draw_ammo_turret_info(player, entity, item_requests)
  local inventory = entity.get_inventory(defines.inventory.turret_ammo)
  local contents = {}
  if inventory and inventory.valid then
    contents = inventory.get_contents()
  end
  local sprites = get_proxy_sprites(entity, item_requests)
  for _, item in pairs(contents) do
    local sprite = "item." .. item.name
    local count = item.count
    local quality = prototypes.quality[item.quality]
    table.insert(sprites, {sprite = sprite, count = count, quality = quality})
  end
  draw_consuming_turret_info(player, entity, item_requests, sprites)
end

local function draw_fluid_turret_info(player, entity, item_requests)
  local contents = entity.get_fluid_contents()
  if not contents then
    return
  end
  local sprites = {}
  for fluid, count in pairs(contents) do
    local sprite = "fluid." .. fluid
    table.insert(sprites, {sprite = sprite, count = count})
  end
  draw_consuming_turret_info(player, entity, item_requests, sprites)
end

local function inventory_alt_info(inventory_define, use_orientation)
  local function draw(player, entity, item_requests)
    local contents = {}
    local inventory = entity.get_inventory(inventory_define)
    if inventory and inventory.valid then
      contents = inventory.get_contents()
      util.sort_inventory(contents)
    end
    draw_inventory_contents(player, entity, contents, item_requests, use_orientation)
  end
  return draw
end

local alt_functions_per_type = {
  ["accumulator"]              = draw_accumulator_info,
  ["electric-pole"]            = draw_electric_pole_info,
  ["agricultural-tower"]       = draw_agricultural_tower_info,
  ["arithmetic-combinator"]    = draw_arithmetic_combinator_info,
  ["decider-combinator"]       = draw_decider_combinator_info,
  ["constant-combinator"]      = draw_constant_combinator_info,
  ["selector-combinator"]      = draw_selector_combinator_info,
  ["splitter"]                 = draw_splitter_info,
  ["lane-splitter"]            = draw_splitter_info,
  ["assembling-machine"]       = draw_crafting_machine_info,
  ["furnace"]                  = draw_crafting_machine_info,
  ["asteroid-collector"]       = inventory_alt_info(defines.inventory.chest),
  ["character-corpse"]         = inventory_alt_info(defines.inventory.character_corpse),
  ["roboport"]                 = inventory_alt_info(defines.inventory.roboport_robot),
  ["lab"]                      = draw_lab_info,
  ["rocket-silo"]              = draw_rocket_silo_info,
  ["car"]                      = inventory_alt_info(defines.inventory.car_trunk),
  ["locomotive"]               = inventory_alt_info(defines.inventory.fuel),
  ["cargo-wagon"]              = draw_cargo_wagon_info,
  ["beacon"]                   = draw_beacon_info,
  ["mining-drill"]             = draw_mining_drill_info,
  ["artillery-wagon"]          = inventory_alt_info(defines.inventory.artillery_wagon_ammo),
  ["spider-vehicle"]           = inventory_alt_info(defines.inventory.spider_trunk),
  ["space-platform-hub"]       = inventory_alt_info(defines.inventory.hub_main),
  ["cargo-landing-pad"]        = inventory_alt_info(defines.inventory.cargo_landing_pad_main),
  ["cargo-pod"]                = inventory_alt_info(defines.inventory.chest),
  ["container"]                = inventory_alt_info(defines.inventory.chest),
  ["infinity-container"]       = inventory_alt_info(defines.inventory.chest),
  ["logistic-container"]       = inventory_alt_info(defines.inventory.chest),
  ["reactor"]                  = inventory_alt_info(defines.inventory.fuel),
  ["construction-robot"]       = inventory_alt_info(defines.inventory.robot_cargo),
  ["logistic-robot"]           = inventory_alt_info(defines.inventory.robot_cargo),
  ["fluid-wagon"]              = draw_fluid_wagon_contents,
  ["boiler"]                   = draw_fluid_contents,
  ["generator"]                = draw_fluid_contents,
  ["fusion-reactor"]           = inventory_alt_info(defines.inventory.fuel),
  ["burner-generator"]         = inventory_alt_info(defines.inventory.fuel),
  ["fusion-generator"]         = draw_fluid_contents,
  ["thruster"]                 = draw_fluid_contents,
  ["storage-tank"]             = draw_fluid_contents,
  ["pump"]                     = draw_pump_filters,
  ["offshore-pump"]            = draw_fluid_contents,
  ["infinity-pipe"]            = draw_pipe_contents,
  ["pipe"]                     = draw_pipe_contents,
  ["pipe-to-ground"]           = draw_pipe_to_ground_contents,
  ["inserter"]                 = draw_inserter_filters,
  ["loader"]                   = draw_loader_filters,
  ["loader-1x1"]               = draw_loader_filters,
  ["heat-pipe"]                = draw_temperature,
  ["heat-interface"]           = draw_temperature,
  ["radar"]                    = draw_radar_info,
  ["simple-entity"]            = draw_mineable_info,
  ["simple-entity-with-owner"] = draw_mineable_info,
  ["tree"]                     = draw_mineable_info,
  ["fish"]                     = draw_mineable_info,
  ["artillery-turret"]         = inventory_alt_info(defines.inventory.artillery_turret_ammo),
  ["ammo-turret"]              = draw_ammo_turret_info,
  ["fluid-turret"]             = draw_fluid_turret_info,
  ["electric-turret"]          = draw_turret_info,
}

local supported_types = {}
for k, _ in pairs(alt_functions_per_type) do
  table.insert(supported_types, k)
end
table.insert(supported_types, "entity-ghost")

local function show_quality_icon(player, entity)
  -- quality
  if entity.quality and entity.quality.draw_sprite_by_default then
    local box = entity.selection_box
    local center = util.box_center(box)
    center.x = center.x - entity.position.x
    center.y = center.y - entity.position.y
    local left_bottom = {x = box.left_top.x - entity.position.x, y = box.right_bottom.y - entity.position.y}
    local scale = math.min(box.right_bottom.x - box.left_top.x, box.right_bottom.y - box.left_top.y) / 7
    scale = math.max(scale, 0.25)
    local offset = {x = left_bottom.x + scale / 2, y = left_bottom.y - scale / 2}
    if entity.train and entity.orientation ~= 0 then
      util.rotate_around_point(offset, center, entity.orientation)
    end
    local target = {entity = entity, offset = offset}
    local sprite_info = {
      sprite          = "quality." .. entity.quality.name,
      background_type = "quality_badge"
    }
    draw_functions.draw_sprite(player, entity, sprite_info, target, scale)
  end
end

local function show_alt_info_for_entity(player, entity, item_requests)
  if not entity or not entity.valid then
    return
  end
  if not entity.prototype.selectable_in_game then
    return
  end
  if entity.selection_box.left_top.x == entity.selection_box.right_bottom.x then
    return
  end
  if entity.selection_box.left_top.y == entity.selection_box.right_bottom.y then
    return
  end
  local type
  if entity.type == "entity-ghost" then
    type = entity.ghost_type
  else
    type = entity.type
  end
  if alt_functions_per_type[type] then
    alt_functions_per_type[type](player, entity, item_requests)
  end
end

return {
  show_alt_info_for_entity = show_alt_info_for_entity,
  show_quality_icon        = show_quality_icon,
  supported_types          = supported_types,
}