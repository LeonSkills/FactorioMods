local util = require("__AltAltMode__/scripts/util.lua")
local draw_functions = require("__AltAltMode__/scripts/draw_functions")
local constants = require("__AltAltMode__/scripts/constants")
local circuit_network = require("__AltAltMode__/scripts/circuit_network")

local function get_box_parameters(box, num_items)
  local selection_box_center = util.box_center(box)
  local width = math.ceil(box.right_bottom.x - box.left_top.x)
  local height = math.ceil(box.right_bottom.y - box.left_top.y)
  width = math.min(width, constants.max_size)
  height = math.min(height, constants.max_size)
  if num_items == 0 then return end
  local items_per_row, items_per_column, scale = util.fill_grid_with_largest_square(width, height, num_items)
  items_per_row = math.min(items_per_row, num_items)
  if scale < constants.min_scale then
    scale = constants.min_scale
    items_per_row = math.floor(width / scale)
    items_per_column = math.floor(height / scale)
  elseif scale > constants.max_scale then
    scale = constants.max_scale
  end
  scale = scale * 0.8

  return selection_box_center, items_per_row, items_per_column, scale

end

local function draw_inventory_contents(player, entity, inventory)
  if not inventory or not inventory.valid then return end
  local contents = inventory.get_contents()
  if not contents then return end
  local num_items = #contents
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, num_items)
  for index, item in pairs(contents) do
    local text = {right_bottom = util.localise_number(item.count)}
    local target = draw_functions.determine_sprite_position(
            entity, center, index, items_per_row, items_per_column, scale / 0.8, entity.orientation
    )
    if target then
      local sprite = "item." .. item.name
      draw_functions.draw_sprite(player, entity, sprite, target, scale, text, prototypes.quality[item.quality])
    end
  end
end

local function draw_fluid_wagon_contents(player, entity)
  -- cargo wagon does not have a fluid box
  local fluid = entity.get_fluid(1)
  if not fluid then return end
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, 1)
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

local function draw_fluid_contents(player, entity)
  local contents = entity.fluidbox
  if not contents then return end
  local num_items = #contents
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, num_items)
  for index = 1, #contents do
    local fluid = contents[index]
    if fluid then
      local prototype = prototypes.fluid[fluid.name]
      local sprite = "fluid." .. fluid.name
      local text = {right_bottom = util.localise_number(fluid.amount)}
      text.scale = 0.6
      if fluid.temperature ~= prototype.default_temperature then
        text.right_top = {"", util.localise_number(fluid.temperature), {"si-unit-degree-celsius"}}
      end
      local target = draw_functions.determine_sprite_position(
              entity, center, index, items_per_row, items_per_column, scale / 0.8, true
      )
      if target then
        draw_functions.draw_sprite(player, entity, sprite, target, scale, text, nil, false)
      end
    end
  end
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
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, #filters)
  for index, filter in pairs(filters) do
    local sprite
    local text, quality = get_item_filter_quality(filter)
    if filter.name then
      sprite = "item." .. filter.name
    else
      sprite = "quality." .. quality.name
      quality = nil
    end
    local target = draw_functions.determine_sprite_position(
            entity, center, index, items_per_row, items_per_column, scale / 0.8, false
    )
    if target then
      draw_functions.draw_sprite(player, entity, sprite, target, scale, text, quality)
      if blacklist then
        local blacklist_sprite = rendering.draw_sprite {
          sprite       = 'alt-alt-filter-blacklist',
          players      = {player},
          target       = target,
          surface      = entity.surface,
          x_scale      = scale,
          y_scale      = scale,
          time_to_live = constants.time_to_live
        }
        table.insert(storage[player.index], blacklist_sprite)
      end
    end
  end
end

local function get_and_draw_filters(player, entity, filter_mode)
  local control = entity.get_control_behavior()
  local filters = {}
  if control and control.circuit_set_filters then
    local signals = circuit_network.get_circuit_signals(entity, "item", true, false)
    local slots_filled = 0
    for _, signal in pairs(signals) do
      if signal.signal.count > 0 then
        table.insert(filters, signal.signal.signal) -- SignalID has the same relevant attributes as Itemfilter
        slots_filled = slots_filled + 1
        if slots_filled > entity.filter_slot_count then break end
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
    if filter_mode == "blacklist" or filter_mode == "none" then return end
    draw_functions.draw_sprite(player, entity, "alt-alt-filter-blacklist", entity, 0.45)
    return
  end
  draw_filters(player, entity, filters, filter_mode == "blacklist")
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

local function draw_pipe_contents(player, entity)
  if (entity.position.x + entity.position.y) % 2 == 0 then return end
  return draw_fluid_contents(player, entity)
end

local function draw_accumulator_info(player, entity)
  local text = {"", util.localise_number(entity.energy), {"si-unit-symbol-joule"}}
  local fullness = entity.energy / prototypes.entity[entity.name].electric_energy_source_prototype.buffer_capacity
  local background_tint = {1 - fullness, fullness, 0}
  draw_functions.draw_text_sprite(player, entity, text, entity, 1, nil, true, background_tint)
end

local function draw_electric_pole_info(player, entity)
  -- Cache the text per electric network so it does not have to be computed for each pole
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
  draw_functions.draw_text_sprite(player, entity, text, entity, 1, nil, true)
end

local function draw_agricultural_tower_info(player, entity)
  local inventory = entity.get_output_inventory()
  draw_inventory_contents(player, entity, inventory)
end

local function draw_arithmetic_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local parameters = control.parameters
  local x_offset = 0.35
  local y_offset = 0.25
  local first_signal_target = {entity = entity, offset = {x = -x_offset, y = -y_offset}}
  local second_signal_target = {entity = entity, offset = {x = x_offset, y = -y_offset}}
  local output_signal_target = {entity = entity, offset = {x = 0, y = y_offset}}
  local op_target = {entity = entity, offset = {x = 0, y = -y_offset}}
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
  local operation = parameters.operation
  local operator_scale = 1
  if operation == "XOR" then
    operation = "⊕"
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
  if parameters.output_signal then
    local tex
    -- if parameters.output_signal.name ~= "signal-each" then
    --   local count = control.get_signal_last_tick(parameters.output_signal) or 0
    --   text = {right_bottom = util.localise_number(count)}
    -- end
    draw_functions.draw_signal_id_sprite(player, entity, parameters.output_signal, output_signal_target, 0.45, text)
  end
end

local function draw_decider_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local x_offset = 0.35
  local y_offset = 0.25
  local first_signal_target = {entity = entity, offset = {x = -x_offset, y = -y_offset}}
  local second_signal_target = {entity = entity, offset = {x = x_offset, y = -y_offset}}
  local output_signal_target = {entity = entity, offset = {x = 0, y = y_offset}}
  local op_target = {entity = entity, offset = {x = 0, y = -y_offset}}
  local condition = control.get_condition(1)
  if condition then
    if condition.first_signal then
      draw_functions.draw_signal_id_sprite(player, entity, condition.first_signal, first_signal_target, 0.45, nil,
                                           condition.first_signal_networks.red, condition.first_signal_networks.green)
    end
    if condition.second_signal then
      draw_functions.draw_signal_id_sprite(player, entity, condition.second_signal, second_signal_target, 0.45, nil,
                                           condition.first_signal_networks.red, condition.first_signal_networks.green)
    else
      draw_functions.draw_signal_constant(player, entity, condition.constant, second_signal_target)
    end
    draw_functions.draw_text_sprite(player, entity, condition.comparator, op_target)
    -- local text_sprite = rendering.draw_text {text = condition.comparator, players = {player}, target = op_target, surface = entity.surface, scale = 1, color = {1, 1, 1}, alignment = "center", vertical_alignment = "middle", time_to_live = constants.time_to_live}
    -- table.insert(storage[player.index], text_sprite)
  end
  local output = control.get_output(1)
  if output and output.signal then
    local text
    local draw_red, draw_green
    if not output.copy_count_from_input then
      text = {right_bottom = "1"}
    else
      draw_red = output.networks.red
      draw_green = output.networks.green
    end
    draw_functions.draw_signal_id_sprite(player, entity, output.signal, output_signal_target, 0.45, text, draw_red,
                                         draw_green)
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
          signals[id].amount = signals[id].amount + signal.min
        else
          num_items = num_items + 1
          contents[num_items] = {signal = signal.value, key = id}
          signals[id] = {signal = signal.value, amount = signal.min or 0}
        end
      end
    end
  end
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, num_items)
  for index, item in pairs(contents) do
    local text = {right_bottom = util.localise_number(signals[item.key].amount)}
    local signal_type = item.signal.type
    if signal_type == "virtual" then
      signal_type = "virtual-signal"
    end
    local sprite = signal_type .. "." .. item.signal.name
    local target = draw_functions.determine_sprite_position(
            entity, center, index, items_per_row, items_per_column, scale / 0.7, true
    )
    if target then
      local quality
      if item.signal.quality then
        quality = prototypes.quality[item.signal.quality]
      end
      draw_functions.draw_sprite(player, entity, sprite, target, scale, text, quality)
    end
  end
end

local function draw_selector_combinator_info(player, entity)
  local control = entity.get_control_behavior()
  local parameters = control.parameters
  local x_offset = 0.25
  local y_offset = 0.25
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
    local sprite
    if parameters.quality_filter and parameters.quality_filter.quality then
      sprite = "quality." .. parameters.quality_filter.quality
      local left_target = {entity = entity, offset = {x = -x_offset, y = y_offset}}
      target.offset.x = x_offset
      draw_functions.draw_text_sprite(
              player, entity, parameters.quality_filter.comparator, left_target, 0.75, nil, true, nil, "left"
      )
    else
      sprite = "virtual-signal.signal-any-quality"
    end
    draw_functions.draw_sprite(player, entity, sprite, target, 0.45)
  elseif parameters.operation == "quality-transfer" then
    local left_target = {entity = entity, offset = {x = -x_offset, y = y_offset}}
    local right_target = {entity = entity, offset = {x = x_offset, y = y_offset}}
    if parameters.select_quality_from_signal then
      if parameters.quality_source_signal then
        draw_functions.draw_signal_id_sprite(player, entity, parameters.quality_source_signal, left_target, 0.45)
      end
    else
      local sprite = "quality.normal"
      if parameters.quality_source_static then
        sprite = "quality." .. parameters.quality_source_static.name
      end
      draw_functions.draw_sprite(player, entity, sprite, left_target, 0.45)
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
  util.rotate_around_point(offset, {x = 0, y = 0}, entity.orientation)
  local target = {entity = entity, offset = offset}
  if not input and entity.splitter_filter then
    target.offset.y = 0
    local main_sprite
    if entity.splitter_filter.name then
      main_sprite = "item." .. entity.splitter_filter.name
    end
    local text, quality = get_item_filter_quality(entity.splitter_filter)
    draw_functions.draw_sprite(player, entity, main_sprite, target, scale * 0.45, text, quality)
  else
    local output_sprite = rendering.draw_sprite {
      sprite       = arrow_sprite,
      players      = {player},
      target       = target,
      orientation  = entity.orientation,
      surface      = entity.surface,
      x_scale      = scale * 0.75,
      y_scale      = scale * 0.75,
      time_to_live = constants.time_to_live
    }
    table.insert(storage[player.index], output_sprite)
  end
end

local function draw_splitter_info(player, entity)
  local scale = 1
  if entity.type == "lane-splitter" then
    scale = 0.5
  end
  if entity.splitter_input_priority ~= "none" then
    _draw_splitter_arrows(player, entity, scale, true, entity.splitter_input_priority == "left")
  end
  if entity.splitter_output_priority ~= "none" then
    _draw_splitter_arrows(player, entity, scale, false, entity.splitter_output_priority == "left")
  end
end

local function draw_modules(player, entity, y_ratio)
  -- y_ratio is the ratio of which the height of the entity where the modules are drawn
  -- For crafting machines this is 2/5
  -- Beacons get the whole width
  if not y_ratio then
    y_ratio = 1
  end
  local inventory = entity.get_module_inventory()
  if not inventory then return end
  -- rendering.draw_rectangle{surface=entity.surface, color={1,1,1}, width=1, left_top=module_box.left_top, right_bottom=module_box.right_bottom}
  local sprites = {}
  for index = 1, #inventory do
    local item = inventory[index]
    if item and item.valid and item.count > 0 then
      table.insert(sprites, {sprite = "item." .. item.name, quality = item.quality})
    end
  end
  draw_functions.draw_module_like(player, entity, sprites, 0.5, y_ratio)
  -- local width = box.right_bottom.x - box.left_top.x
  -- local scale = 0.5
  -- local center = util.box_center(module_box)
  -- local max_items_per_row = math.floor(width / (scale / 0.75))
  -- local num_rows = math.ceil(#inventory / max_items_per_row)
  -- local num_columns = #inventory / num_rows
  -- for index = 1, #inventory do
  --   local item = inventory[index]
  --   if item and item.valid and item.count > 0 then
  --     local target = draw_functions.determine_sprite_position(
  --             entity, center, index, num_columns, num_rows, scale / 0.8, false
  --     )
  --     local sprite = "item." .. item.name
  --     if target then
  --       draw_functions.draw_sprite(player, entity, sprite, target, scale, {}, item.quality)
  --     end
  --   end
  -- end
end

local function draw_crafting_machine_info(player, entity)
  draw_modules(player, entity, 2 / 5)
  local recipe, quality = entity.get_recipe()
  if not recipe then return end
  local box = entity.selection_box
  local sprite = "recipe." .. recipe.name
  local dimension_diff = math.max((box.right_bottom.y - box.left_top.y), (box.right_bottom.x - box.left_top.x))
  local scale = math.ceil(dimension_diff / 2) / 2
  local y_offset = scale / 2
  local target = {entity = entity, offset = {x = 0, y = -y_offset}}
  if target then
    draw_functions.draw_sprite(player, entity, sprite, target, scale, {}, quality)
  end
end

local function draw_rocket_silo_info(player, entity)
  draw_modules(player, entity, 1 / 3)
  local inventory = entity.get_inventory(defines.inventory.rocket_silo_rocket)
  draw_inventory_contents(player, entity, inventory)
end

local function draw_radar_info(player, entity)
  local signals = circuit_network.get_circuit_signals(entity)
  if #signals == 0 then return end
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, #signals)
  for i, signal_data in pairs(signals) do
    local signal = signal_data.signal
    local text = {right_bottom = util.localise_number(signal.count)}
    local target = draw_functions.determine_sprite_position(
            entity, center, i, items_per_row, items_per_column, scale / 0.8, false
    )
    draw_functions.draw_signal_id_sprite(player, entity, signal.signal, target, scale, text, signal.use_red, signal.use_green)
  end
end

local function draw_temperature(player, entity)
  local scale = 0.5
  local target_text = entity
  local text = {"", util.localise_number(entity.temperature), {"si-unit-degree-celsius"}}
  local text_sprite = rendering.draw_text {text = text, players = {player}, target = target_text, surface = entity.surface, scale = scale, color = {1, 1, 1}, alignment = "center", vertical_alignment = "middle", time_to_live = constants.time_to_live}
  table.insert(storage[player.index], text_sprite)
end

local function draw_mineable_info(player, entity)
  local prototype = prototypes.entity[entity.name]
  if not entity.minable or not prototype.mineable_properties or not prototype.mineable_properties.products then return end
  local num_items = #prototype.mineable_properties.products
  if num_items == 0 then return end
  local center, items_per_row, items_per_column, scale = get_box_parameters(entity.selection_box, num_items)
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
    local sprite = product.type .. "." .. product.name
    draw_functions.draw_sprite(player, entity, sprite, target, scale, text, entity.quality)
  end
end

local function draw_turret_info(player, entity, use_direction)
  local targets = {}
  local index = 0
  while true do
    index = index + 1
    local status, target = pcall(entity.get_priority_target, index)
    if not status then break end
    if target then
      table.insert(targets, target)
    end
  end
  if #targets == 0 then return end
  local sprites = {}
  for i, turret_target in pairs(targets) do
    table.insert(sprites, {sprite = "entity." .. turret_target.name, index = i})
  end
  draw_functions.draw_module_like(player, entity, sprites, 0.5, 2 / 5, use_direction)
end

local function draw_consuming_turret_info(player, entity, sprites)
  local selection_box = prototypes.entity[entity.name].selection_box
  local use_direction = selection_box.left_top.x ~= selection_box.left_top.y
  draw_turret_info(player, entity, use_direction)
  local box = {left_top = selection_box.left_top, right_bottom = {x = selection_box.right_bottom.x, y = 0}}
  local center, items_per_row, items_per_column, scale = get_box_parameters(box, #sprites)
  for index, sprite in pairs(sprites) do
    local text = {right_bottom = util.localise_number(sprite.amount)}
    local target = draw_functions.determine_sprite_position(
            entity, center, index, items_per_row, items_per_column, scale / 0.8, false
    )
    if target then
      target.offset.x = target.offset.x + entity.position.x
      target.offset.y = target.offset.y + entity.position.y
      if use_direction then
        util.rotate_around_point(target.offset, {x = 0, y = 0}, entity.direction / 16)
      end
      draw_functions.draw_sprite(player, entity, sprite.sprite, target, scale, text, sprite.quality)
    end
  end
end

local function draw_ammo_turret_info(player, entity)
  local inventory = entity.get_inventory(defines.inventory.turret_ammo)
  if not inventory or not inventory.valid then return end
  local contents = inventory.get_contents()
  if not contents then return end
  local sprites = {}
  for _, item in pairs(contents) do
    local sprite = "item." .. item.name
    local amount = item.count
    local quality = prototypes.quality[item.quality]
    table.insert(sprites, {sprite = sprite, amount = amount, quality = quality})
  end
  draw_consuming_turret_info(player, entity, sprites)
end

local function draw_fluid_turret_info(player, entity)
  local contents = entity.get_fluid_contents()
  if not contents then return end
  local sprites = {}
  for fluid, amount in pairs(contents) do
    local sprite = "fluid." .. fluid
    table.insert(sprites, {sprite = sprite, amount = amount})
  end
  draw_consuming_turret_info(player, entity, sprites)
end

local function inventory_alt_info(inventory_define)
  local function draw(player, entity)
    local inventory = entity.get_inventory(inventory_define)
    draw_inventory_contents(player, entity, inventory)
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
  ["lab"]                      = inventory_alt_info(defines.inventory.lab_input),
  ["rocket-silo"]              = draw_rocket_silo_info,
  ["car"]                      = inventory_alt_info(defines.inventory.car_trunk),
  ["locomotive"]               = inventory_alt_info(defines.inventory.fuel),
  ["cargo-wagon"]              = inventory_alt_info(defines.inventory.cargo_wagon),
  ["beacon"]                   = draw_modules,
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
  ["pump"]                     = draw_fluid_contents,
  ["offshore-pump"]            = draw_fluid_contents,
  ["infinity-pipe"]            = draw_pipe_contents,
  ["pipe"]                     = draw_pipe_contents,
  ["pipe-to-ground"]           = draw_pipe_contents,
  ["inserter"]                 = draw_inserter_filters,
  ["loader"]                   = draw_loader_filters,
  ["loader-1x1"]               = draw_loader_filters,
  ["heat-pipe"]                = draw_temperature,
  ["heat-interface"]           = draw_temperature,
  ["radar"]                    = draw_radar_info,
  ["simple-entity"]            = draw_mineable_info,
  ["simple-entity-with-owner"] = draw_mineable_info,
  ["tree"]                     = draw_mineable_info,
  ["artillery-turret"]         = inventory_alt_info(defines.inventory.artillery_turret_ammo),
  ["ammo-turret"]              = draw_ammo_turret_info,
  ["fluid-turret"]             = draw_fluid_turret_info,
  ["electric-turret"]          = draw_turret_info,
}

local function show_alt_info_for_entity(player, entity)
  if not entity or not entity.valid then
    return
  end
  local type
  if entity.type == "entity-ghost" then
    type = entity.ghost_type
  else
    type = entity.type
  end
  if alt_functions_per_type[type] then
    alt_functions_per_type[type](player, entity)
  end
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
    local sprite = "quality." .. entity.quality.name
    draw_functions.draw_sprite(player, entity, sprite, target, scale, {}, nil, true)
  end
end

local function show_alt_info_for_player(player)
  if not storage.change_radius_events then
    storage.change_radius_events = {}
  end
  if storage.change_radius_events[player.index] then
    local render = rendering.get_object_by_id(storage.change_radius_events[player.index])
    if render and render.valid then
      render.destroy()
    end
    storage.change_radius_events[player.index] = nil
  end
  storage["electric_network"] = nil

  if storage[player.index] then
    for _, sprite in pairs(storage[player.index]) do
      if sprite.valid then
        sprite.destroy()
      end
    end
    storage[player.index] = nil
  end
  if storage.alt_mode_status and storage.alt_mode_status and storage.alt_mode_status[player.index] ~= "alt-alt" then
    return
  end
  if not player.selected then return end
  storage[player.index] = {}
  local radius = settings.get_player_settings(player)["alt-alt-radius"].value
  local selected_entity = player.selected
  if not selected_entity or not selected_entity.valid then return end
  if radius <= 0 then
    show_alt_info_for_entity(player, player.selected)
  else
    for _, entity in pairs(player.selected.surface.find_entities_filtered {position = player.selected.position, radius = radius}) do
      show_alt_info_for_entity(player, entity)
    end
  end
end

return {
  show_alt_info_for_entity = show_alt_info_for_entity,
  show_alt_info_for_player = show_alt_info_for_player
}