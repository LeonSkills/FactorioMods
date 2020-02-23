local M = {}

function M.calc_signals(entity, indices)
  local res = {}
  if indices[11] then
    res[11] = entity.products_finished
  end
  return res
end

function M.create_gui(control_behaviour, tbl)
  tbl.add{type="label", caption={"eir-gui.products-finished"}}
  tbl.add{type="choose-elem-button", name="entity_info_choose_button_11", elem_type="signal", signal= control_behaviour.get_signal(11).signal}
end

return M