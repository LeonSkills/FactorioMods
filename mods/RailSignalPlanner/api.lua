local supported_rails = {}

function add_supported_rail(rail_name, rail_planner_name, overwrite)
  if rail_planner_name == nil then
    rail_planner_name = "rail"
  end
  if not supported_rails[rail_name] or overwrite then
    supported_rails[rail_name] = rail_planner_name
  end
end

function get_supported_rail(rail_name)
  return supported_rails[rail_name]
end

remote.add_interface("RailSignalPlanner", {
  add_supported_rail = add_supported_rail,
  get_rail_planner = get_rail_planner
})
