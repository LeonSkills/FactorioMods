
local util = {}

util.log = function(...)
  print(game.tick, "Alternative Alt Mode", ...)
end

util.print = function(tbl)
  game.print(serpent.line(tbl))
end


util.get_entity_type = function(entity)
  if entity.type =="entity-ghost" then
    return entity.ghost_type
  end
  return entity.type
end

util.get_entity_name = function(entity)
  if entity.name =="entity-ghost" then
    return entity.ghost_name
  end
  return entity.name
end

util.get_entity_prototype = function(entity)
  if entity.type == "entity-ghost" then
    return entity.ghost_prototype
  end
  return entity.prototype
end

util.get_target_offset = function(index, shift, x_scale, y_scale, num_columns, num_rows, separation_multiplier, y_centered)
  if index > num_columns * num_rows then return end
  local column = (index - 1) % num_columns + 1
  local row = math.ceil(index / num_columns)
  local x = (column - (num_columns + 1) / 2) * separation_multiplier * x_scale + shift[1]
  local y
  if y_centered then
    y = (row - (num_rows + 1) / 2) * separation_multiplier * y_scale + shift[2]
  else
    y = (row - 1) * separation_multiplier * y_scale + shift[2]
  end
  return {x = x, y = y}
end

util.arctan_clockwise = function(point1, point2)
  if point1.x == point2.x then
    return (point1.y -point2.y) > 0 and 0 or 0.5
  end
  if point1.y == point2.y then
    return (point1.x -point2.x) > 0 and 0.75 or 0.25
  end
  return math.atan((point1.x - point2.x) / (point1.y - point2.y)) / (2 * math.pi)
end

util.get_order = function(str, proto_type)
  if proto_type then
    proto_type = (proto_type == "virtual") and "virtual_signal" or proto_type
    local prototype = prototypes[proto_type][str]
    if not prototype then
      return "zzz"
    end
    return prototype.group.order .. "-" .. prototype.subgroup.order .. "-" .. prototype.order
  end
  for _, type in pairs({"item", "fluid", "entity", "virtual_signal", "recipe", "technology"}) do
    if prototypes[type][str] then
      local prototype = prototypes[type][str]
      return prototype.group.order .. "-" .. prototype.subgroup.order .. "-" .. prototype.order
    end
  end
end

util.sort_inventory = function(inventory_contents)
  table.sort(inventory_contents, function(s1, s2)
    if s1.count == s2.count then
      local order1 = util.get_order(s1.name, s1.type)
      local order2 = util.get_order(s2.name, s2.type)
      if order1 == order2 then
        return prototypes.quality[s1.quality].order < prototypes.quality[s2.quality].order
      end
      return order1 < order2
    end
    return s1.count > s2.count
  end)
end

util.number_length = function(num)
  if num == 0 then return 1 end
  local length = 0
  if num < 0 then
    length = length + 1
  end
  num = math.abs(num)
  local prefix_index = math.floor(math.log10(num) / 3)
  if prefix_index > 0 then
    length = length + 1
  end
  num = num / math.pow(10, prefix_index * 3)
  if num < 100 then
    num = string.sub(num, 1, 4)
  else
    num = string.sub(num, 1, 3)
  end
  return length + num:len()
end

local si_prefixes = {"kilo", "mega", "giga", "tera", "peta", "exa", "zetta", "yotta", "ronna", "quetta"}
util.localise_number = function(num)
  if num == 0 then return "0" end
  local negative = num < 0 and "-" or ""
  num = math.abs(num)
  if num < 1 then
    return {"", negative, string.sub(num, 1, 4)}
  end
  local prefix_index = math.floor(math.log10(num) / 3)
  local localised_prefix = ""
  if prefix_index > #si_prefixes then
    localised_prefix = "e" .. prefix_index * 3
  end
  if prefix_index > 0 then
    local prefix = si_prefixes[prefix_index]
    localised_prefix = prefix and {"si-prefix-symbol-" .. prefix} or ""
  end
  num = num / math.pow(10, prefix_index * 3)
  if num < 100 then
    return {"", negative, string.sub(num, 1, 4), localised_prefix}
  end
  return {"", negative, string.sub(num, 1, 3), localised_prefix}
end

util.box_center = function(bounding_box)
  local x = bounding_box.right_bottom.x - (bounding_box.right_bottom.x - bounding_box.left_top.x) / 2
  local y = bounding_box.right_bottom.y - (bounding_box.right_bottom.y - bounding_box.left_top.y) / 2
  return {x = x, y = y}
end

util.rotate_around_point = function(point, center, orientation)
  if orientation == 0 then return end
  local angle = orientation * math.pi * 2
  local sin = math.sin(angle)
  local cos = math.cos(angle)
  point.x = point.x - center.x
  point.y = point.y - center.y

  local x_new = point.x * cos - point.y * sin
  local y_new = point.x * sin + point.y * cos

  point.x = x_new + center.x
  point.y = y_new + center.y
end

-- Function to compare two semantic version strings
util.compare_versions = function(version1, version2)
  -- Quick check if they are equal
  if version1 == version2 then
    return 0
  end
  -- Split a version string into its components
  local function split_version(version)
    local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)$")
    return tonumber(major), tonumber(minor), tonumber(patch)
  end

  -- Extract major, minor, and patch for both versions
  local major1, minor1, patch1 = split_version(version1)
  local major2, minor2, patch2 = split_version(version2)

  -- Compare major versions
  if major1 ~= major2 then
    return major1 > major2 and 1 or -1
  end

  -- Compare minor versions
  if minor1 ~= minor2 then
    return minor1 > minor2 and 1 or -1
  end

  -- Compare patch versions
  if patch1 ~= patch2 then
    return patch1 > patch2 and 1 or -1
  end

  -- Versions are equal
  return 0
end

util.contains = function(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

return util