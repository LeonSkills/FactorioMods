data:extend(
        {
          {
            type          = "double-setting",
            name          = "alt-alt-radius",
            setting_type  = "runtime-per-user",
            default_value = 15,
            minimum_value = 0,
            maximum_value = 50,
            order         = "alt-alt-a-a[radius]"
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-radius-indicator",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-a-b[radius-indicator]"
          },
          {
            type          = "int-setting",
            name          = "alt-alt-update-interval",
            setting_type  = "runtime-global",
            default_value = 5,
            minimum_value = 5,
            maximum_value = 120,
            order         = "alt-alt-a-a[update-interval]"
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-turn-off-completely",
            setting_type  = "runtime-per-user",
            default_value = false,
            order         = "alt-alt-a-c[turn-off]",
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-show-quality-badge",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-b-a[badge]",
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-show-quality-background",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-b-b[background]",
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-show-pipe-amount",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-b-c[pipe]",
          },

        }
)

-- Option to turn on/off certain entities
data:extend(
        {
          {
            type          = "string-setting",
            name          = "alt-alt-blacklist",
            setting_type  = "runtime-per-user",
            default_value = "construction-robot,logistic-robot,tree,fish,simple-entity,car,accumulator",
            order         = "alt-alt-x-a[blacklist]",
            allow_blank   = true,
            auto_trim     = true,
          },
        }
)

