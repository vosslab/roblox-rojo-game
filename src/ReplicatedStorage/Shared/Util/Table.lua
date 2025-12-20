local Table = {}

function Table.ShallowCopy(source)
  return table.clone(source)
end

function Table.DeepCopy(source)
  if type(source) ~= "table" then
    return source
  end

  local copy = {}
  for key, value in pairs(source) do
    copy[Table.DeepCopy(key)] = Table.DeepCopy(value)
  end
  return copy
end

return Table
