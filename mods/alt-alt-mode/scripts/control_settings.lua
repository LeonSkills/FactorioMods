local entity_logic = require("__alt-alt-mode__/scripts/entity_logic")

local escape_lua_pattern
do
  local matches = {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
  }

  escape_lua_pattern = function(s)
    return s:gsub(".", matches)
  end
end

local function update_blacklist_setting(player)
  if not storage.player_entity_whitelist then
    storage.player_entity_whitelist = {}
  end
  local blacklist_string = settings.get_player_settings(player)["alt-alt-blacklist"].value
  local blacklist = {}
  for entity_type in string.gmatch(blacklist_string, "([^ *(,|;)+ *]+)") do
    blacklist[entity_type] = true
  end
  local whitelist = {}
  for _, entity_type in pairs(entity_logic.supported_types) do
    if blacklist[entity_type] then
      blacklist[entity_type] = nil
    else
      table.insert(whitelist, entity_type)
    end
  end
  local new_blacklist_string = blacklist_string
  new_blacklist_string = string.gsub(new_blacklist_string, " ", "")
  new_blacklist_string = string.gsub(new_blacklist_string, ";", ",")
  new_blacklist_string = string.gsub(new_blacklist_string, ",+", ",")
  new_blacklist_string = string.gsub(new_blacklist_string, ",$", "")
  new_blacklist_string = string.gsub(new_blacklist_string, "^,", "")
  for entity_type, _ in pairs(blacklist) do
    player.print("Alternative Alt Mode: Entity type '" .. entity_type .. "' in settings has no alt mode logic.")
    new_blacklist_string = string.gsub(new_blacklist_string, "," .. escape_lua_pattern(entity_type) .. ",", ",")
    new_blacklist_string = string.gsub(new_blacklist_string, "," .. escape_lua_pattern(entity_type) .. "$", "")
    new_blacklist_string = string.gsub(new_blacklist_string, "^" .. escape_lua_pattern(entity_type) .. ",", "")
    new_blacklist_string = string.gsub(new_blacklist_string, "^" .. escape_lua_pattern(entity_type) .. "$", "")
  end
  if blacklist_string ~= new_blacklist_string then
    settings.get_player_settings(player)["alt-alt-blacklist"] = {value = new_blacklist_string}
  end
  storage.player_entity_whitelist[player.index] = whitelist
end

local function update_blacklist_setting_individual(player)
  if not storage.player_entity_blacklist_individual then
    storage.player_entity_blacklist_individual = {}
  end
  local blacklist_string = settings.get_player_settings(player)["alt-alt-blacklist-individual"].value
  local blacklist = {}
  local new_blacklist_string = blacklist_string
  for entity_name in string.gmatch(blacklist_string, "([^ *(,|;)+ *]+)") do
    if prototypes.entity[entity_name] then
      blacklist[entity_name] = true
      else
      player.print("Unknown entity name " .. entity_name)
      new_blacklist_string = string.gsub(new_blacklist_string, entity_name, "")
    end
  end
  new_blacklist_string = string.gsub(new_blacklist_string, " ", "")
  new_blacklist_string = string.gsub(new_blacklist_string, ";", ",")
  new_blacklist_string = string.gsub(new_blacklist_string, ",+", ",")
  new_blacklist_string = string.gsub(new_blacklist_string, ",$", "")
  new_blacklist_string = string.gsub(new_blacklist_string, "^,", "")
  if blacklist_string ~= new_blacklist_string then
    settings.get_player_settings(player)["alt-alt-blacklist-individual"] = {value = new_blacklist_string}
  end
  storage.player_entity_blacklist_individual[player.index] = blacklist
end

local function get_player_entity_types(player)
  if not storage.player_entity_whitelist then
    storage.player_entity_whitelist = {}
  end
  if not storage.player_entity_whitelist[player.index] then
    update_blacklist_setting(player)
  end
  return storage.player_entity_whitelist[player.index]
end

return {
  get_player_entity_types  = get_player_entity_types,
  update_blacklist_setting = update_blacklist_setting,
  update_blacklist_setting_individual = update_blacklist_setting_individual,
}