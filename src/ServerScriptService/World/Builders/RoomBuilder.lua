local WallBuilder = require(script.Parent.WallBuilder)

local RoomBuilder = {}

local function normalizeOpenings(openings)
  if not openings then
    return nil
  end
  if openings.width then
    return { openings }
  end
  if #openings > 0 then
    return openings
  end
  return nil
end

function RoomBuilder.buildWalls(config)
  if
    not config
    or not config.model
    or not config.baseCFrame
    or not config.center
    or not config.size
  then
    return
  end

  local centerLocal = config.center
  local wallThickness = config.wallThickness or 1
  local halfX = config.size.X / 2
  local halfZ = config.size.Z / 2
  local wallY = centerLocal.Y

  local northZ = centerLocal.Z + halfZ
  local southZ = centerLocal.Z - halfZ
  local eastX = centerLocal.X + halfX
  local westX = centerLocal.X - halfX

  local frames = {}

  frames.North = WallBuilder.buildWall({
    model = config.model,
    namePrefix = config.namePrefix .. "North",
    baseCFrame = config.baseCFrame,
    center = Vector3.new(centerLocal.X, wallY, northZ),
    length = config.size.X + wallThickness,
    height = config.size.Y,
    thickness = wallThickness,
    axis = "x",
    wallColor = config.wallColor,
    material = config.material,
    openings = normalizeOpenings(config.openings and config.openings.North or nil),
  })

  frames.South = WallBuilder.buildWall({
    model = config.model,
    namePrefix = config.namePrefix .. "South",
    baseCFrame = config.baseCFrame,
    center = Vector3.new(centerLocal.X, wallY, southZ),
    length = config.size.X + wallThickness,
    height = config.size.Y,
    thickness = wallThickness,
    axis = "x",
    wallColor = config.wallColor,
    material = config.material,
    openings = normalizeOpenings(config.openings and config.openings.South or nil),
  })

  frames.East = WallBuilder.buildWall({
    model = config.model,
    namePrefix = config.namePrefix .. "East",
    baseCFrame = config.baseCFrame,
    center = Vector3.new(eastX, wallY, centerLocal.Z),
    length = config.size.Z + wallThickness,
    height = config.size.Y,
    thickness = wallThickness,
    axis = "z",
    wallColor = config.wallColor,
    material = config.material,
    openings = normalizeOpenings(config.openings and config.openings.East or nil),
  })

  frames.West = WallBuilder.buildWall({
    model = config.model,
    namePrefix = config.namePrefix .. "West",
    baseCFrame = config.baseCFrame,
    center = Vector3.new(westX, wallY, centerLocal.Z),
    length = config.size.Z + wallThickness,
    height = config.size.Y,
    thickness = wallThickness,
    axis = "z",
    wallColor = config.wallColor,
    material = config.material,
    openings = normalizeOpenings(config.openings and config.openings.West or nil),
  })

  return frames
end

return RoomBuilder
