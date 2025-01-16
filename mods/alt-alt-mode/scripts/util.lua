local function log(...)
  print(game.tick, "Alternative Alt Mode", ...)
end

local function get_target_offset(index, shift, x_scale, y_scale, num_columns, num_rows, separation_multiplier, y_centered)
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

local function get_order(str, proto_type)
  if proto_type then
    local prototype = prototypes[proto_type][str]
    return prototype.group.order .. "-" .. prototype.subgroup.order .. "-" .. prototype.order
  end
  for _, type in pairs({"item", "fluid", "entity", "virtual_signal", "recipe", "technology"}) do
    if prototypes[type][str] then
      local prototype = prototypes[type][str]
      return prototype.group.order .. "-" .. prototype.subgroup.order .. "-" .. prototype.order
    end
  end
end

local function sort_inventory(inventory_contents)
  table.sort(inventory_contents, function(s1, s2)
    if s1.count == s2.count then
      local order1 = get_order(s1.name, s1.type)
      local order2 = get_order(s2.name, s1.type)
      if order1 == order2 then
        return prototypes.quality[s1.quality].order < prototypes.quality[s2.quality].order
      end
      return order1 < order2
    end
    return s1.count > s2.count
  end)
end

local function fill_grid_with_largest_square(width, height, num_items)
  if width <= 0 or height <= 0 then
    return 0, 0, 1
  end
  width = width * 0.9
  height = height * 0.9
  -- Compute number of rows and columns, and cell size
  local ratio = width / height
  local ideal_num_columns = math.sqrt(num_items * ratio)
  local ideal_num_rows = num_items / ideal_num_columns

  local num_rows_1 = math.ceil(ideal_num_rows)
  local num_columns_1 = math.ceil(num_items / num_rows_1)
  while (num_rows_1 * ratio < num_columns_1) do
    num_rows_1 = num_rows_1 + 1;
    num_columns_1 = math.ceil(num_items / num_rows_1)
  end
  local cell_size_1 = height / num_rows_1

  -- Find best option filling the whole width
  local num_columns_2 = math.ceil(ideal_num_columns)
  local num_rows_2 = math.ceil(num_items / num_columns_2)
  while (num_columns_2 < num_rows_2 * ratio) do
    num_columns_2 = num_columns_2 + 1
    num_rows_2 = math.ceil(num_items / num_columns_2)
  end
  local cell_size_2 = width / num_columns_2

  -- Find the best values
  if cell_size_1 <= cell_size_2 then
    return num_columns_2, num_rows_2, cell_size_2
  else
    return num_columns_1, num_rows_1, cell_size_1
  end
end

local function number_length(num)
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
local function localise_number(num)
  if num == 0 then return "0" end
  local negative = num < 0 and "-" or ""
  num = math.abs(num)
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

local function box_center(bounding_box)
  local x = bounding_box.right_bottom.x - (bounding_box.right_bottom.x - bounding_box.left_top.x) / 2
  local y = bounding_box.right_bottom.y - (bounding_box.right_bottom.y - bounding_box.left_top.y) / 2
  return {x = x, y = y}
end

local function rotate_around_point(point, center, orientation)
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
local function compare_versions(version1, version2)
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

local function contains(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

return {
  log                           = log,
  contains                      = contains,
  number_length                 = number_length,
  localise_number               = localise_number,
  box_center                    = box_center,
  rotate_around_point           = rotate_around_point,
  fill_grid_with_largest_square = fill_grid_with_largest_square,
  get_target_offset             = get_target_offset,
  compare_versions              = compare_versions,
  sort_inventory                = sort_inventory,
}
-- "alt-alt-entity-info-white-background"