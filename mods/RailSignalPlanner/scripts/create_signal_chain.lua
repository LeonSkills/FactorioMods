require("rail_utility")
require("scripts/utility")


local function create_table_entry(signals, rail, placement, rail_direction)
  local unique_id = create_unique_id(placement.pos, placement.dir)
  if signals[unique_id] then
    local visited = true
    if not contains(signals[unique_id].rails, rail) then
      table.insert(signals[unique_id].rails, rail)
      visited = false
    end
    return signals[unique_id], visited  -- already initialized
  end
   signals[unique_id] = {
    rails = {rail}, -- the rail belonging to this signal
    position = placement.pos, -- position of the signal
    direction = placement.dir, -- direction of the signal
    length = placement.length, -- distance til next signal
    twin_signal = nil, -- the signal at the other end of the rail
    can_be_used = {front=nil, back=nil}, -- if this belongs to a chain of signals that is used
    signals_front = {}, -- signals when going forwards on this signal
    signals_back = {}, -- signals when going backwards on this signal
    rail_direction = rail_direction, --left/right, the direction this signal is going
    start_signal = nil, -- if this signal is the start of a chain
    end_signal = nil, -- if this signal is the end of a chain
    signal_entity = nil, -- the entity at the signal
    distance_til_next_regular_signal = 0, -- the distance until we can place a next regular signal
    closest_overlap_front = 10000, -- distance to first overlapping rails
    closest_overlap_back = 10000, -- distance from last overlapping rails
  }
  return signals[unique_id], false
end

local function link_signals(back, front)
  if not contains(back.signals_back, front) then
    table.insert(back.signals_back, front)
  end
  if not contains(front.signals_front, back) then
    table.insert(front.signals_front, back)
  end
end

local function twin_signals(signal1, signal2)
  signal1.twin_signal = signal2
  signal2.twin_signal = signal1
end

local function connect_rail(rail, signals, rails)
  local entity_id = entity_id(rail)
  rail = rails[entity_id]
  if not rail then return end
  local signal_placements = get_signal_placements(rail.entity)
  local front_left, already_visited = create_table_entry(signals, rail, signal_placements.front.left, "left")
  local front_right, _ = create_table_entry(signals, rail, signal_placements.front.right, "right")
  local back_left
  local back_right
  if signal_placements.back then
    back_left, _ = create_table_entry(signals, rail, signal_placements.back.left, "left")
    back_right, _ = create_table_entry(signals, rail, signal_placements.back.right, "right")
    link_signals(back_right, front_right)
    link_signals(back_left, front_left)
    twin_signals(back_left, front_right)
    twin_signals(back_right, front_left)
  else
    back_left = front_left
    back_right = front_right
    twin_signals(front_left, front_right)
  end
  if already_visited then
    return {back_left = back_left, back_right = back_right, front_left = front_left, front_right = front_right}
  end
  for _, rail_connection_direction in pairs({"left", "straight", "right"}) do
    local connected_rail_front = rail.entity.get_connected_rail{rail_direction=defines.rail_direction.front, rail_connection_direction=defines.rail_connection_direction[rail_connection_direction]}
    local connected_rail_back = rail.entity.get_connected_rail{rail_direction=defines.rail_direction.back, rail_connection_direction=defines.rail_connection_direction[rail_connection_direction]}

    if connected_rail_front then
      local connections = connect_rail(connected_rail_front, signals, rails)
      if connections then
        if should_switch(rail.entity, connected_rail_front) then
          link_signals(connections.front_right, back_left)
          link_signals(front_right, connections.back_left)
        else
          link_signals(connections.front_left, back_left)
          link_signals(front_right, connections.back_right)
        end
      end
    end
    if connected_rail_back then
      local connections = connect_rail(connected_rail_back, signals, rails)
      if connections then
        if should_switch(connected_rail_back, rail.entity) then
          link_signals(connections.front_left, back_right)
          link_signals(front_left, connections.back_right)
        else
          link_signals(connections.front_right, back_right)
          link_signals(front_left, connections.back_left)
        end
      end
    end
  end
  return {back_left = back_left, back_right = back_right, front_left = front_left, front_right = front_right}
end

local function init_signals(signals, rails)
  for _, rail in pairs(rails) do
    connect_rail(rail.entity, signals, rails)
  end
end

local function init_rails(entities, surface)
  local rails = {}
  for _, entity in pairs(entities) do
    if entity.type == "straight-rail" or entity.type == "curved-rail" then
      rails[entity_id(entity)] = {entity=entity}
    end
  end
  return rails
end

local function draw_pretty_stuff(signals, rails, surface)
  for _, signal in pairs(signals) do
    rendering.draw_text{color={0, 1, 0}, text=signal.length, target=signal.position, surface=surface, time_to_live=600}
    rendering.draw_line{color={0, 1, 0}, width=1, from=signal.twin_signal.position, to=signal.position, surface=surface, time_to_live=600}
    for _, front_signal in pairs(signal.signals_back) do
      rendering.draw_line{color={1, 1, 0}, width=1, from=signal.position, to=front_signal.position, surface=surface, time_to_live=600}
      rendering.draw_circle{color={1, 0, 0}, radius=0.3, width=2, target=signal.position, surface=surface, time_to_live=600}
      rendering.draw_circle{color={0, 0, 1}, radius=0.2, filled=true, target=front_signal.position, surface=surface, time_to_live=600}
    end
  end
end

local function create_signal_chain(entities, player)
  local signals = {}
  local rails = init_rails(entities, player.surface)
  init_signals(signals, rails)
  --draw_pretty_stuff(signals, rails, player.surface)
  return signals, rails
end
return create_signal_chain