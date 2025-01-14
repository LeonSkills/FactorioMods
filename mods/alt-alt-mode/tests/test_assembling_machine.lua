local entity_logic = require("__alt-alt-mode__/scripts/entity_logic.lua")
local util_tests = require("__alt-alt-mode__/tests/util_tests.lua")

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
  local bg = sprites[1]
  local recipe = sprites[2]
  assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
  assert(recipe.sprite == "recipe.iron-gear-wheel", sprites[2].sprite)
  assert(recipe.target.entity == entity, recipe.target.entity)
  util_tests.assert_equal_position(recipe.target.offset, {x = 0, y = -0.3}, serpent.line(recipe.target.offset))
  assert(recipe.x_scale == 0.9, recipe.x_scale)
  assert(recipe.y_scale == 0.9, recipe.y_scale)
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
  local bg_mod1 = sprites[1]
  local mod1 = sprites[2]
  local bg_mod3 = sprites[3]
  local mod3 = sprites[4]
  local bg = sprites[5]
  local recipe = sprites[6]
  local blacklisted = sprites[7]
  assert(bg.sprite == "alt-alt-entity-info-white-background", bg.sprite)
  util_tests.assert_equal_array(bg.color, prototypes.quality["epic"].color,
                                serpent.line(bg_mod3.color) .. "!=" .. serpent.line(prototypes.quality["epic"].color))
  assert(bg_mod1.sprite == "alt-alt-entity-info-white-background", bg_mod1.sprite)
  assert(bg_mod3.sprite == "alt-alt-entity-info-white-background", bg_mod3.sprite)
  util_tests.assert_equal_array(bg_mod3.color, prototypes.quality["uncommon"].color,
                                serpent.line(bg_mod3.color) .. "!=" .. serpent.line(prototypes.quality["uncommon"].color))
  assert(mod1.sprite == "item.productivity-module", mod1.sprite)
  util_tests.assert_equal_position(mod1.target.offset, {x = -0.825, y = 0.85}, serpent.line(mod1.target.offset))
  assert(mod3.sprite == "item.productivity-module-3", mod1.sprite)
  util_tests.assert_equal_position(mod3.target.offset, {x = 0.275, y = 13.15 / 9}, serpent.line(mod3.target.offset))
  assert(recipe.sprite == "recipe.plastic-bar", recipe.sprite)
  assert(recipe.target.entity == entity, recipe.target.entity)
  util_tests.assert_equal_position(recipe.target.offset, {x = 0, y = -0.3}, serpent.line(recipe.target.offset))
  assert(recipe.x_scale == 1.8, recipe.x_scale)
  assert(recipe.y_scale == 1.8, recipe.y_scale)
  assert(blacklisted.sprite == "alt-alt-filter-blacklist", blacklisted.sprite)
  assert(blacklisted.x_scale == 1.8 * 2, blacklisted.x_scale)
  assert(blacklisted.y_scale == 1.8 * 2, blacklisted.y_scale)
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
  local bg = sprites[1]
  local recipe = sprites[2]
  assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
  assert(recipe.sprite == "recipe.copper-cable", sprites[2].sprite)
  assert(recipe.target.entity == entity, recipe.target.entity)
  util_tests.assert_equal_position(recipe.target.offset, {x = 0, y = -0.25}, serpent.line(recipe.target.offset))
  assert(recipe.x_scale == 0.9, recipe.x_scale)
  assert(recipe.y_scale == 0.9, recipe.y_scale)
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
    local bg1 = sprites[1]
    local mod1 = sprites[2]
    local bg2 = sprites[3]
    local mod2 = sprites[4]
    assert(bg1.sprite == "alt-alt-entity-info-white-background", bg1.sprite)
    assert(mod1.sprite == "item.quality-module", mod1.sprite)
    assert(mod1.target.entity == entity, mod1.target.entity.name)
    assert(mod2.sprite == "item.quality-module-3", mod2.sprite)
    assert(mod2.target.entity == entity, mod2.target.entity.name)
    util_tests.assert_equal_array(bg2.color, prototypes.quality["uncommon"].color, serpent.line(bg2.color))
    util_tests.assert_equal_position(mod1.target.offset, {x = -0.275, y = 0.1}, serpent.line(mod1.target.offset))
    util_tests.assert_equal_position(mod2.target.offset, {x = 0.275, y = 32 / 45}, serpent.line(mod2.target.offset))
    assert(mod1.x_scale == 0.5, mod1.x_scale)
    assert(mod1.y_scale == 0.5, mod1.y_scale)
    assert(mod2.x_scale == 0.5, mod2.x_scale)
    assert(mod2.y_scale == 0.5, mod2.y_scale)
    return entity
  end
end

return tests