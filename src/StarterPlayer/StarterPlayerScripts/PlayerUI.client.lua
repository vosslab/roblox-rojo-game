-- PlayerUI.client.lua
-- Minimal HUD that shows Coins and Income. Server sends updates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local statsEvent = remotesFolder:WaitForChild("PlayerStatsUpdated")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "StatsLabel"
label.Size = UDim2.new(0, 260, 0, 80)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundTransparency = 0.2
label.TextColor3 = Color3.fromRGB(20, 20, 20)
label.Font = Enum.Font.SourceSansBold
label.TextSize = 18
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Parent = screenGui
label.Text = "Coins: 0\nIncome: 0 / 5s\nUpgrade: 0\nNext Cost: 0"

statsEvent.OnClientEvent:Connect(function(coins, incomeRate, upgradeLevel, nextCost)
	label.Text = string.format(
		"Coins: %d\nIncome: %d / 5s\nUpgrade: %d\nNext Cost: %d",
		tonumber(coins) or 0,
		tonumber(incomeRate) or 0,
		tonumber(upgradeLevel) or 0,
		tonumber(nextCost) or 0
	)
end)
