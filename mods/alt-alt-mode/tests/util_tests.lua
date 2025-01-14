local function assert_close(num1, num2, message)
  return assert(math.abs(num1 - num2) <= 0.0001, message)
end

local function assert_equal_position(pos1, pos2, message)
  local x1 = pos1.x or pos1[1]
  local x2 = pos2.x or pos2[1]
  local y1 = pos1.y or pos1[2]
  local y2 = pos2.y or pos2[2]
  assert_close(x1, x2, message)
  assert_close(y1, y2, message)
end

local function assert_equal_array(arr1, arr2, message)
  for i, _ in pairs(arr1) do
    assert_close(arr1[i], arr2[i], message)
  end
end



return {
  assert_close          = assert_close,
  assert_equal_position = assert_equal_position,
  assert_equal_array    = assert_equal_array,
}