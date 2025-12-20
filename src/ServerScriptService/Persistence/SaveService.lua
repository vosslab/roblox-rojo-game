local DataStoreService = game:GetService("DataStoreService")

local SaveService = {}

local DATASTORE_NAME = "IdleTycoonSave_v1"
local MAX_RETRIES = 2

local store = nil

local function getStore()
  if store then
    return store
  end

  local ok, result = pcall(function()
    return DataStoreService:GetDataStore(DATASTORE_NAME)
  end)

  if not ok then
    warn("[SaveService] GetDataStore failed:", result)
    return nil
  end

  store = result
  return store
end

function SaveService.Load(player)
  local currentStore = getStore()
  if not currentStore then
    return nil
  end

  local key = tostring(player.UserId)
  local ok, result = pcall(function()
    return currentStore:GetAsync(key)
  end)

  if not ok then
    warn("[SaveService] Load failed for", player.Name, result)
    return nil
  end

  return result
end

function SaveService.Save(player, data)
  local currentStore = getStore()
  if not currentStore then
    return false
  end

  local key = tostring(player.UserId)
  local attempts = 0

  while attempts <= MAX_RETRIES do
    local ok, err = pcall(function()
      currentStore:SetAsync(key, data)
    end)

    if ok then
      return true
    end

    warn("[SaveService] Save failed for", player.Name, err)
    attempts += 1
    task.wait(2)
  end

  return false
end

return SaveService
