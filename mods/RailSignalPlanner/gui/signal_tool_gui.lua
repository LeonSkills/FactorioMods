require("scripts/settings")
require("scripts/utility")
local mod_gui = require("mod-gui")

-- scripts to initialize the buttons
local function get_button_flow(player)
  local button_flow = mod_gui.get_button_flow(player)
  if button_flow.rsp_flow then button_flow.rsp_flow.destroy() end --legacy
  return button_flow
end

function refresh_button(player)
  local flow = get_button_flow(player)
  if flow.rsp_button then
    local gui_unifyer_style = settings.get_player_settings(player)["gu_button_style_setting"]
    local style = gui_unifyer_style and (gui_unifyer_style.value or "slot_button_notext") or mod_gui.button_style
    flow.rsp_button.style = style
    local tooltip = {
      "",
      {"rsp-gui.rsp-menu-button-tooltip"},
      {"controls.rsp-custom-control", "__CONTROL_LEFT_CLICK__, __CONTROL__rsp-open-menu__"},
      "\n",
      {"controls.give-rail-signal-planner"},
      {"controls.rsp-custom-control", "__CONTROL_RIGHT_CLICK__, __CONTROL__give-rail-signal-planner__"},
    }
    flow.rsp_button.tooltip = tooltip
  end
end

local function remove_button(player)
  local flow = get_button_flow(player)
  if flow.rsp_flow then flow.rsp_flow.destroy() end --legacy
  if flow.rsp_button then flow.rsp_button.destroy() end
  if #flow.children == 0 then
    if #flow.parent.children == 1 then
      if #flow.parent.parent.children == 1 then
        flow.parent.parent.destroy()
      else
        flow.parent.destroy()
      end
    else
      flow.destroy()
    end
  end
end

local function add_setting_button(player)
  local flow = get_button_flow(player)
  if flow.rsp_flow then flow.rsp_flow.destroy() end --legacy
  if flow.rsp_button then flow.rsp_button.destroy() end

  flow.add{type="sprite-button", name="rsp_button", sprite="item/rail-signal"}
  refresh_button(player)
end

local function initialize_player(player)
  if settings.get_player_settings(player.index)["rsp-toggle-menu-icon"].value then
    add_setting_button(player)
    refresh_button(player)
  else
    remove_button(player)
  end
  if player.gui.left.rail_signal_gui then
    player.gui.left.rail_signal_gui.destroy()
  end
end

local function initialize()
  for _, player in pairs(game.players) do
    initialize_player(player)
  end
end

local function on_player_created(event)
  local player = game.players[event.player_index]
  initialize_player(player)
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
script.on_event(defines.events.on_player_created, on_player_created)

-- building the ui

local function on_gui_click(event)
  local player = game.players[event.player_index]
  local rail_planner = event.element.name:match("^(.*)_planner_button$")
  if rail_planner and game.item_prototypes[rail_planner] and game.item_prototypes[rail_planner].type == "rail-planner" then
    set_settings({["selected_rail_planner"] = rail_planner}, player)
    toggle_signal_ui(event.player_index)
    toggle_signal_ui(event.player_index)
  elseif event.element.name == "rsp_button" or event.element.name == "rsp_close_setting_interface" then
    refresh_button(player)
    if event.button == defines.mouse_button_type.right and event.element.name == "rsp_button" then
      player.clear_cursor()
      local inventory = player.get_main_inventory()
      local item_stack = inventory.find_item_stack("rail-signal-planner")
      if item_stack then
        item_stack.swap_stack(player.cursor_stack)
      else
        player.cursor_stack.set_stack({name="rail-signal-planner"})
        player.cursor_stack_temporary=true  -- Will hopefully get fixed in the future: https://forums.factorio.com/viewtopic.php?f=28&t=105083
      end
    else
      toggle_signal_ui(event.player_index)
    end
  end
end

local function add_titlebar(gui, caption, close_button_name)
  local titlebar = gui.add{type = "flow"}
  titlebar.add{
    type = "label",
    style = "frame_title",
    caption = caption,
    ignored_by_interaction = true,
  }
  local filler = titlebar.add{
    type = "empty-widget",
    ignored_by_interaction = true,
  }
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  titlebar.add{
    type = "sprite-button",
    name = close_button_name,
    style = "frame_action_button",
    sprite = "utility/close_white",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = {"gui.close-instruction"},
  }
end

local j = 0
function toggle_signal_ui(player_index)
  local player = game.players[player_index]
  local gui = player.gui
  j = j + 1
  if gui.left.rail_signal_gui then
    gui.left.rail_signal_gui.destroy()
    return
  end
  if not global.signal_settings then
    global.signal_settings = {}
  end
  local global_settings = global.signal_settings[player_index]
  if not global_settings then
    set_default_settings(player_index)
  end

  local frame = gui.left.add{type="frame", name="rail_signal_gui"}
  player.opened = frame
  local flow = frame.add{type="flow", name="rail_signal_flow", direction="vertical"}
  add_titlebar(flow, {"rsp-gui.rail-signal-planner"}, "rsp_close_setting_interface")
  local toggle_table = flow.add{type="table", name="toggle_table", column_count = 2, vertical_screening = true}

  local place_signals_with_rail_planner_label = {"rsp-gui.place-signals-with-rail-planner-tooltip", "\n__CONTROL__rsp-toggle-place-signals-with-planner__"}
  toggle_table.add{type="label", name="signals_and_rails_label", caption={"rsp-gui.place-signals-with-rail-planner"}, tooltip=place_signals_with_rail_planner_label}
  toggle_table.add{type="checkbox", name="toggle_place_signals_with_rail_planner", state=get_setting("place_signals_with_rail_planner", player), tooltip=place_signals_with_rail_planner_label}

  local one_way_label = {"rsp-gui.force-unidirectional-tooltip", "\n__CONTROL__rsp-toggle-unidirectional__"}
  toggle_table.add{type="label", name="force_one_directional_label", caption={"rsp-gui.force-unidirectional"}, tooltip=one_way_label}
  toggle_table.add{type="checkbox", name="toggle_one_directional", state=get_setting("force_unidirectional", player), tooltip=one_way_label}

  local force_build_rails = {"rsp-gui.force-build-rails-tooltip", ""}
  toggle_table.add{type="label", name="force_build_rails_label", caption={"rsp-gui.force-build-rails"}, tooltip=force_build_rails}
  toggle_table.add{type="checkbox", name="toggle_force_build_rails", state=get_setting("force_build_rails", player), tooltip=force_build_rails}

  local current_opened_rail = get_setting("selected_rail_planner", player)
  if not game.item_prototypes[current_opened_rail] or not game.item_prototypes[current_opened_rail].type == "rail-planner" then
    current_opened_rail = "rail"
  end
  local planners = game.get_filtered_item_prototypes{{filter="type", type="rail-planner"}}
  local rail_planners = {}
  local i = 1
  -- Get the vanilla one as first tab
  for k, planner in pairs(planners) do
    if planner.name == "rail" then
      rail_planners[1] = planner
    else
      rail_planners[i + 1] = planner
      i = i + 1
    end
  end
  local i = 0
  flow.style.horizontal_align = "center"
  local tabbed_pane = flow.add{type="tabbed-pane"}
  tabbed_pane.style.minimal_width=220

  for _, rail_planner in pairs(rail_planners) do
    if rail_planner.has_flag("hidden") then goto continue end
    i = i + 1
    local tab = tabbed_pane.add{type="tab", name=rail_planner.name .. "_planner_button", tooltip = rail_planner.localised_name, resize_to_sprite=true}
    tab.style.horizontally_squashable = false
    tab.style.vertically_squashable = false
    tab.style.horizontally_stretchable = false
    tab.style.vertically_stretchable = false
    tab.style.left_padding = 0
    tab.style.right_padding = 0
    tab.style.top_padding = 0
    tab.style.bottom_padding = 0
    tab.style.height = 40
    tab.style.width = 50
    local tab_frame = tab.add{type="flow", ignored_by_interaction=true}
    tab_frame.style.width = 50
    tab_frame.style.height = 40
    tab_frame.style.horizontal_align = "center"
    tab_frame.style.vertical_align = "center"
    tab_frame.style.horizontally_squashable = false
    tab_frame.style.vertically_squashable = false
    tab_frame.style.horizontally_stretchable = false
    tab_frame.style.vertically_stretchable = false
    local sprite = tab_frame.add{type="sprite", sprite="item/" .. rail_planner.name, ignored_by_interaction=true}
    sprite.style.vertical_align = "center"
    sprite.style.horizontal_align = "center"
    local tab_flow = tabbed_pane.add{type="flow", direction="vertical"}
    tabbed_pane.add_tab(tab, tab_flow)
    if rail_planner.name == current_opened_rail then
      tabbed_pane.selected_tab_index = i
      flow = tab_flow
    end
    ::continue::
  end
  local chain_signal = get_setting("rail_chain_signal_item", player, current_opened_rail)
  if not game.entity_prototypes[chain_signal] then
    chain_signal = "rail-chain-signal"
    set_settings({["rail_chain_signal_item"] = chain_signal}, player)
  end
  local rail_signal = get_setting("rail_signal_item", player, current_opened_rail)
  if not game.entity_prototypes[rail_signal] then
    rail_signal = "rail-signal"
    set_settings({["rail_signal_item"] = rail_signal}, player)
  end
  local signal_entity_table = flow.add{type="table", name="rail_signal_table", column_count=2, vertical_screening=true}
  signal_entity_table.add{type="label", name="rail_signal_item_label", caption={"entity-name.rail-signal"}}
  signal_entity_table.add{type="choose-elem-button", name="rail_signal_item", elem_type="entity", elem_filters = {{filter="type", type="rail-signal"}, {filter="hidden", invert=true, mode="and"}}, entity=rail_signal, tooltip={"rsp-gui.tooltip-rail-signal"}}
  signal_entity_table.add{type="label", name="rail_chain_signal_item_label", caption={"entity-name.rail-chain-signal"}}
  signal_entity_table.add{type="choose-elem-button", name="rail_chain_signal_item", elem_type="entity", elem_filters = {{filter="type", type="rail-chain-signal"}, {filter="hidden", invert=true, mode="and"}}, entity=chain_signal, tooltip={"rsp-gui.tooltip-rail-chain-signal"}}

  local train_length = get_setting("train_length", player, current_opened_rail)
  local rail_signal_distance = get_setting("rail_signal_distance", player, current_opened_rail)
  local wagon_value = math.ceil((train_length + 1)/7)
  local wagon_length_tooltip = {"rsp-gui.tooltip-wagon-length"}
  flow.add{type="label", name="wagon_length_label", caption={"rsp-gui.wagon-length-label"}, tooltip=wagon_length_tooltip}
  local wagon_length_flow = flow.add{type="flow", name="wagon_length_flow", direction="horizontal", tooltip=wagon_length_tooltip}
  local wagon_slider = wagon_length_flow.add{type="slider", name="wagon_length_slider", minimum_value=1, maximum_value=16, value=wagon_value, value_step=1, tooltip=wagon_length_tooltip}
  wagon_slider.style.maximal_width = 200
  local wagon_textfield = wagon_length_flow.add{type="textfield", name="wagon_length_textfield", text=wagon_value, numeric=true, allow_decimal=false, allow_negative=false, tooltip=wagon_length_tooltip}
  wagon_textfield.style.maximal_width = 50

  local train_length_tooltip = {"rsp-gui.tooltip-train-length"}
  flow.add{type="label", name="train_length_label", caption={"rsp-gui.train-length-label"}, tooltip=train_length_tooltip}
  local train_length_flow = flow.add{type="flow", name="train_length_flow", direction="horizontal", tooltip=train_length_tooltip}
  local train_length_slider = train_length_flow.add{type="slider", name="train_length_slider", minimum_value=0, maximum_value=16*7-1, value=train_length, value_step=1, tooltip=train_length_tooltip}
  train_length_slider.style.maximal_width = 200
  local train_length_textfield = train_length_flow.add{type="textfield", name="train_length_textfield", text=train_length, numeric=true, allow_decimal=false, allow_negative=false, tooltip=train_length_tooltip}
  train_length_textfield.style.maximal_width = 50

  local rail_signal_distance_tooltip = {"rsp-gui.tooltip-rail-distance"}
  flow.add{type="label", name="rail_distance_label", caption={"rsp-gui.rail-distance-label"}, tooltip=rail_signal_distance_tooltip}
  local rail_signal_distance_flow = flow.add{type="flow", name="rail_signal_distance_flow", direction="horizontal", tooltip=rail_signal_distance_tooltip}
  local rail_signal_distance_slider = rail_signal_distance_flow.add{type="slider", name="rail_signal_distance_slider", minimum_value=2, maximum_value=50, value=rail_signal_distance, value_step=1, tooltip=rail_signal_distance_tooltip}
  rail_signal_distance_slider.style.maximal_width = 200
  local rail_signal_distance_textfield = rail_signal_distance_flow.add{type="textfield", name="rail_signal_distance_textfield", text=rail_signal_distance, numeric=true, allow_decimal=false, allow_negative=false, tooltip=rail_signal_distance_tooltip}
  rail_signal_distance_textfield.style.maximal_width = 50
end

local is_gui_just_closed_escape
local is_gui_just_closed_mod

-- functionality because on_gui_closed and on_mod_item_opened are both fired at the same time
-- And there is no way to distinguish if on_gui_closed was called by escape/E press or by right click on the selection tool
-- So we keep track how the menu was closed last time
local function on_toggle_menu_pressed(event)
  is_gui_just_closed_escape = true
end

local function close_signal_gui(event)
  if not event.element or event.element.name ~= "rail_signal_gui" then return end
  event.element.destroy()
  is_gui_just_closed_mod = not is_gui_just_closed_escape
end

local function open_signal_gui(event)
  if event.item.name ~= "rail-signal-planner" then return end
  if is_gui_just_closed_mod then
    is_gui_just_closed_mod = false
  else
    toggle_signal_ui(event.player_index)
    is_gui_just_closed_escape = false
  end
end

script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_closed, close_signal_gui)
script.on_event(defines.events.on_mod_item_opened, open_signal_gui)
script.on_event("rsp-close-menu-escape", on_toggle_menu_pressed)
script.on_event("rsp-close-menu-e", on_toggle_menu_pressed)

-- When values are changed

local function on_gui_value_changed(event)
  local player = game.players[event.player_index]
  local current_opened_rail = get_setting("selected_rail_planner", player)
  if event.element.name == "wagon_length_slider" then
    local slider_value = event.element.slider_value
    event.element.parent.wagon_length_textfield.text = tostring(event.element.slider_value)
    set_settings({["train_length"] = 7*slider_value - 1}, player, current_opened_rail)
    event.element.parent.parent.train_length_flow.train_length_textfield.text = tostring(7*slider_value - 1)
    event.element.parent.parent.train_length_flow.train_length_slider.slider_value = 7*slider_value - 1
  elseif event.element.name == "train_length_slider" then
    set_settings({["train_length"] = event.element.slider_value}, player, current_opened_rail)
    event.element.parent.train_length_textfield.text = tostring(event.element.slider_value)
  elseif event.element.name == "rail_signal_distance_slider" then
    set_settings({["rail_signal_distance"] = event.element.slider_value}, player, current_opened_rail)
    event.element.parent.rail_signal_distance_textfield.text = tostring(event.element.slider_value)
  end
end

local function on_gui_text_changed(event)
  local player = game.players[event.player_index]
  local current_opened_rail = get_setting("selected_rail_planner", player)
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
    set_settings({["train_length"] = 7*slider_value - 1}, player, current_opened_rail)
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
    set_settings({["train_length"] = slider_value}, player, current_opened_rail)
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
    set_settings({["rail_signal_distance"] = slider_value}, player, current_opened_rail)
    event.element.parent.rail_signal_distance_slider.slider_value = slider_value
  end
end

local function on_gui_elem_changed(event)
  local element = event.element
  local player = game.players[event.player_index]
  local current_opened_rail = get_setting("selected_rail_planner", player)
  if element.name == "rail_signal_item" then
    set_settings({["rail_signal_item"] = element.elem_value}, player, current_opened_rail)
  elseif element.name == "rail_chain_signal_item" then
    set_settings({["rail_chain_signal_item"] = element.elem_value}, player, current_opened_rail)
  elseif element.name == "toggle_place_signals_with_rail_planner" then
    set_settings({["place_signals_with_rail_planner"] = element.state}, player)
  elseif element.name == "toggle_one_directional" then
    set_settings({["force_unidirectional"] = element.state}, player)
  elseif element.name == "toggle_force_build_rails" then
    set_settings({["force_build_rails"] = element.state}, player)
  end
end

script.on_event(defines.events.on_gui_value_changed, on_gui_value_changed)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_elem_changed)

-- toggle the menu button
local function on_runtime_mod_setting_changed(event)
  if not event.player_index then return end
  local player = game.players[event.player_index]
  refresh_button(player)
  if event.setting == "rsp-toggle-menu-icon" then
    if settings.get_player_settings(event.player_index)["rsp-toggle-menu-icon"].value then
      add_setting_button(player)
    else
      remove_button(player)
    end
  end
end

script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)