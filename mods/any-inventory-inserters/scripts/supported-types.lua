local supported_types = {
  ["assembling-machine"] = {
    {},
    {display = {"iaai.input"}, inventory = defines.inventory.assembling_machine_input},
    {display = {"iaai.output"}, inventory = defines.inventory.assembling_machine_output},
    {display = {"iaai.modules"}, inventory = defines.inventory.assembling_machine_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.assembling_machine_trash},
    {display = {"iaai.rejected"}, inventory = defines.inventory.assembling_machine_dump},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["furnace"]            = {
    {},
    {display = {"iaai.input"}, inventory = defines.inventory.furnace_source},
    {display = {"iaai.output"}, inventory = defines.inventory.furnace_result},
    {display = {"iaai.modules"}, inventory = defines.inventory.furnace_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.furnace_trash},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["lab"]                = {
    {},
    {display = {"iaai.input"}, inventory = defines.inventory.lab_input},
    {display = {"iaai.modules"}, inventory = defines.inventory.lab_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.furnace_trash},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["rocket-silo"]        = {
    {},
    {display = {"iaai.rocket-inventory"}, inventory = defines.inventory.rocket_silo_rocket},
    {display = {"iaai.input"}, inventory = defines.inventory.rocket_silo_input},
    {display = {"iaai.output"}, inventory = defines.inventory.rocket_silo_output},
    {display = {"iaai.modules"}, inventory = defines.inventory.rocket_silo_modules},
    {display = {"iaai.trash"}, inventory = defines.inventory.rocket_silo_trash},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
  ["cargo-landing-pad"]  = {
    {},
    {display = {"iaai.main-inventory"}, inventory = defines.inventory.cargo_landing_pad_main},
    {display = {"iaai.trash"}, inventory = defines.inventory.cargo_landing_pad_trash},
  },
  ["space-platform-hub"] = {
    {},
    {display = {"iaai-main-inventory"}, inventory = defines.inventory.hub_main},
    {display = {"iaai.trash"}, inventory = defines.inventory.hub_trash},
  },
  ["logistic-container"] = {
    {},
    {display = {"iaai.main-inventory"}, inventory = defines.inventory.chest},
    {display = {"iaai.trash"}, inventory = defines.inventory.logistic_container_trash},
  },
  ["mining-drill"]       = {
    {},
    {display = {"iaai.modules"}, inventory = defines.inventory.mining_drill_modules},
    {display = {"iaai.fuel"}, inventory = defines.inventory.fuel},
    {display = {"iaai.burnt-result"}, inventory = defines.inventory.burnt_result},
  },
}

local supported_types_filter = {}
for k, v in pairs(supported_types) do
  table.insert(supported_types_filter, k)
end

local function entity_has_inventory(entity_type, inventory_define)
  for _, inventory in pairs(supported_types[entity_type]) do
    if inventory.inventory == inventory_define then
      return true
    end
  end
  return false

end

return {
  supported_types        = supported_types,
  supported_types_filter = supported_types_filter,
  entity_has_inventory = entity_has_inventory,
}