require("__AlternativeAltMode__/input.lua")

data:extend{
  {
    type="sprite",
    name="alt-alt-entity-info-white-background",
    filename = "__AlternativeAltMode__/graphics/entity-info-white-background.png",
    priority = "extra-high-no-scale",
    width = 53,
    height = 53,
    flags = {"icon"}
  }
}
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
-- }
data:extend{
  {
    type="sprite",
    name="alt-alt-indication-arrow",
    filename = "__core__/graphics/arrows/indication-arrow.png",
    priority = "extra-high-no-scale",
    flags = { "icon" },
    width = 64,
    height = 64,
    scale = 0.5
  }
}
data:extend{
  {
    type="sprite",
    name="alt-alt-filter-blacklist",
    filename = "__core__/graphics/filter-blacklist.png",
    priority = "extra-high-no-scale",
    width = 101,
    height = 101,
    scale = 0.3,
    flags = { "icon" },
  }
}
