-- Base functions commonly used go in here
function contains(array, value)
  for i, v in pairs(array) do
    if v == value then
      return true
    end
  end
  return false
end

function add_leading_zeros(num, str_length)
  local res = tostring(num)
  local l = string.len(res)
  for i = 0,(str_length-l-1) do
    res = 0 .. res
  end
  return res
end

function format_number(amount, delimiter)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1'..delimiter..'%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function tprint (tbl, indent)
  if not indent then indent = 2 end
  if not tbl then
    print(nil)
  end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

function union ( a, b )
    local result = {}
    for k,v in pairs ( a ) do
        table.insert( result, v )
    end
    for k,v in pairs ( b ) do
         table.insert( result, v )
    end
    return result
end

function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function remove(tbl, element)
  table.remove(tbl, tablefind(tbl, element))
end

function create_unique_id(position, direction)
  return position.x..",".. position.y..",".. direction
end

function entity_id(entity)
  return entity.type..","..create_unique_id(entity.position, entity.direction)
end