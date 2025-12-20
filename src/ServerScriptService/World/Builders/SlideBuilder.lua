local BuilderUtil = require(script.Parent.BuilderUtil)

local SlideBuilder = {}

function SlideBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local GROUND_Y = context.surfaceY
  local slideModel = BuilderUtil.findOrCreateModel(playground, constants.NAMES.Slide)

  for _, child in ipairs(slideModel:GetDescendants()) do
    if child.Name:match("_Unexpected$") or child:IsA("TrussPart") then
      child:Destroy()
    end
  end

  local SLIDE_X = context.playgroundCenter.X - 30
  local SLIDE_Z = context.playgroundCenter.Z - 10
  local PLATFORM_Y = GROUND_Y + 10

  local platform = BuilderUtil.findOrCreatePart(slideModel, constants.NAMES.SlidePlatform, "Part")
  local ramp = BuilderUtil.findOrCreatePart(slideModel, constants.NAMES.SlideRamp, "Part")
  local support = BuilderUtil.findOrCreatePart(slideModel, constants.NAMES.SlideSupport, "Part")

  BuilderUtil.applyPhysics(platform, true, true, false)
  BuilderUtil.applyPhysics(ramp, true, true, false)
  BuilderUtil.applyPhysics(support, true, true, false)

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

  local ladderModel = BuilderUtil.findOrCreateModel(slideModel, "SlideLadder")
  local ladderHeight = PLATFORM_Y - GROUND_Y
  local ladderWidth = 4
  local railThickness = 0.4
  local rungThickness = 0.3
  local rungCount = 6
  local ladderX = SLIDE_X - (platform.Size.X / 2) - 2
  local ladderZ = SLIDE_Z

  local leftRail = BuilderUtil.findOrCreatePart(ladderModel, "LadderRailLeft", "Part")
  local rightRail = BuilderUtil.findOrCreatePart(ladderModel, "LadderRailRight", "Part")
  BuilderUtil.applyPhysics(leftRail, true, true, false)
  BuilderUtil.applyPhysics(rightRail, true, true, false)
  leftRail.Size = Vector3.new(railThickness, ladderHeight, railThickness)
  rightRail.Size = Vector3.new(railThickness, ladderHeight, railThickness)
  leftRail.Position =
    Vector3.new(ladderX, GROUND_Y + (ladderHeight / 2), ladderZ - (ladderWidth / 2))
  rightRail.Position =
    Vector3.new(ladderX, GROUND_Y + (ladderHeight / 2), ladderZ + (ladderWidth / 2))
  leftRail.Material = Enum.Material.Metal
  rightRail.Material = Enum.Material.Metal
  leftRail.BrickColor = BrickColor.new("Dark stone grey")
  rightRail.BrickColor = BrickColor.new("Dark stone grey")

  for i = 1, rungCount do
    local rung = BuilderUtil.findOrCreatePart(ladderModel, "LadderRung" .. i, "Part")
    BuilderUtil.applyPhysics(rung, true, true, false)
    rung.Size = Vector3.new(railThickness, rungThickness, ladderWidth + railThickness)
    local t = i / (rungCount + 1)
    rung.Position = Vector3.new(ladderX, GROUND_Y + (ladderHeight * t), ladderZ)
    rung.Material = Enum.Material.Metal
    rung.BrickColor = BrickColor.new("Dark stone grey")
  end
end

return SlideBuilder
