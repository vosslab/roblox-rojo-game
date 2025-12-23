local BuilderUtil = require(script.Parent.BuilderUtil)
local House = require(script.Parent.House)

local NeighborhoodBuilder = {}

local function doTheseOverlap(a, b)
  if not a or not b then
    return false
  end
  local overlapX = a.min.X < b.max.X and a.max.X > b.min.X
  local overlapZ = a.min.Z < b.max.Z and a.max.Z > b.min.Z
  return overlapX and overlapZ
end

function NeighborhoodBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local layout = context.layout
  if not layout then
    return
  end

  local neighborhoodModel = BuilderUtil.findOrCreateModel(playground, constants.NAMES.Neighborhood)

  local zone = layout.zones and layout.zones.neighborhood or nil
  local zoneWidth = zone and zone.width or 140
  local floorHeight = 10
  local doorTag = constants and constants.TAGS and constants.TAGS.AutoSwingDoor or nil

  local houseSize = House.DEFAULT_SIZE
  local cols = 4
  local rows = 4
  local gap = 8
  local roadWidth = 8
  local spacingX = houseSize.X + gap
  local gridWidth = (cols - 1) * spacingX
  local totalWidth = gridWidth + houseSize.X

  local stepNoRoad = houseSize.Z + gap
  local stepWithRoad = houseSize.Z + roadWidth + (gap * 2)
  local rowOffsets = {}
  local currentZ = 0
  for row = 1, rows do
    rowOffsets[row] = currentZ
    if row < rows then
      if row == 1 or row == 3 then
        currentZ += stepWithRoad
      else
        currentZ += stepNoRoad
      end
    end
  end
  local spanZ = rowOffsets[rows] - rowOffsets[1]
  local centerShiftZ = spanZ / 2
  for row = 1, rows do
    rowOffsets[row] -= centerShiftZ
  end

  local zoneShiftX = (zoneWidth / 2) + 40 + math.max(0, (totalWidth - zoneWidth) / 2)
  local neighborhoodCenter = layout.neighborhoodCenter + Vector3.new(zoneShiftX, 0, 0)
  local baseCFrame = CFrame.lookAt(neighborhoodCenter, layout.spawnCenter, Vector3.new(0, 1, 0))

  local streetModel = BuilderUtil.findOrCreateModel(neighborhoodModel, "Streets")
  local streetThickness = 1
  local streetMaterial = Enum.Material.Asphalt
  local streetColor = BrickColor.new("Dark stone grey")

  local function buildStreetPart(name, sizeX, sizeZ, centerX, centerZ)
    local part = BuilderUtil.findOrCreatePart(streetModel, name, "Part")
    BuilderUtil.applyPhysics(part, true, true, false)
    part.Size = Vector3.new(sizeX, streetThickness, sizeZ)
    part.CFrame = baseCFrame * CFrame.new(centerX, streetThickness / 2, centerZ)
    part.Material = streetMaterial
    part.BrickColor = streetColor
  end

  local roadCount = 0
  for row = 1, rows - 1 do
    if row == 1 or row == 3 then
      roadCount += 1
      local streetZ = (rowOffsets[row] + rowOffsets[row + 1]) / 2
      buildStreetPart(
        string.format("StreetRow%02d", roadCount),
        totalWidth + (gap * 2),
        roadWidth,
        0,
        streetZ
      )
    end
  end

  local palettes = {
    {
      wallColor = BrickColor.new("Fawn"),
      floorColor = BrickColor.new("Medium stone grey"),
      roofColor = BrickColor.new("Reddish brown"),
      trimColor = BrickColor.new("White"),
    },
    {
      wallColor = BrickColor.new("Linen"),
      floorColor = BrickColor.new("Medium stone grey"),
      roofColor = BrickColor.new("Reddish brown"),
      trimColor = BrickColor.new("White"),
    },
    {
      wallColor = BrickColor.new("Dusty Rose"),
      floorColor = BrickColor.new("Medium stone grey"),
      roofColor = BrickColor.new("Reddish brown"),
      trimColor = BrickColor.new("White"),
    },
    {
      wallColor = BrickColor.new("Cocoa"),
      floorColor = BrickColor.new("Medium stone grey"),
      roofColor = BrickColor.new("Reddish brown"),
      trimColor = BrickColor.new("White"),
    },
    {
      wallColor = BrickColor.new("Light stone grey"),
      floorColor = BrickColor.new("Medium stone grey"),
      roofColor = BrickColor.new("Reddish brown"),
      trimColor = BrickColor.new("White"),
    },
    {
      wallColor = BrickColor.new("Pastel Blue"),
      floorColor = BrickColor.new("Medium stone grey"),
      roofColor = BrickColor.new("Reddish brown"),
      trimColor = BrickColor.new("White"),
    },
  }

  local houseConfigs = {}
  local index = 0
  for row = 1, rows do
    local rowOffsetZ = rowOffsets[row]
    for col = 1, cols do
      index += 1
      local colOffsetX = (col - ((cols + 1) / 2)) * spacingX
      local palette = palettes[((index - 1) % #palettes) + 1]
      local doorSide = "south"
      if row == 1 then
        doorSide = "south"
      elseif row == rows then
        doorSide = "north"
      elseif col == 1 then
        doorSide = "west"
      elseif col == cols then
        doorSide = "east"
      end
      table.insert(houseConfigs, {
        name = string.format("House%02d", index),
        offset = Vector3.new(colOffsetX, 0, rowOffsetZ),
        size = houseSize,
        floorHeight = floorHeight,
        hasDoor = index == 1,
        hasInterior = index == 1,
        doorSide = doorSide,
        doorTag = doorTag,
        autoDoorDistance = 10,
        interiorDoorDistance = 7,
        wallColor = palette.wallColor,
        floorColor = palette.floorColor,
        roofColor = palette.roofColor,
        trimColor = palette.trimColor,
      })
    end
  end

  local expected = {}
  local footprints = {}
  for _, config in ipairs(houseConfigs) do
    expected[config.name] = true
    local house = House.new(config)
    local footprint = house:Build(neighborhoodModel, baseCFrame)
    if footprint then
      table.insert(footprints, footprint)
    end
  end

  for _, child in ipairs(neighborhoodModel:GetChildren()) do
    if child:IsA("Model") and child.Name:match("^House") and not expected[child.Name] then
      child:Destroy()
    end
  end

  for _, child in ipairs(streetModel:GetChildren()) do
    if child:IsA("BasePart") then
      local isCol = child.Name:match("^StreetCol")
      local isRow = child.Name:match("^StreetRow")
      if not isCol and not isRow then
        child:Destroy()
      end
    end
  end

  for i = 1, #footprints do
    for j = i + 1, #footprints do
      if doTheseOverlap(footprints[i], footprints[j]) then
        warn(
          "[NeighborhoodBuilder] Houses overlap: "
            .. footprints[i].name
            .. " and "
            .. footprints[j].name
        )
      end
    end
  end
end

return NeighborhoodBuilder
