local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")
local tests = {}

tests.test_rocket_silo = function(player)
  local entity = player.surface.create_entity {name = "rocket-silo", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity_logic.show_alt_info_for_entity(player, entity)
  assert(#storage[player.index] == 0)
  entity.get_inventory(defines.inventory.rocket_silo_rocket).insert {name = "copper-plate", count = 4}
  entity.get_inventory(defines.inventory.rocket_silo_rocket).insert {name = "copper-cable", count = 3}
  entity.get_inventory(defines.inventory.rocket_silo_rocket).insert {name = "copper-plate", count = 4}
  entity.get_inventory(defines.inventory.rocket_silo_modules).insert {name = "productivity-module", count = 1}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 8, #sprites)
  local bg = sprites[1]
  local module = sprites[2]
  local bg1 = sprites[3]
  local item1 = sprites[4]
  local text1 = sprites[5]
  local bg2 = sprites[6]
  local item2 = sprites[7]
  local text2 = sprites[8]
  assert(bg.sprite == test.bg_sprite, bg.sprite)
  assert(bg1.sprite == test.bg_sprite, bg1.sprite)
  assert(bg2.sprite == test.bg_sprite, bg2.sprite)
  assert(module.sprite == "item.productivity-module", module.sprite)
  assert(item1.sprite == "item.copper-plate", item1.sprite)
  assert(item2.sprite == "item.copper-cable", item2.sprite)
  assert(item1.target.entity == entity, item1.target.entity.name)
  test.assert_equal_position(item1.target.offset, {x = -.2475, y = 2}, serpent.line(item1.target.offset))
  test.assert_equal_position(item2.target.offset, {x = 0.2475, y = 2}, serpent.line(item2.target.offset))
  test.assert_equal_position(module.target.offset, {x = -0.825, y = 3.3}, serpent.line(module.target.offset))
  assert(item1.x_scale == 0.45, item1.x_scale)
  assert(item1.y_scale == 0.45, item1.y_scale)
  assert(item2.x_scale == 0.45, item2.x_scale)
  assert(item2.y_scale == 0.45, item2.y_scale)
  assert(module.x_scale == 0.5, module.x_scale)
  assert(module.y_scale == 0.5, module.y_scale)
  assert(text1.text[3] == "8", text1.text[3])
  assert(text2.text[3] == "3", text2.text[3])
  return entity
end

tests.test_lab = function(player)
  local entity = player.surface.create_entity {name = "lab", position = player.position, force = player.force, create_build_effect_smoke = false}
  entity.get_inventory(defines.inventory.lab_input).insert {name = "promethium-science-pack", count = 45}
  entity.get_inventory(defines.inventory.lab_input).insert {name = "automation-science-pack", count = 3, quality = "uncommon"}
  entity.get_inventory(defines.inventory.lab_modules).insert {name = "productivity-module", count = 1}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 8, #sprites)
  local bg = sprites[1]
  local module = sprites[2]
  local bg1 = sprites[3]
  local item1 = sprites[4]
  local text1 = sprites[5]
  local bg2 = sprites[6]
  local item2 = sprites[7]
  local text2 = sprites[8]
  assert(bg.sprite == test.bg_sprite, bg.sprite)
  assert(bg1.sprite == test.bg_sprite, bg1.sprite)
  assert(bg2.sprite == test.bg_sprite, bg2.sprite)
  test.assert_equal_array(bg1.color, prototypes.quality.uncommon.color, serpent.line(bg1.color))
  assert(module.sprite == "item.productivity-module", module.sprite)
  assert(item1.sprite == "item.automation-science-pack", item1.sprite)
  assert(item2.sprite == "item.promethium-science-pack", item2.sprite)
  assert(item1.target.entity == entity, item1.target.entity.name)
  test.assert_equal_position(item1.target.offset, {x = -12.5 / 11, y = -0.1}, serpent.line(item1.target.offset))
  test.assert_equal_position(item2.target.offset, {x = 12.5 / 11, y = 401 / 990}, serpent.line(item2.target.offset))
  test.assert_equal_position(module.target.offset, {x = -0.275, y = 0.9}, serpent.line(module.target.offset))
  assert(item1.x_scale == 0.5, item1.x_scale)
  assert(item1.y_scale == 0.5, item1.y_scale)
  assert(item2.x_scale == 0.5, item2.x_scale)
  assert(item2.y_scale == 0.5, item2.y_scale)
  assert(module.x_scale == 0.5, module.x_scale)
  assert(module.y_scale == 0.5, module.y_scale)
  assert(text1.text[3] == "3", text1.text[3])
  assert(text2.text[3] == "45", text2.text[3])
  return entity
end



return tests