local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")

local function clean_sprites(player, assert_invalid)
  for _, sprite in pairs(storage[player.index] or {}) do
    if assert_invalid then
      assert(not sprite.valid, "sprite was not destroyed")
    end
    sprite.destroy()
  end
  storage[player.index] = {}
end
local all_tests = {}

local function add_tests(tests)
  for test_name, test in pairs(tests) do
    if all_tests[test_name] then
      error("Duplicate test name " .. test_name)
    end
    all_tests[test_name] = test
  end
end

add_tests(require("__alt-alt-mode__/tests/test_assembling_machine.lua"))
add_tests(require("__alt-alt-mode__/tests/test_container.lua"))
add_tests(require("__alt-alt-mode__/tests/test_mining_drill.lua"))
add_tests(require("__alt-alt-mode__/tests/test_special_buildings.lua"))
add_tests(require("__alt-alt-mode__/tests/test_fluid_containers.lua"))
add_tests(require("__alt-alt-mode__/tests/test_pump.lua"))
add_tests(require("__alt-alt-mode__/tests/test_accumulator.lua"))
add_tests(require("__alt-alt-mode__/tests/test_electric_pole.lua"))
add_tests(require("__alt-alt-mode__/tests/test_agricultural_tower.lua"))
add_tests(require("__alt-alt-mode__/tests/test_constant_combinator.lua"))
add_tests(require("__alt-alt-mode__/tests/test_arithmetic_combinator.lua"))
add_tests(require("__alt-alt-mode__/tests/test_decider_combinator.lua"))
add_tests(require("__alt-alt-mode__/tests/test_mineables.lua"))
add_tests(require("__alt-alt-mode__/tests/test_cargo_wagon.lua"))

local function run_tests(player)
  clean_sprites(player, false)
  local num_tests = 0
  local tested_entity_types = {}
  for test_name, func in pairs(all_tests) do
    local success, ret = xpcall(func, debug.traceback, player)
    if success then
      if ret then
        if type(ret) == "table" then  -- testing rolling stock
          tested_entity_types[ret[1].type] = true
          ret[1].destroy()
          for _, entity in pairs(ret[2]) do
            entity.destroy()
          end
        else
          tested_entity_types[ret.type] = true
          ret.destroy()
        end
      end
    else
      error("Test '" .. test_name .. "' failed. " .. ret)
    end
    num_tests = num_tests + 1
    clean_sprites(player, false)
  end
  player.print("Ran all " .. num_tests .. " tests successfully")
  local not_tested = {}
  for _, type in pairs(entity_logic.supported_types) do
    if not tested_entity_types[type] then
      table.insert(not_tested, type)
    end
  end
  if #not_tested > 0 then
    game.print("No test for " .. #not_tested .. " types: " .. serpent.line(not_tested))
  else
    game.print("All types tested!")
  end
end

commands.add_command("run_alt_tests", nil, function(command)
  local player = game.players[command.player_index]
  run_tests(player)
end)
