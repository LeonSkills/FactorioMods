local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")
local test = require("__alt-alt-mode__/tests/util_tests")

local tests = {}

for filter_type, temp_filters in pairs({normal = {15, 5000}, filters = {70, 200}}) do
  tests["test-pump-with-filters:" .. filter_type] = function(player)
    local entity = player.surface.create_entity {name = "pump", position = player.position, force = player.force, create_build_effect_smoke = false}
    entity_logic.show_alt_info_for_entity(player, entity)
    assert(#storage[player.index] == 0, "Some sprites where drawn when it shouldn't have")
    entity.fluidbox.set_filter(1, {name = "steam", minimum_temperature = temp_filters[1], maximum_temperature = temp_filters[2]})
    entity_logic.show_alt_info_for_entity(player, entity)
    local sprites = storage[player.index]
    assert(#sprites == filter_type == "normal" and 2 or 4, #sprites)
    test.assert_sprite_equal(sprites[1], {sprite = test.bg_sprite, color = test.black})
    test.assert_sprite_equal(sprites[2], {sprite = "fluid.steam", target = {entity, {0, 0}}, scale = 0.45})
    if filter_type == "filters" then
      test.assert_sprite_equal(sprites[3], {text = {"", "≥", {"", "", "70", ""}, {"si-unit-degree-celsius"}}, target = {entity, {-.225, 0.1485}}, text_scale = 0.35})
      local text = {"", "≤", {"", "", "200", ""}, {"si-unit-degree-celsius"}}
      test.assert_sprite_equal(sprites[4], {text = text, target = {entity, {-.225, -0.1485}}, text_scale = 0.35})
    end
    return entity
  end
end

return tests