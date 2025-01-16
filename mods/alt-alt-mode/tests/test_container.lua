local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")

local tests = {}
tests.test_chest = function(player)
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "steel-chest", position = position, force = force, create_build_effect_smoke = false}
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 3}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 3, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {0, 0}}, scale = 0.567})
  test.assert_sprite_equal(sprites[2], {sprite = "item.copper-cable", target = {entity, {0, 0}}, scale = 0.63})
  test.assert_sprite_equal(sprites[3], {text = {"", "", "3", ""}, target = {entity, {0.315, 0.2079}}, text_scale = 0.63})
  return entity
end

tests.test_chest_3_items = function(player)
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "active-provider-chest", position = position, force = force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  assert(#storage[player.index] == 0, #storage[player.index])
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 4}
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 5, quality = "uncommon"}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-ore", count = 2351, quality = "legendary"}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 9, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {-0.2475, -0.2475}}, scale = 0.405, color = prototypes.quality.legendary.color})
  test.assert_sprite_equal(sprites[2], {sprite = "item.iron-ore", target = {entity, {-0.2475, -0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[3], {text = {"", "", "2.3", {"si-prefix-symbol-kilo"}}, target = {entity, {-.0225, -0.099}}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[4], {sprite = test.bg_sprite, target = {entity, {0.2475, -0.2475}}, scale = 0.405, color = prototypes.quality.uncommon.color})
  test.assert_sprite_equal(sprites[5], {sprite = "item.copper-cable", target = {entity, {0.2475, -0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[6], {text = {"", "", "5", ""}, target = {entity, {0.4725, -0.099}}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[7], {sprite = test.bg_sprite, target = {entity, {-0.2475, 0.2475}}, scale = 0.405, color = test.black})
  test.assert_sprite_equal(sprites[8], {sprite = "item.copper-cable", target = {entity, {-0.2475, 0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[9], {text = {"", "", "4", ""}, target = {entity, {-.0225, 0.396}}, text_scale = 0.45})
  return entity
end

tests.test_chest_5_items = function(player)
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "infinity-chest", position = position, force = force, create_build_effect_smoke = false}
  entity.get_inventory(defines.inventory.chest).insert {name = "transport-belt", count = 2343}
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 5}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-ore", count = 5, quality = "uncommon"}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-ore", count = 5, quality = "legendary"}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-plate", count = 5}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 12, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {-0.2475, -0.2475}}, scale = 0.405, color = test.black})
  test.assert_sprite_equal(sprites[2], {sprite = "item.transport-belt", target = {entity, {-0.2475, -0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[3], {text = {"", "", "2.34", {"si-prefix-symbol-kilo"}}, target = {entity, {-.0225, -0.099}}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[4], {sprite = test.bg_sprite, target = {entity, {0.2475, -0.2475}}, scale = 0.405, color = prototypes.quality.uncommon.color})
  test.assert_sprite_equal(sprites[5], {sprite = "item.iron-ore", target = {entity, {0.2475, -0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[6], {text = {"", "", "5", ""}, target = {entity, {0.4725, -0.099}}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[7], {sprite = test.bg_sprite, target = {entity, {-0.2475, 0.2475}}, scale = 0.405, color = prototypes.quality.legendary.color})
  test.assert_sprite_equal(sprites[8], {sprite = "item.iron-ore", target = {entity, {-0.2475, 0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[9], {text = {"", "", "5", ""}, target = {entity, {-.0225, 0.396}}, text_scale = 0.45})
  test.assert_sprite_equal(sprites[10], {sprite = test.bg_sprite, target = {entity, {0.2475, 0.2475}}, scale = 0.405, color = test.black})
  test.assert_sprite_equal(sprites[11], {sprite = "item.iron-plate", target = {entity, {0.2475, 0.2475}}, scale = 0.45})
  test.assert_sprite_equal(sprites[12], {text = {"", "", "5", ""}, target = {entity, {0.4725, 0.396}}, text_scale = 0.45})
  return entity
end

return tests
