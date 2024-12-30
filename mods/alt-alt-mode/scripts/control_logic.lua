local entity_info = require("__alt-alt-mode__/scripts/draw_entity_info")
local draw_functions = require("__alt-alt-mode__/scripts/draw_functions")

local function change_radius(event, amount)
  local player = game.players[event.player_index]
  local radius = settings.get_player_settings(player)["alt-alt-radius"].value + amount
  radius = math.max(0, math.min(radius, 50))
  settings.get_player_settings(player)["alt-alt-radius"] = {value = radius}
  entity_info.show_alt_info_for_player(player)
  draw_functions.draw_radius_indicator(player, nil, radius, 60)
end

local function increase_radius(event)
  change_radius(event, 1)
end

local function decrease_radius(event)
  change_radius(event, -1)

end

script.on_event({"alt-alt-increase-radius"}, increase_radius)
script.on_event({"alt-alt-decrease-radius"}, decrease_radius)
