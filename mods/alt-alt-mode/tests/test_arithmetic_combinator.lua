local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local test = require("__alt-alt-mode__/tests/util_tests.lua")
local tests = {}

tests.test_empty_arithmetic_combinator = function(player)
  local entity = player.surface.create_entity {name = "arithmetic-combinator", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 5, "Number of sprites not equal")
  test.assert_sprite_equal(sprites[1], {target = {entity, {0, -0.2}}, text = "*", text_scale = 1})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.324, sprite = test.bg_sprite, target = {entity, {-0.3, -0.2}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {-0.3, -0.2}}, text = "0", text_scale = 1})
  test.assert_sprite_equal(sprites[4], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.324, sprite = test.bg_sprite, target = {entity, {0.3, -0.2}}})
  test.assert_sprite_equal(sprites[5], {target = {entity, {0.3, -0.2}}, text = "0", text_scale = 1})
  return entity
end

tests.test_arithmetic_combinator = function(player)
  local entity = player.surface.create_entity {name = "arithmetic-combinator", position = player.position, force = player.force, create_build_effect_smoke = false}
  local behaviour = entity.get_control_behavior().parameters
  behaviour.first_signal = {type = "item", name = "transport-belt", quality = "epic"}
  behaviour.second_constant = 234e6
  behaviour.operation = "XOR"
  behaviour.output_signal = {type = "fluid", name = "water", quality = "legendary"}
  entity.get_control_behavior().parameters = behaviour
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 7, "Number of sprites not equal")
  test.assert_sprite_equal(sprites[1], {target = {entity, {0, -0.2}}, text = "⊕", text_scale = 0.75})
  test.assert_sprite_equal(sprites[2], {color = prototypes.quality.epic.color, scale = 0.405, sprite = test.bg_sprite, target = {entity, {-0.3, -0.2}}})
  test.assert_sprite_equal(sprites[3], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.transport-belt", target = {entity, {-0.3, -0.2}}})
  test.assert_sprite_equal(sprites[4], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.324, sprite = test.bg_sprite, target = {entity, {0.3, -0.2}}})
  test.assert_sprite_equal(sprites[5], {target = {entity, {0.3, -0.2}}, text = {"", "", "234", {"si-prefix-symbol-mega"}}, text_scale = 0.5})
  test.assert_sprite_equal(sprites[6], {color = prototypes.quality.legendary.color, scale = 0.405, sprite = test.bg_sprite, target = {entity, {0, 0.2}}})
  test.assert_sprite_equal(sprites[7], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "fluid.water", target = {entity, {0, 0.2}}})
  return entity
end

return tests
