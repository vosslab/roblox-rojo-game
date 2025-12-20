-- SaveService.server.lua
-- Server-only saving for Coins, UpgradeLevel, IncomeRate.
-- Uses a simple _G table so other server scripts can call it without modules.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DATASTORE_NAME = "IdleTycoonSave_v1"
local SAVE_INTERVAL = 60 -- seconds
local SAVE_COOLDOWN = 50 -- seconds, prevents spamming DataStore
local MAX_RETRIES = 2 -- number of extra tries after first failure

local store = DataStoreService:GetDataStore(DATASTORE_NAME)

local DEFAULT_DATA = {
	Coins = 0,
	UpgradeLevel = 0,
	IncomeRate = 1,
}

local cache = {} -- [userIdString] = data table
local lastSaveTime = {} -- [userIdString] = os.clock() time

local function sanitizeData(raw)
	return {
		Coins = math.max(0, tonumber(raw and raw.Coins) or DEFAULT_DATA.Coins),
		UpgradeLevel = math.max(0, tonumber(raw and raw.UpgradeLevel) or DEFAULT_DATA.UpgradeLevel),
		IncomeRate = math.max(0, tonumber(raw and raw.IncomeRate) or DEFAULT_DATA.IncomeRate),
	}
end

local function copyData(data)
	local clone = {}
	for k, v in pairs(data) do
		clone[k] = v
	end
	return clone
end

local SaveService = {}

function SaveService:Load(player)
	local key = tostring(player.UserId)
	local data

	local ok, result = pcall(function()
		return store:GetAsync(key)
	end)

	if ok then
		data = sanitizeData(result)
	else
		warn("[SaveService] Load failed for", player.Name, result)
		data = sanitizeData(nil)
	end

	cache[key] = data
	return copyData(data)
end

function SaveService:UpdateCache(player, newData)
	local key = tostring(player.UserId)
	cache[key] = sanitizeData(newData)
end

function SaveService:Save(player, force)
	local key = tostring(player.UserId)
	local data = cache[key]
	if not data then
		return false
	end

	local now = os.clock()
	if not force then
		local last = lastSaveTime[key]
		if last and (now - last) < SAVE_COOLDOWN then
			return false
		end
	end

	local attempts = 0
	while attempts <= MAX_RETRIES do
		local ok, err = pcall(function()
			store:SetAsync(key, data)
		end)

		if ok then
			lastSaveTime[key] = os.clock()
			return true
		end

		warn("[SaveService] Save failed for", player.Name, err)
		attempts += 1
		task.wait(2)
	end

	return false
end

function SaveService:Clear(player)
	local key = tostring(player.UserId)
	cache[key] = nil
	lastSaveTime[key] = nil
end

_G.SaveService = SaveService
_G.SaveService.IsReady = true

Players.PlayerRemoving:Connect(function(player)
	SaveService:Save(player, true)
	SaveService:Clear(player)
end)

-- Autosave loop

task.spawn(function()
	while true do
		task.wait(SAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			SaveService:Save(player, false)
		end
	end
end)
