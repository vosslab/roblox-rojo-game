-- GameServer.server.lua
-- Core gameplay: coins, passive income, upgrades, and UI updates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- World bootstrap: keep players from falling in an empty place.
local function ensureBaseplate()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and not baseplate:IsA("BasePart") then
		warn("[Bootstrap] 'Baseplate' exists but is not a Part. Renaming it.")
		baseplate.Name = "Baseplate_Unexpected"
		baseplate = nil
	end

	if not baseplate then
		baseplate = Instance.new("Part")
		baseplate.Name = "Baseplate"
		baseplate.Parent = workspace
	end

	baseplate.Anchored = true
	baseplate.Size = Vector3.new(512, 10, 512)
	baseplate.Position = Vector3.new(0, -5, 0)
	baseplate.Material = Enum.Material.Grass
	baseplate.BrickColor = BrickColor.new("Medium green")
	return baseplate
end

local function ensureHomeSpawn(baseplate)
	local spawn = workspace:FindFirstChild("HomeSpawn")
	if spawn and not spawn:IsA("SpawnLocation") then
		warn("[Bootstrap] 'HomeSpawn' exists but is not a SpawnLocation. Renaming it.")
		spawn.Name = "HomeSpawn_Unexpected"
		spawn = nil
	end

	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "HomeSpawn"
		spawn.Parent = workspace
	end

	spawn.Anchored = true
	local topY = baseplate.Position.Y + (baseplate.Size.Y / 2)
	spawn.Position = Vector3.new(0, topY + 3, 0)
	return spawn
end

local baseplate = ensureBaseplate()
local homeSpawn = ensureHomeSpawn(baseplate)

-- Playground bootstrap: create simple swing + merry-go-round if missing.
local function applyTag(instance, tag)
	if instance and not CollectionService:HasTag(instance, tag) then
		CollectionService:AddTag(instance, tag)
	end
end

local function applyPhysics(part, anchored, canCollide, massless)
	if not part or not part:IsA("BasePart") then
		return
	end
	part.Anchored = anchored
	part.CanCollide = canCollide
	part.Massless = massless or false
end

local function findOrCreateModel(parent, name)
	local model = parent:FindFirstChild(name)
	if model and not model:IsA("Model") then
		warn("[Bootstrap] '" .. name .. "' exists but is not a Model. Renaming it.")
		model.Name = name .. "_Unexpected"
		model = nil
	end

	if not model then
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent
		return model, true
	end

	return model, false
end

local function findOrCreatePart(parent, name, className)
	local part = parent:FindFirstChild(name)
	if part and not part:IsA(className) then
		warn("[Bootstrap] '" .. name .. "' exists but is not a " .. className .. ". Renaming it.")
		part.Name = name .. "_Unexpected"
		part = nil
	end

	if not part then
		part = Instance.new(className)
		part.Name = name
		part.Parent = parent
		return part, true
	end

	return part, false
end

local function findOrCreateAttachment(parent, name, position, axis, secondaryAxis)
	local attachment = parent:FindFirstChild(name)
	if attachment and not attachment:IsA("Attachment") then
		warn("[Bootstrap] '" .. name .. "' exists but is not an Attachment. Renaming it.")
		attachment.Name = name .. "_Unexpected"
		attachment = nil
	end

	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.Parent = parent
	end

	if position then
		attachment.Position = position
	end
	if axis then
		attachment.Axis = axis
	end
	if secondaryAxis then
		attachment.SecondaryAxis = secondaryAxis
	end

	return attachment
end

local function ensurePlayground()
	local playground = findOrCreateModel(workspace, "Playground")

	local groundY = baseplate.Position.Y + (baseplate.Size.Y / 2)
	local playgroundCenter = Vector3.new(homeSpawn.Position.X + 80, groundY, homeSpawn.Position.Z)
	local sandThickness = 1
	local sandTopY = groundY + sandThickness
	local surfaceY = sandTopY
	local GROUND_Y = surfaceY

	-- Sand patch around the playground
	local sandPatch = findOrCreatePart(playground, "PlaygroundSand", "Part")
	applyPhysics(sandPatch, true, true, false)
	sandPatch.Size = Vector3.new(70, sandThickness, 70)
	sandPatch.CFrame = CFrame.new(Vector3.new(playgroundCenter.X, groundY + (sandThickness / 2), playgroundCenter.Z))
	sandPatch.Material = Enum.Material.Sand
	sandPatch.BrickColor = BrickColor.new("Sand yellow")

	-- Swing setup
	local swingArea = findOrCreatePart(playground, "SwingArea", "Part")
	applyPhysics(swingArea, true, true, false)
	swingArea.Size = Vector3.new(20, 1, 20)
	swingArea.CFrame = CFrame.new(Vector3.new(playgroundCenter.X, GROUND_Y + 0.5, playgroundCenter.Z))
	swingArea.Material = Enum.Material.SmoothPlastic
	swingArea.BrickColor = BrickColor.new("Sand yellow")
	applyTag(swingArea, "QuestTarget")

	local swingSet = findOrCreateModel(playground, "SwingSet")
	local swingSeat = swingSet:FindFirstChild("SwingSeat")
	if not swingSeat then
		local existingSeat = playground:FindFirstChild("SwingSeat")
		if existingSeat and existingSeat:IsA("Seat") then
			existingSeat.Parent = swingSet
			swingSeat = existingSeat
		end
	end
	if not swingSeat then
		swingSeat = findOrCreatePart(swingSet, "SwingSeat", "Seat")
	end
	applyPhysics(swingSeat, false, true, false)
	swingSeat.Size = Vector3.new(2, 1, 2)
	swingSeat.BrickColor = BrickColor.new("Bright blue")
	applyTag(swingSeat, "QuestMount")

	local pushButton = findOrCreatePart(playground, "PushButton", "Part")
	applyPhysics(pushButton, true, true, false)
	pushButton.Size = Vector3.new(2, 1, 2)
	pushButton.CFrame = CFrame.new(Vector3.new(swingArea.Position.X + 6, GROUND_Y + 0.5, swingArea.Position.Z))
	pushButton.Material = Enum.Material.SmoothPlastic
	pushButton.BrickColor = BrickColor.new("Bright green")
	applyTag(pushButton, "QuestButton")

	local prompt = pushButton:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = pushButton
	end
	prompt.ActionText = "Push"
	prompt.ObjectText = "Swing"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0

	-- Merry-go-round setup
	local merryModel = findOrCreateModel(playground, "MerryGoRound")
	local baseCenter = Vector3.new(playgroundCenter.X + 30, GROUND_Y + 0.5, playgroundCenter.Z)

	local basePieces = findOrCreateModel(merryModel, "BasePieces")
	local baseRadius = 6.5
	for i = 1, 8 do
		local piece = findOrCreatePart(basePieces, "BasePiece" .. i, "Part")
		applyPhysics(piece, true, true, false)
		piece.Size = Vector3.new(4, 1, 6)
		local angle = math.rad((i - 1) * 45)
		piece.CFrame = CFrame.new(baseCenter)
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(baseRadius, 0, 0)
			* CFrame.Angles(0, math.rad(90), 0)
		piece.Material = Enum.Material.SmoothPlastic
		piece.BrickColor = BrickColor.new("Bright red")
	end

	local merryBase = findOrCreatePart(merryModel, "MerryGoRoundBase", "Part")
	applyPhysics(merryBase, true, false, false)
	merryBase.Size = Vector3.new(18, 1, 18)
	merryBase.CFrame = CFrame.new(baseCenter)
	merryBase.Transparency = 1
	merryBase.Material = Enum.Material.SmoothPlastic
	merryBase.BrickColor = BrickColor.new("Bright red")
	applyTag(merryBase, "QuestTarget")

	local merrySeat = findOrCreatePart(merryModel, "MerryGoRoundSeat", "Seat")
	applyPhysics(merrySeat, false, true, false)
	merrySeat.Size = Vector3.new(2, 1, 2)
	merrySeat.CFrame = CFrame.new(baseCenter + Vector3.new(0, 1.5, 0))
	merrySeat.BrickColor = BrickColor.new("Bright yellow")
	applyTag(merrySeat, "QuestMount")

	local weld = merrySeat:FindFirstChildOfClass("WeldConstraint")
	if not weld then
		weld = Instance.new("WeldConstraint")
		weld.Name = "SeatWeld"
		weld.Part0 = merryBase
		weld.Part1 = merrySeat
		weld.Parent = merrySeat
	end

	-- Swing frame (anchored) + constraints (moving seat)
	local swingFrame = swingSet
	local leftPost = findOrCreatePart(swingFrame, "SwingPostLeft", "Part")
	local rightPost = findOrCreatePart(swingFrame, "SwingPostRight", "Part")
	local topBar = findOrCreatePart(swingFrame, "SwingTopBar", "Part")

	applyPhysics(leftPost, true, true, false)
	applyPhysics(rightPost, true, true, false)
	applyPhysics(topBar, true, true, false)

	local beamHeight = 10
	local beamLength = 12
	local swingSetCenter = Vector3.new(swingArea.Position.X, GROUND_Y, swingArea.Position.Z - 4)
	local ropeLength = 6

	leftPost.Size = Vector3.new(1, beamHeight, 1)
	rightPost.Size = Vector3.new(1, beamHeight, 1)
	topBar.Size = Vector3.new(beamLength, 1, 1)

	leftPost.CFrame = CFrame.new(Vector3.new(
		swingSetCenter.X - (beamLength / 2) + 1,
		GROUND_Y + (beamHeight / 2),
		swingSetCenter.Z
	))
	rightPost.CFrame = CFrame.new(Vector3.new(
		swingSetCenter.X + (beamLength / 2) - 1,
		GROUND_Y + (beamHeight / 2),
		swingSetCenter.Z
	))
	topBar.CFrame = CFrame.new(Vector3.new(swingSetCenter.X, GROUND_Y + 10, swingSetCenter.Z))

	leftPost.Material = Enum.Material.Metal
	rightPost.Material = Enum.Material.Metal
	topBar.Material = Enum.Material.Metal

	leftPost.BrickColor = BrickColor.new("Dark stone grey")
	rightPost.BrickColor = BrickColor.new("Dark stone grey")
	topBar.BrickColor = BrickColor.new("Dark stone grey")

	swingSeat.CFrame = CFrame.new(Vector3.new(topBar.Position.X, GROUND_Y + 2.5, topBar.Position.Z))

	local ropeTopLeft = findOrCreateAttachment(topBar, "RopeTopLeft", Vector3.new(-1.5, -1.5, 0))
	local ropeTopRight = findOrCreateAttachment(topBar, "RopeTopRight", Vector3.new(1.5, -1.5, 0))
	local ropeSeatLeft = findOrCreateAttachment(swingSeat, "RopeSeatLeft", Vector3.new(-0.5, 0.5, 0))
	local ropeSeatRight = findOrCreateAttachment(swingSeat, "RopeSeatRight", Vector3.new(0.5, 0.5, 0))

	local ropeLeft = topBar:FindFirstChild("RopeLeft")
	if not ropeLeft or not ropeLeft:IsA("RopeConstraint") then
		if ropeLeft then
			ropeLeft.Name = "RopeLeft_Unexpected"
		end
		ropeLeft = Instance.new("RopeConstraint")
		ropeLeft.Name = "RopeLeft"
		ropeLeft.Parent = topBar
	end
	ropeLeft.Attachment0 = ropeTopLeft
	ropeLeft.Attachment1 = ropeSeatLeft
	ropeLeft.Length = ropeLength
	ropeLeft.Visible = true
	ropeLeft.Thickness = 0.05

	local ropeRight = topBar:FindFirstChild("RopeRight")
	if not ropeRight or not ropeRight:IsA("RopeConstraint") then
		if ropeRight then
			ropeRight.Name = "RopeRight_Unexpected"
		end
		ropeRight = Instance.new("RopeConstraint")
		ropeRight.Name = "RopeRight"
		ropeRight.Parent = topBar
	end
	ropeRight.Attachment0 = ropeTopRight
	ropeRight.Attachment1 = ropeSeatRight
	ropeRight.Length = ropeLength
	ropeRight.Visible = true
	ropeRight.Thickness = 0.05

	local hingeTop = findOrCreateAttachment(topBar, "HingeTop", Vector3.new(0, -1.5, 0), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0))
	local hingeSeat = findOrCreateAttachment(swingSeat, "HingeSeat", Vector3.new(0, 0.5, 0), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0))

	local hinge = topBar:FindFirstChild("SwingHinge")
	if not hinge or not hinge:IsA("HingeConstraint") then
		if hinge then
			hinge.Name = "SwingHinge_Unexpected"
		end
		hinge = Instance.new("HingeConstraint")
		hinge.Name = "SwingHinge"
		hinge.Parent = topBar
	end
	hinge.Attachment0 = hingeTop
	hinge.Attachment1 = hingeSeat

	-- Tall slide setup
	local slideModel = findOrCreateModel(playground, "Slide")
	local SLIDE_X = playgroundCenter.X - 30
	local SLIDE_Z = playgroundCenter.Z - 10
	local PLATFORM_Y = GROUND_Y + 10

	local platform = findOrCreatePart(slideModel, "SlidePlatform", "Part")
	local ramp = findOrCreatePart(slideModel, "SlideRamp", "Part")
	local support = findOrCreatePart(slideModel, "SlideSupport", "Part")

	applyPhysics(platform, true, true, false)
	applyPhysics(ramp, true, true, false)
	applyPhysics(support, true, true, false)

	platform.Size = Vector3.new(8, 1, 8)
	platform.Position = Vector3.new(SLIDE_X, PLATFORM_Y, SLIDE_Z)
	platform.Material = Enum.Material.SmoothPlastic
	platform.BrickColor = BrickColor.new("Bright blue")

	local RAMP_LENGTH = 18
	local RAMP_THICK = 1
	local heightDelta = (PLATFORM_Y + (platform.Size.Y / 2)) - (GROUND_Y + (RAMP_THICK / 2))
	local rampAngle = math.asin(math.clamp(heightDelta / RAMP_LENGTH, -1, 1))
	local highEdgeX = SLIDE_X + (platform.Size.X / 2)
	local lowEdgeX = highEdgeX + RAMP_LENGTH
	local rampCenterX = (highEdgeX + lowEdgeX) / 2
	local rampCenterY = (PLATFORM_Y + (platform.Size.Y / 2) + GROUND_Y + (RAMP_THICK / 2)) / 2

	ramp.Size = Vector3.new(RAMP_LENGTH, RAMP_THICK, 8)
	-- Ramp high end is at platform, low end is at ground.
	ramp.Position = Vector3.new(rampCenterX, rampCenterY, SLIDE_Z)
	ramp.Orientation = Vector3.new(0, 0, -math.deg(rampAngle))
	ramp.Material = Enum.Material.SmoothPlastic
	ramp.CanCollide = true
	ramp.BrickColor = BrickColor.new("Bright blue")

	local supportHeight = (PLATFORM_Y - (platform.Size.Y / 2)) - GROUND_Y
	support.Size = Vector3.new(2, supportHeight, 2)
	support.CFrame = CFrame.new(Vector3.new(SLIDE_X, GROUND_Y + (supportHeight / 2), SLIDE_Z - 2))
	support.Material = Enum.Material.Metal
	support.BrickColor = BrickColor.new("Dark stone grey")

	-- Path from spawn to playground
	local pathModel = findOrCreateModel(playground, "Path")
	local pathSegments = 6
	local PATH_W = 10
	local PATH_H = 1
	local PATH_L = 8
	local PATH_GAP = 0.5
	local stepDistance = PATH_L + PATH_GAP
	local startPos = Vector3.new(homeSpawn.Position.X, GROUND_Y + 0.5, homeSpawn.Position.Z)
	local endPos = Vector3.new(playgroundCenter.X, GROUND_Y + 0.5, playgroundCenter.Z)
	local pathAxis = (endPos - startPos).Unit

	local lastPos = nil
	local secondLastPos = nil
	for i = 1, pathSegments do
		local segmentName = "PathSegment" .. i
		local segment = findOrCreatePart(pathModel, segmentName, "Part")
		applyPhysics(segment, true, true, false)
		segment.Size = Vector3.new(PATH_W, PATH_H, PATH_L)
		segment.Material = Enum.Material.Concrete
		segment.BrickColor = BrickColor.new("Medium stone grey")
		local centerPos = startPos + (pathAxis * (stepDistance * i))
		segment.CFrame = CFrame.new(centerPos)
		secondLastPos = lastPos
		lastPos = centerPos
	end
	if secondLastPos and lastPos then
		print("[Path] Last two segment centers:", secondLastPos, lastPos)
	end

	print("Playground rebuilt")
end

ensurePlayground()

local SAVE_SERVICE_WAIT = 0.1
local COIN_RESPAWN_TIME = 5
local PASSIVE_INCOME_INTERVAL = 5

local DEFAULT_INCOME = 1
local UPGRADE_BASE_COST = 10
local UPGRADE_COST_STEP = 10
local UPGRADE_INCOME_BONUS = 1

local houseModel = workspace:WaitForChild("HouseModel")
local coinFolder = workspace:WaitForChild("CoinSpawners")
local upgradePad = workspace:WaitForChild("UpgradePad")

local houseBase = houseModel:WaitForChild("Base")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local statsEvent = remotesFolder:FindFirstChild("PlayerStatsUpdated")
if not statsEvent then
	statsEvent = Instance.new("RemoteEvent")
	statsEvent.Name = "PlayerStatsUpdated"
	statsEvent.Parent = remotesFolder
end

local function getSaveService()
	while not _G.SaveService or not _G.SaveService.IsReady do
		task.wait(SAVE_SERVICE_WAIT)
	end
	return _G.SaveService
end

local SaveService = getSaveService()

local playerData = {} -- [player] = {Coins, IncomeRate, UpgradeLevel, NextUpgradeCost}
local upgradeDebounce = {} -- [userId] = last touch time

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

local function sendStats(player)
	local data = playerData[player]
	if not data then
		return
	end

	statsEvent:FireClient(player, data.Coins, data.IncomeRate, data.UpgradeLevel, data.NextUpgradeCost)
end

local function updateSaveCache(player)
	local data = playerData[player]
	if not data then
		return
	end

	SaveService:UpdateCache(player, {
		Coins = data.Coins,
		UpgradeLevel = data.UpgradeLevel,
		IncomeRate = data.IncomeRate,
	})
end

local function updateLeaderstatsCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local coinsValue = stats:FindFirstChild("Coins")
	if coinsValue then
		coinsValue.Value = playerData[player].Coins
	end
end

local function addCoins(player, amount)
	local data = playerData[player]
	if not data then
		return
	end

	data.Coins = math.max(0, data.Coins + amount)
	updateLeaderstatsCoins(player)
	updateSaveCache(player)
	sendStats(player)
end

local function createLeaderstats(player, coins)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = coins
	coinsValue.Parent = leaderstats
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
	local data = playerData[player]
	if not data then
		return
	end

	local cost = data.NextUpgradeCost
	if data.Coins < cost then
		return
	end

	data.Coins -= cost
	data.UpgradeLevel += 1
	data.IncomeRate += UPGRADE_INCOME_BONUS
	data.NextUpgradeCost = getNextUpgradeCost(data.UpgradeLevel)

	applyHouseLevel(data.UpgradeLevel)
	updateLeaderstatsCoins(player)
	updateSaveCache(player)
	sendStats(player)
end

upgradePad.Touched:Connect(function(hit)
	local player = getPlayerFromHit(hit)
	if not player or not player.Character then
		return
	end
	if not player.Character:FindFirstChild("Humanoid") then
		return
	end

	local userId = player.UserId
	local now = os.clock()
	local lastTouch = upgradeDebounce[userId]
	if lastTouch and (now - lastTouch) < 1 then
		return
	end
	upgradeDebounce[userId] = now

	tryUpgrade(player)
end)

Players.PlayerAdded:Connect(function(player)
	local saved = SaveService:Load(player)

	local coins = saved.Coins or 0
	local income = saved.IncomeRate or DEFAULT_INCOME
	local level = saved.UpgradeLevel or 0
	local nextCost = getNextUpgradeCost(level)

	playerData[player] = {
		Coins = coins,
		IncomeRate = income,
		UpgradeLevel = level,
		NextUpgradeCost = nextCost,
	}

	createLeaderstats(player, coins)
	applyHouseLevel(level)
	updateSaveCache(player)
	sendStats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
	upgradeDebounce[player.UserId] = nil
end)

setupAllCoins()

-- Passive income loop

task.spawn(function()
	while true do
		task.wait(PASSIVE_INCOME_INTERVAL)
		for player, data in pairs(playerData) do
			if player and player.Parent then
				addCoins(player, data.IncomeRate)
			end
		end
	end
end)
