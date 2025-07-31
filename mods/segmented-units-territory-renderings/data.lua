data:extend(
        {
          {
            type                     = "shortcut",
            name                     = "sutr-toggle-shortcut",
            order                    = "d",
            action                   = "lua",
            associated_control_input = "sutr-toggle-territories",
            toggleable               = true,
            icon                     = "__segmented-units-territory-renderings__/graphics/shortcut.png",
            icon_size                = 64,
            small_icon               = "__segmented-units-territory-renderings__/graphics/shortcut.png",
            small_icon_size          = 64,
            localised_name           = {"controls.sutr-toggle-territories"},
            localised_description    = {"controls-description.sutr-toggle-territories"},
          },

          {
            name         = "sutr-toggle-territories",
            type         = "custom-input",
            key_sequence = "ALT + SHIFT + T",
            action       = "lua",
            order        = "d"
          },
        })
