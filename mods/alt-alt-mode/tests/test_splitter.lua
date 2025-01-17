local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local test = require("__alt-alt-mode__/tests/util_tests.lua")
local tests = {}

tests.test_empty_splitter = function(player)
  local entity = player.surface.create_entity {name = "splitter", position = player.position, force = player.force, create_build_effect_smoke = false, direction = defines.direction.north}
  entity.splitter_filter = {quality = "epic"}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 0)
  return entity
end

tests.test_splitter_quality_output = function(player)
  local entity = player.surface.create_entity {name = "splitter", position = player.position, force = player.force, create_build_effect_smoke = false, direction = defines.direction.east}
  entity.splitter_filter = {quality = "epic"}
  entity.splitter_output_priority = "left"
  entity.splitter_input_priority = "right"
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 3, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 3")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.405, sprite = test.bg_sprite, target = {entity, {0, -0.5}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "quality.epic", target = {entity, {0, -0.5}}})
  test.assert_sprite_equal(sprites[3], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.65, sprite = "alt-alt-indication-arrow", target = {entity, {-0.25, 0.5}}})
  return entity
end

tests.test_splitter_item_output = function(player)
  local entity = player.surface.create_entity {name = "splitter", position = player.position, force = player.force, create_build_effect_smoke = false, direction = defines.direction.south}
  entity.splitter_filter = {name = "iron-plate", quality = "legendary"}
  entity.splitter_output_priority = "right"
  entity.splitter_input_priority = "right"
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 3, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 3")
  test.assert_sprite_equal(sprites[1], {color = prototypes.quality.legendary.color, scale = 0.405, sprite = test.bg_sprite, target = {entity, {-0.5, 0}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.iron-plate", target = {entity, {-0.5, 0}}})
  test.assert_sprite_equal(sprites[3], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.65, sprite = "alt-alt-indication-arrow", target = {entity, {-0.5, -0.25}}})
  return entity
end

tests.test_splitter_priority_output = function(player)
  local entity = player.surface.create_entity {name = "splitter", position = player.position, force = player.force, create_build_effect_smoke = false, direction = defines.direction.west}
  entity.splitter_output_priority = "left"
  entity.splitter_input_priority = "left"
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 2")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.65, sprite = "alt-alt-indication-arrow", target = {entity, {-0.25, 0.5}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.65, sprite = "alt-alt-indication-arrow", target = {entity, {0.25, 0.5}}})
  return entity
end

return tests