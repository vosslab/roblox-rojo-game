local Players = game:GetService("Players")

local WorldBuilder = require(script.Parent.World.WorldBuilder)
local SaveService = require(script.Parent.Persistence.SaveService)
local PlayerStatsService = require(script.Parent.Economy.PlayerStatsService)
local TycoonService = require(script.Parent.Economy.TycoonService)
local QuestService = require(script.Parent.Quests.QuestService)
local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local baseplate, homeSpawn = WorldBuilder.ensureBaseplateAndSpawn()
WorldBuilder.ensurePlayground(baseplate, homeSpawn)
local remotes = WorldBuilder.ensureRemotes()

PlayerStatsService.Init(remotes)
QuestService.Init(remotes)
TycoonService.Init(SaveService)

Players.PlayerAdded:Connect(function(player)
  PlayerStatsService.AddPlayer(player)
  TycoonService.AddPlayer(player)
  QuestService.StartQuest(player, Constants.QUESTS.Q1_PLAYGROUND)
end)

Players.PlayerRemoving:Connect(function(player)
  QuestService.RemovePlayer(player)
  TycoonService.RemovePlayer(player)
  PlayerStatsService.RemovePlayer(player)
end)
