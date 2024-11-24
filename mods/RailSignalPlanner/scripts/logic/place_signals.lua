local function debug()
  -- Draw for each signal position if a signal entity has been placed
  for _, signal in pairs(Signal.all_signals) do
    signal:debug_current_signal()
  end
end

local function place_signals(debug_rails)
  -- place signals everywhere possible. This makes it easier to check for overlaps later
  for _, signal in pairs(Signal.all_signals) do
    if signal.original_signal then
      signal:place_signal_everywhere()
    end
  end
  for _, signal in pairs(Signal.all_signals) do
    signal:place_signal_everywhere()
  end
  if debug_rails then
    debug()
  end
end

return place_signals