local test_util = {}

test_util.assert_close = function(num1, num2, message)
  return assert(math.abs(num1 - num2) <= 0.0001, message)
end

test_util.assert_equal_position = function(pos1, pos2, message)
  local x1 = pos1.x or pos1[1]
  local x2 = pos2.x or pos2[1]
  local y1 = pos1.y or pos1[2]
  local y2 = pos2.y or pos2[2]
  test_util.assert_close(x1, x2, message)
  test_util.assert_close(y1, y2, message)
end

test_util.assert_equal_array = function(arr1, arr2, message)
  for i, _ in pairs(arr1) do
    test_util.assert_equal(arr1[i], arr2[i], message)
  end
end

test_util.assert_equal = function(obj1, obj2, message)
  assert(type(obj1) == type(obj2), message)
  if type(obj1) == "number" then
    test_util.assert_close(obj1, obj2, message)
  elseif type(obj1) == "table" then
    test_util.assert_equal_array(obj1, obj2, message)
  else
    assert(obj1 == obj2, message)
  end
end

test_util.assert_sprite_equal = function(sprite, expected)
  if expected.sprite then
    assert(sprite.sprite == expected.sprite, "Unexpected sprite '" .. sprite.sprite .. "', expected: '" .. expected.sprite .. "'")
  end
  if expected.target then
    test_util.assert_equal_array(
            sprite.target, {entity = expected.target[1], offset = expected.target[2]},
            "Targets not the same. Current '" .. serpent.line(sprite.target) ..
                    "', expected: '" .. serpent.line(expected.target) .. "'"
    )
  end
  if expected.scale then
    test_util.assert_close(sprite.x_scale, expected.scale, "Received scale: " .. sprite.x_scale .. ". Expected scale: " .. expected.scale)
    test_util.assert_close(sprite.y_scale, expected.scale, "Received scale: " .. sprite.y_scale .. ". Expected scale: " .. expected.scale)
  end
  if expected.text_scale then
    test_util.assert_close(sprite.scale, expected.text_scale, "Received scale: '" .. sprite.scale .. "'. Expected scale: '" .. expected.text_scale .. "'")
  end
  if expected.color then
    test_util.assert_equal_array(sprite.color, expected.color,
                                 "Colours not the same. Current '" .. serpent.line(sprite.color) ..
                                         "', expected: '" .. serpent.line(expected.color) .. "'"
    )
  end
  if expected.text then
    test_util.assert_equal(sprite.text, expected.text,
                           "Texts not the same. Current '" .. serpent.line(sprite.text) ..
                                   "', expected: '" .. serpent.line(expected.text) .. "'"
    )
  end
end

test_util.write_tests = function(sprites)
  print('assert(#sprites == ' .. #sprites .. ', "Number of sprites not equal. Current:" .. #sprites .. ", expected: ' .. #sprites .. '")')
  for index, sprite in pairs(sprites) do
    local sprite_info = {
      target = {"entity", sprite.target.offset}
    }
    if sprite.type == "text" then
      sprite_info.text_scale = sprite.scale
      sprite_info.text = sprite.text
    elseif sprite.type == "sprite" then
      sprite_info.sprite = sprite.sprite
      sprite_info.color = sprite.color
      sprite_info.scale = sprite.x_scale
    else
      game.print("Unknown sprite type " .. sprite.type)
    end
    local line = serpent.line(sprite_info)
    line = string.gsub(line, '"entity"', "entity")

    print("test.assert_sprite_equal(sprites[" .. index .. "], " .. line .. ")")
  end

end

test_util.bg_sprite = "alt-alt-entity-info-white-background"
test_util.black = {a = 1, r = 0, g = 0, b = 0}

return test_util

-- \.([0-9]+)49{3,}[0-9]+

-- {a = 1, b = 0.23921568691730499, g = 0.64705884456634521, r = 0.16862745583057404} -- uncommon