local M = {}

function M.calc_signals(container, indices)
  local res = {}
  if indices[11] then
    local inventory = container.get_inventory(defines.inventory.chest)
    local num_empty_stacks = inventory.count_empty_stacks() - #inventory + inventory.get_bar() - 1
    res[11] = num_empty_stacks
  end
  return res
end

function M.create_gui(control_behaviour, tbl)
  tbl.add{type="label", caption={"eir-gui.empty-stack-signal"}}
  tbl.add{type="choose-elem-button", name="entity_info_choose_button_11", elem_type="signal", signal= control_behaviour.get_signal(11).signal}
end

return M