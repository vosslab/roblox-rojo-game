local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(shared:WaitForChild("Constants"))

local WorldBuilder = {}

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
    warn("[WorldBuilder] '" .. name .. "' exists but is not a Model. Renaming it.")
    model.Name = name .. "_Unexpected"
    model = nil
  end

  if not model then
    model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
  end

  return model
end

local function findOrCreatePart(parent, name, className)
  local part = parent:FindFirstChild(name)
  if part and not part:IsA(className) then
    warn("[WorldBuilder] '" .. name .. "' exists but is not a " .. className .. ". Renaming it.")
    part.Name = name .. "_Unexpected"
    part = nil
  end

  if not part then
    part = Instance.new(className)
    part.Name = name
    part.Parent = parent
  end

  return part
end

local function findOrCreateAttachment(parent, name, position, axis, secondaryAxis)
  local attachment = parent:FindFirstChild(name)
  if attachment and not attachment:IsA("Attachment") then
    warn("[WorldBuilder] '" .. name .. "' exists but is not an Attachment. Renaming it.")
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

function WorldBuilder.ensureBaseplateAndSpawn()
  local baseplate = workspace:FindFirstChild(Constants.NAMES.Baseplate)
  if baseplate and not baseplate:IsA("BasePart") then
    warn("[WorldBuilder] Baseplate exists but is not a Part. Renaming it.")
    baseplate.Name = Constants.NAMES.Baseplate .. "_Unexpected"
    baseplate = nil
  end

  if not baseplate then
    baseplate = Instance.new("Part")
    baseplate.Name = Constants.NAMES.Baseplate
    baseplate.Parent = workspace
  end

  baseplate.Anchored = true
  baseplate.Size = Vector3.new(512, 10, 512)
  baseplate.Position = Vector3.new(0, -5, 0)
  baseplate.Material = Enum.Material.Grass
  baseplate.BrickColor = BrickColor.new("Medium green")

  local spawn = workspace:FindFirstChild(Constants.NAMES.HomeSpawn)
  if spawn and not spawn:IsA("SpawnLocation") then
    warn("[WorldBuilder] HomeSpawn exists but is not a SpawnLocation. Renaming it.")
    spawn.Name = Constants.NAMES.HomeSpawn .. "_Unexpected"
    spawn = nil
  end

  if not spawn then
    spawn = Instance.new("SpawnLocation")
    spawn.Name = Constants.NAMES.HomeSpawn
    spawn.Parent = workspace
  end

  spawn.Anchored = true
  local topY = baseplate.Position.Y + (baseplate.Size.Y / 2)
  spawn.Position = Vector3.new(0, topY + 3, 0)

  return baseplate, spawn
end

function WorldBuilder.ensureRemotes()
  local remotesFolder = ReplicatedStorage:FindFirstChild(Constants.NAMES.Remotes)
  if remotesFolder and not remotesFolder:IsA("Folder") then
    warn("[WorldBuilder] Remotes exists but is not a Folder. Renaming it.")
    remotesFolder.Name = Constants.NAMES.Remotes .. "_Unexpected"
    remotesFolder = nil
  end

  if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = Constants.NAMES.Remotes
    remotesFolder.Parent = ReplicatedStorage
  end

  local remotes = {}
  for _, remoteName in pairs(Constants.REMOTES) do
    local remote = remotesFolder:FindFirstChild(remoteName)
    if remote and not remote:IsA("RemoteEvent") then
      warn("[WorldBuilder] Remote '" .. remoteName .. "' exists but is not a RemoteEvent. Renaming it.")
      remote.Name = remoteName .. "_Unexpected"
      remote = nil
    end

    if not remote then
      remote = Instance.new("RemoteEvent")
      remote.Name = remoteName
      remote.Parent = remotesFolder
    end

    remotes[remoteName] = remote
  end

  return remotes
end

function WorldBuilder.ensurePlayground(baseplate, homeSpawn)
  local playground = findOrCreateModel(workspace, Constants.NAMES.Playground)

  local groundY = baseplate.Position.Y + (baseplate.Size.Y / 2)
  local playgroundCenter = Vector3.new(homeSpawn.Position.X + 80, groundY, homeSpawn.Position.Z)
  local sandThickness = 1
  local sandTopY = groundY + sandThickness
  local surfaceY = sandTopY
  local GROUND_Y = surfaceY

  -- Sand patch around the playground
  local sandPatch = findOrCreatePart(playground, Constants.NAMES.PlaygroundSand, "Part")
  applyPhysics(sandPatch, true, true, false)
  sandPatch.Size = Vector3.new(70, sandThickness, 70)
  sandPatch.CFrame = CFrame.new(Vector3.new(playgroundCenter.X, groundY + (sandThickness / 2), playgroundCenter.Z))
  sandPatch.Material = Enum.Material.Sand
  sandPatch.BrickColor = BrickColor.new("Sand yellow")

  -- Swing setup
  local swingArea = findOrCreatePart(playground, Constants.NAMES.SwingArea, "Part")
  applyPhysics(swingArea, true, true, false)
  swingArea.Size = Vector3.new(20, 1, 20)
  swingArea.CFrame = CFrame.new(Vector3.new(playgroundCenter.X, GROUND_Y + 0.5, playgroundCenter.Z))
  swingArea.Material = Enum.Material.SmoothPlastic
  swingArea.BrickColor = BrickColor.new("Sand yellow")
  applyTag(swingArea, Constants.TAGS.QuestTarget)

  local swingSet = findOrCreateModel(playground, Constants.NAMES.SwingSet)
  local swingSeat = swingSet:FindFirstChild(Constants.NAMES.SwingSeat)
  if not swingSeat then
    local existingSeat = playground:FindFirstChild(Constants.NAMES.SwingSeat)
    if existingSeat and existingSeat:IsA("Seat") then
      existingSeat.Parent = swingSet
      swingSeat = existingSeat
    end
  end
  if not swingSeat then
    swingSeat = findOrCreatePart(swingSet, Constants.NAMES.SwingSeat, "Seat")
  end
  applyPhysics(swingSeat, false, true, false)
  swingSeat.Size = Vector3.new(2, 1, 2)
  swingSeat.BrickColor = BrickColor.new("Bright blue")
  applyTag(swingSeat, Constants.TAGS.QuestMount)

  local pushButton = findOrCreatePart(playground, Constants.NAMES.PushButton, "Part")
  applyPhysics(pushButton, true, true, false)
  pushButton.Size = Vector3.new(2, 1, 2)
  pushButton.CFrame = CFrame.new(Vector3.new(swingArea.Position.X + 6, GROUND_Y + 0.5, swingArea.Position.Z))
  pushButton.Material = Enum.Material.SmoothPlastic
  pushButton.BrickColor = BrickColor.new("Bright green")
  applyTag(pushButton, Constants.TAGS.QuestButton)

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
  local merryModel = findOrCreateModel(playground, Constants.NAMES.MerryGoRound)
  local baseCenter = Vector3.new(playgroundCenter.X + 30, GROUND_Y + 0.5, playgroundCenter.Z)

  local basePieces = findOrCreateModel(merryModel, Constants.NAMES.MerryGoRoundBasePieces)
  for _, child in ipairs(basePieces:GetChildren()) do
    child:Destroy()
  end

  local baseRadius = 6
  for i = 1, 8 do
    local wedge = Instance.new("WedgePart")
    wedge.Name = "BaseWedge" .. i
    wedge.Parent = basePieces
    applyPhysics(wedge, true, true, false)
    wedge.Size = Vector3.new(6, 1, 6)
    wedge.Material = Enum.Material.SmoothPlastic
    wedge.BrickColor = BrickColor.new("Bright red")

    local angle = math.rad((i - 1) * 45)
    local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local position = baseCenter + (outward * baseRadius)
    wedge.CFrame = CFrame.lookAt(position, position + outward) * CFrame.Angles(0, math.rad(90), 0)
  end

  local merryBase = findOrCreatePart(merryModel, Constants.NAMES.MerryGoRoundBase, "Part")
  applyPhysics(merryBase, true, false, false)
  merryBase.Size = Vector3.new(18, 1, 18)
  merryBase.CFrame = CFrame.new(baseCenter)
  merryBase.Transparency = 1
  merryBase.Material = Enum.Material.SmoothPlastic
  merryBase.BrickColor = BrickColor.new("Bright red")
  applyTag(merryBase, Constants.TAGS.QuestTarget)
  merryModel.PrimaryPart = merryBase

  local spinPrompt = merryBase:FindFirstChild("SpinPrompt")
  if spinPrompt and not spinPrompt:IsA("ProximityPrompt") then
    spinPrompt.Name = "SpinPrompt_Unexpected"
    spinPrompt = nil
  end
  if not spinPrompt then
    spinPrompt = Instance.new("ProximityPrompt")
    spinPrompt.Name = "SpinPrompt"
    spinPrompt.Parent = merryBase
  end
  spinPrompt.ActionText = "Push"
  spinPrompt.ObjectText = "Merry-go-round"
  spinPrompt.KeyboardKeyCode = Enum.KeyCode.E
  spinPrompt.HoldDuration = 0
  spinPrompt.MaxActivationDistance = 10

  local merrySeat = findOrCreatePart(merryModel, Constants.NAMES.MerryGoRoundSeat, "Seat")
  applyPhysics(merrySeat, false, true, false)
  merrySeat.Size = Vector3.new(2, 1, 2)
  merrySeat.CFrame = CFrame.new(baseCenter + Vector3.new(0, 1.5, 0))
  merrySeat.BrickColor = BrickColor.new("Bright yellow")
  applyTag(merrySeat, Constants.TAGS.QuestMount)

  local spinMarker = findOrCreatePart(merryModel, "SpinMarker", "Part")
  applyPhysics(spinMarker, true, false, false)
  spinMarker.Size = Vector3.new(1, 0.5, 1)
  spinMarker.Position = baseCenter + Vector3.new(8, 1.25, 0)
  spinMarker.BrickColor = BrickColor.new("Pastel blue")
  if RunService:IsStudio() then
    spinMarker.Transparency = 0.2
  else
    spinMarker.Transparency = 1
  end

  local weld = merrySeat:FindFirstChildOfClass("WeldConstraint")
  if not weld then
    weld = Instance.new("WeldConstraint")
    weld.Name = "SeatWeld"
    weld.Part0 = merryBase
    weld.Part1 = merrySeat
    weld.Parent = merrySeat
  end

  -- Swing frame (anchored) + constraints (moving seat)
  local leftPost = findOrCreatePart(swingSet, "SwingPostLeft", "Part")
  local rightPost = findOrCreatePart(swingSet, "SwingPostRight", "Part")
  local topBar = findOrCreatePart(swingSet, Constants.NAMES.SwingTopBar, "Part")

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
  local slideModel = findOrCreateModel(playground, Constants.NAMES.Slide)
  local SLIDE_X = playgroundCenter.X - 30
  local SLIDE_Z = playgroundCenter.Z - 10
  local PLATFORM_Y = GROUND_Y + 10

  local platform = findOrCreatePart(slideModel, Constants.NAMES.SlidePlatform, "Part")
  local ramp = findOrCreatePart(slideModel, Constants.NAMES.SlideRamp, "Part")
  local support = findOrCreatePart(slideModel, Constants.NAMES.SlideSupport, "Part")

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
  local pathModel = findOrCreateModel(playground, Constants.NAMES.Path)
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

return WorldBuilder
