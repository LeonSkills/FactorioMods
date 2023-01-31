
if data.raw["rail-planner"]["water-way"] then
  data.raw["rail-planner"]["water-way"].localised_name = {"item-name.water-way"}
end

if data.raw["rail-chain-signal"]["invisible_chain_signal"] then
  table.insert(data.raw["rail-chain-signal"]["invisible_chain_signal"].flags, "hidden")
end