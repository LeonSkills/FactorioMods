require("scripts/objects/signal.lua")

-- Rail object, extends LuaEntity for rail to add some more methods to it to connect neighbouring signals
Rail = {}
Rail.all_rails = {}

function Rail:new(entity, player)
  local id = entity_id(entity)
  local rail = Rail.all_rails[id]
  if rail then
    if rail.broken_up then
      rail:initialize_signals()
    end
    return rail
  end
  local rail_object = Rail:construct(entity, player)
  Rail.all_rails[rail_object.id] = rail_object
  return rail_object
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
  local front_out = self.signals[defines.rail_direction.front].out_signal
  local front_in = self.signals[defines.rail_direction.front].in_signal
  local back_out = self.signals[defines.rail_direction.back].out_signal
  local back_in = self.signals[defines.rail_direction.back].in_signal
  back_in:connect_to_back(front_out)
  front_in:connect_to_back(back_out)
  if self.visited_connect_rail then
    return {back_out = back_out, back_in = back_in, front_out = front_out, front_in = front_in}
  end
  self.visited_connect_rail = true
  for _, rail_connection_direction in pairs({"left", "straight", "right"}) do
    local connected_rail_front = self.entity.get_connected_rail {rail_direction = defines.rail_direction.front, rail_connection_direction = defines.rail_connection_direction[rail_connection_direction]}
    local connected_rail_back = self.entity.get_connected_rail {rail_direction = defines.rail_direction.back, rail_connection_direction = defines.rail_connection_direction[rail_connection_direction]}

    if connected_rail_front then
      local rail_obj = Rail.all_rails[entity_id(connected_rail_front)]
      if rail_obj then
        local connections = rail_obj:connect_rails()
        if connections then
          -- Here we could check a lookup table which one should connect to which.
          -- Or we just connect it to the one with the shortest (taxicab) distance
          local dist_back = taxicab_distance(front_out.position, connections.back_in.position)
          local dist_front = taxicab_distance(front_out.position, connections.front_in.position)
          if dist_back < dist_front then
            front_out:connect_to_back(connections.back_in)
            connections.back_out:connect_to_back(front_in)
          else
            front_out:connect_to_back(connections.front_in)
            connections.front_out:connect_to_back(front_in)
          end
        end
      end
    end
    if connected_rail_back then
      local rail_obj = Rail.all_rails[entity_id(connected_rail_back)]
      if rail_obj then
        local connections = rail_obj:connect_rails()
        if connections then
          -- Here we could check a lookup table which one should connect to which.
          -- Or we just connect it to the one with the shortest (taxicab) distance
          local dist_back = taxicab_distance(back_out.position, connections.back_in.position)
          local dist_front = taxicab_distance(back_out.position, connections.front_in.position)
          if dist_back < dist_front then
            back_out:connect_to_back(connections.back_in)
            connections.back_out:connect_to_back(back_in)
          else
            back_out:connect_to_back(connections.front_in)
            connections.front_out:connect_to_back(back_in)
          end
        end
      end
    end
  end
  return {back_out = back_out, back_in = back_in, front_out = front_out, front_in = front_in}
end

function Rail:initialize_signals()
  -- For the two or four signals of this rail, create the signal object with position, direction and length
  local positions = {}
  local rail = self.entity
  local length = rail_length(rail)
  self.signals = {}
  for _, rail_direction in pairs(defines.rail_direction) do
    local rail_end = rail.get_rail_end(rail_direction)
    self.signals[rail_direction] = {}
    local out_signal = Signal:new(
            rail_end.out_signal_location.position,
            rail_end.out_signal_location.direction,
            rail_end.out_signal_location.rail_layer,
            self.entity.surface, self.player,
            0,
            rail
    )
    if rail_end.alternative_out_signal_location and not out_signal:can_place() then
      out_signal:destroy()
      out_signal = Signal:new(
              rail_end.alternative_out_signal_location.position,
              rail_end.alternative_out_signal_location.direction,
              rail_end.alternative_out_signal_location.rail_layer,
              self.entity.surface, self.player,
              0,
              rail
      )
    end

    local in_signal = Signal:new(
            rail_end.in_signal_location.position,
            rail_end.in_signal_location.direction,
            rail_end.in_signal_location.rail_layer,
            self.entity.surface, self.player,
            length,
            rail
    )
    if rail_end.alternative_in_signal_location and not in_signal:can_place() then
      in_signal:destroy()
      in_signal = Signal:new(
              rail_end.alternative_in_signal_location.position,
              rail_end.alternative_in_signal_location.direction,
              rail_end.alternative_in_signal_location.rail_layer,
              self.entity.surface, self.player,
              length,
              rail
      )
    end
    assert(in_signal)
    assert(out_signal)
    self.signals[rail_direction].out_signal = out_signal
    self.signals[rail_direction].in_signal = in_signal
    in_signal.twin = out_signal
    out_signal.twin = in_signal
  end


  -- rendering.draw_text{text="FO", color={1, 0, 0}, target=self.signals[defines.rail_direction.front].out_signal.position, time_to_live=300, surface=self.entity.surface}
  -- rendering.draw_text{text="FI", color={0, 1, 0}, target=self.signals[defines.rail_direction.front].in_signal.position, time_to_live=300, surface=self.entity.surface}
  -- rendering.draw_text{text="BO", color={0, 1, 1}, target=self.signals[defines.rail_direction.back].out_signal.position, time_to_live=300, surface=self.entity.surface}
  -- rendering.draw_text{text="BI", color={1, 1, 0}, target=self.signals[defines.rail_direction.back].in_signal.position, time_to_live=300, surface=self.entity.surface}
  -- self.signals.front.out_signal:connect_to_back(self.signals.back.out_signal)
  -- self.signals.front.in_signal:connect_to_back(self.signals.back.in_signal)

  return positions
end

-- debugging functions

function Rail:debug()
  rendering.draw_circle {target = self.entity.position, color = {1, 0.8, 0}, time_to_live = 300, surface = self.entity.surface, radius = 0.2, filled = true}
  self:debug_connections()
  self:debug_overlaps()
end

function Rail:debug_connections()
  for _, rail_direction in pairs(defines.rail_direction) do
    for _, signal in pairs(self.signals[rail_direction]) do
      signal:debug_connections()
    end
  end
end

function Rail:debug_overlaps()
  if not self.entity.valid then return end
  rendering.draw_text {color = {1, 0, self.entity.direction / 8}, text = self.num_overlaps, target = self.entity.position, target_offset = {(self.entity.direction - 4) / 4, 0}, time_to_live = 300, surface = self.entity.surface}
end