require("scripts/settings")

-- finding and marking overlaps functions

local function mark_overlaps()
  for _, rail in pairs(Rail.all_rails) do
    rail:mark_overlap()
  end
end

-- marking exits-entrances functions


local function mark_entrances()
  for _, signal in pairs(Signal.all_signals) do
    signal:check_if_entrance()
    signal:check_if_exit()
  end
end

--clear exit functions

local function change_signal_based_on_entrance(player)
  for _, signal in pairs(Signal.all_signals) do
    if signal.is_entrance and signal.current_signal then
      signal:change_signal("rail-chain-signal")
    end
    if signal.is_exit and not signal.is_entrance then
      signal:clear_exit()
    end
  end
end


local function change_signal_on_long_stretches(player)
  -- on long stretches we don't place any signal if the distance between previous is too small (setting)
  -- or if the rail is bidirectional
  local original_signals_to_check = {}
  local entrances_to_check = {}
  local other_signals_to_check = {}
  for _, signal in pairs(Signal.all_signals) do
    if signal.current_signal then
      if signal.original_signal then
        table.insert(original_signals_to_check, signal)
      elseif signal.is_entrance then
        table.insert(entrances_to_check, signal)
      elseif signal.current_signal then
        table.insert(other_signals_to_check, signal)
      end
    end
  end
  for _, signal in pairs(entrances_to_check) do
    for _, back_signal in pairs(signal.signals_back) do
      back_signal:clean_up_long_stretch("back", back_signal.rail_signal_distance - back_signal.length)
    end
  end
  for _, signal in pairs(original_signals_to_check) do
    signal:clean_up_long_stretch("front")
    signal:clean_up_long_stretch("back")
  end
  for _, signal in pairs(other_signals_to_check) do
    if not signal.visited_clean_up_long["front"] and not signal.visited_clean_up_long["back"] then
      local exit_signal = signal:find_exit()
      exit_signal:clean_up_long_stretch("front")
    end
  end
end

-- debugging functions
local function debug()
  for _, rail in pairs(Rail.all_rails) do
    rail:debug_overlaps()
  end
  for _, signal in pairs(Signal.all_signals) do
    signal:debug_entrances()
  end
end


-- method to call
local function change_signals(player, debug_rails)
  mark_overlaps()
  mark_entrances()
  change_signal_based_on_entrance(player)
  change_signal_on_long_stretches(player)
  if debug_rails then
    debug()
  end

end

return change_signals