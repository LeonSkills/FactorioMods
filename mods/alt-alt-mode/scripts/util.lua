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

return {
  number_length = number_length,
  localise_number = localise_number,
  box_center = box_center,
  rotate_around_point = rotate_around_point,
  fill_grid_with_largest_square = fill_grid_with_largest_square,
}
