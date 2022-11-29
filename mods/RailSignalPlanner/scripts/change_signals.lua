require("scripts/settings")

local function mark_overlaps(rails)
  for _, rail in pairs(rails) do
    rail.num_overlaps = #rail.entity.get_rail_segment_overlaps()
  end
end

local function overlaps(signal)
  -- if the rails at this signal have overlapping rails
  for _, rail in pairs(signal.rails) do
    if rail.num_overlaps > 0 then
      return true
    end
  end
  return false
end

local function change_signal(signal, signal_type, player)
  local signal_entity = signal.signal_entity
  if not signal_entity or not signal_entity.valid then return end
  if signal_type == nil then
    signal_entity.destroy{raise_built=false}  -- no need to raise, is always dummy signal
    signal.signal_entity = nil
    if signal.twin_signal.signal_entity then
      change_signal(signal.twin_signal, nil, player)
    end
  end
  signal.final_entity_type = signal_type
end

local function get_prev_signals(signal, visited_signals)
  if not visited_signals then
    visited_signals = {}
  end
  if contains(visited_signals, signal) then
    signal.prev_signals = {}
    return {}
  end
  table.insert(visited_signals, signal)

  if signal.signal_entity then return {signal} end
  if signal.prev_signals then return signal.prev_signals end
  local prev_signals = {}
  for _, back_signal in pairs(signal.signals_back) do
    local back_prev_signals = get_prev_signals(back_signal, visited_signals)
    for _, back_prev_signal in pairs(back_prev_signals) do
      table.insert(prev_signals, back_prev_signal)
    end
  end
  signal.prev_signals = prev_signals
  return prev_signals
end

local function get_next_signals(signal, visited_signals)
  if not visited_signals then
    visited_signals = {}
  end
  if contains(visited_signals, signal) then
    signal.next_signals = {}
    return {}
  end
  table.insert(visited_signals, signal)
  if signal.signal_entity then return {signal} end
  if signal.next_signals then return signal.next_signals end
  local next_signals = {}
  for _, front_signal in pairs(signal.signals_front) do
    local front_next_signals = get_next_signals(front_signal, visited_signals)
    for _, front_next_signal in pairs(front_next_signals) do
      table.insert(next_signals, front_next_signal)
    end
  end
  signal.next_signals = next_signals
  return next_signals
end


local function mark_closest_overlap_front(signal, front, max_train_length)
  if signal.closest_overlap_front <= front then return end
  signal.closest_overlap_front = front
  if front > max_train_length then return end
  for _, front_signal in pairs(signal.signals_front) do
    mark_closest_overlap_front(front_signal, front + signal.length, max_train_length) -- TODO, base it on rail length
  end
end
local function mark_closest_overlap_back(signal, back, max_train_length)
  if signal.closest_overlap_back <= back then return end
  signal.closest_overlap_back = back
  if back >= max_train_length then return end
  for _, front_signal in pairs(signal.signals_back) do
    mark_closest_overlap_back(front_signal, back + signal.length, max_train_length) -- TODO, base it on rail length
  end
end

local function mark_closest_overlaps(signal, player)
  if signal.overlap_updated then return end
  signal.overlap_updated = true
  local max_train_length = get_setting("train_length", player)
  for _, rail in pairs(signal. rails) do
    if rail.num_overlaps > 0 then
      mark_closest_overlap_front(signal, 0, max_train_length)
      mark_closest_overlap_back(signal, 0, max_train_length)
    end
  end
end

local function change_to_chain(signal, distance_left, player, first)
  if distance_left <= 0 then
    return
  end
  if signal.signal_entity then
    if first then
      first = false
    else
      change_signal(signal, "rail-chain-signal", player)
    end
  end
  for _, next_signal in pairs(signal.signals_front) do
    change_to_chain(next_signal, distance_left - signal.length, player, first) -- TODO, base on rail length
  end
end

local function mark_entrance(signal)
  signal.is_entrance = true
end

local function mark_exit(signal)
  signal.is_exit = true
end


local function mark_entrances(signal_chain)
  for _, signal in pairs(signal_chain) do
    for _, rail in pairs(signal.rails) do
      if rail.num_overlaps > 0 then
        -- change previous signals to chain
        local prev_signals = get_prev_signals(signal)
        for _, prev_signal in pairs(prev_signals) do
          local tmp = #prev_signal.signals_front > 0
          for _, next_signal in pairs(prev_signal.signals_front) do
            if next_signal.closest_overlap_front > signal.closest_overlap_front then
              tmp = false
            end
          end
          if tmp then
            mark_entrance(prev_signal)
          end
        end
        local next_signals = get_next_signals(signal)
        for _, next_signal in pairs(next_signals) do
          mark_exit(next_signal)
        end
      end
    end
  end
end

local function clear_exit(signal, player, distance_left, visited_signals)
  if not visited_signals then
    visited_signals = {}
  end
  if contains(visited_signals, signal) then
    signal.prev_signals = {}
    return false
  end
  table.insert(visited_signals, signal)
  if signal.closest_next_exit then return signal.closest_next_exit end
  if distance_left <= 0 then return false end
  --local closest_next_exit = 10000
  local should_remove = false
  for _, next_signal in pairs(signal.signals_front) do
    if next_signal.signal_entity and not next_signal.is_exit and not next_signal.is_entrance and not next_signal.twin_signal.signal_entity then
      change_signal(next_signal, nil, player)
    end
    if (next_signal.is_entrance or next_signal.is_exit) then
      return true -- should remove the exit
    end
    local should_remove_exit = clear_exit(next_signal, player, distance_left - signal.length, visited_signals)
    should_remove = should_remove or should_remove_exit
  end
  signal.should_remove = should_remove
  return should_remove
end

local function change_signal_based_on_entrance(signal_chain, player)
  local max_train_length = get_setting("train_length", player)
  for _, signal in pairs(signal_chain) do
    if signal.is_entrance then
      change_signal(signal, "rail-chain-signal", player)
    end
    if signal.is_exit and not signal.is_entrance then
      local should_remove = clear_exit(signal, player, max_train_length)
      if should_remove then
        change_signal(signal, nil, player)
      end
    end
  end
end

local function find_start(signal, start_signal, first)
  if signal.start_signal then return signal.start_signal end
  -- finds the start of a long stretch
  local start
  if signal.is_exit or (signal == start_signal and not first) then
    start = signal
  elseif signal.signal_entity and overlaps(signal) then
    start = signal
  elseif #signal.signals_back == 0 then
    if signal.signal_entity then
      start = signal
    else
      start = nil
    end
  else
    local back_start = find_start(signal.signals_back[1], start_signal, false)
    if back_start then
      start = back_start
    elseif signal.signal_entity then
      start = signal
    else
      start = nil
    end
  end
  signal.start_signal = start
  return start
end

local function clear_front(signal, player, separation, max_separation, first_signal)
  if signal == first_signal then return end
  if not first_signal then
    first_signal = signal
  end
  if signal.was_cleared_front then return end
  if signal.closest_next_exit and signal.closest_next_exit < max_separation then return end
  if signal.is_exit or signal.is_entrance then return end
  if overlaps(signal) then return end
  if signal.signal_entity then
    if signal.signal_entity.type ~= "rail-chain-signal" then
      if separation > 0 then
        change_signal(signal, nil, player)
      else
        separation = max_separation
      end
    else
      return
    end
  end
  for _, signal_next in pairs(signal.signals_front) do
    clear_front(signal_next, player, separation - signal.length, max_separation, first_signal)
  end
end

local function clear_fronts(signal, player, separation)
  local start_signal = find_start(signal, signal, true)
  if start_signal.visited_clear_fronts then
    return
  end
  start_signal.visited_clear_fronts = true
  for _, signal_next in pairs(start_signal.signals_front) do
    clear_front(signal_next, player, separation - start_signal.length, separation)
  end
end

local function change_signal_on_long_stretches(signal_chain, player)
  -- on long stretches we don't place any signal if the distance between previous is too small (setting)
  -- or if the rail is bidirectional
  local separation = get_setting("rail_signal_distance", player)
  for _, signal in pairs(signal_chain) do
    if signal.signal_entity and not overlaps(signal) then
      if signal.twin_signal.signal_entity then
        if not signal.is_exit and not signal.is_entrance and not signal.twin_signal.is_exit and not signal.twin_signal.is_entrance then
          change_signal(signal, nil, player)
          change_signal(signal.twin_signal, nil, player)
        end
      else --  a signal on a long stretch
        clear_fronts(signal, player, separation)
      end
    end
  end
end

local function draw_pretty_stuff(rails, signal_chain, player)
  for _, rail in pairs(rails) do
    rendering.draw_text{color={1, 0, rail.entity.direction/8}, text = rail.num_overlaps, target=rail.entity, target_offset={(rail.entity.direction-4)/4, 0}, time_to_live=600, surface=rail.entity.surface}
  end
  for _, signal in pairs(signal_chain) do
    if signal.is_exit then
      rendering.draw_circle{color={1, 0, 0}, radius=0.2, target=signal.position, time_to_live=600, surface=player.surface}
    end
    if signal.is_entrance then
      rendering.draw_circle{color={0, 1, 0}, radius=0.3, target=signal.position, time_to_live=600, surface=player.surface}
    end
    local pos_front = {x=signal.position.x + 0.2, y = signal.position.y}
    local pos_back = {x=signal.position.x - 0.2, y = signal.position.y}
    --rendering.draw_text{color={0, 1, 0}, text = signal.closest_overlap_front, target=pos_front, time_to_live=600, surface=player.surface}
    --rendering.draw_text{color={1, 0, 0}, text = signal.closest_overlap_back, target=pos_back, time_to_live=600, surface=player.surface}
  end
end

local function change_signals(rails, signal_chain, player)
  mark_overlaps(rails)
  for _, signal in pairs(signal_chain) do
    mark_closest_overlaps(signal, player)
  end
  mark_entrances(signal_chain)
  change_signal_based_on_entrance(signal_chain, player)
  change_signal_on_long_stretches(signal_chain, player)


  --draw_pretty_stuff(rails, signal_chain, player)

end

return change_signals