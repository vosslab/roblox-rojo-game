local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local PlayerStatsService = {}

local statsByPlayer = {}
local statsRemote = nil

local function ensureLeaderstats(player)
  local leaderstats = player:FindFirstChild("leaderstats")
  if not leaderstats then
    leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
  end

  local function ensureIntValue(name)
    local value = leaderstats:FindFirstChild(name)
    if not value then
      value = Instance.new("IntValue")
      value.Name = name
      value.Value = 0
      value.Parent = leaderstats
    end
    return value
  end

  return {
    Coins = ensureIntValue("Coins"),
    Smarts = ensureIntValue("Smarts"),
    Fun = ensureIntValue("Fun"),
    Age = ensureIntValue("Age"),
  }
end

local function copyState(state)
  return {
    coins = state.coins,
    smarts = state.smarts,
    fun = state.fun,
    age = state.age,
    incomeRate = state.incomeRate,
    upgradeLevel = state.upgradeLevel,
    nextUpgradeCost = state.nextUpgradeCost,
  }
end

local function fireStats(player, state)
  if not statsRemote then
    return
  end
  statsRemote:FireClient(player, state.coins, state.incomeRate, state.upgradeLevel, state.nextUpgradeCost)
end

function PlayerStatsService.Init(remotes)
  statsRemote = remotes[Constants.REMOTES.PlayerStatsUpdated]
end

function PlayerStatsService.AddPlayer(player)
  if statsByPlayer[player] then
    return
  end

  local leaderstats = ensureLeaderstats(player)
  statsByPlayer[player] = {
    coins = 0,
    smarts = 0,
    fun = 0,
    age = 0,
    incomeRate = 1,
    upgradeLevel = 0,
    nextUpgradeCost = 10,
    leaderstats = leaderstats,
  }

  fireStats(player, statsByPlayer[player])
end

function PlayerStatsService.RemovePlayer(player)
  statsByPlayer[player] = nil
end

function PlayerStatsService.Get(player)
  local state = statsByPlayer[player]
  if not state then
    return nil
  end
  return copyState(state)
end

function PlayerStatsService.SetAge(player, age)
  local state = statsByPlayer[player]
  if not state then
    return
  end
  state.age = age
  state.leaderstats.Age.Value = age
end

function PlayerStatsService.AddCoins(player, amount)
  local state = statsByPlayer[player]
  if not state then
    return
  end
  state.coins = math.max(0, state.coins + amount)
  state.leaderstats.Coins.Value = state.coins
  fireStats(player, state)
end

function PlayerStatsService.AddStat(player, statName, amount)
  local state = statsByPlayer[player]
  if not state then
    return
  end

  if statName == "Fun" then
    state.fun = math.max(0, state.fun + amount)
    state.leaderstats.Fun.Value = state.fun
  elseif statName == "Smarts" then
    state.smarts = math.max(0, state.smarts + amount)
    state.leaderstats.Smarts.Value = state.smarts
  end
end

function PlayerStatsService.SetEconomy(player, data)
  local state = statsByPlayer[player]
  if not state then
    return
  end

  state.coins = math.max(0, data.coins or state.coins)
  state.incomeRate = math.max(0, data.incomeRate or state.incomeRate)
  state.upgradeLevel = math.max(0, data.upgradeLevel or state.upgradeLevel)
  state.nextUpgradeCost = math.max(0, data.nextUpgradeCost or state.nextUpgradeCost)

  state.leaderstats.Coins.Value = state.coins
  fireStats(player, state)
end

function PlayerStatsService.SetIncomeRate(player, incomeRate)
  local state = statsByPlayer[player]
  if not state then
    return
  end
  state.incomeRate = math.max(0, incomeRate)
  fireStats(player, state)
end

function PlayerStatsService.SetUpgradeLevel(player, level, nextCost)
  local state = statsByPlayer[player]
  if not state then
    return
  end
  state.upgradeLevel = math.max(0, level)
  if nextCost then
    state.nextUpgradeCost = math.max(0, nextCost)
  end
  fireStats(player, state)
end

return PlayerStatsService
