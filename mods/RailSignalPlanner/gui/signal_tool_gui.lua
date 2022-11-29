require("scripts/settings")

local function create_button(parent, name, sprite_path)
  local button = parent.add{
    type = "sprite-button",
    name=name,
    sprite = sprite_path
  }
  button.style.width = 36
  button.style.height = 36
  return button
end

local function open_signal_gui(event)
  if event.item.name ~= "rail-signal-planner" then
    return
  end
  if not global.signal_settings then
    global.signal_settings = {}
  end
  if not global.signal_settings[event.player_index] then
    set_default_settings(event.player_index)
  end
  local global_settings = global.signal_settings[event.player_index]
  local player = game.players[event.player_index]
  if player.opened then
    player.opened.destroy()
  end
  local gui = player.gui
  local frame = gui.screen.add{type="frame", name="rail_signal_gui", caption={"rsp-gui.rail-signal-planner"}}
  frame.auto_center=true
  local flow = frame.add{type="flow", name="rail_signal_flow", direction="vertical"}
  local signal_entity_table = flow.add{type="table", name="rail_signal_table", column_count=2, vertical_screening=true}
  flow.drag_target=frame
  signal_entity_table.add{type="label", name="rail_signal_item_label", caption={"entity-name.rail-signal"}}
  signal_entity_table.add{type="choose-elem-button", name="rail_signal_item", elem_type="item", item=get_setting("rail_signal_item", player), tooltip={"rsp-gui.tooltip-rail-signal"}}
  signal_entity_table.add{type="label", name="rail_chain_signal_item_label", caption={"entity-name.rail-chain-signal"}}
  signal_entity_table.add{type="choose-elem-button", name="rail_chain_signal_item", elem_type="item", item=get_setting("rail_chain_signal_item", player), tooltip={"rsp-gui.tooltip-rail-chain-signal"}}


  local wagon_value = math.ceil((global_settings.train_length + 1)/7)
  local wagon_length_tooltip = {"rsp-gui.tooltip-wagon-length"}
  flow.add{type="label", name="wagon_length_label", caption={"rsp-gui.wagon-length-label"}, tooltip=wagon_length_tooltip}
  local wagon_length_flow = flow.add{type="flow", name="wagon_length_flow", direction="horizontal", tooltip=wagon_length_tooltip}
  local wagon_slider = wagon_length_flow.add{type="slider", name="wagon_length_slider", minimum_value=1, maximum_value=16, value=wagon_value, value_step=1, tooltip=wagon_length_tooltip}
  wagon_slider.style.maximal_width = 100
  local wagon_textfield = wagon_length_flow.add{type="textfield", name="wagon_length_textfield", text=wagon_value, numeric=true, allow_decimal=false, allow_negative=false, tooltip=wagon_length_tooltip}
  wagon_textfield.style.maximal_width=50

  local train_length_tooltip = {"rsp-gui.tooltip-train-length"}
  flow.add{type="label", name="train_length_label", caption={"rsp-gui.train-length-label"}, tooltip=train_length_tooltip}
  local train_length_flow = flow.add{type="flow", name="train_length_flow", direction="horizontal", tooltip=train_length_tooltip}
  local train_length_slider = train_length_flow.add{type="slider", name="train_length_slider", minimum_value=0, maximum_value=16*7-1, value=global_settings.train_length, value_step=1, tooltip=train_length_tooltip}
  train_length_slider.style.maximal_width = 100
  local train_length_textfield = train_length_flow.add{type="textfield", name="train_length_textfield", text=global_settings.train_length, numeric=true, allow_decimal=false, allow_negative=false, tooltip=train_length_tooltip}
  train_length_textfield.style.maximal_width=50

  local rail_signal_distance_tooltip = {"rsp-gui.tooltip-rail-distance"}
  flow.add{type="label", name="rail_distance_label", caption={"rsp-gui.rail-distance-label"}, tooltip=rail_signal_distance_tooltip}
  local rail_signal_distance_flow = flow.add{type="flow", name="rail_signal_distance_flow", direction="horizontal", tooltip=rail_signal_distance_tooltip}
  local rail_signal_distance_slider = rail_signal_distance_flow.add{type="slider", name="rail_signal_distance_slider", minimum_value=2, maximum_value=50, value=global_settings.rail_signal_distance, value_step=1, tooltip=rail_signal_distance_tooltip}
  rail_signal_distance_slider.style.maximal_width = 100
  local rail_signal_distance_textfield = rail_signal_distance_flow.add{type="textfield", name="rail_signal_distance_textfield", text=global_settings.rail_signal_distance, numeric=true, allow_decimal=false, allow_negative=false, tooltip=rail_signal_distance_tooltip}
  rail_signal_distance_textfield.style.maximal_width=50
  --
  --local button_flow = flow.add{type="flow", name="rail_signal_button_flow", direction="horizontal"}
  --button_flow.style.top_margin=20
  --button_flow.style.horizontal_align = "center"
  --local cancel_button = create_button(button_flow, "rail_cancel_button", "utility/close_black", {1,0,0})
  --local delete_button = create_button(button_flow, "rail_delete_button", "utility/remove", {1,0,0})
  --local reset_button = create_button(button_flow, "rail_reset_button", "utility/reset", {1,0.5,0})
  --local set_default_button = create_button(button_flow, "rail_set_default_button", "utility/export_slot", {1,1,1})
  --local conform_button = create_button(button_flow, "rail_confirm_button", "utility/confirm_slot", {1,1,1})



  player.opened = gui.screen.rail_signal_gui
end

local function on_gui_value_changed(event)
  local player = game.players[event.player_index]
  if event.element.name == "wagon_length_slider" then
    local slider_value = event.element.slider_value
    event.element.parent.wagon_length_textfield.text = tostring(event.element.slider_value)
    set_settings({["train_length"] = 7*slider_value - 1}, player)
    event.element.parent.parent.train_length_flow.train_length_textfield.text = tostring(7*slider_value - 1)
    event.element.parent.parent.train_length_flow.train_length_slider.slider_value = 7*slider_value - 1
  elseif event.element.name == "train_length_slider" then
    set_settings({["train_length"] = event.element.slider_value}, player)
    event.element.parent.train_length_textfield.text = tostring(event.element.slider_value)
  elseif event.element.name == "rail_signal_distance_slider" then
    set_settings({["rail_signal_distance"] = event.element.slider_value}, player)
    event.element.parent.rail_signal_distance_textfield.text = tostring(event.element.slider_value)
  end
end

local function on_gui_text_changed(event)
  local player = game.players[event.player_index]
  if event.element.name == "wagon_length_textfield" then
    local slider_value
    if not event.element.text or event.element.text == "" then
      slider_value = 1
    else
      slider_value = tonumber(event.element.text)
    end
    if slider_value < 1 then
      slider_value = 1
    end
    set_settings({["train_length"] = 7*slider_value - 1}, player)
    event.element.parent.wagon_length_slider.slider_value = slider_value
    event.element.parent.parent.train_length_flow.train_length_textfield.text = tostring(7*slider_value - 1)
    event.element.parent.parent.train_length_flow.train_length_slider.slider_value = 7*slider_value - 1
  elseif event.element.name == "train_length_textfield" then
    local slider_value
    if not event.element.text or event.element.text == "" then
      slider_value = 1
    else
      slider_value = tonumber(event.element.text)
    end
    if slider_value < 1 then
      slider_value = 1
    end
    set_settings({["train_length"] = slider_value}, player)
    event.element.parent.train_length_slider.slider_value = slider_value
  elseif event.element.name == "rail_signal_distance_textfield" then
    local slider_value
    if not event.element.text or event.element.text == "" then
      slider_value = 2
    else
      slider_value = tonumber(event.element.text)
    end
    if slider_value < 2 then
      slider_value = 2
    end
    set_settings({["rail_signal_distance"] = slider_value}, player)
    event.element.parent.rail_signal_distance_slider.slider_value = slider_value
  end
end

local function on_gui_elem_changed(event)
  local element = event.element
  local player = game.players[event.player_index]
  if element.name == "rail_signal_item" then
    set_settings({["rail_signal_item"] = element.elem_value}, player)
  elseif element.name == "rail_chain_signal_item" then
    set_settings({["rail_chain_signal_item"] = element.elem_value}, player)
  end
end

local function close_signal_gui(event)
  local player = game.players[event.player_index]
  if player and player.valid and player.gui.screen.rail_signal_gui then
    player.gui.screen.rail_signal_gui.destroy()
  end
end

script.on_event(defines.events.on_mod_item_opened, open_signal_gui)

script.on_event(defines.events.on_gui_closed, close_signal_gui)

script.on_event(defines.events.on_gui_value_changed, on_gui_value_changed)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)