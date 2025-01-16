local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")
local tests = {}

tests.test_fish = function(player)
  local entity = player.surface.create_entity {name = "fish", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 3, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 3")
  test.assert_sprite_equal(sprites[1],
                           {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.648, sprite = test.bg_sprite, target = {entity, {0, 0}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.72, sprite = "item.raw-fish", target = {entity, {0, 0}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {0.36, 0.2376}}, text = {"", "", "5", ""}, text_scale = 0.72})
  return entity
end

tests.test_tree = function(player)
  local entity = player.surface.create_entity {name = "tree-01", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 3, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 3")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.08, sprite = test.bg_sprite, target = {entity, {0, -0.80078125}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.2, sprite = "item.wood", target = {entity, {0, -0.80078125}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {0.6, -0.40478125}}, text = {"", "", "4", ""}, text_scale = 1.2})
  return entity
end

tests.test_rock = function(player)
  local entity = player.surface.create_entity {name = "huge-rock", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 6, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 6")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.08, sprite = test.bg_sprite, target = {entity, {-0.75, 0}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.2, sprite = "item.stone", target = {entity, {-0.75, 0}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {-0.15, 0.396}}, text = {"", "", "37", ""}, text_scale = 1.2})
  test.assert_sprite_equal(sprites[4], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.08, sprite = test.bg_sprite, target = {entity, {0.75, 0}}})
  test.assert_sprite_equal(sprites[5], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.2, sprite = "item.coal", target = {entity, {0.75, 0}}})
  test.assert_sprite_equal(sprites[6], {target = {entity, {1.35, 0.396}}, text = {"", "", "37", ""}, text_scale = 1.2})
  return entity
end

tests.test_simple_entity_with_owner = function(player)
  local entity = player.surface.create_entity {name = "crash-site-spaceship-wreck-small-1", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 0, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 6")
  return entity
end

return tests
