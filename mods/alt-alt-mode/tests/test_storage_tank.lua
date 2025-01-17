local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local test = require("__alt-alt-mode__/tests/util_tests.lua")
local tests = {}

tests.test_empty_storage_tank = function(player)
  local entity = player.surface.create_entity {name = "storage-tank", position = player.position, force = player.force, create_build_effect_smoke = false, direction = defines.direction.north}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 0)
  return entity
end

tests.test_half_empty_storage_tank = function(player)
  local entity = player.surface.create_entity {name = "storage-tank", position = player.position, force = player.force, create_build_effect_smoke = false, direction = defines.direction.north}
  entity.insert_fluid {name = "steam", amount = 23423, temperature = 345.43}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  test.write_tests(sprites)
  assert(#sprites == 4, "Number of sprites not equal. Current:" .. #sprites .. ", expected: 4")
  test.assert_sprite_equal(sprites[1], {color = {a = 1, b = 0, g = 0, r = 0}, scale = 1.215, sprite = test.bg_sprite, target = {entity, {0, -0.3}}})
  test.assert_sprite_equal(sprites[2], {color = {a = 1, b = 1, g = 1, r = 1}, scale = 1.35, sprite = "fluid.steam", target = {entity, {0, -0.3}}})
  test.assert_sprite_equal(sprites[3], {target = {entity, {0.675, 0.1455}}, text = {"", "", "23.4", {"si-prefix-symbol-kilo"}}, text_scale = 1.35})
  test.assert_sprite_equal(sprites[4], {target = {entity, {0.675, -0.7455}}, text = {"", {"", "", "345", ""}, {"si-unit-degree-celsius"}}, text_scale = 1.35})
end

return tests