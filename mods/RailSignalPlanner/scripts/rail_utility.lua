function equal_pos(pos1, pos2)
  return pos1.x == pos2.x and pos1.y == pos2.y
end

function rail_connected_rails(rail)
  -- get all rails connected to this rail
  local connected_rails = {}
  for _, connection_direction in pairs({"left", "straight", "right"}) do
    for _, rail_direction in pairs(defines.rail_direction) do
      local connected_rail = rail.get_connected_rail {rail_direction = rail_direction, rail_connection_direction = defines.rail_connection_direction[connection_direction]}
      if connected_rail then
        table.insert(connected_rails, connected_rail)
      end
    end
  end
  return connected_rails
end

function rail_length(rail)
  local type = rail.type:gsub("elevated%-", "")
  if type == "curved-rail-a" then
    return 5.1322845561  -- 13atan(5/12)
  end
  if type == "curved-rail-b" then
    return 5.077893568 -- 2*pi*13/8 - A
  end
  if type == "half-diagonal-rail" then
    return math.sqrt(20) -- 4.47
  end
  if type == "rail-ramp" then
    return 39.524464324429 -- ??
  end
  if type == "straight-rail" then
    if rail.direction % 2 == 0 then
      return 2
    else
      return 2 * math.sqrt(2)
    end
  end
  if not length then
    error("Unsupported rail type " .. type .. " (" .. rail.type .. ")")
  end

end