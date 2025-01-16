local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local test = require("__alt-alt-mode__/tests/util_tests.lua")
local tests = {}

tests.test_empty_constant_combinator = function(player)
  local entity = player.surface.create_entity {name = "constant-combinator", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 0)
  return entity
end

tests.test_full_constant_combinator = function(player)
  local entity = player.surface.create_entity {name = "constant-combinator", position = player.position, force = player.force, create_build_effect_smoke = false}
  local behaviour = entity.get_control_behavior()
  behaviour.add_section()
  behaviour.sections[1].set_slot(5, {value = {type = "item", name = "iron-ore", comparator = "=", quality = "normal"}, min = 4})
  behaviour.sections[2].set_slot(9, {value = {type = "item", name = "iron-ore", quality = "normal"}, min = 98})
  behaviour.sections[1].set_slot(4, {value = {type = "item", name = "iron-ore", quality = "uncommon"}, min = 30})
  behaviour.sections[1].set_slot(3, {value = {type = "item", name = "copper-ore", quality = "normal"}, min = 3000000})
  behaviour.sections[2].set_slot(3, {value = {type = "item", name = "copper-ore", quality = "normal"}, min = 3000000})
  behaviour.sections[2].set_slot(2, {value = {type = "item", name = "coal", quality = "normal"}, min = 1})
  behaviour.sections[2].set_slot(1, {value = {type = "item", name = "transport-belt", quality = "normal"}, min = 0})
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 12, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 12")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.405, sprite = test.bg_sprite, target = {entity, {-0.2475, -0.2475}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.transport-belt", target = {entity, {-0.2475, -0.2475}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {-0.0225, -0.099}}, text = "0", text_scale = 0.45})
  test.assert_sprite_equal(sprites[4], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.405, sprite = test.bg_sprite, target = {entity, {0.2475, -0.2475}}})
  test.assert_sprite_equal(sprites[5], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.coal", target = {entity, {0.2475, -0.2475}}})
  test.assert_sprite_equal(sprites[6], {target = {entity, {0.4725, -0.099}}, text = {"", "", "1", ""}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[7], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 0.405, sprite = test.bg_sprite, target = {entity, {-0.2475, 0.2475}}})
  test.assert_sprite_equal(sprites[8], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.iron-ore", target = {entity, {-0.2475, 0.2475}}})
  test.assert_sprite_equal(sprites[9], {target = {entity, {-0.0225, 0.396}}, text = {"", "", "102", ""}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[10], {color = prototypes.quality.uncommon.color, scale = 0.405, sprite = test.bg_sprite, target = {entity, {0.2475, 0.2475}}})
  test.assert_sprite_equal(sprites[11], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 0.45, sprite = "item.iron-ore", target = {entity, {0.2475, 0.2475}}})
  test.assert_sprite_equal(sprites[12], {target = {entity, {0.4725, 0.396}}, text = {"", "", "30", ""}, text_scale = 0.45})
  return entity
end

return tests