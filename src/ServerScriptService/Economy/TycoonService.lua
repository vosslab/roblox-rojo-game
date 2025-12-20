local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(shared:WaitForChild("Constants"))
local PlayerStatsService = require(script.Parent.PlayerStatsService)

local TycoonService = {}

local SaveService = nil

local COIN_RESPAWN_TIME = 5
local PASSIVE_INCOME_INTERVAL = 5
local SAVE_INTERVAL = 60
local SAVE_COOLDOWN = 50

local DEFAULT_INCOME = 1
local UPGRADE_BASE_COST = 10
local UPGRADE_COST_STEP = 10
local UPGRADE_INCOME_BONUS = 1

local houseModel = nil
local houseBase = nil
local coinFolder = nil
local upgradePad = nil

local playerEconomy = {}
local lastSaveTime = {}
local upgradeDebounce = {}

local HOUSE_COLORS = {
  BrickColor.new("Bright yellow"),
  BrickColor.new("Bright blue"),
  BrickColor.new("Bright green"),
  BrickColor.new("Bright orange"),
  BrickColor.new("Bright red"),
}

local currentHouseLevel = 0

local function getNextUpgradeCost(level)
  return UPGRADE_BASE_COST + (level * UPGRADE_COST_STEP)
end

local function addHouseLevelPart(level)
  local partName = "Level" .. level
  if houseModel:FindFirstChild(partName) then
    return
  end

  local levelHeight = 2
  local sizeShrink = math.min(level * 0.5, 4)
  local sizeX = math.max(2, houseBase.Size.X - sizeShrink)
  local sizeZ = math.max(2, houseBase.Size.Z - sizeShrink)

  local part = Instance.new("Part")
  part.Name = partName
  part.Anchored = true
  part.CanCollide = true
  part.Material = Enum.Material.SmoothPlastic
  part.BrickColor = HOUSE_COLORS[((level - 1) % #HOUSE_COLORS) + 1]
  part.Size = Vector3.new(sizeX, levelHeight, sizeZ)

  local yOffset = houseBase.Size.Y / 2 + (level - 0.5) * levelHeight
  part.CFrame = houseBase.CFrame * CFrame.new(0, yOffset, 0)
  part.Parent = houseModel
end

local function applyHouseLevel(level)
  if level <= currentHouseLevel then
    return
  end

  for i = currentHouseLevel + 1, level do
    addHouseLevelPart(i)
  end

  currentHouseLevel = level
end

local function ensureEconomy(player)
  if not playerEconomy[player] then
    playerEconomy[player] = {
      coins = 0,
      incomeRate = DEFAULT_INCOME,
      upgradeLevel = 0,
      nextUpgradeCost = getNextUpgradeCost(0),
    }
  end
  return playerEconomy[player]
end

local function addCoins(player, amount)
  local economy = ensureEconomy(player)
  economy.coins = math.max(0, economy.coins + amount)
  PlayerStatsService.SetEconomy(player, economy)
end

local function getPlayerFromHit(hit)
  if not hit or not hit.Parent then
    return nil
  end
  return Players:GetPlayerFromCharacter(hit.Parent)
end

local function setupCoin(coin)
  if not coin:IsA("BasePart") then
    return
  end

  coin:SetAttribute("OnCooldown", false)

  coin.Touched:Connect(function(hit)
    if coin:GetAttribute("OnCooldown") then
      return
    end

    local player = getPlayerFromHit(hit)
    if not player or not player.Character then
      return
    end
    if not player.Character:FindFirstChild("Humanoid") then
      return
    end

    coin:SetAttribute("OnCooldown", true)
    coin.CanTouch = false
    coin.CanCollide = false
    coin.Transparency = 1

    addCoins(player, 1)

    task.delay(COIN_RESPAWN_TIME, function()
      if coin and coin.Parent then
        coin:SetAttribute("OnCooldown", false)
        coin.CanTouch = true
        coin.CanCollide = true
        coin.Transparency = 0
      end
    end)
  end)
end

local function setupAllCoins()
  for _, child in ipairs(coinFolder:GetChildren()) do
    setupCoin(child)
  end

  coinFolder.ChildAdded:Connect(function(child)
    setupCoin(child)
  end)
end

local function tryUpgrade(player)
  local economy = ensureEconomy(player)
  local cost = economy.nextUpgradeCost
  if economy.coins < cost then
    return
  end

  economy.coins -= cost
  economy.upgradeLevel += 1
  economy.incomeRate += UPGRADE_INCOME_BONUS
  economy.nextUpgradeCost = getNextUpgradeCost(economy.upgradeLevel)

  applyHouseLevel(economy.upgradeLevel)
  PlayerStatsService.SetEconomy(player, economy)
end

local function updateSaveCache(player)
  local economy = ensureEconomy(player)
  economy.coins = math.max(0, economy.coins)
  economy.incomeRate = math.max(0, economy.incomeRate)
  economy.upgradeLevel = math.max(0, economy.upgradeLevel)
end

local function savePlayer(player, force)
  if not SaveService then
    return
  end

  local now = os.clock()
  if not force then
    local last = lastSaveTime[player]
    if last and (now - last) < SAVE_COOLDOWN then
      return
    end
  end

  local economy = ensureEconomy(player)
  local ok = SaveService.Save(player, {
    Coins = economy.coins,
    UpgradeLevel = economy.upgradeLevel,
    IncomeRate = economy.incomeRate,
  })

  if ok then
    lastSaveTime[player] = os.clock()
  end
end

function TycoonService.Init(saveService)
  SaveService = saveService
  houseModel = workspace:WaitForChild(Constants.NAMES.HouseModel)
  houseBase = houseModel:WaitForChild(Constants.NAMES.HouseBase)
  coinFolder = workspace:WaitForChild(Constants.NAMES.CoinSpawners)
  upgradePad = workspace:WaitForChild(Constants.NAMES.UpgradePad)

  setupAllCoins()

  upgradePad.Touched:Connect(function(hit)
    local player = getPlayerFromHit(hit)
    if not player or not player.Character then
      return
    end
    if not player.Character:FindFirstChild("Humanoid") then
      return
    end

    local now = os.clock()
    local last = upgradeDebounce[player]
    if last and (now - last) < 1 then
      return
    end
    upgradeDebounce[player] = now

    tryUpgrade(player)
  end)

  task.spawn(function()
    while true do
      task.wait(PASSIVE_INCOME_INTERVAL)
      for player, economy in pairs(playerEconomy) do
        if player and player.Parent then
          addCoins(player, economy.incomeRate)
        end
      end
    end
  end)

  task.spawn(function()
    while true do
      task.wait(SAVE_INTERVAL)
      for _, player in ipairs(Players:GetPlayers()) do
        savePlayer(player, false)
      end
    end
  end)
end

function TycoonService.AddPlayer(player)
  local saved = SaveService and SaveService.Load(player) or nil
  local economy = ensureEconomy(player)

  economy.coins = math.max(0, tonumber(saved and saved.Coins) or 0)
  economy.upgradeLevel = math.max(0, tonumber(saved and saved.UpgradeLevel) or 0)
  economy.incomeRate = math.max(0, tonumber(saved and saved.IncomeRate) or DEFAULT_INCOME)
  economy.nextUpgradeCost = getNextUpgradeCost(economy.upgradeLevel)

  PlayerStatsService.SetEconomy(player, economy)
  applyHouseLevel(economy.upgradeLevel)
  updateSaveCache(player)
end

function TycoonService.RemovePlayer(player)
  savePlayer(player, true)
  playerEconomy[player] = nil
  lastSaveTime[player] = nil
  upgradeDebounce[player] = nil
end

return TycoonService
