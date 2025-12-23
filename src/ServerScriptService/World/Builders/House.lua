local BuilderUtil = require(script.Parent.BuilderUtil)
local DoorBuilder = require(script.Parent.DoorBuilder)
local RoomBuilder = require(script.Parent.RoomBuilder)
local WallBuilder = require(script.Parent.WallBuilder)
local WindowBuilder = require(script.Parent.WindowBuilder)

local House = {}
House.__index = House

local FLOOR_THICKNESS = 1
local ROOF_THICKNESS = 1
local WALL_THICKNESS = 1
local DEFAULT_FLOOR_HEIGHT = 10
local DEFAULT_DOOR_WIDTH = 6
local DEFAULT_DOOR_HEIGHT = 9
local DOOR_THICKNESS = 0.35
local WINDOW_WIDTH = 4
local WINDOW_HEIGHT = 4
local WINDOW_THICKNESS = 0.3
local INTERIOR_DOOR_WIDTH = 3.5
local INTERIOR_DOOR_HEIGHT = 7

local DOOR_KEYS = {
  north = "North",
  south = "South",
  east = "East",
  west = "West",
}

local function normalizeDoorSide(side)
  if not side then
    return "south"
  end
  side = string.lower(tostring(side))
  if DOOR_KEYS[side] then
    return side
  end
  return "south"
end

local function getFrontVector(side)
  if side == "north" then
    return Vector3.new(0, 0, 1)
  elseif side == "south" then
    return Vector3.new(0, 0, -1)
  elseif side == "east" then
    return Vector3.new(1, 0, 0)
  elseif side == "west" then
    return Vector3.new(-1, 0, 0)
  end
  return Vector3.new(0, 0, -1)
end

local function axisForVector(vector)
  if math.abs(vector.X) > 0.5 then
    return "x"
  end
  return "z"
end

local function sizeForAxes(width, depth, right)
  if math.abs(right.X) > 0.5 then
    return width, depth
  end
  return depth, width
end

local function layoutOffset(right, front, x, y, z)
  return (right * x) + (front * z) + Vector3.new(0, y, 0)
end

local function clearPartsByPrefix(model, prefix)
  for _, child in ipairs(model:GetChildren()) do
    if child:IsA("BasePart") and child.Name:match("^" .. prefix) then
      child:Destroy()
    end
  end
end


House.DEFAULT_SIZE = Vector3.new(48, DEFAULT_FLOOR_HEIGHT * 2, 38)

function House.new(config)
  config = config or {}
  local self = setmetatable({}, House)
  local baseSize = config.size or House.DEFAULT_SIZE
  local floorHeight = config.floorHeight
  if floorHeight then
    baseSize = Vector3.new(baseSize.X, floorHeight * 2, baseSize.Z)
  end
  self.name = config.name or "House"
  self.offset = config.offset or Vector3.new(0, 0, 0)
  self.size = baseSize
  self.floorHeight = floorHeight
  self.wallHeight = config.wallHeight
  self.wallColor = config.wallColor or BrickColor.new("Linen")
  self.floorColor = config.floorColor or BrickColor.new("Medium stone grey")
  self.roofColor = config.roofColor or BrickColor.new("Reddish brown")
  self.trimColor = config.trimColor or BrickColor.new("White")
  self.hasDoor = config.hasDoor == true
  self.hasInterior = config.hasInterior == true
  self.doorSide = normalizeDoorSide(config.doorSide)
  self.doorTag = config.doorTag
  self.autoDoorDistance = config.autoDoorDistance
  self.interiorDoorDistance = config.interiorDoorDistance
  return self
end

function House:getFootprint()
  local halfX = self.size.X / 2
  local halfZ = self.size.Z / 2
  return {
    name = self.name,
    center = self.offset,
    size = Vector3.new(self.size.X, 0, self.size.Z),
    min = Vector3.new(self.offset.X - halfX, 0, self.offset.Z - halfZ),
    max = Vector3.new(self.offset.X + halfX, 0, self.offset.Z + halfZ),
  }
end

function House:Build(parent, baseCFrame)
  if not parent or not baseCFrame then
    return nil
  end

  local wallHeight = self.wallHeight or self.size.Y or (DEFAULT_FLOOR_HEIGHT * 2)
  if wallHeight <= 0 then
    wallHeight = DEFAULT_FLOOR_HEIGHT * 2
  end
  local floorHeight = self.floorHeight or (wallHeight / 2)
  if floorHeight <= 0 then
    floorHeight = DEFAULT_FLOOR_HEIGHT
    wallHeight = floorHeight * 2
  end
  local upperWallHeight = floorHeight - FLOOR_THICKNESS

  local front = getFrontVector(self.doorSide)
  local right = front:Cross(Vector3.new(0, 1, 0))
  local frontAxis = axisForVector(front)
  local rightAxis = axisForVector(right)
  local depth = math.abs(front.X) > 0.5 and self.size.X or self.size.Z
  local width = math.abs(front.X) > 0.5 and self.size.Z or self.size.X
  local halfDepth = depth / 2
  local halfWidth = width / 2
  local frontEdge = halfDepth
  local backEdge = -halfDepth
  local leftEdge = -halfWidth

  local houseModel = BuilderUtil.findOrCreateModel(parent, self.name)
  local houseCFrame = baseCFrame * CFrame.new(self.offset)

  local floor = BuilderUtil.findOrCreatePart(houseModel, "Floor", "Part")
  BuilderUtil.applyPhysics(floor, true, true, false)
  floor.Size = Vector3.new(self.size.X, FLOOR_THICKNESS, self.size.Z)
  floor.CFrame = houseCFrame * CFrame.new(0, FLOOR_THICKNESS / 2, 0)
  floor.Material = Enum.Material.SmoothPlastic
  floor.BrickColor = self.floorColor

  local existingRoof = houseModel:FindFirstChild("Roof")
  if existingRoof and existingRoof:IsA("BasePart") then
    existingRoof:Destroy()
  end

  local roofModel = BuilderUtil.findOrCreateModel(houseModel, "Roof")
  local roofOverhang = 2
  local roofRise = math.max(6, floorHeight * 0.6)
  local roofThickness = math.max(0.4, ROOF_THICKNESS)
  local roofDepth = depth + (roofOverhang * 2)
  local roofHalfWidth = (width / 2) + roofOverhang
  local slopeLength = math.sqrt((roofHalfWidth * roofHalfWidth) + (roofRise * roofRise))
  local slopeAngle = math.atan2(roofRise, roofHalfWidth)
  local ridgeY = wallHeight + roofRise
  local panelCenterY = wallHeight + (roofRise / 2)
  local panelOffsetX = roofHalfWidth / 2

  local function buildRoofPanel(name, sign)
    local panel = BuilderUtil.findOrCreatePart(roofModel, name, "Part")
    BuilderUtil.applyPhysics(panel, true, true, false)
    panel.Size = Vector3.new(slopeLength, roofThickness, roofDepth)
    panel.Material = Enum.Material.SmoothPlastic
    panel.BrickColor = self.roofColor

    local tilt = CFrame.fromAxisAngle(front, slopeAngle * sign)
    local base = houseCFrame
      * CFrame.new(layoutOffset(right, front, panelOffsetX * sign, panelCenterY, 0))
    panel.CFrame = base * tilt
  end

  buildRoofPanel("RoofLeft", -1)
  buildRoofPanel("RoofRight", 1)

  local ridge = BuilderUtil.findOrCreatePart(roofModel, "RoofRidge", "Part")
  BuilderUtil.applyPhysics(ridge, true, true, false)
  ridge.Size = Vector3.new(roofThickness, roofThickness, roofDepth)
  ridge.Material = Enum.Material.SmoothPlastic
  ridge.BrickColor = self.roofColor
  ridge.CFrame = houseCFrame * CFrame.new(0, ridgeY, 0)

  local existingSecondFloor = houseModel:FindFirstChild("SecondFloor")
  if existingSecondFloor and existingSecondFloor:IsA("BasePart") then
    existingSecondFloor:Destroy()
  end

  local secondFloorModel = BuilderUtil.findOrCreateModel(houseModel, "SecondFloor")
  local secondFloorY = floorHeight + (FLOOR_THICKNESS / 2)

  local function buildSecondFloorPiece(name, pieceWidth, pieceDepth, centerX, centerZ)
    if pieceWidth <= 0 or pieceDepth <= 0 then
      return nil
    end
    local sizeX, sizeZ = sizeForAxes(pieceWidth, pieceDepth, right)
    local piece = BuilderUtil.findOrCreatePart(secondFloorModel, name, "Part")
    BuilderUtil.applyPhysics(piece, true, true, false)
    piece.Size = Vector3.new(sizeX, FLOOR_THICKNESS, sizeZ)
    local offset = layoutOffset(right, front, centerX, secondFloorY, centerZ)
    piece.CFrame = houseCFrame * CFrame.new(offset)
    piece.Material = Enum.Material.SmoothPlastic
    piece.BrickColor = self.floorColor
    return piece
  end

  local openings = nil
  if self.hasDoor then
    openings = {
      [DOOR_KEYS[self.doorSide]] = {
        width = DEFAULT_DOOR_WIDTH,
        height = DEFAULT_DOOR_HEIGHT,
        bottom = 0,
      },
    }
  end

  local wallFrames = RoomBuilder.buildWalls({
    model = houseModel,
    namePrefix = "Wall",
    baseCFrame = houseCFrame,
    center = Vector3.new(0, wallHeight / 2, 0),
    size = Vector3.new(self.size.X, wallHeight, self.size.Z),
    wallThickness = WALL_THICKNESS,
    wallColor = self.wallColor,
    material = Enum.Material.SmoothPlastic,
    openings = openings,
  })

  local doorFrames = wallFrames and wallFrames[DOOR_KEYS[self.doorSide]] or nil
  local doorFrame = doorFrames and doorFrames[1] and doorFrames[1].cframe or nil
  if self.hasDoor and doorFrame then
    local sizeX
    local sizeZ
    if frontAxis == "x" then
      sizeX = DOOR_THICKNESS
      sizeZ = DEFAULT_DOOR_WIDTH
    else
      sizeX = DEFAULT_DOOR_WIDTH
      sizeZ = DOOR_THICKNESS
    end
    local door = BuilderUtil.findOrCreatePart(houseModel, "Door", "Part")
    BuilderUtil.applyPhysics(door, true, false, false)
    door.Size = Vector3.new(sizeX, DEFAULT_DOOR_HEIGHT, sizeZ)
    door.CFrame = doorFrame
    door.Material = Enum.Material.SmoothPlastic
    door.BrickColor = self.trimColor
    local doorWallAxis = (self.doorSide == "east" or self.doorSide == "west") and "z" or "x"
    DoorBuilder.enableAutoSlide(
      door,
      doorWallAxis,
      DEFAULT_DOOR_WIDTH * 0.9,
      1,
      self.autoDoorDistance,
      self.doorTag
    )
  end

  if self.hasInterior then
    clearPartsByPrefix(houseModel, "UpperHallWallLeft")
    clearPartsByPrefix(houseModel, "UpperHallWallRight")
    clearPartsByPrefix(houseModel, "BedroomDoor")

    local interiorColor = BrickColor.new("Light stone grey")
    local upperBaseCFrame = houseCFrame * CFrame.new(0, floorHeight + FLOOR_THICKNESS, 0)
    local upperCenterY = upperWallHeight / 2

    local bathWidth = math.min(12, width * 0.35)
    local bathDepth = math.min(10, depth * 0.28)
    local bathBackZ = frontEdge - bathDepth
    local bathCenterX = leftEdge + (bathWidth / 2)
    local bathCenterZ = frontEdge - (bathDepth / 2)
    local bathSideX = leftEdge + bathWidth

    local bathFrames = WallBuilder.buildWall({
      model = houseModel,
      namePrefix = "BathFrontWall",
      baseCFrame = houseCFrame,
      center = layoutOffset(right, front, bathCenterX, floorHeight / 2, bathBackZ),
      length = bathWidth,
      height = floorHeight,
      thickness = WALL_THICKNESS,
      axis = rightAxis,
      wallColor = interiorColor,
      material = Enum.Material.SmoothPlastic,
      openings = {
        width = INTERIOR_DOOR_WIDTH,
        height = INTERIOR_DOOR_HEIGHT,
        bottom = 0,
        offset = 0,
      },
    })

    WallBuilder.buildWall({
      model = houseModel,
      namePrefix = "BathSideWall",
      baseCFrame = houseCFrame,
      center = layoutOffset(right, front, bathSideX, floorHeight / 2, bathCenterZ),
      length = bathDepth,
      height = floorHeight,
      thickness = WALL_THICKNESS,
      axis = frontAxis,
      wallColor = interiorColor,
      material = Enum.Material.SmoothPlastic,
    })

    local bathDoorFrame = bathFrames and bathFrames[1] and bathFrames[1].cframe or nil
    if bathDoorFrame then
      local sizeX
      local sizeZ
      if rightAxis == "x" then
        sizeX = INTERIOR_DOOR_WIDTH
        sizeZ = DOOR_THICKNESS
      else
        sizeX = DOOR_THICKNESS
        sizeZ = INTERIOR_DOOR_WIDTH
      end
      local bathDoor = BuilderUtil.findOrCreatePart(houseModel, "BathDoor", "Part")
      BuilderUtil.applyPhysics(bathDoor, true, false, false)
      bathDoor.Size = Vector3.new(sizeX, INTERIOR_DOOR_HEIGHT, sizeZ)
      bathDoor.CFrame = bathDoorFrame
      bathDoor.Material = Enum.Material.SmoothPlastic
      bathDoor.BrickColor = self.trimColor
      DoorBuilder.enableAutoSlide(
        bathDoor,
        rightAxis,
        INTERIOR_DOOR_WIDTH * 0.9,
        -1,
        self.interiorDoorDistance,
        self.doorTag
      )
    end

    local hallDepth = math.max(12, math.min(depth * 0.35, 16))
    local hallBackZ = frontEdge - hallDepth

    local bedroomWidth = width / 3
    local bedroomDepth = hallBackZ - backEdge
    local bedroomCenterZ = backEdge + (bedroomDepth / 2)

    local doorOffsets = {
      leftEdge + (bedroomWidth / 2),
      leftEdge + (bedroomWidth * 1.5),
      leftEdge + (bedroomWidth * 2.5),
    }

    local doorOpenings = {}
    for _, offset in ipairs(doorOffsets) do
      table.insert(doorOpenings, {
        width = INTERIOR_DOOR_WIDTH,
        height = INTERIOR_DOOR_HEIGHT,
        bottom = 0,
        offset = offset,
      })
    end

    local upperFrames = WallBuilder.buildWall({
      model = houseModel,
      namePrefix = "UpperBackWall",
      baseCFrame = upperBaseCFrame,
      center = layoutOffset(right, front, 0, upperCenterY, hallBackZ),
      length = width,
      height = upperWallHeight,
      thickness = WALL_THICKNESS,
      axis = rightAxis,
      wallColor = interiorColor,
      material = Enum.Material.SmoothPlastic,
      openings = doorOpenings,
    })

    local expectedDoors = {}
    if upperFrames then
      for index, frame in ipairs(upperFrames) do
        local sizeX
        local sizeZ
        if rightAxis == "x" then
          sizeX = INTERIOR_DOOR_WIDTH
          sizeZ = DOOR_THICKNESS
        else
          sizeX = DOOR_THICKNESS
          sizeZ = INTERIOR_DOOR_WIDTH
        end
        local doorName = "BedroomDoor" .. index
        expectedDoors[doorName] = true
        local bedroomDoor = BuilderUtil.findOrCreatePart(houseModel, doorName, "Part")
        BuilderUtil.applyPhysics(bedroomDoor, true, false, false)
        bedroomDoor.Size = Vector3.new(sizeX, INTERIOR_DOOR_HEIGHT, sizeZ)
        bedroomDoor.CFrame = frame.cframe
        bedroomDoor.Material = Enum.Material.SmoothPlastic
        bedroomDoor.BrickColor = self.trimColor
        local slideSign = index % 2 == 0 and -1 or 1
        DoorBuilder.enableAutoSlide(
          bedroomDoor,
          rightAxis,
          INTERIOR_DOOR_WIDTH * 0.9,
          slideSign,
          self.interiorDoorDistance,
          self.doorTag
        )
      end
    end

    for _, child in ipairs(houseModel:GetChildren()) do
      if
        child:IsA("BasePart")
        and child.Name:match("^BedroomDoor")
        and not expectedDoors[child.Name]
      then
        child:Destroy()
      end
    end

    for index = 1, 2 do
      local dividerX = leftEdge + (bedroomWidth * index)
      WallBuilder.buildWall({
        model = houseModel,
        namePrefix = "BedroomWall" .. index,
        baseCFrame = upperBaseCFrame,
        center = layoutOffset(right, front, dividerX, upperCenterY, bedroomCenterZ),
        length = bedroomDepth,
        height = upperWallHeight,
        thickness = WALL_THICKNESS,
        axis = frontAxis,
        wallColor = interiorColor,
        material = Enum.Material.SmoothPlastic,
      })
    end

    local stairModel = BuilderUtil.findOrCreateModel(houseModel, "Stairs")
    local stepCount = 8
    local stepHeight = floorHeight / stepCount
    local stepDepth = 2.6
    local stepWidth = 6
    local stairStartZ = frontEdge - 3
    local stairCenterX = bathSideX + (stepWidth / 2) + 0.2
    local maxStairX = halfWidth - (stepWidth / 2) - 0.2
    if stairCenterX > maxStairX then
      stairCenterX = maxStairX
    end

    local stepSizeX, stepSizeZ = sizeForAxes(stepWidth, stepDepth, right)
    for stepIndex = 1, stepCount do
      local step =
        BuilderUtil.findOrCreatePart(stairModel, "Step" .. string.format("%02d", stepIndex), "Part")
      BuilderUtil.applyPhysics(step, true, true, false)
      step.Size = Vector3.new(stepSizeX, stepHeight, stepSizeZ)
      local stepY = (stepHeight / 2) + (stepHeight * (stepIndex - 1))
      local stepZ = stairStartZ - (stepDepth * (stepIndex - 1))
      local offset = layoutOffset(right, front, stairCenterX, stepY, stepZ)
      step.CFrame = houseCFrame * CFrame.new(offset)
      step.Material = Enum.Material.SmoothPlastic
      step.BrickColor = BrickColor.new("Medium stone grey")
    end

    local stepIndex = stepCount + 1
    while true do
      local extra = stairModel:FindFirstChild("Step" .. string.format("%02d", stepIndex))
      if not extra then
        break
      end
      if extra:IsA("BasePart") then
        extra:Destroy()
      else
        extra.Name = extra.Name .. "_Unexpected"
      end
      stepIndex += 1
    end

    local openingPadding = 0.1
    local openingWidth = stepWidth + openingPadding
    local openingLength = (stepDepth * stepCount) + openingPadding
    local openingCenterZ = stairStartZ - ((stepDepth * (stepCount - 1)) / 2)
    local openingLeft = math.max(leftEdge, stairCenterX - (openingWidth / 2))
    local openingRight = math.min(halfWidth, stairCenterX + (openingWidth / 2))
    local openingFront = math.min(frontEdge, openingCenterZ + (openingLength / 2))
    local openingBack = math.max(backEdge, openingCenterZ - (openingLength / 2))

    local expectedFloors = {}
    local leftWidth = openingLeft - leftEdge
    if leftWidth > 0.1 then
      buildSecondFloorPiece("SecondFloorLeft", leftWidth, depth, leftEdge + (leftWidth / 2), 0)
      expectedFloors.SecondFloorLeft = true
    end

    local rightWidth = halfWidth - openingRight
    if rightWidth > 0.1 then
      buildSecondFloorPiece(
        "SecondFloorRight",
        rightWidth,
        depth,
        openingRight + (rightWidth / 2),
        0
      )
      expectedFloors.SecondFloorRight = true
    end

    local openingSpan = openingRight - openingLeft
    if openingSpan > 0.1 then
      local frontDepth = frontEdge - openingFront
      if frontDepth > 0.1 then
        buildSecondFloorPiece(
          "SecondFloorFront",
          openingSpan,
          frontDepth,
          openingLeft + (openingSpan / 2),
          openingFront + (frontDepth / 2)
        )
        expectedFloors.SecondFloorFront = true
      end

      local backDepth = openingBack - backEdge
      if backDepth > 0.1 then
        buildSecondFloorPiece(
          "SecondFloorBack",
          openingSpan,
          backDepth,
          openingLeft + (openingSpan / 2),
          backEdge + (backDepth / 2)
        )
        expectedFloors.SecondFloorBack = true
      end
    end

    for _, child in ipairs(secondFloorModel:GetChildren()) do
      if child:IsA("BasePart") and not expectedFloors[child.Name] then
        child:Destroy()
      end
    end
  else
    local fullFloor = BuilderUtil.findOrCreatePart(secondFloorModel, "SecondFloorFull", "Part")
    BuilderUtil.applyPhysics(fullFloor, true, true, false)
    fullFloor.Size = Vector3.new(self.size.X, FLOOR_THICKNESS, self.size.Z)
    fullFloor.CFrame = houseCFrame * CFrame.new(0, secondFloorY, 0)
    fullFloor.Material = Enum.Material.SmoothPlastic
    fullFloor.BrickColor = self.floorColor
    for _, child in ipairs(secondFloorModel:GetChildren()) do
      if child:IsA("BasePart") and child.Name ~= "SecondFloorFull" then
        child:Destroy()
      end
    end

    local stairs = houseModel:FindFirstChild("Stairs")
    if stairs then
      stairs:Destroy()
    end
    clearPartsByPrefix(houseModel, "Bath")
    clearPartsByPrefix(houseModel, "UpperBackWall")
    clearPartsByPrefix(houseModel, "BedroomWall")
  end

  local windowLowerY = math.min(wallHeight - 2, 6)
  local windowUpperY = math.min(wallHeight - 2, floorHeight + 6)
  local windowInset = (WINDOW_THICKNESS / 2) + 0.05
  local windowOffset = width / 4

  local function sizeForAxis(axis)
    if axis == "x" then
      return WINDOW_THICKNESS, WINDOW_WIDTH
    end
    return WINDOW_WIDTH, WINDOW_THICKNESS
  end

  local function buildWindow(name, axis, x, y, z)
    local sizeX, sizeZ = sizeForAxis(axis)
    local offset = layoutOffset(right, front, x, y, z)
    local windowSize = Vector3.new(sizeX, WINDOW_HEIGHT, sizeZ)
    WindowBuilder.buildPanelWindow(
      houseModel,
      name,
      houseCFrame * CFrame.new(offset),
      windowSize,
      nil
    )
  end

  local frontZ = frontEdge + windowInset
  local backZ = backEdge - windowInset
  local leftX = leftEdge - windowInset
  local rightX = halfWidth + windowInset
  local sideDepth = 0

  buildWindow("WindowFrontLeftLower", frontAxis, -windowOffset, windowLowerY, frontZ)
  buildWindow("WindowFrontRightLower", frontAxis, windowOffset, windowLowerY, frontZ)
  buildWindow("WindowFrontLeftUpper", frontAxis, -windowOffset, windowUpperY, frontZ)
  buildWindow("WindowFrontRightUpper", frontAxis, windowOffset, windowUpperY, frontZ)

  buildWindow("WindowBackLower", frontAxis, 0, windowLowerY, backZ)
  buildWindow("WindowBackUpper", frontAxis, 0, windowUpperY, backZ)

  buildWindow("WindowLeftLower", rightAxis, leftX, windowLowerY, sideDepth)
  buildWindow("WindowLeftUpper", rightAxis, leftX, windowUpperY, sideDepth)
  buildWindow("WindowRightLower", rightAxis, rightX, windowLowerY, sideDepth)
  buildWindow("WindowRightUpper", rightAxis, rightX, windowUpperY, sideDepth)

  return self:getFootprint()
end

return House
