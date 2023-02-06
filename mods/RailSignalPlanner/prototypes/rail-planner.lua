local font_start = "[font=default-semibold][color=255, 230, 192]"
local font_end = "[/color][/font]"
local line_start = "\n  •   "

data:extend({
  {
    name = "rail-signal-planner",
    type = "selection-tool",
    order = "c[automated-construction]-s[rail-signal-planner]",
    selection_color = {255, 127, 0},
    alt_selection_color = {127, 255, 0},
    reverse_selection_color = {0, 127, 255},
    alt_reverse_selection_color = {0, 255, 127},
    selection_mode = {"any-entity", "same-force"},
    alt_selection_mode = {"any-entity", "same-force"},
    selection_cursor_box_type = "pair",
    alt_selection_cursor_box_type = "pair",
    icon =  "__RailSignalPlanner__/graphics/icons/rail-signal-planner.png",
    icon_size = 64,
    stack_size = 1,
    stackable = false,
    subgroup = "tool",
    show_in_library = true,
    flags = {"only-in-cursor", "spawnable"},
    entity_type_filters = {"straight-rail", "curved-rail"},
    alt_entity_type_filters = {"straight-rail", "curved-rail"},
    reverse_entity_type_filters = {"rail-signal", "rail-chain-signal"},
    alt_reverse_entity_type_filters = {"rail-signal", "rail-chain-signal"},
    can_be_mod_opened = true,
    localised_description = {
      "",
      {"item-description.rail-signal-planner"},
      "\n",
      font_start,
      {"gui.instruction-when-in-cursor"},
      ":",
      line_start,
      {"item-description.rsp-regular-behaviour", "__CONTROL_LEFT_CLICK__"},
      line_start,
      {"item-description.rsp-alt-behaviour",  "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_LEFT_CLICK__", {"rsp-gui.force-unidirectional"}},
      line_start,
      {"item-description.rsp-cancel-construction-jobs", "__CONTROL_RIGHT_CLICK__"},
      line_start,
      {"item-description.rsp-drag-to-deconstruct", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_RIGHT_CLICK__"},
      font_end,
    }
  },
  {
    name = "give-rail-signal-planner",
    type = "shortcut",
    order = "b[blueprints]-s[rail-signal-planner]",
    action = "spawn-item",
    localised_name = {"",
      {"controls.give-rail-signal-planner"},
      "\n",
      font_start,
      {"gui.instruction-when-in-cursor"},
      ":",
      line_start,
      {"item-description.rsp-regular-behaviour", "__CONTROL_LEFT_CLICK__"},
      line_start,
      {"item-description.rsp-alt-behaviour",  "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_LEFT_CLICK__", {"rsp-gui.force-unidirectional"}},
      line_start,
      {"item-description.rsp-cancel-construction-jobs", "__CONTROL_RIGHT_CLICK__"},
      line_start,
      {"item-description.rsp-drag-to-deconstruct", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_RIGHT_CLICK__"},
      font_end,
    },
    item_to_spawn = "rail-signal-planner",
    icon = {
      filename = "__RailSignalPlanner__/graphics/icons/rail-signal-shortcut.png",
      --filename = data.raw["rail-signal"]["rail-signal"].icon,
      size = 32,
      flags = {"icon"}
    },
    associated_control_input = "give-rail-signal-planner"
  },
  {
    name = "give-rail-signal-planner",
    type = "custom-input",
    key_sequence = "CONTROL + P",
    action = "spawn-item",
    item_to_spawn = "rail-signal-planner",
    consuming = "game-only",
    order = "b"
  },
  {
    name = "rsp-open-menu",
    type = "custom-input",
    key_sequence = "SHIFT + P",
    consuming = "game-only",
    order = "a"
  },
  {
    name = "rsp-toggle-place-signals-with-planner",
    type = "custom-input",
    key_sequence = "CONTROL + SHIFT + P",
    consuming = "game-only",
    order = "c"
  },
  {
    name = "rsp-toggle-unidirectional",
    type = "custom-input",
    key_sequence = "ALT + P",
    consuming = "game-only",
    order = "d"
  },
  { -- These two are there because on_mod_item_opened and on_gui_closed fire both on right click. We are keeping track of the closed state of the menu when E and Escape are pressed
  name = "rsp-close-menu-escape",
  type = "custom-input",
  key_sequence = "",
  linked_game_control = "toggle-menu"
  },
  {
  name = "rsp-close-menu-e",
  type = "custom-input",
  key_sequence = "",
  linked_game_control = "confirm-gui"
  }
})