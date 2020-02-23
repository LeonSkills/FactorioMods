local M = {}

function M.calc_signals(entity, indices)
  local res = {}
  if indices[1] then
    res[1] = entity.health
  end
  if indices[2] then
    res[2] = entity.prototype.max_health
  end
  return res
end

function M.create_gui(control_behaviour, tbl)
  tbl.add{type="label", caption={"eir-gui.cur-health"}}
  tbl.add{type="choose-elem-button", name="entity_info_choose_button_1", elem_type="signal", signal= control_behaviour.get_signal(1).signal}
  tbl.add{type="label", caption={"eir-gui.max-health"}}
  tbl.add{type="choose-elem-button", name="entity_info_choose_button_2", elem_type="signal", signal= control_behaviour.get_signal(2).signal}
end

return M