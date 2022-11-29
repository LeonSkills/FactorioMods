data:extend({
  {
    name = "rail-signal-planner",
    type = "selection-tool",
    order = "c[automated-construction]-s[rail-signal-planner]",
    alt_selection_color = {127, 255, 0},
    selection_color = {255, 127, 0},
    selection_mode = {"any-entity", "same-force"},
    alt_selection_mode = {"any-entity", "same-force"},
    selection_cursor_box_type = "pair",
    alt_selection_cursor_box_type = "pair",
    icons = {
      {
        icon="__RailSignalPlanner__/graphics/icons/rail-signal-planner.png",
        icon_size = 32
      },
      {
        icon = data.raw["rail-signal"]["rail-signal"].icon,
        icon_size = data.raw["rail-signal"]["rail-signal"].icon_size,
        scale = 0.7 * 32 / data.raw["rail-signal"]["rail-signal"].icon_size,
      }
    },
    icon_size = 32,
    stack_size = 1,
    stackable = false,
    subgroup = "tool",
    show_in_library = true,
    flags = {"mod-openable", "spawnable"},
    entity_type_filters = {"straight-rail", "curved-rail", "rail-signal", "rail-chain-signal"},
    alt_entity_type_filters = {"straight-rail", "curved-rail", "rail-signal", "rail-chain-signal"},
    can_be_mod_opened = true
  },
  {
    name = "give-rail-signal-planner",
    type = "shortcut",
    order = "b[blueprints]-s[rail-signal-planner]",
    action = "spawn-item",
    localised_name = {"item-name.rail-signal-planner"},
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
    key_sequence = "ALT + S",
    action = "spawn-item",
    item_to_spawn = "rail-signal-planner",
    consuming = "game-only"
  }
})