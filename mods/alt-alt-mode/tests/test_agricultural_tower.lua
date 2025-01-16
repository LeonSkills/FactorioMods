local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")
local tests = {}

tests.test_agricultural_tower = function(player)
  local entity = player.surface.create_entity {name = "agricultural-tower", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  assert(#storage[player.index] == 0, "Some sprites where drawn when it shouldn't have")
  entity.insert({name = "tree-seed", count = 4})
  entity.get_output_inventory().insert {name = "copper-cable", count = 5, quality = "uncommon"}
  entity.get_output_inventory().insert {name = "iron-ore", count = 2351, quality = "legendary"}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 6, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {-0.495, 0}}, scale = 0.81, color = prototypes.quality.legendary.color})
  test.assert_sprite_equal(sprites[2], {sprite = "item.iron-ore", target = {entity, {-0.495, 0.0}}, scale = 0.9})
  test.assert_sprite_equal(sprites[3], {text = {"", "", "50", ""}, target = {entity, {-.045, 0.297}}, text_scale = 0.9})
  test.assert_sprite_equal(sprites[4], {sprite = test.bg_sprite, target = {entity, {0.495, 0}}, scale = 0.81, color = prototypes.quality.uncommon.color})
  test.assert_sprite_equal(sprites[5], {sprite = "item.copper-cable", target = {entity, {0.495, 0}}, scale = 0.9})
  test.assert_sprite_equal(sprites[6], {text = {"", "", "5", ""}, target = {entity, {0.945, 0.297}}, text_scale = 0.9})
  return entity
end


return tests