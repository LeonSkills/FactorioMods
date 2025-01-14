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
    assert(type(arr1[i]) == type(arr2[i]), message)
    if type(arr1[i]) == "number" then
      assert_close(arr1[i], arr2[i], message)
    elseif type(arr1[i]) == "table" then
      assert_equal_array(arr1[i], arr2[i], message)
    else
      assert(arr1[i] == arr2[i], message)
    end
  end
end

local function assert_sprite_equal(sprite, expected)
  if expected.sprite then
    assert(sprite.sprite == expected.sprite,
           "Unexpected sprite '" .. sprite.sprite .. "', expected: '" .. expected.sprite .. "'")
  end
  if expected.target then
    assert_equal_array(
            sprite.target, expected.target,
            "Targets not the same. Current '" .. serpent.line(sprite.target) ..
                    "', expected: '" .. serpent.line(expected.target) .. "'"
    )
  end
  if expected.scale then
    assert(sprite.x_scale == expected.scale,
           "Received scale: " .. sprite.x_scale .. ". Expected scale: " .. expected.scale)
    assert(sprite.y_scale == expected.scale,
           "Received scale: " .. sprite.y_scale .. ". Expected scale: " .. expected.scale)
  end
  if expected.text_scale then
    assert(sprite.scale == expected.text_scale,
           "Received scale: " .. sprite.scale .. ". Expected scale: " .. expected.text_scale)
  end
  if expected.color then
    assert_equal_array(sprite.color, expected.color,
                       "Colours not the same. Current '" .. serpent.line(sprite.color) ..
                               "', expected: '" .. serpent.line(expected.color) .. "'"
    )
  end
  if expected.text then
    assert_equal_array(sprite.text, expected.text,
                       "Texts not the same. Current '" .. serpent.line(sprite.text) ..
                               "', expected: '" .. serpent.line(expected.text) .. "'"
    )
  end

end

return {
  assert_close          = assert_close,
  assert_equal_position = assert_equal_position,
  assert_equal_array    = assert_equal_array,
  assert_sprite_equal   = assert_sprite_equal
}