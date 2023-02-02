require("scripts/rail_utility")
require("scripts/utility")
require("scripts/objects/rail")

local inbound_signals = {}
local outbound_signals = {}
local inbound_signals_to_check = {}
local outbound_signals_to_check = {}

local function debug()
  -- draw the connections between each signal (twin, front and back signals)
  for _, rail in pairs(Rail.all_rails) do
    rail:debug_connections()
  end
end

local function rail_length(connected_rail)
  -- Return the approximate length of a rail.
  -- Used to check how far back the rails should be checked for potential exits
  -- This is an approximation!
  if connected_rail.type == "curved-rail" then return 9 end
  return 2
end

local function add_block(rail, player, distance_so_far)
  -- Add all rails that are in this block to the network
  if not rail.valid then return end
  -- Gets all rails in all blocks in initial_rails
  local rails_to_check = {rail}
  -- First, we get all rails in the block of the initial rails
  local block_distance = distance_so_far or 0
  local has_branches_or_overlaps = false -- This is used to truncate backward long stretches
  while #rails_to_check > 0 do
    local current_rail = table.remove(rails_to_check, 1)
    if not current_rail.valid then goto continue end
    local id = entity_id(current_rail)
    if Rail.all_rails[id] then goto continue end
    Rail:new(current_rail, player)
    block_distance = block_distance + rail_length(rail)
    local connections_found = false
    for _, connected_rail in pairs(rail_connected_rails(current_rail)) do
      if not Rail.all_rails[entity_id(connected_rail)] then
        if connected_rail.is_rail_in_same_rail_block_as(current_rail) then
          if connections_found then
            has_branches_or_overlaps = true
          end
          connections_found = true
          table.insert(rails_to_check, connected_rail)
        end
      end
    end
    for _, overlap in pairs(current_rail.get_rail_segment_overlaps()) do
      has_branches_or_overlaps = true
      if not Rail.all_rails[entity_id(overlap)] and overlap.is_rail_in_same_rail_block_as(current_rail) then
        table.insert(rails_to_check, overlap)
      end
    end
    ::continue::
  end
  block_distance = has_branches_or_overlaps and 0 or block_distance
  -- Then we get all in and outbound signals. We check later if blocks have to be added after the outbound signals
  for _, signal in pairs(rail.get_inbound_signals()) do
    local id = entity_id(signal)
    if not inbound_signals[id] then
      inbound_signals[id] = signal
      table.insert(inbound_signals_to_check, signal)
    end
  end
  for _, signal in pairs(rail.get_outbound_signals()) do
    local id = entity_id(signal)
    if not outbound_signals[id] then
      outbound_signals[id] = signal
      table.insert(outbound_signals_to_check, {signal, block_distance})
    end
  end
end

local function initialize_rails(initial_rails, player)
  -- For the selected rails, add all blocks to the network
  for _, rail in pairs(initial_rails) do
    add_block(rail, player, max_train_length)
  end
end

local function add_rail_up_to_signal(signal, player, direction)
  -- If the rail is not part of the network yet, then we add it, but remove last two connections
  local is_front = direction == "front"
  for _, rail in pairs(signal.get_connected_rails()) do
    local id = entity_id(rail)
    if Rail.all_rails[id] then goto continue end
    local rail = Rail:new(rail, player)
    local signal_obj = Signal.all_signals[create_unique_id(signal.position, signal.direction)]
    for dir, _ in pairs(rail.signals) do
      for side, rail_signal in pairs(rail.signals[dir]) do
        if rail_signal ~= signal_obj and rail_signal ~= signal_obj.twin then
          for _, back_signal in pairs(is_front and rail_signal.signals_back or rail_signal.signals_front) do
            if back_signal == signal_obj then
              remove(is_front and signal_obj.signals_front or signal_obj.signals_back, rail_signal)
              remove(is_front and signal_obj.twin.signals_back or signal_obj.twin.signals_front, rail_signal.twin)
              remove(is_front and rail_signal.signals_back or rail_signal.signals_front, signal_obj)
              remove(is_front and rail_signal.twin.signals_front or rail_signal.twin.signals_back, signal_obj.twin)
              rail_signal.invalid = true
              rail_signal.twin.invalid = true
              rail.broken_up = true
              goto continue
            end
          end
        end
      end
    end
    ::continue::
  end
end

function add_blocks_at_signal(signal, player, distance_so_far)
  -- Add all blocks before and after a signal to the network
  for _, rail in pairs(signal.get_connected_rails()) do
    local id = entity_id(rail)
    if Rail.all_rails[id] then
      for _, connected_rail in pairs(rail_connected_rails(rail)) do
        add_block(connected_rail, player, distance_so_far or 0)
      end
    else
      add_block(rail, player, distance_so_far or 0)
    end
  end
end

local function add_neighbouring_blocks(player)
  -- For inbound signals, add the rail the signal is attached to to the network
  -- For outbound signals, add the blocks after it to the network if there might be exits to check,
  -- otherwise add only the rail the signal is attached to to the network
  while #outbound_signals_to_check > 0 or #inbound_signals_to_check > 0 do
    while #outbound_signals_to_check > 0 do
      local outbound_signal = table.remove(outbound_signals_to_check, 1)
      local signal = outbound_signal[1]
      local previous_distance = outbound_signal[2]
      local planner = Rail.planners[signal.get_connected_rails()[1].name]
      if not planner then
        planner = "rail"
      end
      if signal.type == "rail-chain-signal" or previous_distance > Signal.settings.train_length[planner] then
        add_rail_up_to_signal(signal, player, "front")
      else
        add_blocks_at_signal(signal, player, previous_distance)
      end
    end
    while #inbound_signals_to_check > 0 do
      local signal = table.remove(inbound_signals_to_check, 1)
      add_rail_up_to_signal(signal, player, "back")
      local parents = signal.get_parent_signals()
      local has_parents = false
      for _, parent in pairs(parents) do
        local parent_id = entity_id(parent)
        if not outbound_signals[parent_id] and not inbound_signals[parent_id] then
          has_parents = true
        end
      end
      if has_parents then
        Signal.all_signals[create_unique_id(signal.position, signal.direction)].is_exit = true
      end
    end
  end
end

local function revive_ghost_signals()
  for _, signal in pairs(Signal.all_signals) do
    if signal.original_signal and signal.original_signal.is_ghost then
      local _, entity, _ = signal.current_signal.silent_revive{raise_revive=false}
      signal.current_signal = entity
    end
  end
end

local function build_graph(initial_rails, player, debug_rails)
  -- Create a network of signals that might influence the given initial rails
  -- Assumes blocks adjacent to this network are already correctly signalled
  initialize_rails(initial_rails, player)
  add_neighbouring_blocks(player)
  revive_ghost_signals()
  if debug_rails then
    debug()
  end
  inbound_signals = {}
  outbound_signals = {}
  inbound_signals_to_check = {}
  outbound_signals_to_check = {}
end

return build_graph