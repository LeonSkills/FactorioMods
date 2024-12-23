data:extend(
        {
          {
            name                     = "alt-alt-increase-radius",
            type                     = "custom-input",
            key_sequence             = "CTRL + ALT + mouse-wheel-up",
            alternative_key_sequence = "ALT + KP_PLUS",
            consuming                = "game-only",
            order                    = "radius-a"
          },
          {
            name                     = "alt-alt-decrease-radius",
            type                     = "custom-input",
            key_sequence             = "CTRL + ALT + mouse-wheel-down",
            alternative_key_sequence = "ALT + KP_MINUS",
            consuming                = "game-only",
            order                    = "radius-b"
          },
          {
            name                     = "alt-alt",
            type                     = "custom-input",
            key_sequence             = "CTRL + ALT + mouse-wheel-down",
            alternative_key_sequence = "ALT + KP_MINUS",
            consuming                = "game-only",
            order                    = "radius-b"
          },
        }
)
