
require("scripts/settings")

local function debug(player)
  for _, signal in pairs(Signal.all_signals) do
    local orig = signal.original_signal
    local new = signal.current_signal
    if not orig and not new then goto continue end
    if orig then
      if orig.type == "rail-chain-signal" then
        rendering.draw_circle{radius=0.4, width=2, color={0, 0.5, 1}, target=signal.position, surface=player.surface, time_to_live=300}
      else
        rendering.draw_circle{radius=0.4, width=2, color={1, 0.8, 0}, target=signal.position, surface=player.surface, time_to_live=300}
      end
    else
      rendering.draw_circle{radius=0.4, width=2, color={1, 1, 1}, target=signal.position, surface=player.surface, time_to_live=300}
    end
    if new then
      if new.type == "rail-chain-signal" then
        rendering.draw_circle{radius=0.6, width=2, color={0, 0.5, 1}, target=signal.position, surface=player.surface, time_to_live=300}
      else
        rendering.draw_circle{radius=0.6, width=2, color={1, 0.8, 0}, target=signal.position, surface=player.surface, time_to_live=300}
      end
    else
      rendering.draw_circle{radius=0.6, width=2, color={1, 1, 1}, target=signal.position, surface=player.surface, time_to_live=300}
    end
    ::continue::
  end
end


local function ghostify(player, revive_signals_in_range, debug_rails)
  if debug_rails then
    debug(player)
  end
  -- first restore the original signals
  for _, signal in pairs(Signal.all_signals) do
    signal:restore_signal(revive_signals_in_range)
  end


end

return ghostify