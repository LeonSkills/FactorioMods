function equal_pos(pos1, pos2)
  return pos1.x == pos2.x and pos1.y == pos2.y
end

function rail_connected_rails(rail)
  -- get all rails connected to this rail
  local connected_rails = {}
  for _, connection_direction in pairs({"left", "straight", "right"}) do
    for _, rail_direction in pairs(defines.rail_direction) do
      local connected_rail = rail.get_connected_rail{rail_direction=rail_direction, rail_connection_direction=defines.rail_connection_direction[connection_direction]}
      if connected_rail then
        table.insert(connected_rails, connected_rail)
      end
    end
  end
  return connected_rails
end

function get_signal_placements(rail)
  local positions = {}
  local r_x = rail.position.x
  local r_y = rail.position.y
  if rail.type == "straight-rail" then
    if rail.direction == defines.direction.east then
      positions.back ={left={position={x=r_x+0.5, y=r_y+1.5}, direction=defines.direction.west, length=1}, right={position={x=r_x-0.5, y=r_y-1.5}, direction=defines.direction.east, length=1}}
      positions.front = {left={position={x=r_x-0.5, y=r_y+1.5}, direction=defines.direction.west, length=1}, right={position={x=r_x+0.5, y=r_y-1.5}, direction=defines.direction.east, length=1}}
    elseif rail.direction == defines.direction.north then
      positions.front = {left={position={x=r_x+1.5, y=r_y+0.5}, direction=defines.direction.south, length=1}, right={position={x=r_x-1.5, y=r_y-0.5}, direction=defines.direction.north, length=1}}
      positions.back = {left={position={x=r_x+1.5, y=r_y-0.5}, direction=defines.direction.south, length=1}, right={position={x=r_x-1.5, y=r_y+0.5}, direction=defines.direction.north, length=1}}
    elseif rail.direction == defines.direction.northeast then
      --game.print("Northeast straight " .. (r_x + r_y) % 4 )
      if (r_x + r_y) % 4 == 2 then
        positions.front = {left={position={x=r_x+1.5, y=r_y-1.5}, direction=defines.direction.southeast, length=1.5}, right={position={x=r_x-0.5, y=r_y+0.5}, direction=defines.direction.northwest, length=1.5}}
      elseif (r_x + r_y) % 4 == 0 then
        positions.front = {left={position={x=r_x+1.5, y=r_y-1.5}, direction=defines.direction.southeast, length=1.5}, right={position={x=r_x-0.5, y=r_y+0.5}, direction=defines.direction.northwest, length=1.5}}
      end
    elseif rail.direction == defines.direction.southwest then
      --game.print("Southwest straight " .. (r_x + r_y) % 4 )
      if (r_x + r_y) % 4 == 2 then
        positions.front = {right={position={x=r_x+0.5, y=r_y-0.5}, direction=defines.direction.southeast, length=1.5}, left={position={x=r_x-1.5, y=r_y+1.5}, direction=defines.direction.northwest, length=1.5}}
      elseif (r_x + r_y) % 4 == 0 then
        positions.front = {right={position={x=r_x+0.5, y=r_y-0.5}, direction=defines.direction.southeast, length=1.5}, left={position={x=r_x-1.5, y=r_y+1.5}, direction=defines.direction.northwest, length=1.5}}
      end
    elseif rail.direction == defines.direction.southeast then
      --game.print("Southeast straight " .. (r_x + r_y) % 4 )
      if (r_x + r_y) % 4 == 2 then
        positions.front = {right={position={x=r_x-0.5, y=r_y-0.5}, direction=defines.direction.northeast, length=1.5}, left={position={x=r_x+1.5, y=r_y+1.5}, direction=defines.direction.southwest, length=1.5}}
      elseif (r_x + r_y) % 4 == 0 then
        positions.front = {right={position={x=r_x-0.5, y=r_y-0.5}, direction=defines.direction.northeast, length=1.5}, left={position={x=r_x+1.5, y=r_y+1.5}, direction=defines.direction.southwest, length=1.5}}
      end
    elseif rail.direction == defines.direction.northwest then
      --game.print("Northwest straight " .. (r_x + r_y) % 4 )
      if (r_x + r_y) % 4 == 2 then
        positions.front = {left={position={x=r_x-1.5, y=r_y-1.5}, direction=defines.direction.northeast, length=1.5}, right={position={x=r_x+0.5, y=r_y+0.5}, direction=defines.direction.southwest, length=1.5}}
      elseif (r_x + r_y) % 4 == 0 then
        positions.front = {left={position={x=r_x-1.5, y=r_y-1.5}, direction=defines.direction.northeast, length=1.5}, right={position={x=r_x+0.5, y=r_y+0.5}, direction=defines.direction.southwest, length=1.5}}
      end
    end
  else
    if rail.direction == defines.direction.north then
      --game.print("North")
      positions.back = {right={position={x=r_x-0.5, y=r_y-3.5}, direction=defines.direction.southeast, length=1}, left={position={x=r_x-0.5, y=r_y+3.5}, direction=defines.direction.north, length=1}}
      positions.front = {right={position={x=r_x+2.5, y=r_y+3.5}, direction=defines.direction.south, length=7}, left={position={x=r_x-2.5, y=r_y-1.5}, direction=defines.direction.northwest, length=7}}
    elseif rail.direction == defines.direction.northeast then
      --game.print("NorthEast")
      positions.back = {right={position={x=r_x+2.5, y=r_y-1.5}, direction=defines.direction.southwest, length=1}, left={position={x=r_x-2.5, y=r_y+3.5}, direction=defines.direction.north, length=1}}
      positions.front = {right={position={x=r_x+0.5, y=r_y+3.5}, direction=defines.direction.south, length=7}, left={position={x=r_x+0.5, y=r_y-3.5}, direction=defines.direction.northeast, length=7}}
    elseif rail.direction == defines.direction.east then
      --game.print("East")
      positions.back = {right={position={y=r_y-0.5, x=r_x+3.5}, direction=defines.direction.southwest, length=1}, left={position={y=r_y-0.5, x=r_x-3.5}, direction=defines.direction.east, length=1}}
      positions.front = {right={position={y=r_y+2.5, x=r_x-3.5}, direction=defines.direction.west, length=7}, left={position={y=r_y-2.5, x=r_x+1.5}, direction=defines.direction.northeast, length=7}}
    elseif rail.direction == defines.direction.southeast then
      --game.print("SouthEast")
      positions.back = {right={position={y=r_y+2.5, x=r_x+1.5}, direction=defines.direction.northwest, length=1}, left={position={y=r_y-2.5, x=r_x-3.5}, direction=defines.direction.east, length=1}}
      positions.front = {right={position={y=r_y+0.5, x=r_x-3.5}, direction=defines.direction.west, length=7}, left={position={y=r_y+0.5, x=r_x+3.5}, direction=defines.direction.southeast, length=7}}
    elseif rail.direction == defines.direction.south then
      --game.print("South")
      positions.back = {right={position={x=r_x+0.5, y=r_y+3.5}, direction=defines.direction.northwest, length=1}, left={position={x=r_x+0.5, y=r_y-3.5}, direction=defines.direction.south, length=1}}
      positions.front = {right={position={x=r_x-2.5, y=r_y-3.5}, direction=defines.direction.north, length=7}, left={position={x=r_x+2.5, y=r_y+1.5}, direction=defines.direction.southeast, length=7}}
    elseif rail.direction == defines.direction.southwest then
      --game.print("SouthWest")
      positions.back = {right={position={x=r_x-2.5, y=r_y+1.5}, direction=defines.direction.northeast, length=1}, left={position={x=r_x+2.5, y=r_y-3.5}, direction=defines.direction.south, length=1}}
      positions.front = {right={position={x=r_x-0.5, y=r_y-3.5}, direction=defines.direction.north, length=7}, left={position={x=r_x-0.5, y=r_y+3.5}, direction=defines.direction.southwest, length=7}}
    elseif rail.direction == defines.direction.west then
      --game.print("West")
      positions.back = {right={position={y=r_y+0.5, x=r_x-3.5}, direction=defines.direction.northeast, length=1}, left={position={y=r_y+0.5, x=r_x+3.5}, direction=defines.direction.west, length=1}}
      positions.front = {right={position={y=r_y-2.5, x=r_x+3.5}, direction=defines.direction.east, length=7}, left={position={y=r_y+2.5, x=r_x-1.5}, direction=defines.direction.southwest, length=7}}
    elseif rail.direction == defines.direction.northwest then
      --game.print("NorthWest")
      positions.back = {right={position={y=r_y-2.5, x=r_x-1.5}, direction=defines.direction.southeast, length=1}, left={position={y=r_y+2.5, x=r_x+3.5}, direction=defines.direction.west, length=1}}
      positions.front = {right={position={y=r_y-0.5, x=r_x+3.5}, direction=defines.direction.east, length=7}, left={position={y=r_y-0.5, x=r_x-3.5}, direction=defines.direction.northwest, length=7}}
    end
  end
  --rendering.draw_circle{color={1, 0, 0}, radius=0.2, filled=true, target=positions.front.right.position, time_to_live=6000, surface=rail.surface}
  --rendering.draw_circle{color={0, 1, 0}, radius=0.2, filled=true,  target=positions.front.left.position, time_to_live=6000, surface=rail.surface}
  --if positions.back then
  --  rendering.draw_circle{color={0, 0, 1}, radius=0.2, filled=true, target=positions.back.right.position, time_to_live=6000, surface=rail.surface}
  --  rendering.draw_circle{color={0, 1, 0.5}, radius=0.2, filled=true, target=positions.back.left.position, time_to_live=6000, surface=rail.surface}
  --end
  return positions
end

function should_switch(rail1, rail2)
  -- Don't ask
  -- Or do actually, curious to know who is reading this
  if rail1.type == "straight-rail" then
    if rail2.type == "straight-rail" then
      return rail1.direction % 2 == 1
    else
      if rail1.direction % 2 == 0 then
        return rail2.direction <= 3
      else
        return rail2.direction % 2 == 0
      end
    end
  else
    if rail2.type == "curved-rail" then
      return true
    end
    return math.abs(rail2.direction - rail1.direction) <= 1
  end
end

function get_collision_positions(signal)
  for _, rail in pairs(signal.rails) do
    rail = rail.entity
    local r_x = rail.position.x
    local r_y = rail.position.y
    local positions = {}
    if rail.type == "straight-rail" then
      if rail.direction == defines.direction.east then
        positions.back = {left={{2, 0}}, right={{-2, 0}}}
        positions.front = {left={{0.5, 0}}, right={{-0.5, 0}}}
      elseif rail.direction == defines.direction.north then
        positions.back = {left={{0, -2}}, right={{0, 2}}}
        positions.front = {left={{0, -0.5}}, right={{0, 0.5}}}
      elseif rail.direction == defines.direction.northeast then
          positions.front = {left={{-0.5, -1.5}}, right={{1.5, 0.5}}}
      elseif rail.direction == defines.direction.southwest then
          positions.front = {left={{1, 1.5}}, right={{-1.5, -0.5}}}
      elseif rail.direction == defines.direction.southeast then
          positions.front = {left={{1.5, -0.5}}, right={{-0.5, 1.5}}}
      elseif rail.direction == defines.direction.northwest then
          positions.front = {left={{-1.5, 0.5}}, right={{0.5, -1.5}}}
      end
    else
      if rail.direction == defines.direction.north then
        --game.print("North")
        positions.front = {left={}, right={{0, 0}, {0.8, 1}, {-0.5, -0.5}, {1, 2.5}, {-1.5, -2.1}}}
        positions.back = {left={{1, 5}}, right={{-2.7, -3.7}}}
      elseif rail.direction == defines.direction.northeast then
        --game.print("NorthEast")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      elseif rail.direction == defines.direction.east then
        --game.print("East")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      elseif rail.direction == defines.direction.southeast then
        --game.print("SouthEast")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      elseif rail.direction == defines.direction.south then
        --game.print("South")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      elseif rail.direction == defines.direction.southwest then
        --game.print("SouthWest")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      elseif rail.direction == defines.direction.west then
        --game.print("West")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      elseif rail.direction == defines.direction.northwest then
        --game.print("NorthWest")
        positions.front = {left={}, right={}}
        positions.back = {left={}, right={}}
      end
    end
    for i, pos in pairs(positions.front.right) do
      position = {x=r_x + pos[1], y=r_y + pos[2]}
      positions.front.right[i] = pos
      -- rendering.draw_circle{color={1, 0, 0}, radius=0.2, filled=true, target.position, time_to_live=6000, surface=rail.surface}
      local num_entities = #rail.surface.find_entities_filtered{type={"straight-rail", "curved-rail"}, position = position, radius=0.1, force=rail.force}
      -- rendering.draw_text{color={0, 1, 1}, text=num_entities, target.position, time_to_live=6000, surface=rail.surface}
    end
    for i, pos in pairs(positions.front.left) do
      position = {x=r_x + pos[1], y=r_y + pos[2]}
      positions.front.left[i] = {x=r_x + pos[1], y=r_y + pos[2]}
      -- rendering.draw_circle{color={0, 1, 0}, radius=0.2, filled=true,  target.position, time_to_live=6000, surface=rail.surface}
      local num_entities = #rail.surface.find_entities_filtered{type={"straight-rail", "curved-rail"}, position = position, radius=0.1, force=rail.force}
      -- rendering.draw_text{color={0, 1, 1}, text=num_entities, target.position, time_to_live=6000, surface=rail.surface}
    end
    if positions.back then
      for i, pos in pairs(positions.back.right) do
        position = {x=r_x + pos[1], y=r_y + pos[2]}
        positions.back.right[i] = pos
        -- rendering.draw_circle{color={0, 0, 1}, radius=0.2, filled=true, target.position, time_to_live=6000, surface=rail.surface}
        local num_entities = #rail.surface.find_entities_filtered{type={"straight-rail", "curved-rail"}, position = position, radius=0.1, force=rail.force}
        -- rendering.draw_text{color={0, 1, 1}, text=num_entities, target.position, time_to_live=6000, surface=rail.surface}
      end
      for i, pos in pairs(positions.back.left) do
        position = {x=r_x + pos[1], y=r_y + pos[2]}
        positions.back.left[i] = pos
        -- rendering.draw_circle{color={0, 1, 0.5}, radius=0.2, filled=true, target.position, time_to_live=6000, surface=rail.surface}
        local num_entities = #rail.surface.find_entities_filtered{type={"straight-rail", "curved-rail"}, position = position, radius=0.1, force=rail.force}
        -- rendering.draw_text{color={0, 1, 1}, text=num_entities, target.position, time_to_live=6000, surface=rail.surface}
      end
    end
  end
  return
end