local util_tests = require("__alt-alt-mode__/tests/util_tests")

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
      error("Dupclicate test name " .. test_name)
    end
    all_tests[test_name] = test
  end
end

add_tests(require("__alt-alt-mode__/tests/test_assembling_machine.lua"))
add_tests(require("__alt-alt-mode__/tests/test_container.lua"))
add_tests(require("__alt-alt-mode__/tests/test_special_buildings.lua"))

local function run_tests(player)
  clean_sprites(player, false)
  local num_tests = 0
  for test_name, func in pairs(all_tests) do
    func(player)
    -- local success, err = pcall(func, player)
    -- if not success then
    --   error("Test '" .. test_name .. "' failed. " ..  err)
    -- end
    num_tests = num_tests + 1
    clean_sprites(player, true)
  end
  player.print("Ran all " .. num_tests .. " tests successfully")
end

commands.add_command("run_alt_tests", nil, function(command)
  local player = game.players[command.player_index]
  run_tests(player)
end)
