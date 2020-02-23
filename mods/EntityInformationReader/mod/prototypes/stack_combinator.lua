-- ENTITY

local empty_sprite = {
  filename = "__EntityInformationReader__/graphics/empty.png",
  size = 1
}

local stack_combinator_entity = {}
stack_combinator_entity.type = "constant-combinator"
stack_combinator_entity.name = "entity-information-reader"
stack_combinator_entity.icon = "__base__/graphics/icons/info.png"
stack_combinator_entity.icon_size = 64
stack_combinator_entity.circuit_wire_max_distance = 9
stack_combinator_entity.circuit_wire_connection_points = {
  {
    wire = {
      green = {0, 0.2},
      red = {-0, -0.2}
    },
    shadow = {
      green = {-0, 0.4},
      red = {-0, 0}
    }
  },
  {
    wire = {
      green = {0, 0},
      red = {0, 0}
    },
    shadow = {
      green = {0, 0},
      red = {0, 0}
    }
  },
  {
    wire = {
      green = {0, 0},
      red = {0, 0}
    },
    shadow = {
      green = {0, 0},
      red = {0, 0}
    }
  },
  {
    wire = {
      green = {0, 0},
      red = {0, 0}
    },
    shadow = {
      green = {0, 0},
      red = {0, 0}
    }
  },
}

stack_combinator_entity.minable = {
  result = "entity-information-reader",
  mining_time = 0.1
}
stack_combinator_entity.order = "zzz"
stack_combinator_entity.item_slot_count = 100
stack_combinator_entity.selection_priority = 100
stack_combinator_entity.activity_led_light = nil
stack_combinator_entity.activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}}
stack_combinator_entity.activity_led_sprites = empty_sprite
stack_combinator_entity.sprites = {
  filename = "__base__/graphics/icons/info.png",
  size = 64,
  scale = 0.2
}
stack_combinator_entity.collision_mask = {"layer-13"}
stack_combinator_entity.collision_box = {{-0.3, -0.3}, {0.3, 0.3}}
stack_combinator_entity.selection_box = {{-0.3, -0.3}, {0.3, 0.3}}
stack_combinator_entity.max_health=1
stack_combinator_entity.flags = {"player-creation", "not-repairable"}

data:extend({stack_combinator_entity})

data:extend{
  {
    name = "entity-information-reader",
    type = "item",
    stack_size = 100,
    icon = "__base__/graphics/icons/info.png",
    icon_size = 64,
    place_result = "entity-information-reader",
    order = "zzz"
  },
  {
    name = "entity-information-reader",
    type = "recipe",
    enabled = true,  -- TODO
    ingredients = {
      {
        type = "item",
        name = "arithmetic-combinator",
        amount = 1
      },
      {
        type = "item",
        name = "decider-combinator",
        amount = 1
      },
      {
        type = "item",
        name = "constant-combinator",
        amount = 1
      }
    },
    result = "entity-information-reader"
  }
}

-- TECHNOLOGY
table.insert(data.raw.technology['circuit-network'].effects, {type="unlock-recipe", recipe="entity-information-reader"})
