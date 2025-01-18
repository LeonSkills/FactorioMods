local icon_draw_specification = require("__alt-alt-mode__/scripts/icon_draw_specification")
local icons_positioning = require("__alt-alt-mode__/scripts/icons_positioning")

local new_icon_draw = {}
local new_icon_positioning = {}
print("Alt-alt - Icons draw specification:")
for type, _ in pairs(data.raw) do
  for _, entity in pairs(data.raw[type]) do
    if entity.icon_draw_specification then
      if not icon_draw_specification[entity.name] then
        table.insert(new_icon_draw, entity.name)
        print('["' .. entity.name .. '"] = ' .. serpent.block(entity.icon_draw_specification) .. ",")
      else
        print(entity.name)
        print(serpent.line(entity.icon_draw_specification))
        print(serpent.line(icon_draw_specification[entity.name]))
        assert(serpent.line(entity.icon_draw_specification) == serpent.line(icon_draw_specification[entity.name]))
      end
    end
  end
end

print("Alt-alt - Icons positioning:")

for type, _ in pairs(data.raw) do
  for _, entity in pairs(data.raw[type]) do
    if entity.icons_positioning and not icons_positioning[entity.name] then
      table.insert(new_icon_positioning, entity.name)
      print('["' .. entity.name .. '"] = {')
      for _, inventory_positioning in pairs(entity.icons_positioning) do
        print('[' .. inventory_positioning.inventory_index .. '] = ' .. serpent.block(inventory_positioning) .. ",")
      end
      print('},')
    end
  end
end

if #new_icon_draw > 0 or #new_icon_positioning > 0 then
  print(serpent.line(new_icon_draw))
  print(serpent.line(new_icon_positioning))
  error()
end

-- data.raw["mining-drill"]["big-mining-drill"].icons_positioning = {
--   {
--     inventory_index       = 2,
--     max_icons_per_row     = 1,
--     separation_multiplier = 4,
--     shift                 = {
--       0,
--       0.95
--     }}
-- }

