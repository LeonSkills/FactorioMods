local entity_info = require("__AlternativeAltMode__/scripts/draw_entity_info")

local function change_radius(event, amount)
  local player = game.players[event.player_index]
  local radius = settings.get_player_settings(player)["alt-alt-radius"].value + amount
  radius = math.max(0, math.min(radius, 50))
  settings.get_player_settings(player)["alt-alt-radius"] = {value=radius}
  if not storage.change_radius_events then
    storage.change_radius_events = {}
  end
  entity_info.show_alt_info_for_player(player)

  if player.selected then
    local render = rendering.draw_circle{radius=radius, color={0, 1, 1}, width=2, target=player.selected, surface=player.selected.surface, players={player}, time_to_live=60}
    storage.change_radius_events[event.player_index] = render.id
  end
end

local function increase_radius(event)
  change_radius(event, 1)
end

local function decrease_radius(event)
  change_radius(event, -1)

end

script.on_event({"alt-alt-increase-radius"}, increase_radius)
script.on_event({"alt-alt-decrease-radius"}, decrease_radius)
