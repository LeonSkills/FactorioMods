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

        }
)

-- Option to turn on/off certain entities
data:extend(
        {
          {
            type          = "bool-setting",
            name          = "alt-alt-toggle-robots",
            setting_type  = "runtime-per-user",
            default_value = false,
            order         = "alt-alt-x-a[robots]"
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-toggle-poles",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-x-b[poles]"
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-toggle-accus",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-x-c[accus]"
          },
          {
            type          = "bool-setting",
            name          = "alt-alt-toggle-heatpipes",
            setting_type  = "runtime-per-user",
            default_value = true,
            order         = "alt-alt-x-d[heatpipes]"
          },
        }
)

