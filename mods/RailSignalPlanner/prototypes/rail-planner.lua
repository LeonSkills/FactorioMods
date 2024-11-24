local font_start = "[font=default-semibold][color=255, 230, 192]"
local font_end = "[/color][/font]"
local line_start = "\n  •   "

local rail_types = {
  "straight-rail",
  "curved-rail-a",
  "curved-rail-b",
  "half-diagonal-rail",
  "elevated-straight-rail",
  "elevated-curved-rail-a",
  "elevated-curved-rail-b",
  "elevated-half-diagonal-rail",
  "rail-ramp",
}
local signal_types = {
  "rail-signal",
  "rail-chain-signal"
}

data:extend(
        {
          {
            name                  = "rail-signal-planner",
            type                  = "selection-tool",
            order                 = "c[automated-construction]-s[rail-signal-planner]",
            select                = {
              border_color        = {255, 127, 0},
              cursor_box_type     = "entity",
              entity_type_filters = rail_types,
              mode                = {"any-entity", "same-force"},
              box_type            = "pair",
            },
            alt_select            = {
              border_color        = {127, 255, 0},
              cursor_box_type     = "entity",
              entity_type_filters = rail_types,
              mode                = {"any-entity", "same-force"},
              box_type            = "pair",
            },
            reverse_select        = {
              border_color        = {0, 127, 255},
              cursor_box_type     = "entity",
              entity_type_filters = signal_types,
              mode                = {"any-entity", "same-force"},
              box_type            = "pair",
            },
            alt_reverse_select    = {
              border_color        = {0, 255, 127},
              cursor_box_type     = "entity",
              entity_type_filters = signal_types,
              mode                = {"any-entity", "same-force"},
              box_type            = "pair",
            },
            icon                  = "__RailSignalPlanner__/graphics/icons/rail-signal-planner.png",
            icon_size             = 64,
            stack_size            = 1,
            stackable             = false,
            subgroup              = "tool",
            show_in_library       = true,
            flags                 = {"only-in-cursor", "spawnable"},
            can_be_mod_opened     = true,
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
              {"item-description.rsp-alt-behaviour", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_LEFT_CLICK__", {"rsp-gui.force-unidirectional"}},
              line_start,
              {"item-description.rsp-cancel-construction-jobs", "__CONTROL_RIGHT_CLICK__"},
              line_start,
              {"item-description.rsp-drag-to-deconstruct", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_RIGHT_CLICK__"},
              font_end,
            }
          },
          {
            name                     = "give-rail-signal-planner",
            type                     = "shortcut",
            order                    = "b[blueprints]-s[rail-signal-planner]",
            action                   = "spawn-item",
            localised_name           = {"",
                                        {"controls.give-rail-signal-planner"},
                                        "\n",
                                        font_start,
                                        {"gui.instruction-when-in-cursor"},
                                        ":",
                                        line_start,
                                        {"item-description.rsp-regular-behaviour", "__CONTROL_LEFT_CLICK__"},
                                        line_start,
                                        {"item-description.rsp-alt-behaviour", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_LEFT_CLICK__", {"rsp-gui.force-unidirectional"}},
                                        line_start,
                                        {"item-description.rsp-cancel-construction-jobs", "__CONTROL_RIGHT_CLICK__"},
                                        line_start,
                                        {"item-description.rsp-drag-to-deconstruct", "__CONTROL_KEY_SHIFT__ __CONTROL_STYLE_BEGIN__+__CONTROL_STYLE_END__ __CONTROL_RIGHT_CLICK__"},
                                        font_end,
            },
            item_to_spawn            = "rail-signal-planner",
            icon                     = "__RailSignalPlanner__/graphics/icons/rail-signal-shortcut.png",
            icon_size                = 32,
            small_icon               = "__RailSignalPlanner__/graphics/icons/rail-signal-shortcut.png",
            small_icon_size          = 32,
            associated_control_input = "give-rail-signal-planner",
          },
          {
            name          = "give-rail-signal-planner",
            type          = "custom-input",
            key_sequence  = "ALT + P",
            action        = "spawn-item",
            item_to_spawn = "rail-signal-planner",
            consuming     = "game-only",
            order         = "b"
          },
          {
            name         = "rsp-open-menu",
            type         = "custom-input",
            key_sequence = "SHIFT + P",
            consuming    = "game-only",
            order        = "a"
          },
          {
            name         = "rsp-toggle-place-signals-with-planner",
            type         = "custom-input",
            key_sequence = "CONTROL + SHIFT + P",
            consuming    = "game-only",
            order        = "c"
          },
          {
            name         = "rsp-toggle-unidirectional",
            type         = "custom-input",
            key_sequence = "CONTROL + P",
            consuming    = "game-only",
            order        = "d"
          },
          { -- These two are there because on_mod_item_opened and on_gui_closed fire both on right click. We are keeping track of the closed state of the menu when E and Escape are pressed
            name                = "rsp-close-menu-escape",
            type                = "custom-input",
            key_sequence        = "",
            linked_game_control = "toggle-menu"
          },
          {
            name                = "rsp-close-menu-e",
            type                = "custom-input",
            key_sequence        = "",
            linked_game_control = "confirm-gui"
          }
        }
)