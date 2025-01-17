local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")

local tests = {}
tests.test_dir_north = function(player)
  local surface = player.surface
  local position = {}
  position.x = math.floor(player.position.x / 2) * 2
  position.y = math.floor(player.position.y / 2) * 2
  local force = player.force
  local rail1 = surface.create_entity {name = "straight-rail", position = position, force = force, create_build_effect_smoke = false}
  local rail2 = surface.create_entity {name = "straight-rail", position = {position.x, position.y - 2}, force = force, create_build_effect_smoke = false}
  local entity = surface.create_entity {name = "cargo-wagon", position = position, force = force, create_build_effect_smoke = false, direction = 0}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "copper-cable", count = 3}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "transport-belt", count = 2343}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "copper-cable", count = 5}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "iron-ore", count = 5, quality = "uncommon"}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "iron-ore", count = 5, quality = "legendary"}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "iron-plate", count = 5}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 12, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 12")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.008, sprite = test.bg_sprite, target = {entity, {0, -1.9831625}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.transport-belt", target = {entity, {0, -1.9831625}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {0.56, -1.6135625}}, text = {"", "", "2.34", {"si-prefix-symbol-kilo"}}, text_scale = 1.12})
  test.assert_sprite_equal(sprites[4], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.008, sprite = test.bg_sprite, target = {entity, {0, -0.7287625}}})
  test.assert_sprite_equal(sprites[5], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.copper-cable", target = {entity, {0, -0.7287625}}})
  test.assert_sprite_equal(sprites[6], {target = {entity, {0.56, -0.3591625}}, text = {"", "", "8", ""}, text_scale = 1.12})
  test.assert_sprite_equal(sprites[7], {color = prototypes.quality.uncommon.color, scale = 1.008, sprite = test.bg_sprite, target = {entity, {0, 0.5256375}}})
  test.assert_sprite_equal(sprites[8], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.iron-ore", target = {entity, {0, 0.5256375}}})
  test.assert_sprite_equal(sprites[9], {target = {entity, {0.56, 0.8952374}}, text = {"", "", "5", ""}, text_scale = 1.12})
  test.assert_sprite_equal(sprites[10], {color = prototypes.quality.legendary.color, scale = 1.008, sprite = test.bg_sprite, target = {entity, {0, 1.7800375}}})
  test.assert_sprite_equal(sprites[11], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.iron-ore", target = {entity, {0, 1.7800375}}})
  test.assert_sprite_equal(sprites[12], {target = {entity, {0.56, 2.1496375}}, text = {"", "", "5", ""}, text_scale = 1.12})
  return {entity, {rail1, rail2}}
end

tests.test_dir_north_north_east = function(player)
  local surface = player.surface
  local position = {}
  position.x = math.floor(player.position.x / 2) * 2
  position.y = math.floor(player.position.y / 2) * 2
  local rails = {}
  local force = player.force
  for i = -2, 2 do
    for j = -2, 2 do
      local rail = surface.create_entity {name = "half-diagonal-rail", position = {position.x + i, position.y + j}, force = force, create_build_effect_smoke = false}
      table.insert(rails, rail)
    end
  end
  local entity = surface.create_entity {name = "cargo-wagon", position = position, force = force, create_build_effect_smoke = false}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "copper-cable", count = 3}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "transport-belt", count = 2343}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "copper-cable", count = 5}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "iron-ore", count = 5, quality = "uncommon"}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "iron-ore", count = 5, quality = "legendary"}
  entity.get_inventory(defines.inventory.cargo_wagon).insert {name = "iron-plate", count = 5}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 12, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 12")
  test.assert_sprite_equal(sprites[1],
                           {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.008, sprite = test.bg_sprite, target = {entity, {1.158617162095851, 1.8193058459429778}}})
  test.assert_sprite_equal(sprites[2],
                           {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.transport-belt", target = {entity, {1.158617162095851, 1.8193058459429778}}})
  test.assert_sprite_equal(sprites[3],
                           {target = {entity, {1.718617162095851, 2.188905845942978}}, text = {"", "", "2.34", {"si-prefix-symbol-kilo"}}, text_scale = 1.12})
  test.assert_sprite_equal(sprites[4],
                           {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.008, sprite = test.bg_sprite, target = {entity, {0.59714322069862646, 0.69758111531433542}}})
  test.assert_sprite_equal(sprites[5],
                           {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.copper-cable", target = {entity, {0.59714322069862646, 0.69758111531433542}}})
  test.assert_sprite_equal(sprites[6], {target = {entity, {1.1571432206986265, 1.0671811153143356}}, text = {"", "", "8", ""}, text_scale = 1.12})
  test.assert_sprite_equal(sprites[7],
                           {color = prototypes.quality.uncommon.color, scale = 1.008, sprite = test.bg_sprite, target = {entity, {0.035669279301373535, -0.42414361531433542}}})
  test.assert_sprite_equal(sprites[8],
                           {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.iron-ore", target = {entity, {0.035669279301373535, -0.42414361531433542}}})
  test.assert_sprite_equal(sprites[9], {target = {entity, {0.59566927930137359, -0.054543615314335376}}, text = {"", "", "5", ""}, text_scale = 1.12})
  test.assert_sprite_equal(sprites[10],
                           {color = prototypes.quality.legendary.color, scale = 1.008, sprite = test.bg_sprite, target = {entity, {-0.52580466209585097, -1.5458683459429778}}})
  test.assert_sprite_equal(sprites[11],
                           {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.12, sprite = "item.iron-ore", target = {entity, {-0.52580466209585097, -1.5458683459429778}}})
  test.assert_sprite_equal(sprites[12], {target = {entity, {0.034195337904149081, -1.1762683459429777}}, text = {"", "", "5", ""}, text_scale = 1.12})
  return {entity, rails}
end

return tests
