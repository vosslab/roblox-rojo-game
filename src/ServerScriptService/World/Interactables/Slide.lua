local RunService = game:GetService("RunService")

local Slide = {}

local constants = nil
local playground = nil
local slideRamp = nil
local slideModelCached = nil

local activeSliders = {}
local savedWalkSpeed = {}
local lastImpulseTime = {}
local touchingCounts = {}

local IMPULSE_INTERVAL = 0.1
local SPEED_BONUS = 6
local PUSH_FORCE = 55
local MAX_SPEED = 110

local DEBUG = false

local function dprint(...)
  if DEBUG then
    print("[Slide]", ...)
  end
end

local function getPlayground()
  if playground and playground.Parent then
    return playground
  end

  if constants then
    playground = workspace:FindFirstChild(constants.NAMES.Playground)
  end

  return playground
end

local function getSlideModel()
  if slideModelCached and slideModelCached.Parent then
    return slideModelCached
  end

  local pg = getPlayground()
  if not pg then
    slideModelCached = nil
    return nil
  end

  slideModelCached = pg:FindFirstChild("Slide", true)
  return slideModelCached
end

local function getRamp()
  if slideRamp and slideRamp.Parent then
    return slideRamp
  end

  local slideModel = getSlideModel()
  if not slideModel then
    slideRamp = nil
    return nil
  end

  local ramp = slideModel:FindFirstChild("SlideRamp", true)
  if ramp and ramp:IsA("BasePart") then
    slideRamp = ramp
    return slideRamp
  end

  slideRamp = nil
  return nil
end

local function getCharacterFromPart(part)
  if not part or not part.Parent then
    return nil
  end

  local character = part.Parent
  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if humanoid then
    return character, humanoid
  end

  if character.Parent then
    local parentHumanoid = character.Parent:FindFirstChildOfClass("Humanoid")
    if parentHumanoid then
      return character.Parent, parentHumanoid
    end
  end

  return nil
end

local function getRoot(character)
  if not character then
    return nil
  end
  return character:FindFirstChild("HumanoidRootPart")
end

local function beginSlide(character, humanoid)
  if activeSliders[character] then
    return
  end

  activeSliders[character] = true
  savedWalkSpeed[character] = humanoid.WalkSpeed
  humanoid.WalkSpeed = humanoid.WalkSpeed + SPEED_BONUS
  lastImpulseTime[character] = 0

  dprint("Slide active", character.Name)
end

local function endSlide(character)
  if not activeSliders[character] then
    return
  end

  activeSliders[character] = nil
  lastImpulseTime[character] = nil
  touchingCounts[character] = nil

  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local original = savedWalkSpeed[character]
  if humanoid and original then
    humanoid.WalkSpeed = original
  end
  savedWalkSpeed[character] = nil
end

local function computeDownhillDirection(ramp)
  local n = ramp.CFrame.UpVector.Unit
  local g = Vector3.new(0, -1, 0)

  local downhill = g - n * g:Dot(n)

  if downhill.Magnitude < 1e-4 then
    local v = ramp.CFrame.LookVector
    local flat = Vector3.new(v.X, 0, v.Z)
    if flat.Magnitude < 1e-4 then
      return Vector3.new(1, 0, 0)
    end
    return flat.Unit
  end

  return downhill.Unit
end

local function applyImpulse(character, ramp)
  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.SeatPart then
    return
  end

  local root = getRoot(character)
  if not root then
    return
  end

  local now = os.clock()
  local last = lastImpulseTime[character] or 0
  if (now - last) < IMPULSE_INTERVAL then
    return
  end
  lastImpulseTime[character] = now

  local dir = computeDownhillDirection(ramp)
  local push = dir * PUSH_FORCE

  local newVelocity = root.AssemblyLinearVelocity + push
  if newVelocity.Magnitude > MAX_SPEED then
    newVelocity = newVelocity.Unit * MAX_SPEED
  end

  root.AssemblyLinearVelocity = newVelocity
end

local function computeLadderOffset(platform, ramp)
  -- Ramp direction projected onto ground plane
  local rampDir = ramp.CFrame.LookVector
  rampDir = Vector3.new(rampDir.X, 0, rampDir.Z)
  if rampDir.Magnitude < 1e-4 then
    rampDir = Vector3.new(1, 0, 0)
  end
  rampDir = rampDir.Unit

  -- Two perpendicular side directions on ground plane
  local sideA = Vector3.new(-rampDir.Z, 0, rampDir.X)
  local sideB = -sideA

  -- Pick the side that moves away from the ramp centerline (toward the platform's side)
  local toPlatform = platform.Position - ramp.Position
  toPlatform = Vector3.new(toPlatform.X, 0, toPlatform.Z)

  local pick = (toPlatform:Dot(sideA) >= 0) and sideA or sideB

  -- Offset distance away from platform center
  local offsetDist = platform.Size.X * 0.7 + 3
  local offset = pick * offsetDist

  -- Safety flip if it still ends up too close to the ramp
  local candidate = Vector3.new(platform.Position.X, 0, platform.Position.Z) + offset
  local rampPos = Vector3.new(ramp.Position.X, 0, ramp.Position.Z)
  local tooClose = (candidate - rampPos).Magnitude < (platform.Size.X * 0.6)

  if tooClose then
    offset = -offset
  end

  return offset
end

local function ensureLadder()
  local slideModel = getSlideModel()
  if not slideModel then
    return
  end

  local ramp = getRamp()
  if not ramp then
    return
  end

  local platform = slideModel:FindFirstChild("SlidePlatform", true)
  if not platform or not platform:IsA("BasePart") then
    return
  end

  local existing = slideModel:FindFirstChild("SlideLadder", true)
  if existing and existing:IsA("TrussPart") then
    return
  end

  local topY = platform.Position.Y + (platform.Size.Y * 0.5)
  local bottomY = math.min(ramp.Position.Y - (ramp.Size.Y * 0.5), platform.Position.Y - 8)

  local height = math.max(12, topY - bottomY)
  local centerY = bottomY + height * 0.5

  local offset = computeLadderOffset(platform, ramp)

  local ladder = Instance.new("TrussPart")
  ladder.Name = "SlideLadder"
  ladder.Anchored = true
  ladder.CanCollide = true
  ladder.Size = Vector3.new(4, height, 2)
  ladder.CFrame =
    CFrame.new(Vector3.new(platform.Position.X, centerY, platform.Position.Z) + offset)
  ladder.Parent = slideModel

  local step = Instance.new("Part")
  step.Name = "LadderTopStep"
  step.Anchored = true
  step.CanCollide = true
  step.Size = Vector3.new(6, 1, 6)
  step.CFrame =
    CFrame.new(Vector3.new(platform.Position.X, topY + 0.5, platform.Position.Z) + offset)
  step.Parent = slideModel

  dprint("Ladder created")
end

function Slide.Init(playgroundModel, constantsModule)
  constants = constantsModule
  playground = playgroundModel
  slideRamp = nil
  slideModelCached = nil

  local ramp = getRamp()
  if not ramp then
    return
  end

  ensureLadder()

  ramp.Touched:Connect(function(part)
    local character, humanoid = getCharacterFromPart(part)
    if not character or not humanoid then
      return
    end
    touchingCounts[character] = (touchingCounts[character] or 0) + 1
    beginSlide(character, humanoid)
  end)

  if ramp.TouchEnded then
    ramp.TouchEnded:Connect(function(part)
      local character = select(1, getCharacterFromPart(part))
      if not character then
        return
      end

      local count = (touchingCounts[character] or 1) - 1
      if count <= 0 then
        touchingCounts[character] = nil
        endSlide(character)
      else
        touchingCounts[character] = count
      end
    end)
  end

  RunService.Heartbeat:Connect(function()
    local activeRamp = getRamp()
    if not activeRamp then
      return
    end

    for character in pairs(activeSliders) do
      if not character or not character.Parent then
        endSlide(character)
      else
        if activeRamp.TouchEnded == nil and not touchingCounts[character] then
          endSlide(character)
        else
          touchingCounts[character] = touchingCounts[character] or 1
        end
        applyImpulse(character, activeRamp)
      end
    end
  end)
end

return Slide
