local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(shared:WaitForChild("Constants"))
local QuestDefinitions = require(script.Parent.QuestDefinitions)
local PlayerStatsService = require(script.Parent.Parent.Economy.PlayerStatsService)
local MerryGoRound = require(script.Parent.Parent.World.Interactables.MerryGoRound)
local Swing = require(script.Parent.Parent.World.Interactables.Swing)

local QuestService = {}

local QUEST_ID = Constants.QUESTS.Q1_PLAYGROUND
local NEXT_QUEST_ID = "Q2_PLACEHOLDER"

local SWING_PUSH_GOAL = 10
local SPIN_TIME_GOAL = 20

local MAX_INTERACT_DISTANCE = 10

local SPIN_THRESHOLD = 0.8

local remotes = {}
local playerState = {}

local function getPlaygroundObjects()
  local playground = workspace:FindFirstChild(Constants.NAMES.Playground)
  if not playground then
    warn("[QuestService] Playground not found.")
    return nil
  end

  local objects = {
    swingArea = playground:FindFirstChild(Constants.NAMES.SwingArea),
    pushButton = playground:FindFirstChild(Constants.NAMES.PushButton),
  }
  return objects
end

local function hasTag(instance, tag)
  return instance and CollectionService:HasTag(instance, tag)
end

local function getRoot(player)
  local character = player.Character
  if not character then
    return nil
  end
  return character:FindFirstChild("HumanoidRootPart")
end

local function withinDistance(player, target, maxDistance)
  local root = getRoot(player)
  if not root or not target then
    return false
  end
  if target:IsA("BasePart") then
    return (root.Position - target.Position).Magnitude <= maxDistance
  end
  if target:IsA("Model") then
    local pivot = target:GetPivot().Position
    return (root.Position - pivot).Magnitude <= maxDistance
  end
  return false
end

local function getObjectiveText(stage)
  local def = QuestDefinitions[QUEST_ID]
  if not def then
    return ""
  end
  local stageDef = def.stages[stage]
  return stageDef and stageDef.objective or ""
end

local function getTargetName(stage)
  local def = QuestDefinitions[QUEST_ID]
  if not def then
    return ""
  end
  local stageDef = def.stages[stage]
  return stageDef and stageDef.targetName or ""
end

local function sendQuestState(player)
  local state = playerState[player]
  if not state then
    return
  end

  remotes[Constants.REMOTES.QuestStateUpdated]:FireClient(
    player,
    getObjectiveText(state.stage),
    state.swingPushes,
    SWING_PUSH_GOAL,
    state.spinTime,
    SPIN_TIME_GOAL,
    getTargetName(state.stage)
  )
end

local function advanceToStage2(player)
  local state = playerState[player]
  if not state then
    return
  end

  state.stage = 2
  remotes[Constants.REMOTES.ShowToast]:FireClient(player, "Nice swinging")
  sendQuestState(player)
end

local function completeQuest(player)
  local state = playerState[player]
  if not state or state.stage == 3 then
    return
  end

  state.stage = 3
  remotes[Constants.REMOTES.ShowAgeSplash]:FireClient(player, "Age 5 complete")
  PlayerStatsService.AddCoins(player, 10)
  PlayerStatsService.AddStat(player, "Fun", 1)
  player:SetAttribute("currentQuestId", NEXT_QUEST_ID)
  sendQuestState(player)
end

local function handleSwingPush(player, target)
  local objects = getPlaygroundObjects()
  if not objects then
    return
  end

  local state = playerState[player]
  if not state or state.stage ~= 1 then
    return
  end

  if not hasTag(target, Constants.TAGS.QuestButton) then
    return
  end
  if target ~= objects.pushButton then
    return
  end
  if not withinDistance(player, target, MAX_INTERACT_DISTANCE) then
    return
  end
  if not Swing.Push(player) then
    return
  end

  state.swingPushes += 1

  if state.swingPushes >= SWING_PUSH_GOAL then
    advanceToStage2(player)
  else
    sendQuestState(player)
  end
end

local function handleSpinPush(player, target)
  if not target then
    return
  end

  if
    not hasTag(target, Constants.TAGS.QuestTarget)
    and target.Name ~= Constants.NAMES.MerryGoRoundBase
  then
    return
  end
  if not withinDistance(player, target, MAX_INTERACT_DISTANCE) then
    return
  end

  if MerryGoRound.Push(player) then
    remotes[Constants.REMOTES.ShowToast]:FireClient(player, "Push")
  end
end

local function onHeartbeat(dt)
  MerryGoRound.Update(dt)

  local seat = MerryGoRound.GetSeat()
  if not seat then
    return
  end

  local occupant = seat.Occupant
  local rider = nil
  if occupant and occupant.Parent then
    rider = Players:GetPlayerFromCharacter(occupant.Parent)
  end

  if rider and playerState[rider] then
    if
      MerryGoRound.IsRiding(rider) and math.abs(MerryGoRound.GetAngularSpeed()) > SPIN_THRESHOLD
    then
      local state = playerState[rider]
      state.spinTime += dt

      local wholeSeconds = math.floor(state.spinTime)
      if wholeSeconds ~= state.lastSpinSecond then
        state.lastSpinSecond = wholeSeconds
        sendQuestState(rider)
      end

      if state.spinTime >= SPIN_TIME_GOAL then
        completeQuest(rider)
      end
    end
  end
end

function QuestService.Init(remoteTable)
  remotes = remoteTable
  local playground = workspace:FindFirstChild(Constants.NAMES.Playground)
  MerryGoRound.Init(playground, Constants, remotes)
  Swing.Init(playground, Constants)

  remotes[Constants.REMOTES.RequestInteract].OnServerEvent:Connect(function(player, target, action)
    if action == "SwingPush" and typeof(target) == "Instance" then
      handleSwingPush(player, target)
    elseif action == "SpinMerryGoRound" and typeof(target) == "Instance" then
      handleSpinPush(player, target)
    end
  end)

  RunService.Heartbeat:Connect(onHeartbeat)
end

function QuestService.StartQuest(player, questId)
  local questDef = QuestDefinitions[questId]
  if not questDef then
    return
  end

  player:SetAttribute("currentQuestId", questId)
  PlayerStatsService.SetAge(player, questDef.age)

  playerState[player] = {
    questId = questId,
    stage = 1,
    swingPushes = 0,
    spinTime = 0,
    lastSpinSecond = -1,
  }

  sendQuestState(player)
end

function QuestService.GetState(player)
  local state = playerState[player]
  if not state then
    return nil
  end
  return {
    questId = state.questId,
    stage = state.stage,
    swingPushes = state.swingPushes,
    spinTime = state.spinTime,
  }
end

function QuestService.RemovePlayer(player)
  playerState[player] = nil
end

return QuestService
