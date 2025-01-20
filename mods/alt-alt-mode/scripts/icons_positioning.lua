-- This file is required because of https://forums.factorio.com/viewtopic.php?f=28&t=125562&p=658621
return {
  ["electric-furnace"]          = {
    [4] = {
      inventory_index = 4,
      shift           = {
        0,
        0.8
      }
    },
  },
  ["recycler"]                  = {
    [4] = {
      inventory_index = 4,
      shift           = {
        0,
        0.2
      }
    },
  },
  ["crusher"]                   = {
    [4] = {
      inventory_index = 4,
      shift           = {
        0,
        0.3
      }
    },
  },
  ["foundry"]                   = {
    [4] = {
      inventory_index = 4,
      shift           = {
        0,
        1.25
      }
    },
  },
  ["electromagnetic-plant"]     = {
    [4] = {
      inventory_index = 4,
      shift           = {
        0,
        1
      }
    },
  },
  ["cryogenic-plant"]           = {
    [4] = {
      inventory_index   = 4,
      max_icons_per_row = 4,
      shift             = {
        0,
        0.95
      }
    },
  },
  ["lab"]                       = {
    [3] = {
      inventory_index = 3,
      shift           = {
        0,
        0.9
      }
    },
    [2] = {
      inventory_index       = 2,
      max_icons_per_row     = 6,
      separation_multiplier = 0.90909090909090899,
      shift                 = {
        0,
        0
      }
    },
  },
  ["biolab"]                    = {
    [3] = {
      inventory_index = 3,
      shift           = {
        0,
        1.6
      }
    },
    [2] = {
      inventory_index       = 2,
      max_icons_per_row     = 6,
      separation_multiplier = 0.90909090909090899,
      shift                 = {
        0,
        0.4
      }
    },
  },
  ["rocket-silo"]               = {
    [4] = {
      inventory_index = 4,
      shift           = {
        0,
        3.3
      }
    },
  },
  ["beacon"]                    = {
    [1] = {
      inventory_index                   = 1,
      max_icons_per_row                 = 2,
      multi_row_initial_height_modifier = -0.3,
      shift                             = {
        0,
        0
      }
    },
  },
  ["locomotive"]                = {
    [1] = {
      inventory_index   = 1,
      max_icons_per_row = 3,
      shift             = {
        0,
        0.3
      }
    },
  },
  -- creative-mod
  ["creative-mod_creative-lab"] = {
    [3] = {
      inventory_index = 3,
      shift           = {
        0,
        0.9
      }
    },
    [2] = {
      inventory_index       = 2,
      max_icons_per_row     = 4,
      separation_multiplier = 0.90909090909090899,
      shift                 = {
        0,
        0
      }
    },
  },
  ["creative-mod_void-lab"]     = {
    [3] = {
      inventory_index = 3,
      shift           = {
        0,
        0.9
      }
    },
    [2] = {
      inventory_index       = 2,
      max_icons_per_row     = 4,
      separation_multiplier = 0.90909090909090899,
      shift                 = {
        0,
        0
      }
    },
  },
  -- custom
  ["ammo-turret"]               = {
    ["turret"] = {
      max_icons_per_row = 4,
      scale             = 0.45,
    },
  },
  ["electric-turret"]           = {
    ["turret"] = {
      max_icons_per_row = 4,
      scale             = 0.45,
    },
  },
  ["electric-turret"]           = {
    ["turret"] = {
      max_icons_per_row = 4,
      scale             = 0.45,
    },
  },
  ["fluid-turret"]              = {
    ["turret"] = {
      max_icons_per_row = 4,
      scale             = 0.45,
    },
  },
  ["radar"]                     = {
    ["radar"] = {
      max_icons_per_row = 4,
      max_icon_rows     = 4,
      scale             = 0.45,
      shift             = {0, 0},
    },
  },
  ["asteroid-collector"]                     = {
    ["filter"] = {
      max_icons_per_row = 6,
      max_icon_rows     = 1,
      scale             = 0.45,
    },
  },
}

