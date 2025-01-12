require("__alt-alt-mode__/input.lua")

-- sprites
data:extend {
  {
    type     = "sprite",
    name     = "alt-alt-entity-info-white-background",
    filename = "__alt-alt-mode__/graphics/entity-info-white-background.png",
    priority = "extra-high-no-scale",
    width    = 53,
    height   = 53,
    flags    = {"icon"}
  },
  -- data:extend{
  --   {
  --     type="sprite",
  --     name="alt-alt-entity-info-dark-background",
  --     filename = "__core__/graphics/entity-info-dark-background.png",
  --     priority = "extra-high-no-scale",
  --     width = 53,
  --     height = 53,
  --     flags = {"icon"}
  --   }
  -- },
  {
    type     = "sprite",
    name     = "alt-alt-indication-arrow",
    filename = "__core__/graphics/arrows/indication-arrow.png",
    priority = "extra-high-no-scale",
    flags    = {"icon"},
    width    = 64,
    height   = 64,
    scale    = 0.5
  },
  {
    type     = "sprite",
    name     = "alt-alt-filter-blacklist",
    filename = "__core__/graphics/filter-blacklist.png",
    priority = "extra-high-no-scale",
    width    = 101,
    height   = 101,
    scale    = 0.3,
    flags    = {"icon"},
  },
  {
    type     = "sprite",
    name     = "alt-alt-item-request-symbol",
    filename = "__core__/graphics/icons/item-to-be-delivered-symbol.png",
    priority = "extra-high-no-scale",
    width    = 64,
    height   = 92,
    scale    = 0.4,
    flags    = {"icon"},
  }
}

-- Invisible entities
for i = 0, 4 do
  local width = math.pow(3, i) / 2
  data:extend {
    {
      type                    = "simple-entity-with-owner",
      name                    = "alt-alt-invisible-selectable-" .. i,
      force_condition         = "same",
      render_layer            = "remnants",
      flags                   = {"not-on-map", "not-deconstructable", "not-blueprintable"},
      hidden                  = true,
      hidden_in_factoriopedia = true,
      selection_box           = {{-width, -width}, {width, width}},
      collision_mask          = {
        layers                    = {},
        not_colliding_with_itself = true,
        colliding_with_tiles_only = true,
      },
      selection_priority      = 6 - i,
      remove_decoratives      = "false",
    },
  }
end
