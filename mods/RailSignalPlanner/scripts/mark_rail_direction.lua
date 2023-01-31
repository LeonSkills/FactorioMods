require("scripts/utility")
require("scripts/settings")

local function signal_direction_error_handler(err, player, signal, original_rail)
  err_string = err or ""
  -- Handler for if an error occurred, check if because of conflicting directions or two way
  if err_string:match("Inconsistent signals") then
    local locale = Signal.unidirectional and {"rail-signal-tool.not-unidirectional"} or {"rail-signal-tool.conflicting-directions"}
    if get_setting("force_build_rails", player) then return true end
    rendering.draw_circle{target=signal.position, color={1,0,0}, width=2, radius=0.6, surface=signal.surface, time_to_live=150}
    if signal.twin.current_signal then
      rendering.draw_circle{target=signal.twin.position, color={1,0,0}, width=2, radius=0.6, surface=signal.surface, time_to_live=150}
    end
    player.create_local_flying_text{text = locale, position=original_rail.position, time_to_live=150, speed=0.6}
    return
  end
  error("An error occurred when marking signal directions: ".. err_string)
end

local function mark_rails(player, original_rail)
  -- Mark for each rail if signals should be placed on the right, the left, or both
  for _, signal in pairs(Signal.all_signals) do
    -- signal:mark_rail_direction()
    local succeeded, err = pcall(signal.mark_rail_direction,  signal)
    if not succeeded then
      signal_direction_error_handler(err, player, signal, original_rail)
      return false
    end
  end
  -- finalize them
  for _, signal in pairs(Signal.all_signals) do
    if signal.can_be_used == nil then
      if signal.twin.can_be_used == nil and not Signal.unidirectional then
        signal:set_can_be_used()
        signal.twin:set_can_be_used()
      else
        signal:set_can_not_be_used(false)
      end
    end
  end
  return true
end

local function debug()
  for _, signal in pairs(Signal.all_signals) do
    signal:debug_direction()
  end
end

local function mark_rail_direction(player, original_rail, debug_rails)
  assert(original_rail)
  -- Mark for each rail if signals should be placed on the right, the left, or both
  local success = mark_rails(player, original_rail)
  if debug_rails then
    debug()
  end
  return success
end

return mark_rail_direction