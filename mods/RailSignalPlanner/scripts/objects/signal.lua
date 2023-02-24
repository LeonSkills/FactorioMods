require("scripts/settings")
require("api")

Signal = {}
Signal.all_signals = {}

function Signal:new(position, direction, surface, player, length, rail)
  local id = create_unique_id(position, direction)
  local signal = Signal.all_signals[id]
  if signal then
    signal.player = signal.player or player
    signal.length = signal.length or length
    if signal.rails[entity_id(rail)] then
      signal.rails[entity_id(rail)] = rail
    end
    signal.invalid = false
    return signal
  end
  local signal_object = Signal:construct(position, direction, surface, player, length, rail)
  Signal.all_signals[signal_object.id] = signal_object
  return signal_object
end

function Signal:construct(position, direction, surface, player, length, rail)
  local id = create_unique_id(position, direction)
  -- if Signal.all_signals[id] then error("Signal already exists") end
  local obj = {}
  setmetatable(obj, self)
  self.__index = self
  obj.id = id
  obj.position = position
  obj.direction = direction
  obj.surface = surface
  obj.player = player
  obj.length = length
  obj.signals_front = {}
  obj.signals_back = {}
  obj.rails = {[entity_id(rail)] = rail}
  obj.planner = Rail.planners[rail.name]
  obj.can_change = false
  if not obj.planner and get_supported_rail(rail.name) then
    obj.planner = get_supported_rail(rail.name)
  end
  if obj.planner then
    obj.can_change = true
    obj.signal_entities = {}
    obj.signal_entities["rail-signal"] = Signal.settings.rail_signal_item[obj.planner]
    obj.signal_entities["rail-chain-signal"] = Signal.settings.rail_chain_signal_item[obj.planner]
    if not obj.signal_entities["rail-signal"] or not obj.signal_entities["rail-chain-signal"] then
      obj.can_change = false
    end
  end
  obj.rail_signal_distance = Signal.settings.rail_signal_distance[obj.planner] or 0
  obj.train_length = Signal.settings.train_length[obj.planner] or 0
  obj:get_original_signal()
  obj.invalid = false
  obj.visited_clean_up_long = {}
  obj.visited_place_signal_everywhere = {}

  obj.neighbouring_signals = {} -- signal entities that neighbour these
  return obj
end

-- function of building the graph

function Signal:connect_to_back(other)
  -- Connect this signal to the given signal
  if not contains(self.signals_back, other) then
    table.insert(self.signals_back, other)
  end
  if not contains(other.signals_front, self) then
    table.insert(other.signals_front, self)
  end
end

function Signal:get_original_signal()
  -- Find the original signal at the signals location
  local signals = self.surface.find_entities_filtered {type = {"rail-signal", "rail-chain-signal"}, position = self.position, direction = self.direction, force = self.player.force}
  if #signals == 1 then
    self.original_signal = {}
    self.original_signal.type = signals[1].type
    self.original_signal.name = signals[1].name
    self.original_signal.health = signals[1].health
    self.original_signal.last_user = signals[1].last_user
    self.original_signal.is_ghost = false
    self.current_signal = signals[1]
    if self.current_signal.name == "invisible_chain_signal" then
      self.can_change = false
    end
    if self.current_signal.to_be_deconstructed() then
      self.to_be_deconstructed = true
      self.current_signal.destroy {raise_destroy = false}
      self.current_signal = nil
    end
    return
  end
  local ghost_signals = self.surface.find_entities_filtered {ghost_type = {"rail-signal", "rail-chain-signal"}, position = self.position, direction = self.direction, force = self.player.force}
  if #ghost_signals == 1 then
    self.original_signal = {}
    self.original_signal.type = ghost_signals[1].ghost_type
    self.original_signal.name = ghost_signals[1].ghost_name
    self.original_signal.last_user = ghost_signals[1].last_user
    self.original_signal.is_ghost = true
    self.current_signal = ghost_signals[1]
    return
  end
end


-- functions for marking rail directions
function Signal:set_can_be_used()
  if self.can_be_used == false then
    error("Inconsistent signals")
  end
  self.can_be_used = true
end

function Signal:set_can_not_be_used(mark_twin_can_be_used)
  mark_twin_can_be_used = mark_twin_can_be_used == nil and true
  if self.can_be_used == true then
    error("Inconsistent signals")
  end
  self.can_be_used = false
  if mark_twin_can_be_used then
    self.twin:set_can_be_used()
  end
end

function Signal:mark_rail_direction()
  if not self.current_signal then return end
  local twin = self.twin
  if not twin.current_signal then
    twin:mark_disallowed("front")
    twin.can_be_used = nil
    twin:mark_disallowed("back")
  else
    if Signal.unidirectional then
      error("Inconsistent signals")
    end
    self:mark_allowed("front")
    self.can_be_used = nil
    self:mark_allowed("back")
    twin:mark_allowed("front")
    twin.can_be_used = nil
    twin:mark_allowed("back")
  end
end

function Signal:mark_allowed(direction)
  -- We can place a signal here
  local signals_to_check = {self}
  while #signals_to_check > 0 do
    local current_signal = table.remove(signals_to_check, 1)
    if current_signal.can_be_used == true then goto continue end
    current_signal:set_can_be_used()
    local next_signals = (direction == "front") and current_signal.signals_front or current_signal.signals_back
    if #next_signals ~= 1 then goto continue end
    for _, next_signal in pairs(next_signals) do
      table.insert(signals_to_check, next_signal)
    end
    :: continue ::
  end
end

local i = 0
function Signal:mark_disallowed(direction)
  -- We can't place a signal here, or to its neighbours
  if self.can_be_used == false then return end
  local next_signals = (direction == "front") and self.signals_front or self.signals_back
  local prev_signals = (direction == "front") and self.signals_back or self.signals_front
  local all_no = true
  if not Signal.unidirectional then
    for _, prev_signal in pairs(prev_signals) do
      if prev_signal.can_be_used ~= false then
        all_no = false
        break
      end
    end
  end
  if Signal.unidirectional or all_no or #prev_signals == 1 then
    self:set_can_not_be_used()
    for _, next_signal in pairs(next_signals) do
      next_signal:mark_disallowed(direction)
    end
  end
  if Signal.unidirectional then
    for _, prev_signal in pairs(prev_signals) do
      prev_signal:mark_disallowed(direction == "front" and "back" or "front")
    end
  end
end

-- functions for placing and destroying signals

function Signal:change_signal(type)
  -- Turn this signal (and its twin) in the signal of the given type, or destroy if type is nil
  if not self.can_change then return end -- This signal is not allowed to be changed (not supported)
  if type == nil then
    if self.current_signal then
      self.current_signal.destroy {raise_destroy = false}
      self.current_signal = nil
      if self.twin.current_signal then
        self.twin.current_signal.destroy {raise_destroy = false}
        self.twin.current_signal = nil
      end
    end
    return
  end
  if self.twin.can_be_used then
    type = "rail-chain-signal"
  end
  if not self.signal_entities then return end
  local signal_name = self.signal_entities[type]

  if self.current_signal then
    if self.current_signal.name == signal_name and (self.twin.current_signal == nil or self.twin.current_signal.type == type) then return end
    self.current_signal.destroy {raise_destroy = false}
    self.current_signal = nil
  end
  if self.twin.current_signal then
    self.twin.current_signal.destroy {raise_destroy = false}
    self.twin.current_signal = nil
  end
  if #self.surface.find_entities_filtered {position = self.position, type = "entity-ghost"} > 0 then return end
  if not self.surface.can_place_entity {name = signal_name, position = self.position, direction = self.direction, force = self.force} then return end
  self.current_signal = self.surface.create_entity {name = signal_name, position = self.position, direction = self.direction, force = self.player.force, player = self.player, raise_built = false, create_build_effect_smoke = false}
  if self.current_signal and #self.current_signal.get_connected_rails() == 0 then
    self.current_signal.destroy {raise_destroy = false}
    self.current_signal = nil
  elseif self.twin.can_be_used then
    if self.surface.can_place_entity {name = signal_name, position = self.twin.position, direction = self.twin.direction, force = self.force} then
      self.twin.current_signal = self.surface.create_entity {name = signal_name, position = self.twin.position, direction = self.twin.direction, force = self.player.force, player = self.player, raise_built = false, create_build_effect_smoke = false}
      if self.twin.current_signal and #self.twin.current_signal.get_connected_rails() == 0 then
        self.current_signal.destroy {raise_destroy = false}
        self.twin.current_signal.destroy {raise_destroy = false}
        self.current_signal = nil
        self.twin.current_signal = nil
      end
    else
      self.current_signal.destroy {raise_destroy = false}
      self.current_signal = nil
    end
  end
end

function Signal:place_signal_everywhere(dir)
  -- We place a signal everywhere where possible to detect merges/splits/intersections later
  -- To reduce the amount of gaps of 3 as much as possible we propagate this functions forwards and backwards first
  local signals_to_check = {front = {}, back = {}}
  if not self.visited_place_signal_everywhere["front"] and dir ~= "back" then
    signals_to_check["front"] = {self}
  end
  if not self.visited_place_signal_everywhere["back"] and dir ~= "front" then
    signals_to_check["back"] = {self}
  end
  while #signals_to_check.front > 0 or #signals_to_check.back > 0 do
    for _, direction in pairs({"front", "back"}) do
      while #signals_to_check[direction] > 0 do
        local current_signal = table.remove(signals_to_check[direction], 1)
        if current_signal.visited_place_signal_everywhere[direction] then goto continue end
        current_signal.visited_place_signal_everywhere[direction] = true
        if current_signal.can_be_used then
          if current_signal.twin.can_be_used then
            current_signal:change_signal("rail-chain-signal")
          elseif not current_signal.current_signal then
            current_signal:change_signal("rail-signal")
          end
        end
        for _, signal in pairs(direction == "front" and current_signal.signals_front or current_signal.signals_back) do
          table.insert(signals_to_check[direction], signal)
        end
        :: continue ::
      end
    end
  end
end

-- functions for detecting overlaps and marking entrances and exits

function Signal:check_if_entrance()
  if not self.current_signal then return end
  if #self.signals_front > 0 then
    local _, rail_ahead = next(self.signals_front[1].rails)
    if Rail.all_rails[entity_id(rail_ahead)].num_overlaps > 0 then
      self:mark_entrance()
    end
  end
end

function Signal:check_if_exit()
  if not self.current_signal then return end
  if #self.signals_back > 0 then
    local _, rail_before = next(self.signals_back[1].rails)
    if Rail.all_rails[entity_id(rail_before)].num_overlaps > 0 then
      self:mark_exit()
    end
  end
end

function Signal:mark_entrance()
  self.is_entrance = true
end

function Signal:mark_exit()
  self.is_exit = true
end

-- functions to clear exits

function Signal:clear_exit(max_train_length, visited_signals)
  -- Remove all rail signals in front of the exit for length <train_length>
  max_train_length = max_train_length or self.train_length
  local current_signal = self
  local distance_left = max_train_length
  while distance_left >= 0 do
    if #current_signal.signals_front == 0 then return end
    if #current_signal.signals_front > 1 then
      self.player.print("Exit contains a branch, should not happen. Please report to mod author", {1, 0, 0})
      return
    end
    distance_left = distance_left - current_signal.length
    current_signal = current_signal.signals_front[1]
    if current_signal.is_entrance then
      current_signal:change_signal(nil) -- can swap these two around or have both rail. Current (chain followed by none) is optimal.
      self:change_signal("rail-chain-signal")
      return
    end
    if current_signal.current_signal then
      if current_signal.current_signal.type == "rail-chain-signal" then
        current_signal:change_signal(nil) -- can swap these two around or have both rail. Current (chain followed by none) is optimal.
        self:change_signal("rail-chain-signal")
        return
      end
      if distance_left == 0 then
        current_signal:clean_up_long_stretch("front")
        return
      else
        current_signal:change_signal(nil)
      end
    end
  end
  -- we find the next signal to clean up long stretch on that one
  while true do
    if current_signal.is_entrance or current_signal.is_exit then return end
    if current_signal.current_signal then
      current_signal:clean_up_long_stretch("front")
    end
    if #current_signal.signals_front ~= 1 or #current_signal.signals_back > 1 or current_signal.is_entrance or current_signal.is_exit then return end
    current_signal = current_signal.signals_front[1]
    if current_signal.visited_clean_up_long["front"] then return end
  end
end

function Signal:clean_up_long_stretch(direction, max_distance, bidirectional)
  -- Keep the signals on a long stretch every <rail_signal_distance>
  if self.visited_clean_up_long[direction] then return end
  self.visited_clean_up_long[direction] = true
  max_distance = max_distance or self.rail_signal_distance
  if self.twin.can_be_used or bidirectional then
    if not (self.is_exit or self.is_entrance or self.twin.is_exit or self.twin.is_entrance or self.original_signal) then
      self:change_signal(nil)
    end
    local next_signals = direction == "front" and self.signals_front or self.signals_back
    for _, next_signal in pairs(next_signals) do
      next_signal:clean_up_long_stretch(direction, nil, true)
    end
    return
  end
  local distance_left = max_distance
  local current_signal = self
  if current_signal.current_signal and current_signal.current_signal.type == "rail-chain-signal" then return end
  if current_signal.is_entrance or current_signal.is_exit then return end
  local last_possible_signal
  if self.current_signal then
    last_possible_signal = self
  end
  local distance_since_last_possible = 0
  while true do
    local next_signals = direction == "front" and current_signal.signals_front or current_signal.signals_back
    if #next_signals == 0 then return end
    if #next_signals > 1 then
      return
    end
    cur_length = direction == "front" and current_signal.length or next_signals[1].length
    current_signal = next_signals[1]
    distance_left = distance_left - cur_length
    distance_since_last_possible = distance_since_last_possible + cur_length
    if current_signal.visited_clean_up_long[direction] then return end
    current_signal.visited_clean_up_long[direction] = true
    if current_signal.current_signal and current_signal.current_signal.type == "rail-chain-signal" then return end
    if current_signal.is_entrance or current_signal.is_exit then return end
    if current_signal.original_signal and not current_signal.to_be_deconstructed then
      current_signal.visited_clean_up_long[direction] = false
      current_signal:clean_up_long_stretch(direction)
      return
    end
    if distance_left < 0 and last_possible_signal then
      last_possible_signal:change_signal("rail-signal")
      distance_left = max_distance - distance_since_last_possible
    end
    if current_signal.current_signal then
      if distance_left > 0 then
        current_signal:change_signal(nil)
        last_possible_signal = current_signal
        distance_since_last_possible = 0
      else
        distance_left = current_signal.rail_signal_distance
      end
    end
  end
end

function Signal:find_exit()
  -- find the exit before this signal
  local current_signal = self
  local last_known_signal = self
  while true do
    if current_signal.is_exit then return last_known_signal or current_signal end
    if #current_signal.signals_back > 1 then
      -- self.player.print("Long stretch contains a branch, should not happen. Please report to mod author", {1, 0, 0})
      return last_known_signal or current_signal
    end
    if current_signal.current_signal then
      last_known_signal = current_signal
    end
    if #current_signal.signals_back == 0 then return last_known_signal end
    current_signal = current_signal.signals_back[1]
    if current_signal == self then return self end -- loops
  end
end

-- Restoring the signal
function Signal:restore_signal(should_revive)
  -- Restore the original signal and mark it to be changed into the current signal (with upgrade/deconstruction/create)
  local player = self.player
  local new_type
  local orig = self.original_signal
  local has_new_signal = false
  local new_name
  if self.current_signal then
    has_new_signal = true
    new_type = self.current_signal.type
    new_name = self.current_signal.name or self.current_signal.type
    self.current_signal.destroy {raise_destroy = false}
    self.current_signal = nil
  end
  if orig then
    if orig.is_ghost then
      if has_new_signal and self.current_signal then
        self.current_signal.destroy {raise_destroy = true}
        self.current_signal = nil
        self.current_signal = self.surface.create_entity {name = "entity-ghost", inner_name = new_name, position = self.position, direction = self.direction, force = player.force, player = player, raise_built = true}
      end
      goto continue
    else
      self.current_signal = self.surface.create_entity {name = orig.name, position = self.position, direction = self.direction, force = player.force, player = orig.last_user, raise_built = false, create_build_effect_smoke = false}
      self.current_signal.health = orig.health
    end
    if has_new_signal then
      if new_name ~= orig.name then
        local can_be_upgraded = self.current_signal.order_upgrade {force = player.force, target = new_name, player = player}
        if not can_be_upgraded then
          self.current_signal.order_deconstruction(player.force, player)
          self.current_signal = self.surface.create_entity {"entity-ghost", inner_name = new_name, position = self.position, direction = self.direction, force = player.force, player = player, raise_built = true}
          goto continue
        end
        if not self.current_signal.valid then
          -- might have been upgraded already by a creative mod listening to on_marked_for_upgrade
          self.current_signal = nil
        end
      end
    else
      self.current_signal.order_deconstruction(player.force, player)
      if not self.current_signal.valid then
        -- might have been removed by a creative mod listening to on_marked_for_deconstruction
        self.current_signal = nil
      end
    end
  elseif has_new_signal then
    self.current_signal = self.surface.create_entity {name = "entity-ghost", inner_name = new_name, position = self.position, direction = self.direction, force = player.force, player = player, raise_built = true}
  end
  :: continue ::
  if should_revive and self.current_signal and distance(self.position, player.position) <= 3 * player.reach_distance then
    local inventory = player.get_inventory(defines.inventory.character_main) or player.get_inventory(defines.inventory.god_main)
    if not inventory then return end
    if self.current_signal.to_be_deconstructed() then
      for _, product in pairs(self.current_signal.prototype.mineable_properties.products) do
        if not inventory.can_insert(product) then return end
      end
      player.mine_entity(self.current_signal, false)
    elseif self.current_signal.to_be_upgraded() then
      local upgrade_target = self.current_signal.get_upgrade_target()
      for _, product in pairs(upgrade_target.mineable_properties.products) do
        if not inventory.can_insert(product) then return end
      end
      for _, stack in pairs(upgrade_target.items_to_place_this) do
        local amount = inventory.get_item_count(stack.name)
        if amount < stack.count then return end -- can not upgrade the signal. Not in inventory
      end
      for _, stack in pairs(upgrade_target.items_to_place_this) do
        inventory.remove(stack)
      end
      self.surface.create_entity {name = upgrade_target.name, position = self.position, direction = self.direction, player = player, raise_built = true, force = player.force, fast_replace = true, spill = true, create_build_effect_smoke = true}
    elseif self.current_signal.type == "entity-ghost" then
      local items_to_place = self.current_signal.ghost_prototype.items_to_place_this
      for _, stack in pairs(items_to_place) do
        local amount = inventory.get_item_count(stack.name)
        if amount < stack.count then return end -- can not upgrade the signal. Not in inventory
      end
      for _, stack in pairs(items_to_place) do
        inventory.remove(stack)
      end
      self.current_signal.revive {raise_revive = true}
    end
  end
end

-- debugging functions

function Signal:debug()
  if self.invalid then return end
  self:debug_connections()
  self:debug_direction()
  self:debug_entrances()
end

function Signal:debug_connections()
  if self.invalid then return end
  rendering.draw_line {color = {0, 1, 0}, width = 1, from = self.position, to = self.twin.position, surface = self.surface, time_to_live = 300}
  rendering.draw_circle {color = {0, 0, 1}, radius = 0.1, filled = true, target = self.position, surface = self.surface, time_to_live = 300}
  for _, signal in pairs(self.signals_front) do
    local halfway = {x = (self.position.x + signal.position.x) / 2, y = (self.position.y + signal.position.y) / 2}
    rendering.draw_line {color = {1, 1, 0}, width = 1, from = self.position, to = halfway, surface = self.surface, time_to_live = 300}
  end
  for _, signal in pairs(self.signals_back) do
    local halfway = {x = (self.position.x + signal.position.x) / 2, y = (self.position.y + signal.position.y) / 2}
    rendering.draw_line {color = {0, 1, 1}, width = 1, from = self.position, to = halfway, surface = self.surface, time_to_live = 300}
  end
end

function Signal:debug_direction()
  if self.invalid then return end
  self:debug_current_signal()
  if self.can_be_used == true then
    rendering.draw_circle {color = {0, 1, 0}, radius = 0.2, width = 2, target = self.position, surface = self.surface, time_to_live = 300, draw_on_ground = true}
  elseif self.can_be_used == false then
    rendering.draw_circle {color = {1, 0, 0}, radius = 0.2, width = 2, target = self.position, surface = self.surface, time_to_live = 300, draw_on_ground = true}
  else
    rendering.draw_circle {color = {1, 1, 0}, radius = 0.2, width = 2, target = self.position, surface = self.surface, time_to_live = 300, draw_on_ground = true}
  end
end

function Signal:debug_current_signal()
  if self.invalid then return end
  if self.current_signal then
    rendering.draw_circle {color = {0, 1, 0}, radius = 0.3, width = 2, target = self.position, surface = self.surface, time_to_live = 300, draw_on_ground = true}
  end
end

function Signal:debug_entrances()
  if self.invalid then return end
  if self.is_exit then
    rendering.draw_circle {color = {1, 0, 0.5}, radius = 0.45, target = self.position, time_to_live = 300, surface = self.surface}
  end
  if self.is_entrance then
    rendering.draw_circle {color = {0, 1, 0.5}, radius = 0.55, target = self.position, time_to_live = 300, surface = self.surface}
  end
end