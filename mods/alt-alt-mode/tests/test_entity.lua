local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")

local function equal_pos(pos1, pos2)
  local x1 = pos1.x or pos1[1]
  local x2 = pos2.x or pos2[1]
  local y1 = pos1.y or pos1[2]
  local y2 = pos2.y or pos2[2]
  return x1 == x2 and y1 == y2
end

local function clean_sprites(player)
  for _, sprite in pairs(storage[player.index] or {}) do
    sprite.destroy()
  end
  storage[player.index] = {}
end

local function test_assembling_machine(player)  -- 3x3
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity{name="assembling-machine-1", position = position, force = force, recipe="iron-gear-wheel", create_build_effect_smoke=false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2, #sprites)
  local bg = sprites[1]
  local recipe = sprites[2]
  assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
  assert(recipe.sprite == "recipe.iron-gear-wheel", sprites[2].sprite)
  assert(recipe.target.entity == entity, recipe.target.entity)
  assert(equal_pos(recipe.target.offset, {x=0, y=-0.3}), serpent.line(recipe.target.offset))
  assert(recipe.x_scale == 0.9, recipe.x_scale)
  assert(recipe.y_scale == 0.9, recipe.y_scale)
  clean_sprites(player)
  entity.destroy()
end

local function test_cryogenic_plant(player)  -- 5x5
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity{name="cryogenic-plant", position = position, force = force, recipe="plastic-bar", create_build_effect_smoke=false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2, #sprites)
  local bg = sprites[1]
  local recipe = sprites[2]
  assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
  assert(recipe.sprite == "recipe.plastic-bar", sprites[2].sprite)
  assert(recipe.target.entity == entity, recipe.target.entity)
  assert(equal_pos(recipe.target.offset, {x=0, y=-0.3}), serpent.line(recipe.target.offset))
  assert(recipe.x_scale == 1.8, recipe.x_scale)
  assert(recipe.y_scale == 1.8, recipe.y_scale)
  clean_sprites(player)
  entity.destroy()
end

local function test_electromagnetic_plant(player)  -- 4x4
  local surface = player.surface
  local position = player.position
  local force = player.force
  local entity = surface.create_entity{name="electromagnetic-plant", position = position, force = force, recipe="copper-cable", create_build_effect_smoke=false}
  entity_logic.show_alt_info_for_entity(player, entity)
  local sprites = storage[player.index]
  assert(#sprites == 2, #sprites)
  local bg = sprites[1]
  local recipe = sprites[2]
  assert(bg.sprite == "alt-alt-entity-info-white-background", sprites[1].sprite)
  assert(recipe.sprite == "recipe.copper-cable", sprites[2].sprite)
  assert(recipe.target.entity == entity, recipe.target.entity)
  assert(equal_pos(recipe.target.offset, {x=0, y=-0.25}), serpent.line(recipe.target.offset))
  assert(recipe.x_scale == 0.9, recipe.x_scale)
  assert(recipe.y_scale == 0.9, recipe.y_scale)
  clean_sprites(player)
  entity.destroy()
end
commands.add_command("run_alt_tests", nil, function(command)
  local player = game.players[command.player_index]
  clean_sprites(player)

  test_electromagnetic_plant(player)
  test_cryogenic_plant(player)
  test_assembling_machine(player)
  player.print("All tests run successfully")
end)