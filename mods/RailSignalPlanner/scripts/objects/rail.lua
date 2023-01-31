require("scripts/objects/signal.lua")

-- Rail object, extends LuaEntity for rail to add some more methods to it to connect neighbouring signals
Rail = {}
Rail.all_rails = {}

function Rail:new(entity, player)
  assert(entity)
  assert(player)
  local id = entity_id(entity)
  local rail = Rail.all_rails[id]
  if rail then
    if rail.broken_up then
      rail:initialize_signals()
    end
    return rail
  end
  local rail = Rail:construct(entity, player)
  Rail.all_rails[rail.id] = rail
  return rail
end

function Rail:construct(entity, player)
  local id = entity_id(entity)
  -- if Rail[id] then error("Rail object already exists") end
  local obj = {}
  setmetatable(obj, self)
  self.__index = self
  obj.id = id
  obj.entity = entity
  obj.player = player
  -- get name of the rail planner that builds this rail
  obj:initialize_signals()
  obj:connect_rails()
  return obj
end

-- methods regarding to overlaps

function Rail:mark_overlap()
  -- Get the amount of overlaps that this block contains. Not an exact amount, just if it's 0 or more than 0 is needed
  if self.num_overlaps then return end
  self.num_overlaps = #self.entity.get_rail_segment_overlaps()
  if self.num_overlaps == 0 then
    for _, connected_rail in pairs(rail_connected_rails(self.entity)) do
      if connected_rail.is_rail_in_same_rail_block_as(self.entity) then
        local connected_rail_object = Rail.all_rails[entity_id(connected_rail)]
        if connected_rail_object then
          connected_rail_object:mark_overlap()
          if connected_rail_object.num_overlaps and connected_rail_object.num_overlaps > 0 then
            self.num_overlaps = connected_rail_object.num_overlaps
            return
          end
        end
      end
    end
  end

end

-- methods to construct the graph

function Rail:connect_rails()
  -- Connect the connecting rails to the graph and connect the neighbouring signals
  local signal_placements = get_signal_placements(self.entity)
  local front_left = self.signals.front.left
  local front_right = self.signals.front.right
  local back_left
  local back_right
  if self.signals.back then
    back_left = self.signals.back.left
    back_right = self.signals.back.right
    back_right:connect_to_back(front_right)
    back_left:connect_to_back(front_left)
    back_left.twin = front_right
    front_right.twin = back_left
    back_right.twin = front_left
    front_left.twin = back_right
  else
    back_left = front_left
    back_right = front_right
    front_left.twin = front_right
    front_right.twin = front_left
  end
  if self.visited_connect_rail then
    return {back_left = back_left, back_right = back_right, front_left = front_left, front_right = front_right}
  end
  self.visited_connect_rail = true
  for _, rail_connection_direction in pairs({"left", "straight", "right"}) do
    local connected_rail_front = self.entity.get_connected_rail{rail_direction=defines.rail_direction.front, rail_connection_direction=defines.rail_connection_direction[rail_connection_direction]}
    local connected_rail_back = self.entity.get_connected_rail{rail_direction=defines.rail_direction.back, rail_connection_direction=defines.rail_connection_direction[rail_connection_direction]}

    if connected_rail_front then
      local rail_obj = Rail.all_rails[entity_id(connected_rail_front)]
      if rail_obj then
        local connections = rail_obj:connect_rails()
        if connections then
          if should_switch(self.entity, connected_rail_front) then
            connections.front_right:connect_to_back(back_left)
            front_right:connect_to_back(connections.back_left)
          else
            connections.front_left:connect_to_back(back_left)
            front_right:connect_to_back(connections.back_right)
          end
        end
      end
    end
    if connected_rail_back then
      local rail_obj = Rail.all_rails[entity_id(connected_rail_back)]
      if rail_obj then
        local connections = rail_obj:connect_rails()
        if connections then
          if should_switch(connected_rail_back, self.entity) then
            connections.front_left:connect_to_back(back_right)
            front_left:connect_to_back(connections.back_right)
          else
            connections.front_right:connect_to_back(back_right)
            front_left:connect_to_back(connections.back_left)
          end
        end
      end
    end
  end
  return {back_left = back_left, back_right = back_right, front_left = front_left, front_right = front_right}
end

function Rail:initialize_signals()
  -- For the two or four signals of this rail, create the signal object with position, direction and length
  local positions = {}
  local curve_length = 7.55 - math.sqrt(2)/2
  local rail = self.entity
  local r_x = rail.position.x
  local r_y = rail.position.y
  self.signals = {}
  self.signals.front = {}
  if rail.type == "straight-rail" then
    if rail.direction == defines.direction.east then
      -- game.print("Straight east")
      self.signals.back = {}
      self.signals.front.left = Signal:new({x = r_x - 0.5, y = r_y + 1.5}, defines.direction.west, self.entity.surface, self.player, 1, rail)
      self.signals.front.right = Signal:new({x = r_x + 0.5, y = r_y - 1.5}, defines.direction.east, self.entity.surface, self.player, 1, rail)
      self.signals.back.left = Signal:new({x = r_x + 0.5, y = r_y + 1.5}, defines.direction.west, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x - 0.5, y = r_y - 1.5}, defines.direction.east, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.north then
      -- game.print("Straight north")
      self.signals.back = {}
      self.signals.front.left = Signal:new({x = r_x + 1.5, y = r_y + 0.5}, defines.direction.south, self.entity.surface, self.player, 1, rail)
      self.signals.front.right = Signal:new({x = r_x - 1.5, y = r_y - 0.5}, defines.direction.north, self.entity.surface, self.player, 1, rail)
      self.signals.back.left = Signal:new({x = r_x + 1.5, y = r_y - 0.5}, defines.direction.south, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x - 1.5, y = r_y + 0.5}, defines.direction.north, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.northeast then
      -- game.print("Straight northeast")
      self.signals.front.left = Signal:new({x = r_x + 1.5, y = r_y - 1.5}, defines.direction.southeast, self.entity.surface, self.player, math.sqrt(2), rail)
      self.signals.front.right = Signal:new({x = r_x - 0.5, y = r_y + 0.5}, defines.direction.northwest, self.entity.surface, self.player, math.sqrt(2), rail)
    elseif rail.direction == defines.direction.southwest then
      -- game.print("Straight southwest")
      self.signals.front.left = Signal:new({x = r_x - 1.5, y = r_y + 1.5}, defines.direction.northwest, self.entity.surface, self.player, math.sqrt(2), rail)
      self.signals.front.right = Signal:new({x = r_x + 0.5, y = r_y - 0.5}, defines.direction.southeast, self.entity.surface, self.player, math.sqrt(2), rail)
    elseif rail.direction == defines.direction.southeast then
      -- game.print("Straight southeast")
      self.signals.front.left = Signal:new({x = r_x + 1.5, y = r_y + 1.5}, defines.direction.southwest, self.entity.surface, self.player, math.sqrt(2), rail)
      self.signals.front.right = Signal:new({x = r_x - 0.5, y = r_y - 0.5}, defines.direction.northeast, self.entity.surface, self.player, math.sqrt(2), rail)
    elseif rail.direction == defines.direction.northwest then
      -- game.print("Straight northwest")
      self.signals.front.left = Signal:new({x = r_x - 1.5, y = r_y - 1.5}, defines.direction.northeast, self.entity.surface, self.player, math.sqrt(2), rail)
      self.signals.front.right = Signal:new({x = r_x + 0.5, y = r_y + 0.5}, defines.direction.southwest, self.entity.surface, self.player, math.sqrt(2), rail)
    end
  else
    self.signals.back = {}
    if rail.direction == defines.direction.north then
      -- game.print("North")
      self.signals.front.left = Signal:new({x = r_x - 2.5, y = r_y - 1.5}, defines.direction.northwest, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x + 2.5, y = r_y + 3.5}, defines.direction.south, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x - 0.5, y = r_y + 3.5}, defines.direction.north, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x - 0.5, y = r_y - 3.5}, defines.direction.southeast, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.northeast then
      -- game.print("NorthEast")
      self.signals.front.left = Signal:new({x = r_x + 0.5, y = r_y - 3.5}, defines.direction.northeast, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x + 0.5, y = r_y + 3.5}, defines.direction.south, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x - 2.5, y = r_y + 3.5}, defines.direction.north, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x + 2.5, y = r_y - 1.5}, defines.direction.southwest, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.east then
      -- game.print("East")
      self.signals.front.left = Signal:new({x = r_x + 1.5, y = r_y - 2.5}, defines.direction.northeast, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x - 3.5, y = r_y + 2.5}, defines.direction.west, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x - 3.5, y = r_y - 0.5}, defines.direction.east, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x + 3.5, y = r_y - 0.5}, defines.direction.southwest, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.southeast then
      -- game.print("SouthEast")
      self.signals.front.left = Signal:new({x = r_x + 3.5, y = r_y + 0.5}, defines.direction.southeast, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x - 3.5, y = r_y + 0.5}, defines.direction.west, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x - 3.5, y = r_y - 2.5}, defines.direction.east, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x + 1.5, y = r_y + 2.5}, defines.direction.northwest, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.south then
      -- game.print("South")
      self.signals.front.left = Signal:new({x = r_x + 2.5, y = r_y + 1.5}, defines.direction.southeast, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x - 2.5, y = r_y - 3.5}, defines.direction.north, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x + 0.5, y = r_y - 3.5}, defines.direction.south, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x + 0.5, y = r_y + 3.5}, defines.direction.northwest, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.southwest then
      -- game.print("SouthWest")
      self.signals.front.left = Signal:new({x = r_x - 0.5, y = r_y + 3.5}, defines.direction.southwest, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x - 0.5, y = r_y - 3.5}, defines.direction.north, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x + 2.5, y = r_y - 3.5}, defines.direction.south, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x - 2.5, y = r_y + 1.5}, defines.direction.northeast, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.west then
      -- game.print("West")
      self.signals.front.left = Signal:new({x = r_x - 1.5, y = r_y + 2.5}, defines.direction.southwest, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x + 3.5, y = r_y - 2.5}, defines.direction.east, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x + 3.5, y = r_y + 0.5}, defines.direction.west, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x - 3.5, y = r_y + 0.5}, defines.direction.northeast, self.entity.surface, self.player, 1, rail)
    elseif rail.direction == defines.direction.northwest then
      -- game.print("NorthWest")
      self.signals.front.left = Signal:new({x = r_x - 3.5, y = r_y - 0.5}, defines.direction.northwest, self.entity.surface, self.player, curve_length, rail)
      self.signals.front.right = Signal:new({x = r_x + 3.5, y = r_y - 0.5}, defines.direction.east, self.entity.surface, self.player, curve_length, rail)
      self.signals.back.left = Signal:new({x = r_x + 3.5, y = r_y + 2.5}, defines.direction.west, self.entity.surface, self.player, 1, rail)
      self.signals.back.right = Signal:new({x = r_x - 1.5, y = r_y - 2.5}, defines.direction.southeast, self.entity.surface, self.player, 1, rail)
    end
  end
  if self.signals.back then
    self.signals.front.left.twin = self.signals.back.right
    self.signals.back.right.twin = self.signals.front.left
    self.signals.front.right.twin = self.signals.back.left
    self.signals.back.left.twin = self.signals.front.right

    -- rendering.draw_text{text="FL", color={1, 0, 0}, target=self.signals.front.left.position, time_to_live=300, surface=self.entity.surface}
    -- rendering.draw_text{text="FR", color={0, 1, 0}, target=self.signals.front.right.position, time_to_live=300, surface=self.entity.surface}
    -- rendering.draw_text{text="BL", color={0, 1, 1}, target=self.signals.back.left.position, time_to_live=300, surface=self.entity.surface}
    -- rendering.draw_text{text="BR", color={1, 1, 0}, target=self.signals.back.right.position, time_to_live=300, surface=self.entity.surface}
    -- self.signals.front.left:connect_to_back(self.signals.back.left)
    -- self.signals.front.right:connect_to_back(self.signals.back.right)
  else
    self.signals.front.left.twin = self.signals.front.right
    self.signals.front.right.twin = self.signals.front.left
    -- rendering.draw_text{text="FL", color={1, 1, 0}, target=self.signals.front.left.position, time_to_live=300, surface=self.entity.surface}
    -- rendering.draw_text{text="FR", color={1, 1, 0}, target=self.signals.front.right.position, time_to_live=300, surface=self.entity.surface}
  end
  return positions
end

-- debugging functions

function Rail:debug()
  rendering.draw_circle{target=self.entity.position, color={1, 0.8, 0}, time_to_live=300, surface=self.entity.surface, radius=0.2, filled=true}
  self:debug_connections()
  self:debug_overlaps()
end

function Rail:debug_connections()
  for _, signal in pairs(self.signals.front) do
    signal:debug_connections()
  end
  for _, signal in pairs(self.signals.back or {}) do
    signal:debug_connections()
  end
end

function Rail:debug_overlaps()
  if not self.entity.valid then return end
  rendering.draw_text{color={1, 0, self.entity.direction/8}, text = self.num_overlaps, target=self.entity.position, target_offset={(self.entity.direction-4)/4, 0}, time_to_live=300, surface=self.entity.surface}
end