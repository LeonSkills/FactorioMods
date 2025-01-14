local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local util_tests = require("__alt-alt-mode__/tests/util_tests")
local tests = {}
for _, blacklist in pairs({true, false}) do
  tests["test_mining_drill-blacklist=" .. tostring(blacklist)] = function(player)
    local entity = player.surface.create_entity {name = "electric-mining-drill", position = player.position, force = player.force, create_build_effect_smoke = false}
    entity.get_inventory(defines.inventory.mining_drill_modules).insert {name = "productivity-module", count = 1, quality = "epic"}
    entity.set_filter(2, "iron-ore")
    entity.set_filter(4, "copper-ore")
    entity.mining_drill_filter_mode = blacklist and "blacklist" or "whitelist"
    entity_logic.show_alt_info_for_entity(player, entity)
    local sprites = storage[player.index]
    assert(#sprites == blacklist and 8 or 6, #sprites)
    local bg = sprites[1]
    assert(bg.sprite == "alt-alt-entity-info-white-background", bg.sprite)
    util_tests.assert_equal_array(bg.color, prototypes.quality["epic"].color, serpent.line(bg.color))
    local module = sprites[2]
    assert(module.sprite == "item.productivity-module", module.sprite)
    util_tests.assert_equal_position(module.target.offset, {x = -0.55, y = 0.7}, serpent.line(module.target.offset))
    assert(module.x_scale == 0.5, module.x_scale)
    assert(module.y_scale == 0.5, module.y_scale)
    local bg1 = sprites[3]
    assert(bg1.sprite == "alt-alt-entity-info-white-background", bg1.sprite)
    local filter1 = sprites[4]
    assert(filter1.sprite == "item.iron-ore", filter1.sprite)
    assert(filter1.x_scale == 0.45, filter1.x_scale)
    assert(filter1.y_scale == 0.45, filter1.y_scale)
    util_tests.assert_equal_position(filter1.target.offset, {x = -0.2475, y = 0.0}, serpent.line(filter1.target.offset))
    local bg2 = sprites[blacklist and 6 or 5]
    assert(bg2.sprite == "alt-alt-entity-info-white-background", bg2.sprite)
    local filter2 = sprites[blacklist and 7 or 6]
    assert(filter2.sprite == "item.copper-ore", filter2.sprite)
    assert(filter2.x_scale == 0.45, filter2.x_scale)
    assert(filter2.y_scale == 0.45, filter2.y_scale)
    util_tests.assert_equal_position(filter2.target.offset, {x = 0.2475, y = 0.0}, serpent.line(filter2.target.offset))
    if blacklist then
      local blacklist1 = sprites[5]
      local blacklist2 = sprites[8]
      assert(blacklist1.sprite == "alt-alt-filter-blacklist", blacklist1.sprite)
      assert(blacklist2.sprite == "alt-alt-filter-blacklist", blacklist2.sprite)
      assert(blacklist1.x_scale == 0.45, blacklist1.x_scale)
      assert(blacklist1.y_scale == 0.45, blacklist1.y_scale)
      assert(blacklist2.x_scale == 0.45, blacklist2.x_scale)
      assert(blacklist2.y_scale == 0.45, blacklist2.y_scale)
    end
    return entity
  end
end

for _, blacklist in pairs({true, false}) do
  tests["test_pump-jack-blacklist=" .. tostring(blacklist)] = function(player)
    local entity = player.surface.create_entity {name = "pumpjack", position = player.position, force = player.force, create_build_effect_smoke = false}
    entity.get_inventory(defines.inventory.mining_drill_modules).insert {name = "productivity-module", count = 1, quality = "epic"}
    entity.set_filter(2, "crude-oil")
    entity.set_filter(4, "lithium-brine")
    entity.mining_drill_filter_mode = blacklist and "blacklist" or "whitelist"
    entity_logic.show_alt_info_for_entity(player, entity)
    local sprites = storage[player.index]
    assert(#sprites == blacklist and 8 or 6, #sprites)
    local bg = sprites[1]
    assert(bg.sprite == "alt-alt-entity-info-white-background", bg.sprite)
    util_tests.assert_equal_array(bg.color, prototypes.quality["epic"].color, serpent.line(bg.color))
    local module = sprites[2]
    assert(module.sprite == "item.productivity-module", module.sprite)
    util_tests.assert_equal_position(module.target.offset, {x = -0.275, y = 0.7}, serpent.line(module.target.offset))
    assert(module.x_scale == 0.5, module.x_scale)
    assert(module.y_scale == 0.5, module.y_scale)
    local bg1 = sprites[3]
    assert(bg1.sprite == "alt-alt-entity-info-white-background", bg1.sprite)
    local filter1 = sprites[4]
    assert(filter1.sprite == "fluid.crude-oil", filter1.sprite)
    assert(filter1.x_scale == 0.45, filter1.x_scale)
    assert(filter1.y_scale == 0.45, filter1.y_scale)
    util_tests.assert_equal_position(filter1.target.offset, {x = -0.2475, y = 0.0}, serpent.line(filter1.target.offset))
    local bg2 = sprites[blacklist and 6 or 5]
    assert(bg2.sprite == "alt-alt-entity-info-white-background", bg2.sprite)
    local filter2 = sprites[blacklist and 7 or 6]
    assert(filter2.sprite == "fluid.lithium-brine", filter2.sprite)
    assert(filter2.x_scale == 0.45, filter2.x_scale)
    assert(filter2.y_scale == 0.45, filter2.y_scale)
    util_tests.assert_equal_position(filter2.target.offset, {x = 0.2475, y = 0.0}, serpent.line(filter2.target.offset))
    if blacklist then
      local blacklist1 = sprites[5]
      local blacklist2 = sprites[8]
      assert(blacklist1.sprite == "alt-alt-filter-blacklist", blacklist1.sprite)
      assert(blacklist2.sprite == "alt-alt-filter-blacklist", blacklist2.sprite)
      assert(blacklist1.x_scale == 0.45, blacklist1.x_scale)
      assert(blacklist1.y_scale == 0.45, blacklist1.y_scale)
      assert(blacklist2.x_scale == 0.45, blacklist2.x_scale)
      assert(blacklist2.y_scale == 0.45, blacklist2.y_scale)
    end
    return entity
  end
end

return tests