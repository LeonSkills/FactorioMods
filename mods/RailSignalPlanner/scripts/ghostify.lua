
require("scripts/settings")

local function ghostify(signal_chain, player)
  local rail_chain_signal_item = game.item_prototypes[get_setting("rail_chain_signal_item", player)]
  local rail_signal_item = game.item_prototypes[get_setting("rail_signal_item", player)]
  local rail_chain_signal = rail_chain_signal_item.place_result.name
  local rail_signal = rail_signal_item.place_result.name
  for _, signal in pairs(signal_chain) do
    local orig = signal.original_signal
    local new = signal.signal_entity
    local new_type
    local new_name
    local surface
    if new and new.valid then
      surface = new.surface
      new_type = signal.final_entity_type or new.name
    else
      new_type = signal.final_entity_type
      surface = player.surface
    end
    if new_type == "rail-signal" then
      new_name = rail_signal
    elseif new_type == "rail-chain-signal" then
      new_name = rail_chain_signal
    end
    if orig then
      if new then
        -- there was an original one, and a new one
        -- destroy the new one, create the old one, and order it to be upgraded
        new.destroy{raise_destroy=false}  --always dummy
        local new_entity = surface.create_entity{name=orig.name, position=signal.position, direction=signal.direction,
                                                 force=player.force, player=player,
                                                 raise_built=true, create_build_effect_smoke=false
        }
        if new_entity and new_entity.valid then
          new_entity.health = orig.health
          if orig.name ~= new_name then
            local can_be_upgraded = new_entity.order_upgrade{force=player.force, target=new_name, player=player}
            if not can_be_upgraded then
              new_entity.order_deconstruction(player.force, player)
              surface.create_entity{name="entity-ghost", inner_name=new_name, position=signal.position,
                                    direction=signal.direction, force=player.force, player=player,
                                    create_build_effect_smoke=false}
            end
          end
        end
      else
        -- there was an original one, but not a new one
        -- recreate it and mark it for deconstruction
        local new_entity = orig.surface.create_entity{name=orig.name, position=signal.position, direction=signal.direction,
                                                      force=player.force, player=player,
                                                      raise_built=true, create_build_effect_smoke=false
        }
        if new_entity then
          new_entity.health = orig.health
          new_entity.order_deconstruction(player.force, player)
        end
      end
    else
      if new then
        -- there wasn't an original one, but there is a new one
        -- destroy it and place a ghost
        new.destroy{raise_destroy=false} -- always dummy
        surface.create_entity{name="entity-ghost", inner_name=new_name, position=signal.position,
                              direction=signal.direction, force=player.force, player=player,
                              create_build_effect_smoke=false
        }
      else
        -- there wasn't an original nor a new one,
        -- do nothing
      end
    end
  end
end

return ghostify