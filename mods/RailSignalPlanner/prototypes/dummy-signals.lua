local rail_signal = table.deepcopy(data.raw['rail-signal']["rail-signal"])
rail_signal.name = "dummy-rsp-rail-signal"
rail_signal.order = "z"
table.insert(rail_signal.flags, "hidden")
local rail_chain_signal = table.deepcopy(data.raw['rail-chain-signal']["rail-chain-signal"])
rail_chain_signal.name = "dummy-rsp-rail-chain-signal"
rail_chain_signal.order = "z"
table.insert(rail_chain_signal.flags, "hidden")
data:extend({rail_signal, rail_chain_signal})