local BuilderUtil = require(script.Parent.BuilderUtil)
local LayoutUtil = require(script.Parent.LayoutUtil)

local PlaygroundBuilder = {}

function PlaygroundBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local layout = context.layout
  local playgroundZone = layout and layout.zones and layout.zones.playground or nil
  local sandSizeX = playgroundZone and playgroundZone.width or 156
  local sandSizeZ = playgroundZone and playgroundZone.length or 156
  local fenceHeight = 6
  local openingWidth = 16

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
  local fenceThickness = 1.5
  local fenceY = context.groundY + context.sandThickness + (fenceHeight / 2)
  local halfX = sandSizeX / 2
  local halfZ = sandSizeZ / 2

  local spawnCenter = context.layout and context.layout.spawnCenter or context.homeSpawn.Position
  local delta = spawnCenter - sandPatch.Position
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

  local spawnAreaCenter = spawnCenter

  local spawnArea = BuilderUtil.findOrCreateModel(workspace, constants.NAMES.SpawnArea)
  local spawnPlatform =
    BuilderUtil.findOrCreatePart(spawnArea, constants.NAMES.SpawnPlatform, "Part")
  local spawnZone = layout and layout.zones and layout.zones.spawn or nil
  local spawnPlatformSize = Vector3.new(48, 1, 32)
  if spawnZone then
    spawnPlatformSize = Vector3.new(spawnZone.width, 1, spawnZone.length)
  end
  BuilderUtil.applyPhysics(spawnPlatform, true, true, false)
  spawnPlatform.Size = spawnPlatformSize
  spawnPlatform.Position = Vector3.new(
    spawnAreaCenter.X,
    context.groundY + context.sandThickness + (spawnPlatformSize.Y / 2),
    spawnAreaCenter.Z
  )
  spawnPlatform.Material = Enum.Material.SmoothPlastic
  spawnPlatform.BrickColor = BrickColor.new("Light stone grey")

  local spawnPadSize = Vector3.new(6, 1, 6)
  local padLift = 0.05
  local spawnPadY = LayoutUtil.getStackedCenterY(spawnPlatform, spawnPadSize.Y, padLift)
    or spawnPlatform.Position.Y + (spawnPlatformSize.Y / 2) + (spawnPadSize.Y / 2) + padLift
  local gridX = 3
  local gridZ = 2
  local spacing = 8
  local startX = -(spacing * (gridX - 1) / 2)
  local startZ = -(spacing * (gridZ - 1) / 2)
  local maxPads = gridX * gridZ
  local spawnIndex = 1
  for x = 0, gridX - 1 do
    for z = 0, gridZ - 1 do
      local spawn = nil
      if spawnIndex == 1 then
        spawn = context.homeSpawn
      else
        spawn = BuilderUtil.findOrCreatePart(
          spawnArea,
          constants.NAMES.SpawnPad .. spawnIndex,
          "SpawnLocation"
        )
      end
      BuilderUtil.applyPhysics(spawn, true, true, false)
      spawn.Size = spawnPadSize
      spawn.Position = Vector3.new(
        spawnAreaCenter.X + startX + (x * spacing),
        spawnPadY,
        spawnAreaCenter.Z + startZ + (z * spacing)
      )
      spawn.Material = Enum.Material.SmoothPlastic
      spawn.BrickColor = BrickColor.new("Light blue")
      spawnIndex += 1
    end
  end

  for _, child in ipairs(spawnArea:GetChildren()) do
    if child:IsA("SpawnLocation") then
      local index = tonumber(child.Name:match("^" .. constants.NAMES.SpawnPad .. "(%d+)$"))
      if index == 1 or (index and index > maxPads) then
        child:Destroy()
      end
    end
  end
end

return PlaygroundBuilder
