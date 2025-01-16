local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local test = require("__alt-alt-mode__/tests/util_tests.lua")
local tests = {}

tests.test_empty_decider_combinator = function(player)
  local entity = player.surface.create_entity {name = "decider-combinator", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 3, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 3")
  test.assert_sprite_equal(sprites[1], {target = {entity, {0, -0.2}}, text = "<", text_scale = 1})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.324, sprite = test.bg_sprite, target = {entity, {0.3, -0.2}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {0.3, -0.2}}, text = "0", text_scale = 1})
  return entity
end

tests.test_decider_combinator = function(player)
  local entity = player.surface.create_entity {name = "decider-combinator", position = player.position, force = player.force, create_build_effect_smoke = false}
  local input_parameters = {}
  input_parameters.first_signal = {type = "item", name = "transport-belt", quality = "epic"}
  input_parameters.constant = 234e6
  input_parameters.comparator = "≠"
  local output_parameters = {}
  output_parameters.signal = {type = "fluid", name = "water", quality = "legendary"}
  output_parameters.copy_count_from_input = false
  output_parameters.constant = 50
  entity.get_control_behavior().set_condition(1, input_parameters)
  entity.get_control_behavior().set_output(1, output_parameters)
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 8, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 8")
  test.assert_sprite_equal(sprites[1], {target = {entity, {0, -0.2}}, text = "≠", text_scale = 1})
  test.assert_sprite_equal(sprites[2], {color = prototypes.quality.epic.color, scale = 0.405, sprite = test.bg_sprite, target = {entity, {-0.3, -0.2}}})
  test.assert_sprite_equal(sprites[3], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.transport-belt", target = {entity, {-0.3, -0.2}}})
  test.assert_sprite_equal(sprites[4], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.324, sprite = test.bg_sprite, target = {entity, {0.3, -0.2}}})
  test.assert_sprite_equal(sprites[5], {target = {entity, {0.3, -0.2}}, text = {"", "", "234", {"si-prefix-symbol-mega"}}, text_scale = 0.5})
  test.assert_sprite_equal(sprites[6], {color = prototypes.quality.legendary.color, scale = 0.405, sprite = test.bg_sprite, target = {entity, {0, 0.2}}})
  test.assert_sprite_equal(sprites[7], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "fluid.water", target = {entity, {0, 0.2}}})
  test.assert_sprite_equal(sprites[8], {target = {entity, {0.225, 0.3485}}, text = {"", "", "50", ""}, text_scale = 0.45})
  return entity
end

return tests
