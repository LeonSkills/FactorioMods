local proxy_container
local debug = false
if debug then
  proxy_container = table.deepcopy(data.raw["proxy-container"]["proxy-container"])
  proxy_container.name = "ii-proxy-container"
  proxy_container.type = "proxy-container"
  proxy_container.selection_box = nil
  proxy_container.minable = nil
  proxy_container.collision_mask = {layers = {}, not_colliding_with_itself = true, colliding_with_tiles_only = true}
  proxy_container.flags = {"not-on-map", "not-deconstructable", "not-blueprintable"}
else
  proxy_container = {
    name                    = "ii-proxy-container",
    type                    = "proxy-container",
    draw_inventory_content  = false,
    flags                   = {"not-on-map", "not-deconstructable", "not-blueprintable"},
    hidden                  = true,
    hidden_in_factoriopedia = true,
    selection_box           = nil,
    collision_box           = {{-0.4, -0.4}, {0.4, 0.4}},
    collision_mask          = {
      layers                    = {},
      not_colliding_with_itself = true,
      colliding_with_tiles_only = true,
    },
    selection_priority      = 1,
    remove_decoratives      = "false",
  }
end
data:extend {proxy_container}