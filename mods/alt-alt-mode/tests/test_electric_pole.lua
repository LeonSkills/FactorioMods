local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")
local tests = {}

tests.test_accumulator_empty = function(player)
  local entity = player.surface.create_entity {name = "accumulator", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = {a=1, b=0, g=0, r=1}})
  test.assert_sprite_equal(sprites[2], {text = {"", "0", {"si-unit-symbol-joule"}}, target = {entity, {0, 0}}, text_scale = 1})
  return entity
end

tests.test_accumulator_empty = function(player)
  local entity = player.surface.create_entity {name = "accumulator", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity.energy = 2500000
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = {a=1, b=0, g=0.5, r=0.5}})
  local text = {"", {"", "", "2.5", {"si-prefix-symbol-mega"}}, {"si-unit-symbol-joule"}}
  test.assert_sprite_equal(sprites[2], {text = text, target = {entity, {0, 0}}, text_scale = 1})
  return entity
end

return tests
