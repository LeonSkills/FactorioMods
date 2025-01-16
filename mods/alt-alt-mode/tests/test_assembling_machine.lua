local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local test = require("__alt-alt-mode__/tests/util_tests.lua")

local tests = {}

tests.test_assembling_machine = function(player)
  -- 3x3
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "assembling-machine-1", position = position, force = force, recipe = "iron-gear-wheel", create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {0, -0.3}}, scale = 0.81})
  test.assert_sprite_equal(sprites[2], {sprite = "recipe.iron-gear-wheel", target = {entity, {0, -0.3}}, scale = 0.9})
  return entity

end

tests.test_cryogenic_plant = function(player)
  -- 5x5
  local surface = player.surface
  local position = player.position
  local force = player.force
  local recipe_enabled = force.recipes["plastic-bar"].enabled
  force.recipes["plastic-bar"].enabled = false
  local entity = surface.create_entity {name = "cryogenic-plant", position = position, force = force, create_build_effect_smoke = false}
  entity.set_recipe("plastic-bar", "epic")
  local inventory = entity.get_module_inventory()
  inventory.insert({name = "productivity-module", count = 1})
  inventory.insert({name = "productivity-module-2", count = 5})
  inventory.insert({name = "productivity-module-3", count = 1, quality = "uncommon"})
  inventory.remove({name = "productivity-module-2", count = 5})
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 7, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {-0.825, 0.85}}, scale = 0.45})
  test.assert_sprite_equal(sprites[2], {sprite = "item.productivity-module", target = {entity, {-0.825, 0.85}}, scale = 0.5})
  test.assert_sprite_equal(sprites[3], {sprite = test.bg_sprite, target = {entity, {0.275, 13.15 / 9}}, scale = 0.45, color = prototypes.quality.uncommon.color})
  test.assert_sprite_equal(sprites[4], {sprite = "item.productivity-module-3", target = {entity, {0.275, 13.15 / 9}}, scale = 0.5})
  test.assert_sprite_equal(sprites[5], {sprite = test.bg_sprite, target = {entity, {0, -0.3}}, scale = 1.62, color = prototypes.quality.epic.color})
  test.assert_sprite_equal(sprites[6], {sprite = "recipe.plastic-bar", target = {entity, {0, -0.3}}, scale = 1.8})
  test.assert_sprite_equal(sprites[7], {sprite = "alt-alt-filter-blacklist", target = {entity, {0, -0.3}}, scale = 3.6})
  force.recipes["plastic-bar"].enabled = recipe_enabled
  return entity
end

tests.test_electromagnetic_plant = function(player)
  -- 4x4
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "electromagnetic-plant", position = position, force = force, recipe = "copper-cable", create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2, #sprites)
  test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {0, -0.25}}, scale = 0.81})
  test.assert_sprite_equal(sprites[2], {sprite = "recipe.copper-cable", target = {entity, {0, -0.25}}, scale = 0.9})
  return entity
end

for _, direction in pairs({"north", "east"}) do
  tests["test_recycler-direction-" .. direction] = function(player)
    local entity = player.surface.create_entity {name = "recycler", position = player.position, force = player.force, direction = defines.direction[direction], create_build_effect_smoke = false}
    local sprites = storage[player.index]
    local inventory = entity.get_module_inventory()
    inventory.insert({name = "quality-module", count = 1})
    inventory.insert({name = "quality-module-2", count = 2})
    inventory.insert({name = "quality-module-3", count = 1, quality = "uncommon"})
    inventory.remove({name = "quality-module-2", count = 5})
    entity_logic.show_alt_info_for_entity(player, entity)
    assert(#sprites == 4, #sprites)
    test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, target = {entity, {-0.275, 0.1}}, scale = 0.45})
    test.assert_sprite_equal(sprites[2], {sprite = "item.quality-module", target = {entity, {-0.275, 0.1}}, scale = 0.5})
    test.assert_sprite_equal(sprites[3], {sprite = test.bg_sprite, target = {entity, {0.275, 32 / 45}}, scale = 0.45, color = prototypes.quality.uncommon.color})
    test.assert_sprite_equal(sprites[4], {sprite = "item.quality-module-3", target = {entity, {0.275, 32 / 45}}, scale = 0.5})
    return entity
  end
end

return tests