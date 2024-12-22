-- type AltSignal
-- signal::Signal
-- use_green::boolean
-- use_red::boolean

local function signal_id(signal)  -- SignalID -> str
  return (signal.type or "item") .. "." .. signal.name .. "." .. (signal.quality or "normal")
end

local function combine_signals(signals)
  -- list[AltSignal]->  list[AltSignal]
  -- only to be used with the array returned by get_circuit_signals
  -- sorts descending by default
  local signals_dict = {}
  for _, signal_data in pairs(signals) do
    local signal = signal_data.signal -- Signal
    local id = signal_id(signal.signal)
    local new_data = signals_dict[id]
    if not new_data then
      new_data = {signal = {signal = signal.signal, count = 0}} -- Signal = [Signal, boolean]
    end
    new_data.signal.count = new_data.signal.count + signal.count
    new_data.use_red = new_data.use_red or signal_data.use_red
    new_data.use_green = new_data.use_green or signal_data.use_green
    signals_dict[id] = new_data
  end
  local signal_list = {}
  for _, signal in pairs(signals_dict) do
    table.insert(signal_list, signal)
  end
  return signal_list
end

local function get_circuit_signals(entity, filter, combine, sort)
  -- -> list[AltSignal]
  local red_circuit = entity.get_circuit_network(defines.wire_connector_id.circuit_red) or {}
  local green_circuit = entity.get_circuit_network(defines.wire_connector_id.circuit_green) or {}
  local signals = {}
  for _, signal in pairs(red_circuit.signals or {}) do
    local signal_type = signal.signal.type
    -- Sometimes Wube doesn't make sense by defaulting type "nil" to "item"
    if filter and (signal_type == filter or (signal_type == nil and filter == "item")) then
      signal.signal.quality = signal.signal.quality or "normal"
      table.insert(signals, {signal = signal, use_red = true})
    end
  end
  for _, signal in pairs(green_circuit.signals or {}) do
    local signal_type = signal.signal.type
    if filter and (signal_type == filter or (signal_type == nil and filter == "item")) then
      signal.signal.quality = signal.signal.quality or "normal"
      table.insert(signals, {signal = signal, use_green = true})
    end
  end
  if combine then
    signals = combine_signals(signals)
  end
  if sort then
    table.sort(signals, function(s1, s2) return s1.signal.count > s2.signal.count end)
  end
  return signals
end


return {
  get_circuit_signals = get_circuit_signals,
}