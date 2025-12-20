local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function safeRequire(moduleScript)
  local ok, result = pcall(require, moduleScript)
  if not ok then
    warn("[Main] require failed:", moduleScript:GetFullName(), result)
    return nil
  end
  return result
end

local WorldBuilder = safeRequire(script.Parent.World.WorldBuilder)
local Slide = safeRequire(script.Parent.World.Interactables.Slide)
local SaveService = safeRequire(script.Parent.Persistence.SaveService)
local PlayerStatsService = safeRequire(script.Parent.Economy.PlayerStatsService)
local TycoonService = safeRequire(script.Parent.Economy.TycoonService)
local QuestService = safeRequire(script.Parent.Quests.QuestService)

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = safeRequire(shared:WaitForChild("Constants"))

local remotes = nil
if WorldBuilder then
  local baseplate, homeSpawn = WorldBuilder.ensureBaseplateAndSpawn()
  WorldBuilder.ensurePlayground(baseplate, homeSpawn)
  remotes = WorldBuilder.ensureRemotes()
end
if Slide and Constants then
  local playground = workspace:FindFirstChild(Constants.NAMES.Playground)
  Slide.Init(playground, Constants)
end

if PlayerStatsService and remotes then
  PlayerStatsService.Init(remotes)
end
if QuestService and remotes then
  QuestService.Init(remotes)
end
if TycoonService and SaveService then
  TycoonService.Init(SaveService)
end

if RunService:IsStudio() then
  local devFolder = script.Parent:FindFirstChild("Dev")
  if devFolder then
    local diagnostics = devFolder:FindFirstChild("Diagnostics")
    if diagnostics then
      local module = safeRequire(diagnostics)
      if module and module.Init then
        module.Init()
      end
    end

    local overlap = devFolder:FindFirstChild("OverlapValidator")
    if overlap then
      local module = safeRequire(overlap)
      if module and module.Init then
        module.Init()
      end
    end
  end
end

Players.PlayerAdded:Connect(function(player)
  if PlayerStatsService then
    PlayerStatsService.AddPlayer(player)
  end
  if TycoonService then
    TycoonService.AddPlayer(player)
  end
  if QuestService and Constants then
    QuestService.StartQuest(player, Constants.QUESTS.Q1_PLAYGROUND)
  end
end)

Players.PlayerRemoving:Connect(function(player)
  if QuestService then
    QuestService.RemovePlayer(player)
  end
  if TycoonService then
    TycoonService.RemovePlayer(player)
  end
  if PlayerStatsService then
    PlayerStatsService.RemovePlayer(player)
  end
end)
