local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local util_tests = require("__alt-alt-mode__/tests/util_tests")

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
  local bg = sprites[1]
  local item = sprites[2]
  local text = sprites[3]
  assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
  assert(item.sprite == "item.copper-cable", sprites[2].sprite)
  assert(item.target.entity == entity, item.target.entity)
  util_tests.assert_equal_position(item.target.offset, {x = 0, y = 0}, serpent.line(item.target.offset))
  assert(item.x_scale == 0.9 * 0.7, item.x_scale)
  assert(item.y_scale == 0.9 * 0.7, item.y_scale)
  assert(text.text[3] == "3", text.text[3])
  entity.destroy()
end

tests.test_chest_3_items = function(player)
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "steel-chest", position = position, force = force, create_build_effect_smoke = false}
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 4}
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 5, quality = "uncommon"}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-ore", count = 5, quality = "legendary"}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 9, #sprites)
  local expected_sprites = {"item.iron-ore", "item.copper-cable", "item.copper-cable"}
  local expected_offsets = {{-0.2475, -0.2475}, {0.2475, -0.2475}, {-0.2475, 0.2475}}
  local expected_bg_colors = {
    prototypes.quality.legendary.color,
    prototypes.quality.uncommon.color,
    {a = 1, r = 0, g = 0, b = 0},
  }
  local expected_counts = {5, 5, 4}
  for i = 1, 3 do
    local bg = sprites[i * 3 - 2]
    local item = sprites[i * 3 - 1]
    local text = sprites[i * 3]
    assert(item.sprite == expected_sprites[i], i .. ", " .. item.sprite .. " is not " .. expected_sprites[i])
    assert(item.target.entity == entity, i .. ", " .. item.target.entity.name)
    util_tests.assert_equal_position(item.target.offset, expected_offsets[i], i .. ", " .. serpent.line(item.target.offset) .. "!= " .. serpent.line(expected_offsets[i]))
    assert(item.x_scale == 0.9 * 0.5, i .. ", " .. item.x_scale)
    assert(item.y_scale == 0.9 * 0.5, i .. ", " .. item.y_scale)
    assert(text.text[3] == tostring(expected_counts[i]), i .. ", " .. text.text[3])
    assert(bg.sprite == "alt-alt-entity-info-white-background", i .. ", " .. sprites[1].sprite)
    util_tests.assert_equal_array(bg.color, expected_bg_colors[i], i .. ", " .. serpent.line(bg.color))
  end
  entity.destroy()
end

tests.test_chest_5_items = function(player)
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity {name = "steel-chest", position = position, force = force, create_build_effect_smoke = false}
  entity.get_inventory(defines.inventory.chest).insert {name = "transport-belt", count = 5}
  entity.get_inventory(defines.inventory.chest).insert {name = "copper-cable", count = 5}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-ore", count = 5, quality = "uncommon"}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-ore", count = 5, quality = "legendary"}
  entity.get_inventory(defines.inventory.chest).insert {name = "iron-plate", count = 5}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 12, #sprites)
  local expected_sprites = {"item.transport-belt", "item.iron-ore", "item.iron-ore", "item.iron-plate"}
  local expected_offsets = {{-0.2475, -0.2475}, {0.2475, -0.2475}, {-0.2475, 0.2475}, {0.2475, 0.2475}}
  local expected_bg_colors = {
    {a = 1, r = 0, g = 0, b = 0},
    prototypes.quality.uncommon.color,
    prototypes.quality.legendary.color,
    {a = 1, r = 0, g = 0, b = 0},
  }
  local expected_counts = {5, 5, 5, 5}
  for i = 1, 4 do
    local bg = sprites[i * 3 - 2]
    local item = sprites[i * 3 - 1]
    local text = sprites[i * 3]
    assert(item.sprite == expected_sprites[i], i .. ": ".. item.sprite .. " is not " .. expected_sprites[i])
    assert(item.target.entity == entity, item.target.entity.name)
    util_tests.assert_equal_position(item.target.offset, expected_offsets[i], serpent.line(item.target.offset))
    assert(item.x_scale == 0.9 * 0.5, item.x_scale)
    assert(item.y_scale == 0.9 * 0.5, item.y_scale)
    assert(text.text[3] == tostring(expected_counts[i]), text.text[3])
    assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
    util_tests.assert_equal_array(bg.color, expected_bg_colors[i], serpent.line(bg.color))
  end
  entity.destroy()
end

return tests
