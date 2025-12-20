local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(shared:WaitForChild("Constants"))

local uiFolder = script.Parent:WaitForChild("UI")
local inputFolder = script.Parent:WaitForChild("Input")

local QuestUI = require(uiFolder:WaitForChild("QuestUI"))
local ArrowController = require(uiFolder:WaitForChild("ArrowController"))
local StatsUI = require(uiFolder:WaitForChild("StatsUI"))
local InputController = require(inputFolder:WaitForChild("InputController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild(Constants.NAMES.Remotes)

local remotes = {
  [Constants.REMOTES.RequestInteract] = remotesFolder:WaitForChild(
    Constants.REMOTES.RequestInteract
  ),
  [Constants.REMOTES.RequestTurn] = remotesFolder:WaitForChild(Constants.REMOTES.RequestTurn),
  [Constants.REMOTES.QuestStateUpdated] = remotesFolder:WaitForChild(
    Constants.REMOTES.QuestStateUpdated
  ),
  [Constants.REMOTES.ShowToast] = remotesFolder:WaitForChild(Constants.REMOTES.ShowToast),
  [Constants.REMOTES.ShowAgeSplash] = remotesFolder:WaitForChild(Constants.REMOTES.ShowAgeSplash),
  [Constants.REMOTES.PlayerStatsUpdated] = remotesFolder:WaitForChild(
    Constants.REMOTES.PlayerStatsUpdated
  ),
}

QuestUI.Init(playerGui)
ArrowController.Init(QuestUI.GetScreenGui())
StatsUI.Init(playerGui, remotes[Constants.REMOTES.PlayerStatsUpdated])
InputController.Init({
  RequestInteract = remotes[Constants.REMOTES.RequestInteract],
  RequestTurn = remotes[Constants.REMOTES.RequestTurn],
})

remotes[Constants.REMOTES.QuestStateUpdated].OnClientEvent:Connect(
  function(objectiveText, swingCount, swingGoal, spinTime, spinGoal, targetName)
    local swingLine = string.format("Swing pushes: %d/%d", swingCount or 0, swingGoal or 10)
    local spinLine = string.format("Spin time: %d/%ds", math.floor(spinTime or 0), spinGoal or 20)
    QuestUI.SetQuestText(
      string.format("Objective: %s\n%s\n%s", objectiveText or "", swingLine, spinLine)
    )
    ArrowController.SetTargetByName(targetName or "")
  end
)

remotes[Constants.REMOTES.ShowToast].OnClientEvent:Connect(function(message)
  QuestUI.ShowToast(message, 2)
end)

remotes[Constants.REMOTES.ShowAgeSplash].OnClientEvent:Connect(function(message)
  QuestUI.ShowAgeSplash(message, 3)
end)
