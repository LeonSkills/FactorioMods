require("scripts/utility")

local function get_signals(entities)
  local signals = {}
  for _, entity in pairs(entities) do
    if entity.type == "rail-signal" or entity.type == "rail-chain-signal" then
      table.insert(signals, entity)
    end
  end
  return signals
end

local function mark_signal(signal, direction)
  if signal.can_be_used[direction] == nil then
    signal.can_be_used[direction] = true
    if direction == "front" then
      for _, front_signal in pairs(signal.signals_front) do
        mark_signal(front_signal, direction)
      end
   elseif direction == "back" then
      for _, back_signal in pairs(signal.signals_back) do
        mark_signal(back_signal, direction)
      end
    end
  end
end

local function save_signal(signal_info, signal)
  -- save the data of the original signal
  signal_info.original_signal = {
    name = signal.name,
    health = signal.health,
    surface = signal.surface
  }
end


local function mark_rails(signals, signal_chain, surface, alt_mode)
  for _, signal in pairs(signals) do
    local signal_id = create_unique_id(signal.position, signal.direction)
    local signal_info = signal_chain[signal_id]
    if signal_info then
      save_signal(signal_info, signal)
      local twin_signal = {}
      local twin = signal_info.twin_signal
      if not alt_mode then
        -- if there is a signal at its twin spot, then don't do anything
        twin_signal = surface.find_entities_filtered{position=twin.position, type={"rail-signal", "rail-chain-signal"}, force=signal.force}
      end
      if #twin_signal == 0 or twin_signal[1].direction ~= twin.direction then
        mark_signal(signal_info, "front")
        mark_signal(signal_info, "back")
      end
    else
      signal_chain[signal_id] = {
        rails = {}, -- the rail belonging to this signal
        position = signal.position, -- position of the signal
        direction = signal.direction, -- direction of the signal
        twin_signal = nil, -- the signal at the other end of the rail
        can_be_used = {front=nil, back=nil}, -- if this belongs to a chain of signals that is used
        signals_back = {}, -- signals when going backwards on this signal
        signals_front = {}, -- signals when going forwards on this signal
        rail_direction = nil, --left/right, the direction this signal is going
        start_signal = nil, -- if this signal is the start of a chain
        end_signal = nil, -- if this signal is the end of a chain
        signal_entity = nil, -- the entity at the signal
        distance_til_next_regular_signal = 0, -- the distance until we can place a next regular signal
        closest_overlap_front = 10000, -- distance to first overlapping rails
        closest_overlap_back = 10000, -- distance from last overlapping rails
      }
      signal_chain[signal_id].twin_signal = signal_chain[signal_id]
      save_signal(signal_chain[signal_id], signal)
    end
  end
  -- finalize them
  for _, signal in pairs(signal_chain) do
    if signal.can_be_used.front == true or signal.can_be_used.back == true then
      signal.can_be_used = true
    else
      signal.can_be_used = false
    end
  end
  for _, signal in pairs(signal_chain) do
    if signal.can_be_used == false and signal.twin_signal.can_be_used == false then
      signal.can_be_used = true
      signal.twin_signal.can_be_used = true
    end
  end
end

local function draw_pretty_stuff(signals, surface)
  for _, signal in pairs(signals) do
    if signal.can_be_used then
      rendering.draw_circle{color={0, 1, 0}, radius=0.3, width=2, target=signal.position, surface=surface, time_to_live=600}
    else
      rendering.draw_circle{color={1, 0, 0}, radius=0.3, width=2, target=signal.position, surface=surface, time_to_live=600}
    end
  end
end

local function mark_rail_direction(signal_chain, entities, player, alt_mode)
  local signals = get_signals(entities)
  mark_rails(signals, signal_chain, player.surface, alt_mode)
  --draw_pretty_stuff(signal_chain, player.surface)
  return signals
end

return mark_rail_direction