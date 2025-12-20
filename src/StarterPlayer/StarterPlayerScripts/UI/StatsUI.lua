local StatsUI = {}

local screenGui = nil
local statsLabel = nil

local function ensureGui(playerGui)
  screenGui = playerGui:FindFirstChild("HUD")
  if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
  end

  statsLabel = screenGui:FindFirstChild("StatsLabel")
  if not statsLabel then
    statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.fromOffset(260, 80)
    statsLabel.Position = UDim2.fromOffset(10, 110)
    statsLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    statsLabel.BackgroundTransparency = 0.2
    statsLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
    statsLabel.Font = Enum.Font.SourceSansBold
    statsLabel.TextSize = 18
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.Parent = screenGui
  end

  statsLabel.Text = "Coins: 0\nIncome: 0 / 5s\nUpgrade: 0\nNext Cost: 0"
end

function StatsUI.Init(playerGui, playerStatsRemote)
  ensureGui(playerGui)

  playerStatsRemote.OnClientEvent:Connect(function(coins, incomeRate, upgradeLevel, nextCost)
    statsLabel.Text = string.format(
      "Coins: %d\nIncome: %d / 5s\nUpgrade: %d\nNext Cost: %d",
      tonumber(coins) or 0,
      tonumber(incomeRate) or 0,
      tonumber(upgradeLevel) or 0,
      tonumber(nextCost) or 0
    )
  end)
end

return StatsUI
