require("scripts/utility")
require("scripts/settings")

local dummy_signals = {
  ["rail-signal"] = "dummy-rsp-rail-signal",
  ["rail-chain-signal"] = "dummy-rsp-rail-chain-signal",
}

local function destroy_current_signals(entities)
  for _, entity in pairs(entities) do
    if entity.valid then
      entity.destroy{raise_destroy=true}
    end
  end
end

local function get_start_signals(signal_chain)
  local start_signals = {}
  for _, signal in pairs(signal_chain) do
    if #signal.signals_back == 0 then
      signal.start_signal = true
      table.insert(start_signals, signal)
    end
    if #signal.signals_front == 0 then
      signal.end_signal = true
    end
  end
  return start_signals
end

local function can_place_signal(signal, player)
  if signal.can_place_signal ~= nil then
    return signal.can_place_signal
  end
  if signal.signal_entity then return true end
  --if player.surface.can_place_entity{name=get_setting("rail_signal_item", player),
  --                                   position=signal.position,
  --                                   direction=signal.direction,
  --                                   force=player.force,
  --                                   forced=true} then
  if not player.surface.entity_prototype_collides(get_setting("rail_signal_item", player),
      signal.position, false, signal.direction) then
    -- we first check if there are no other signals nearby
    local signals = player.surface.find_entities_filtered{position=signal.position,
                                                         radius=1.5,
                                                         type = {"rail-signal", "rail-chain-signal"},
                                                         direction=signal.direction
    }
    for _, other_signal in pairs(signals) do
      if equal_pos(other_signal.position, signal.position) then
        signal.can_place_signal = other_signal.direction == signal.direction
        return signal.can_place_signal
      else
        if other_signal.direction == signal.direction then
          signal.can_place_signal = false
          return false
        end
      end
    end
    -- same for ghosts
    local ghosts = player.surface.find_entities_filtered{position=signal.position,
                                                         radius=1.5,
                                                         ghost_type = {"rail-signal", "rail-chain-signal"}
    }
    for _, ghost in pairs(ghosts) do
      if equal_pos(ghost.position, signal.position) and ghost.direction ~= signal.direction then
        signal.can_place_signal = false
        return false
      else
        if ghost.direction == signal.direction then
          signal.can_place_signal = false
          return false
        end
      end
    end
    local entity = player.surface.create_entity{name=dummy_signals["rail-signal"],
                                        position=signal.position,
                                        direction=signal.direction,
                                        force=player.force,
                                        raise_built=false,
                                        create_build_effect_smoke=false,
    }
    if entity then
      local can_place = true
      if #entity.get_connected_rails() == 0 then
        can_place = false
      end
      entity.destroy{raise_destroy=false} -- always dummy
      signal.can_place_signal = can_place
      return can_place
    end
    signal.can_place_signal = false
    return false
  end
  signal.can_place_signal = false
  return false

end


local function create_signal(signal, player, signal_type)
  local signal_name = dummy_signals[signal_type]
  signal.can_be_used = false
  --if signal.signal_entity and signal.signal_entity.valid then
  --  if signal.signal_entity.to_be_deconstructed(player.force) then
  --    signal.signal_entity.cancel_deconstruction(player.force, player)
  --    if signal.signal_entity.name ~= signal_name then
  --      signal.signal_entity.order_upgrade{force=player.force, target=signal_name, player=player}
  --    end
  --  end
  --  return
  --end
  local entity = player.surface.create_entity{--name="entity-ghost",
                                              --inner_name=signal_name,
                                              name=signal_name,
                                              position=signal.position,
                                              direction=signal.direction,
                                              force=player.force,
                                              player=player,
                                              create_build_effect_smoke=false,
  }
  signal.signal_entity = entity
  signal.final_entity_type = signal_type
end

local function place_signal(signal, player, signal_chain)
  if signal.visited_placed_rail then return end
  signal.visited_placed_rail = true
  if signal.can_be_used then
    local can_be_placed = can_place_signal(signal, player)
    if can_be_placed then
      if signal.twin_signal.can_be_used then
        if can_place_signal(signal.twin_signal, player) then
          create_signal(signal, player, "rail-chain-signal")
          create_signal(signal.twin_signal, player, "rail-chain-signal")
        end
      else
        create_signal(signal, player, "rail-signal")
      end
    end
  end
  for _, front_signal in pairs(signal.signals_front) do
    place_signal(front_signal, player, signal_chain)
  end
end

--local mark_collisions()

local function draw_pretty_stuff(signals, surface)
  for _, signal in pairs(signals) do
    if signal.start_signal then
      rendering.draw_circle{color={1, 0.5, 0}, radius=0.1, filled=true, target=signal.position, surface=surface, time_to_live=600}
    end
  end
end

local function place_signals(signal_chain, cur_signals, player)
  destroy_current_signals(cur_signals, signal_chain, player) -- destroy current signals
  --mark_collisions(signal_chain) -- mark rails that collide with other rails (And thus should be preceeded by a chain signal
  -- get start of each signal_chain
  for _, start_signal in pairs(signal_chain) do
    place_signal(start_signal, player, signal_chain)
  end
  --draw_pretty_stuff(signal_chain, player.surface)
end

return place_signals