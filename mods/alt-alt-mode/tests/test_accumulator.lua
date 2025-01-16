local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")
local tests = {}

tests.test_electric_pole_disconnected = function(player)
  local global_network_surface = player.surface.has_global_electric_network
  if global_network_surface then
    player.surface.destroy_global_electric_network()
  end
  local entity = player.surface.create_entity {name = "small-electric-pole", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = test.black})
  test.assert_sprite_equal(sprites[2], {text = {"", "0", {"si-unit-symbol-watt"}}, target = {entity, {0, 0}}, text_scale = 1})
  storage.electric_network = {}
  if global_network_surface then
    player.surface.create_global_electric_network()
  end
  return entity
end

tests.test_electric_pole_connected = function(player)
  local global_network_surface = player.surface.has_global_electric_network
  if global_network_surface then
    player.surface.destroy_global_electric_network()
  end
  local entity = player.surface.create_entity {name = "medium-electric-pole", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity.electric_network_statistics.on_flow("inserter", -5000000000)
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = test.black})
  local text = {"", {"", "", "1", {"si-prefix-symbol-giga"}}, {"si-unit-symbol-watt"}}
  test.assert_sprite_equal(sprites[2], {text = text, target = {entity, {0, 0}}, text_scale = 1})
  storage.electric_network = {}
  if global_network_surface then
    player.surface.create_global_electric_network()
  end
  return entity
end

return tests