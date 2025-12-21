local BuilderUtil = require(script.Parent.BuilderUtil)

local PlaygroundBuilder = {}

function PlaygroundBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local sandSizeX = 260
  local sandSizeZ = 260

  local sandPatch = BuilderUtil.findOrCreatePart(playground, constants.NAMES.PlaygroundSand, "Part")
  BuilderUtil.applyPhysics(sandPatch, true, true, false)
  sandPatch.Size = Vector3.new(sandSizeX, context.sandThickness, sandSizeZ)
  sandPatch.CFrame = CFrame.new(
    Vector3.new(
      context.playgroundCenter.X,
      context.groundY + (context.sandThickness / 2),
      context.playgroundCenter.Z
    )
  )
  sandPatch.Material = Enum.Material.Sand
  sandPatch.BrickColor = BrickColor.new("Sand yellow")

  local fenceModel = BuilderUtil.findOrCreateModel(workspace, "Fence")
  local fenceHeight = 12
  local fenceThickness = 1.5
  local fenceY = context.groundY + context.sandThickness + (fenceHeight / 2)
  local halfX = sandSizeX / 2
  local halfZ = sandSizeZ / 2
  local openingWidth = 16

  local delta = context.homeSpawn.Position - sandPatch.Position
  local gateSide = "West"
  if math.abs(delta.X) > math.abs(delta.Z) then
    gateSide = delta.X > 0 and "East" or "West"
  else
    gateSide = delta.Z > 0 and "North" or "South"
  end

  local function styleFence(part)
    BuilderUtil.applyPhysics(part, true, true, false)
    part.Material = Enum.Material.Wood
    part.BrickColor = BrickColor.new("Reddish brown")
  end

  local function buildHorizontal(nameA, nameB, zPos, hasGate)
    local totalLength = sandSizeX + fenceThickness
    local gap = hasGate and math.clamp(openingWidth, 8, sandSizeX - 8) or 0
    local segmentLength = (totalLength - gap) / 2
    local offset = (gap / 2) + (segmentLength / 2)

    local left = BuilderUtil.findOrCreatePart(fenceModel, nameA, "Part")
    local right = BuilderUtil.findOrCreatePart(fenceModel, nameB, "Part")
    styleFence(left)
    styleFence(right)
    left.Size = Vector3.new(segmentLength, fenceHeight, fenceThickness)
    right.Size = Vector3.new(segmentLength, fenceHeight, fenceThickness)
    left.Position = Vector3.new(sandPatch.Position.X - offset, fenceY, zPos)
    right.Position = Vector3.new(sandPatch.Position.X + offset, fenceY, zPos)
  end

  local function buildVertical(nameA, nameB, xPos, hasGate)
    local totalLength = sandSizeZ + fenceThickness
    local gap = hasGate and math.clamp(openingWidth, 8, sandSizeZ - 8) or 0
    local segmentLength = (totalLength - gap) / 2
    local offset = (gap / 2) + (segmentLength / 2)

    local top = BuilderUtil.findOrCreatePart(fenceModel, nameA, "Part")
    local bottom = BuilderUtil.findOrCreatePart(fenceModel, nameB, "Part")
    styleFence(top)
    styleFence(bottom)
    top.Size = Vector3.new(fenceThickness, fenceHeight, segmentLength)
    bottom.Size = Vector3.new(fenceThickness, fenceHeight, segmentLength)
    top.Position = Vector3.new(xPos, fenceY, sandPatch.Position.Z + offset)
    bottom.Position = Vector3.new(xPos, fenceY, sandPatch.Position.Z - offset)
  end

  local northZ = sandPatch.Position.Z + halfZ + (fenceThickness / 2)
  local southZ = sandPatch.Position.Z - halfZ - (fenceThickness / 2)
  local eastX = sandPatch.Position.X + halfX + (fenceThickness / 2)
  local westX = sandPatch.Position.X - halfX - (fenceThickness / 2)

  buildHorizontal("FenceNorthA", "FenceNorthB", northZ, gateSide == "North")
  buildHorizontal("FenceSouthA", "FenceSouthB", southZ, gateSide == "South")
  buildVertical("FenceEastA", "FenceEastB", eastX, gateSide == "East")
  buildVertical("FenceWestA", "FenceWestB", westX, gateSide == "West")

  local spawnOffset = 6
  local spawnY = context.groundY + 3
  local spawnPos = context.homeSpawn.Position
  if gateSide == "North" then
    spawnPos = Vector3.new(sandPatch.Position.X, spawnY, northZ + spawnOffset)
  elseif gateSide == "South" then
    spawnPos = Vector3.new(sandPatch.Position.X, spawnY, southZ - spawnOffset)
  elseif gateSide == "East" then
    spawnPos = Vector3.new(eastX + spawnOffset, spawnY, sandPatch.Position.Z)
  else
    spawnPos = Vector3.new(westX - spawnOffset, spawnY, sandPatch.Position.Z)
  end
  context.homeSpawn.Position = spawnPos
end

return PlaygroundBuilder
