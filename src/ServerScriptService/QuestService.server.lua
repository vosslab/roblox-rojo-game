-- QuestService.server.lua
-- Server-authoritative quest logic for Q1_PLAYGROUND (Age 5 playground quest).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local QUEST_ID = "Q1_PLAYGROUND"
local NEXT_QUEST_ID = "Q2_PLACEHOLDER"

local SWING_PUSH_GOAL = 10
local SPIN_TIME_GOAL = 20 -- seconds

local PUSH_DEBOUNCE = 0.35
local MAX_INTERACT_DISTANCE = 10

local TURN_ACCEL = 1.4 -- radians per second added per key press
local MAX_TURN_SPEED = 6
local TURN_FRICTION = 1.5 -- higher = more friction
local SPIN_THRESHOLD = 0.8

local PLAYGROUND = workspace:WaitForChild("Playground")
local swingArea = PLAYGROUND:WaitForChild("SwingArea")
local swingSeat = PLAYGROUND:WaitForChild("SwingSeat")
local pushButton = PLAYGROUND:WaitForChild("PushButton")

local merryModel = PLAYGROUND:WaitForChild("MerryGoRound")
local merryBase = merryModel:WaitForChild("MerryGoRoundBase")
local merrySeat = merryModel:WaitForChild("MerryGoRoundSeat")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function ensureRemote(name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local RequestInteract = ensureRemote("RequestInteract")
local RequestTurn = ensureRemote("RequestTurn")
local QuestStateUpdated = ensureRemote("QuestStateUpdated")
local ShowToast = ensureRemote("ShowToast")
local ShowAgeSplash = ensureRemote("ShowAgeSplash")

local playerState = {} -- [player] = state table
local lastPushTime = {} -- [player] = os.clock()

local turnSpeedByPlayer = {} -- [player] = angular speed in radians/sec
local currentRider = nil
local currentAngularSpeed = 0
local basePivot = merryModel:GetPivot()
local currentAngle = 0

local function hasTag(instance, tag)
	return instance and CollectionService:HasTag(instance, tag)
end

local function validateTags()
	if not hasTag(swingArea, "QuestTarget") then
		warn("SwingArea missing QuestTarget tag")
	end
	if not hasTag(merryBase, "QuestTarget") then
		warn("MerryGoRoundBase missing QuestTarget tag")
	end
	if not hasTag(pushButton, "QuestButton") then
		warn("PushButton missing QuestButton tag")
	end
	if not hasTag(swingSeat, "QuestMount") then
		warn("SwingSeat missing QuestMount tag")
	end
	if not hasTag(merrySeat, "QuestMount") then
		warn("MerryGoRoundSeat missing QuestMount tag")
	end
end

validateTags()

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

local function isSeatedOn(player, seat)
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	return humanoid.SeatPart == seat and seat.Occupant == humanoid
end

local function ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0
		coins.Parent = leaderstats
	end

	local fun = leaderstats:FindFirstChild("Fun")
	if not fun then
		fun = Instance.new("IntValue")
		fun.Name = "Fun"
		fun.Value = 0
		fun.Parent = leaderstats
	end

	return coins, fun
end

local function getObjectiveText(stage)
	if stage == 1 then
		return "Go to the swings and push 10 times."
	elseif stage == 2 then
		return "Ride the merry-go-round and keep spinning."
	end
	return "Quest complete!"
end

local function getTargetName(stage)
	if stage == 1 then
		return swingArea.Name
	elseif stage == 2 then
		return merryBase.Name
	end
	return ""
end

local function sendQuestState(player)
	local state = playerState[player]
	if not state then
		return
	end

	QuestStateUpdated:FireClient(
		player,
		getObjectiveText(state.Stage),
		state.SwingPushes,
		SWING_PUSH_GOAL,
		state.SpinTime,
		SPIN_TIME_GOAL,
		getTargetName(state.Stage)
	)
end

local function addCoinsFun(player, coinsDelta, funDelta)
	local coinsValue, funValue = ensureLeaderstats(player)
	coinsValue.Value += coinsDelta
	funValue.Value += funDelta
end

local function applySwingImpulse(player)
	local root = getRoot(player)
	if not root then
		return
	end

	-- Small nudge forward and upward for a "push" feeling
	local forward = swingSeat.CFrame.LookVector
	root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + (forward * 22) + Vector3.new(0, 4, 0)
end

local function advanceToStage2(player)
	local state = playerState[player]
	if not state then
		return
	end

	state.Stage = 2
	ShowToast:FireClient(player, "Nice swinging")
	sendQuestState(player)
end

local function completeQuest(player)
	local state = playerState[player]
	if not state or state.Stage == 3 then
		return
	end

	state.Stage = 3
	ShowAgeSplash:FireClient(player, "Age 5 complete")
	addCoinsFun(player, 10, 1)
	player:SetAttribute("currentQuestId", NEXT_QUEST_ID)
	sendQuestState(player)
end

RequestInteract.OnServerEvent:Connect(function(player, target, action)
	local state = playerState[player]
	if not state or state.Stage ~= 1 then
		return
	end

	if action ~= "SwingPush" then
		return
	end

	if typeof(target) ~= "Instance" then
		return
	end
	if not hasTag(target, "QuestButton") then
		return
	end
	if target ~= pushButton then
		return
	end
	if not withinDistance(player, target, MAX_INTERACT_DISTANCE) then
		return
	end
	if not isSeatedOn(player, swingSeat) then
		return
	end

	local now = os.clock()
	local last = lastPushTime[player]
	if last and (now - last) < PUSH_DEBOUNCE then
		return
	end
	lastPushTime[player] = now

	applySwingImpulse(player)
	state.SwingPushes += 1

	if state.SwingPushes >= SWING_PUSH_GOAL then
		advanceToStage2(player)
	else
		sendQuestState(player)
	end
end)

RequestTurn.OnServerEvent:Connect(function(player, direction)
	local state = playerState[player]
	if not state or state.Stage ~= 2 then
		return
	end

	if direction ~= -1 and direction ~= 1 then
		return
	end

	if not isSeatedOn(player, merrySeat) then
		return
	end

	if not withinDistance(player, merryBase, MAX_INTERACT_DISTANCE) then
		return
	end

	local speed = turnSpeedByPlayer[player] or 0
	speed += direction * TURN_ACCEL
	speed = math.clamp(speed, -MAX_TURN_SPEED, MAX_TURN_SPEED)
	turnSpeedByPlayer[player] = speed
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Age", 5)
	player:SetAttribute("currentQuestId", QUEST_ID)
	ensureLeaderstats(player)

	playerState[player] = {
		Stage = 1,
		SwingPushes = 0,
		SpinTime = 0,
		LastSpinSecond = -1,
	}

	turnSpeedByPlayer[player] = 0
	sendQuestState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
	lastPushTime[player] = nil
	turnSpeedByPlayer[player] = nil
end)

RunService.Heartbeat:Connect(function(dt)
	local occupant = merrySeat.Occupant
	local rider = nil
	if occupant and occupant.Parent then
		rider = Players:GetPlayerFromCharacter(occupant.Parent)
	end

	if rider ~= currentRider then
		currentRider = rider
		currentAngularSpeed = turnSpeedByPlayer[rider] or 0
	end

	if math.abs(currentAngularSpeed) > 0 then
		currentAngle += currentAngularSpeed * dt
		merryModel:PivotTo(basePivot * CFrame.Angles(0, currentAngle, 0))

		local decay = math.max(0, 1 - (TURN_FRICTION * dt))
		currentAngularSpeed = currentAngularSpeed * decay
		if math.abs(currentAngularSpeed) < 0.05 then
			currentAngularSpeed = 0
		end
	end

	if currentRider and playerState[currentRider] then
		turnSpeedByPlayer[currentRider] = currentAngularSpeed

		if isSeatedOn(currentRider, merrySeat) and math.abs(currentAngularSpeed) > SPIN_THRESHOLD then
			local state = playerState[currentRider]
			state.SpinTime += dt

			local wholeSeconds = math.floor(state.SpinTime)
			if wholeSeconds ~= state.LastSpinSecond then
				state.LastSpinSecond = wholeSeconds
				sendQuestState(currentRider)
			end

			if state.SpinTime >= SPIN_TIME_GOAL then
				completeQuest(currentRider)
			end
		end
	end
end)
