local BuilderUtil = require(script.Parent.BuilderUtil)
local LayoutUtil = require(script.Parent.LayoutUtil)
local RoomBuilder = require(script.Parent.RoomBuilder)

local GasStationBuilder = {}

local function toWorldCFrame(baseCFrame, localPos, localYaw)
  local cframe = baseCFrame * CFrame.new(localPos)
  if localYaw then
    cframe = cframe * CFrame.Angles(0, localYaw, 0)
  end
  return cframe
end

local function stylePad(part, colorName)
  part.Material = Enum.Material.SmoothPlastic
  part.BrickColor = BrickColor.new(colorName)
end

local function buildColumn(model, name, baseCFrame, localPos, height)
  local column = BuilderUtil.findOrCreatePart(model, name, "Part")
  BuilderUtil.applyPhysics(column, true, true, false)
  column.Size = Vector3.new(1, height, 1)
  column.CFrame = toWorldCFrame(baseCFrame, localPos)
  column.Material = Enum.Material.SmoothPlastic
  column.BrickColor = BrickColor.new("Dark stone grey")
end

local function buildPump(model, name, baseCFrame, localPos, pumpHeight)
  local pump = BuilderUtil.findOrCreatePart(model, name, "Part")
  BuilderUtil.applyPhysics(pump, true, true, false)
  pump.Size = Vector3.new(3, pumpHeight, 1.5)
  pump.CFrame = toWorldCFrame(baseCFrame, localPos)
  pump.Material = Enum.Material.SmoothPlastic
  pump.BrickColor = BrickColor.new("Bright red")

  local topper = BuilderUtil.findOrCreatePart(model, name .. "Top", "Part")
  BuilderUtil.applyPhysics(topper, true, true, false)
  topper.Size = Vector3.new(3.2, 0.5, 1.7)
  topper.CFrame = toWorldCFrame(baseCFrame, localPos + Vector3.new(0, (pumpHeight / 2) + 0.3, 0))
  topper.Material = Enum.Material.SmoothPlastic
  topper.BrickColor = BrickColor.new("White")
end

local function buildCar(model, baseCFrame, localPos)
  local carModel = BuilderUtil.findOrCreateModel(model, "GasStationCar")
  local body = BuilderUtil.findOrCreatePart(carModel, "CarBody", "Part")
  BuilderUtil.applyPhysics(body, true, true, false)
  body.Size = Vector3.new(14, 3.5, 6)
  body.CFrame = toWorldCFrame(baseCFrame, localPos + Vector3.new(0, 1.75, 0))
  body.Material = Enum.Material.SmoothPlastic
  body.BrickColor = BrickColor.new("Really red")

  local roof = BuilderUtil.findOrCreatePart(carModel, "CarRoof", "Part")
  BuilderUtil.applyPhysics(roof, true, true, false)
  roof.Size = Vector3.new(8, 2, 5)
  roof.CFrame = toWorldCFrame(baseCFrame, localPos + Vector3.new(0, 4, 0))
  roof.Material = Enum.Material.SmoothPlastic
  roof.BrickColor = BrickColor.new("Really red")

  local wheelSize = Vector3.new(2.2, 2.2, 1.4)
  local wheelOffsets = {
    Vector3.new(4.5, 1.1, 3.1),
    Vector3.new(-4.5, 1.1, 3.1),
    Vector3.new(4.5, 1.1, -3.1),
    Vector3.new(-4.5, 1.1, -3.1),
  }
  for index, offset in ipairs(wheelOffsets) do
    local wheel = BuilderUtil.findOrCreatePart(carModel, "CarWheel" .. index, "Part")
    BuilderUtil.applyPhysics(wheel, true, true, false)
    wheel.Size = wheelSize
    wheel.CFrame = toWorldCFrame(baseCFrame, localPos + offset)
    wheel.Material = Enum.Material.SmoothPlastic
    wheel.BrickColor = BrickColor.new("Really black")
  end
end

local function placeAChassis(targetCFrame, desiredMinY)
  local vehicles = workspace:FindFirstChild("Vehicles")
  local chassisModel = vehicles and vehicles:FindFirstChild("A-Chassis")
  if not chassisModel then
    chassisModel = workspace:FindFirstChild("A-Chassis")
  end
  if chassisModel and chassisModel:IsA("Model") then
    local bboxCFrame, bboxSize = chassisModel:GetBoundingBox()
    local minY = bboxCFrame.Position.Y - (bboxSize.Y / 2)
    local desiredY = desiredMinY or targetCFrame.Position.Y
    local lift = desiredY - minY
    chassisModel:PivotTo(targetCFrame + Vector3.new(0, lift, 0))
  end
end

local function buildStore(model, baseCFrame, centerLocal, storeSize, baseHeight, constants)
  local wallThickness = 1
  local roofThickness = 1
  local wallColor = BrickColor.new("Linen")
  local roofColor = BrickColor.new("Reddish brown")
  local baseOffset = Vector3.new(0, baseHeight, 0)

  local store = BuilderUtil.findOrCreatePart(model, "StoreFloor", "Part")
  BuilderUtil.applyPhysics(store, true, true, false)
  store.Size = Vector3.new(storeSize.X, 1, storeSize.Z)
  store.CFrame = toWorldCFrame(baseCFrame, centerLocal + baseOffset + Vector3.new(0, 0.5, 0))
  store.Material = Enum.Material.SmoothPlastic
  store.BrickColor = BrickColor.new("Medium stone grey")

  local roof = BuilderUtil.findOrCreatePart(model, "StoreRoof", "Part")
  BuilderUtil.applyPhysics(roof, true, true, false)
  roof.Size = Vector3.new(storeSize.X, roofThickness, storeSize.Z)
  roof.CFrame = toWorldCFrame(
    baseCFrame,
    centerLocal + baseOffset + Vector3.new(0, storeSize.Y + (roofThickness / 2), 0)
  )
  roof.Material = Enum.Material.SmoothPlastic
  roof.BrickColor = roofColor

  local doorWidth = 5
  local doorHeight = 9
  local doorDepth = math.max(0.2, wallThickness * 0.4)
  local doorGap = 0
  local doorSpan = (doorWidth * 2) + doorGap
  for _, child in ipairs(model:GetChildren()) do
    if child:IsA("BasePart") and child.Name:match("^StoreWall") then
      child:Destroy()
    end
  end

  local function buildSlidingDoors(namePrefix, doorCFrame)
    local doorLeft = BuilderUtil.findOrCreatePart(model, namePrefix .. "Left", "Part")
    local doorRight = BuilderUtil.findOrCreatePart(model, namePrefix .. "Right", "Part")
    BuilderUtil.applyPhysics(doorLeft, true, true, false)
    BuilderUtil.applyPhysics(doorRight, true, true, false)
    doorLeft.Size = Vector3.new(doorWidth, doorHeight, doorDepth)
    doorRight.Size = Vector3.new(doorWidth, doorHeight, doorDepth)
    doorLeft.Material = Enum.Material.Glass
    doorRight.Material = Enum.Material.Glass
    doorLeft.Transparency = 0.4
    doorRight.Transparency = 0.4
    doorLeft.BrickColor = BrickColor.new("Light blue")
    doorRight.BrickColor = BrickColor.new("Light blue")
    doorLeft.CFrame = doorCFrame * CFrame.new(-(doorGap / 2) - (doorWidth / 2), 0, 0)
    doorRight.CFrame = doorCFrame * CFrame.new((doorGap / 2) + (doorWidth / 2), 0, 0)

    local slideDistance = doorWidth * 0.9
    doorLeft:SetAttribute("ClosedCFrame", doorLeft.CFrame)
    doorRight:SetAttribute("ClosedCFrame", doorRight.CFrame)
    doorLeft:SetAttribute("OpenCFrame", doorLeft.CFrame * CFrame.new(-slideDistance, 0, 0))
    doorRight:SetAttribute("OpenCFrame", doorRight.CFrame * CFrame.new(slideDistance, 0, 0))
    doorLeft:SetAttribute("IsOpen", false)
    doorRight:SetAttribute("IsOpen", false)
    BuilderUtil.applyTag(doorLeft, constants.TAGS.SchoolSlidingDoor)
    BuilderUtil.applyTag(doorRight, constants.TAGS.SchoolSlidingDoor)
  end

  local wallFrames = RoomBuilder.buildWalls({
    model = model,
    namePrefix = "StoreWall",
    baseCFrame = baseCFrame,
    center = Vector3.new(centerLocal.X, baseHeight + (storeSize.Y / 2), centerLocal.Z),
    size = storeSize,
    wallThickness = wallThickness,
    wallColor = wallColor,
    material = Enum.Material.SmoothPlastic,
    openings = {
      North = { width = doorSpan, height = doorHeight, bottom = 0 },
      South = { width = doorSpan, height = doorHeight, bottom = 0 },
      East = { width = doorSpan, height = doorHeight, bottom = 0 },
    },
  })

  local doorCFrameSouth = wallFrames
      and wallFrames.South
      and wallFrames.South[1]
      and wallFrames.South[1].cframe
    or toWorldCFrame(
      baseCFrame,
      Vector3.new(centerLocal.X, baseHeight + (doorHeight / 2), centerLocal.Z - (storeSize.Z / 2))
    )
  local doorCFrameNorth = wallFrames
      and wallFrames.North
      and wallFrames.North[1]
      and wallFrames.North[1].cframe
    or toWorldCFrame(
      baseCFrame,
      Vector3.new(centerLocal.X, baseHeight + (doorHeight / 2), centerLocal.Z + (storeSize.Z / 2))
    )
  local doorCFrameEast = wallFrames
      and wallFrames.East
      and wallFrames.East[1]
      and wallFrames.East[1].cframe
    or toWorldCFrame(
      baseCFrame,
      Vector3.new(centerLocal.X + (storeSize.X / 2), baseHeight + (doorHeight / 2), centerLocal.Z)
    )
  doorCFrameEast = doorCFrameEast * CFrame.Angles(0, math.rad(90), 0)

  buildSlidingDoors("StoreFrontDoor", doorCFrameSouth)
  buildSlidingDoors("StoreBackDoor", doorCFrameNorth)
  buildSlidingDoors("StoreEastDoor", doorCFrameEast)

  local shelfSize = Vector3.new(14, 6, 3)
  local shelfY = baseHeight + 3
  local shelfOffset = 7
  for i = 1, 3 do
    local shelf = BuilderUtil.findOrCreatePart(model, "StoreShelf" .. i, "Part")
    BuilderUtil.applyPhysics(shelf, true, false, true)
    shelf.Size = shelfSize
    shelf.CFrame = toWorldCFrame(
      baseCFrame,
      Vector3.new(centerLocal.X, shelfY, centerLocal.Z + ((i - 2) * shelfOffset))
    )
    shelf.Material = Enum.Material.SmoothPlastic
    shelf.BrickColor = BrickColor.new("Dark stone grey")
  end

  local coolerSize = Vector3.new(4.8, 8, 2.5)
  local coolerX = centerLocal.X - (storeSize.X / 2) + (coolerSize.X / 2) + wallThickness + 0.2
  local coolerY = baseHeight + (coolerSize.Y / 2)
  local coolerSpacing = coolerSize.Z
  local usableZ = storeSize.Z - 2
  local coolerCount = math.max(1, math.floor(usableZ / coolerSpacing))
  local totalCoolerSpan = coolerCount * coolerSpacing
  local startZ = centerLocal.Z - (totalCoolerSpan / 2) + (coolerSpacing / 2)

  for index = 1, coolerCount do
    local coolerZ = startZ + ((index - 1) * coolerSpacing)
    local cooler = BuilderUtil.findOrCreatePart(model, "SodaCooler" .. index, "Part")
    BuilderUtil.applyPhysics(cooler, true, true, false)
    cooler.Size = coolerSize
    cooler.CFrame = toWorldCFrame(baseCFrame, Vector3.new(coolerX, coolerY, coolerZ))
    cooler.Material = Enum.Material.SmoothPlastic
    cooler.BrickColor = BrickColor.new("Dark stone grey")

    local coolerDoor = BuilderUtil.findOrCreatePart(model, "SodaCoolerDoor" .. index, "Part")
    BuilderUtil.applyPhysics(coolerDoor, true, false, false)
    coolerDoor.Size = Vector3.new(0.15, coolerSize.Y - 0.5, coolerSize.Z - 0.4)
    coolerDoor.CFrame =
      toWorldCFrame(baseCFrame, Vector3.new(coolerX + (coolerSize.X / 2) + 0.25, coolerY, coolerZ))
    coolerDoor.Material = Enum.Material.Glass
    coolerDoor.Transparency = 0.4
    coolerDoor.BrickColor = BrickColor.new("Light blue")

    local hingeOffsetZ = coolerDoor.Size.Z / 2
    local openAngle = math.rad(-80)
    local openCFrame = coolerDoor.CFrame
      * CFrame.new(0, 0, -hingeOffsetZ)
      * CFrame.Angles(0, openAngle, 0)
      * CFrame.new(0, 0, hingeOffsetZ)
    coolerDoor:SetAttribute("ClosedCFrame", coolerDoor.CFrame)
    coolerDoor:SetAttribute("OpenCFrame", openCFrame)
    coolerDoor:SetAttribute("IsOpen", false)
    coolerDoor:SetAttribute("AutoDistance", 4)
    BuilderUtil.applyTag(coolerDoor, constants.TAGS.AutoSwingDoor)
  end

  local extraIndex = coolerCount + 1
  while true do
    local extra = model:FindFirstChild("SodaCooler" .. extraIndex)
    local extraDoor = model:FindFirstChild("SodaCoolerDoor" .. extraIndex)
    if not extra and not extraDoor then
      break
    end
    if extra and extra:IsA("BasePart") then
      extra:Destroy()
    end
    if extraDoor and extraDoor:IsA("BasePart") then
      extraDoor:Destroy()
    end
    extraIndex += 1
  end
end

function GasStationBuilder.Build(_playground, constants)
  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context or not context.layout then
    return
  end

  local gasCenter = context.layout.gasCenter
  local gasZone = context.layout.zones and context.layout.zones.gas or nil
  local padWidth = gasZone and gasZone.width or 60
  local padLength = gasZone and gasZone.length or 40
  local baseCFrame = CFrame.new(gasCenter) * CFrame.Angles(0, math.rad(180), 0)
  local padHalfX = padWidth / 2
  local padHalfZ = padLength / 2

  local model = BuilderUtil.findOrCreateModel(workspace, "GasStation")

  local base = BuilderUtil.findOrCreatePart(model, "GasPad", "Part")
  BuilderUtil.applyPhysics(base, true, true, false)
  base.Size = Vector3.new(padWidth, 1, padLength)
  base.CFrame = toWorldCFrame(baseCFrame, Vector3.new(0, base.Size.Y / 2, 0))
  stylePad(base, "Dark stone grey")

  local baseTopLocal = (LayoutUtil.getTopSurfaceY(base, 0) or (baseCFrame.Position.Y + base.Size.Y))
    - baseCFrame.Position.Y
  local asphaltOffset = LayoutUtil.getLayerOffset("asphalt")
  local roomOffset = LayoutUtil.getLayerOffset("room_floor")

  local forecourt = BuilderUtil.findOrCreatePart(model, "Forecourt", "Part")
  BuilderUtil.applyPhysics(forecourt, true, true, false)
  local storeMargin = 6
  local storeSize = Vector3.new(72, 10, 48)
  local forecourtWidth =
    math.max(24, math.min(padWidth - 16, padWidth - storeSize.X - (storeMargin * 3)))
  local forecourtLength =
    math.max(26, math.min(padLength - 20, padLength - storeSize.Z - (storeMargin * 3)))
  forecourt.Size = Vector3.new(forecourtWidth, 1, forecourtLength)
  local forecourtY = LayoutUtil.getStackedCenterY(base, forecourt.Size.Y, asphaltOffset)
  local forecourtLocalY = forecourtY and (forecourtY - baseCFrame.Position.Y)
    or (base.Size.Y + (forecourt.Size.Y / 2) + asphaltOffset)
  local forecourtCenter = Vector3.new(
    padHalfX - (forecourtWidth / 2) - storeMargin,
    forecourtLocalY,
    -(padHalfZ - (forecourtLength / 2) - storeMargin)
  )
  forecourt.CFrame = toWorldCFrame(baseCFrame, forecourtCenter)
  stylePad(forecourt, "Medium stone grey")

  local canopy = BuilderUtil.findOrCreatePart(model, "Canopy", "Part")
  BuilderUtil.applyPhysics(canopy, true, true, false)
  local canopyWidth = math.max(16, forecourtWidth - 8)
  local canopyLength = math.max(14, forecourtLength - 8)
  canopy.Size = Vector3.new(canopyWidth, 1, canopyLength)
  local canopyCenter = Vector3.new(-8, 12, forecourtCenter.Z)
  canopyCenter = Vector3.new(forecourtCenter.X, canopyCenter.Y, forecourtCenter.Z)
  canopy.CFrame = toWorldCFrame(baseCFrame, canopyCenter)
  canopy.Material = Enum.Material.SmoothPlastic
  canopy.BrickColor = BrickColor.new("Linen")

  local columnHeight = 12
  local columnY = columnHeight / 2
  local halfCanopyX = canopy.Size.X / 2 - 2
  local halfCanopyZ = canopy.Size.Z / 2 - 2

  buildColumn(
    model,
    "CanopyColumnFL",
    baseCFrame,
    Vector3.new(canopyCenter.X - halfCanopyX, columnY, canopyCenter.Z - halfCanopyZ),
    columnHeight
  )
  buildColumn(
    model,
    "CanopyColumnFR",
    baseCFrame,
    Vector3.new(canopyCenter.X + halfCanopyX, columnY, canopyCenter.Z - halfCanopyZ),
    columnHeight
  )
  buildColumn(
    model,
    "CanopyColumnBL",
    baseCFrame,
    Vector3.new(canopyCenter.X - halfCanopyX, columnY, canopyCenter.Z + halfCanopyZ),
    columnHeight
  )
  buildColumn(
    model,
    "CanopyColumnBR",
    baseCFrame,
    Vector3.new(canopyCenter.X + halfCanopyX, columnY, canopyCenter.Z + halfCanopyZ),
    columnHeight
  )

  local pumpHeight = 10
  local pumpY = (pumpHeight / 2) + 0.5
  local pumpOffsetX = math.min(8, (canopyWidth / 2) - 4)
  buildPump(
    model,
    "GasPumpA",
    baseCFrame,
    Vector3.new(canopyCenter.X - pumpOffsetX, pumpY, canopyCenter.Z),
    pumpHeight
  )
  buildPump(
    model,
    "GasPumpB",
    baseCFrame,
    Vector3.new(canopyCenter.X + pumpOffsetX, pumpY, canopyCenter.Z),
    pumpHeight
  )

  local signPole = BuilderUtil.findOrCreatePart(model, "GasSignPole", "Part")
  BuilderUtil.applyPhysics(signPole, true, true, false)
  signPole.Size = Vector3.new(1, 14, 1)
  signPole.CFrame = toWorldCFrame(baseCFrame, Vector3.new(-padHalfX + 6, 7, padHalfZ - 6))
  signPole.Material = Enum.Material.SmoothPlastic
  signPole.BrickColor = BrickColor.new("Dark stone grey")

  local sign = BuilderUtil.findOrCreatePart(model, "GasSign", "Part")
  BuilderUtil.applyPhysics(sign, true, false, false)
  sign.Size = Vector3.new(8, 4, 1)
  sign.CFrame = toWorldCFrame(baseCFrame, Vector3.new(-padHalfX + 6, 12, padHalfZ - 6))
  sign.Material = Enum.Material.SmoothPlastic
  sign.BrickColor = BrickColor.new("Bright orange")

  local storeCenter = Vector3.new(
    -(padHalfX - (storeSize.X / 2) - storeMargin),
    0,
    padHalfZ - (storeSize.Z / 2) - storeMargin
  )
  buildStore(model, baseCFrame, storeCenter, storeSize, baseTopLocal + roomOffset, constants)

  local carOffsetX = forecourtWidth / 2 - 10
  local carOffsetZ = forecourtLength / 2 - 8
  buildCar(
    model,
    baseCFrame,
    Vector3.new(
      forecourtCenter.X - carOffsetX,
      baseTopLocal + asphaltOffset,
      forecourtCenter.Z - carOffsetZ
    )
  )

  local spawnAnchor = LayoutUtil.anchor(context.layout, "spawn", "east", 26)
  local spawnCenter = context.layout.spawnCenter
  local vehiclePos = spawnAnchor or (spawnCenter + Vector3.new(50, 0, 0))
  local vehicleYaw = math.rad(-90)
  local baseY = LayoutUtil.getLayerY(context.baseplate, "baseplate") or context.groundY
  if baseY then
    placeAChassis(CFrame.new(vehiclePos) * CFrame.Angles(0, vehicleYaw, 0), baseY)
  end
end

return GasStationBuilder
