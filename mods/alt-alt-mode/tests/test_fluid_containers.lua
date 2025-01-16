local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")

local tests = {}

for _, temperature in pairs({15, 500}) do
  tests["test_storage_tank-temperature=" .. temperature] = function(player)
    local entity = player.surface.create_entity {
      name = "storage-tank", position = player.position, force = player.force, create_build_effect_smoke = false
    }
    assert(#storage[player.index] == 0, "Some sprites where drawn when it shouldn't have")
    entity.insert_fluid {name = "steam", amount = 23492, temperature = temperature}
    entity_logic.show_alt_info_for_entity(player, entity)
    local sprites = storage[player.index]
    assert(#sprites == (temperature == 15 and 3 or 4), #sprites)
    test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = {a = 1, b = 0, g = 0, r = 0}})
    test.assert_sprite_equal(sprites[2], {sprite = "fluid.steam", target = {entity, {0, -0.3}}, scale = 1.35, })
    test.assert_sprite_equal(sprites[3], {text = {"", "", "23.4", {"si-prefix-symbol-kilo"}}, target = {entity, {0.675, 0.1455}}, text_scale = 1.35})
    if temperature > 15 then
      local text = {"", {"", "", "500", ""}, {"si-unit-degree-celsius"}}
      test.assert_sprite_equal(sprites[4], {text = text, target = {entity, {0.675, -0.7455}}, text_scale = 1.35})
    end
    return entity
  end
end

for _, entity_name in pairs({"pipe", "pipe-to-ground", "infinity-pipe"}) do
  for _, temperature in pairs({15, 500}) do
    tests["test_" .. entity_name .. "-with-temperature=" .. temperature] = function(player)
      local entity = player.surface.create_entity {
        name = entity_name, position = player.position, force = player.force, create_build_effect_smoke = false
      }
      entity_logic.show_alt_info_for_entity(player, entity)
      assert(#storage[player.index] == 0, "Some sprites where drawn when it shouldn't have")
      entity.insert_fluid {name = "steam", amount = 34, temperature = temperature}
      entity_logic.show_alt_info_for_entity(player, entity)
      local sprites = storage[player.index]
      assert(#sprites == (temperature == 15 and 3 or 4), #sprites)
      test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = {a = 1, b = 0, g = 0, r = 0}})
      test.assert_sprite_equal(sprites[2], {sprite = "fluid.steam", target = {entity, {0, -0.0}}, scale = 0.45})
      test.assert_sprite_equal(sprites[3], {text = {"", "", "34", ""}, target = {entity, {0.225, 0.1485}}, text_scale = 0.45})
      if temperature > 15 then
        test.assert_sprite_equal(sprites[4], {text = {"", {"", "", "500", ""}, {"si-unit-degree-celsius"}}, target = {entity, {0.225, -0.1485}}, text_scale = 0.45})
      end
      return entity
    end
  end
end

return tests