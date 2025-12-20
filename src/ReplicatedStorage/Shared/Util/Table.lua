local Table = {}

function Table.ShallowCopy(source)
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = value
  end
  return copy
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
