local BuilderUtil = require(script.Parent.BuilderUtil)

local SchoolBuilder = {}

local function ensureSurfaceLabel(part, text)
  local surface = part:FindFirstChildOfClass("SurfaceGui")
  if not surface then
    surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.AlwaysOnTop = true
    surface.Parent = part
  end

  local label = surface:FindFirstChildOfClass("TextLabel")
  if not label then
    label = Instance.new("TextLabel")
    label.Parent = surface
  end

  label.Size = UDim2.fromScale(1, 1)
  label.BackgroundTransparency = 1
  label.TextScaled = true
  label.Font = Enum.Font.GothamBold
  label.TextColor3 = Color3.fromRGB(255, 255, 255)
  label.TextStrokeTransparency = 0.4
  label.Text = text
end

function SchoolBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local schoolModel = BuilderUtil.findOrCreateModel(playground, "BloxsburgSchool")

  local groundY = context.surfaceY
  local schoolCenter = context.playgroundCenter + Vector3.new(5, 0, 60)
  local floorSize = Vector3.new(80, 1, 30)
  local wallHeight = 12
  local wallThickness = 1
  local roofThickness = 1

  local floor = BuilderUtil.findOrCreatePart(schoolModel, "SchoolFloor", "Part")
  BuilderUtil.applyPhysics(floor, true, true, false)
  floor.Size = floorSize
  floor.Position = Vector3.new(schoolCenter.X, groundY + (floor.Size.Y / 2), schoolCenter.Z)
  floor.Material = Enum.Material.SmoothPlastic
  floor.BrickColor = BrickColor.new("Linen")

  local roof = BuilderUtil.findOrCreatePart(schoolModel, "SchoolRoof", "Part")
  BuilderUtil.applyPhysics(roof, true, true, false)
  roof.Size = Vector3.new(floorSize.X, roofThickness, floorSize.Z)
  roof.Position =
    Vector3.new(schoolCenter.X, groundY + wallHeight + (roofThickness / 2), schoolCenter.Z)
  roof.Material = Enum.Material.SmoothPlastic
  roof.BrickColor = BrickColor.new("Light stone grey")

  local backWall = BuilderUtil.findOrCreatePart(schoolModel, "BackWall", "Part")
  BuilderUtil.applyPhysics(backWall, true, true, false)
  backWall.Size = Vector3.new(floorSize.X, wallHeight, wallThickness)
  backWall.Position =
    Vector3.new(schoolCenter.X, groundY + (wallHeight / 2), schoolCenter.Z + (floorSize.Z / 2))
  backWall.Material = Enum.Material.SmoothPlastic
  backWall.BrickColor = BrickColor.new("Light stone grey")

  local leftWall = BuilderUtil.findOrCreatePart(schoolModel, "LeftWall", "Part")
  local rightWall = BuilderUtil.findOrCreatePart(schoolModel, "RightWall", "Part")
  BuilderUtil.applyPhysics(leftWall, true, true, false)
  BuilderUtil.applyPhysics(rightWall, true, true, false)
  leftWall.Size = Vector3.new(wallThickness, wallHeight, floorSize.Z)
  rightWall.Size = Vector3.new(wallThickness, wallHeight, floorSize.Z)
  leftWall.Position =
    Vector3.new(schoolCenter.X - (floorSize.X / 2), groundY + (wallHeight / 2), schoolCenter.Z)
  rightWall.Position =
    Vector3.new(schoolCenter.X + (floorSize.X / 2), groundY + (wallHeight / 2), schoolCenter.Z)
  leftWall.Material = Enum.Material.SmoothPlastic
  rightWall.Material = Enum.Material.SmoothPlastic
  leftWall.BrickColor = BrickColor.new("Light stone grey")
  rightWall.BrickColor = BrickColor.new("Light stone grey")

  local entranceGap = 10
  local frontLeft = BuilderUtil.findOrCreatePart(schoolModel, "FrontWallLeft", "Part")
  local frontRight = BuilderUtil.findOrCreatePart(schoolModel, "FrontWallRight", "Part")
  BuilderUtil.applyPhysics(frontLeft, true, true, false)
  BuilderUtil.applyPhysics(frontRight, true, true, false)
  frontLeft.Size = Vector3.new((floorSize.X - entranceGap) / 2, wallHeight, wallThickness)
  frontRight.Size = Vector3.new((floorSize.X - entranceGap) / 2, wallHeight, wallThickness)
  frontLeft.Position = Vector3.new(
    schoolCenter.X - (entranceGap / 2) - (frontLeft.Size.X / 2),
    groundY + (wallHeight / 2),
    schoolCenter.Z - (floorSize.Z / 2)
  )
  frontRight.Position = Vector3.new(
    schoolCenter.X + (entranceGap / 2) + (frontRight.Size.X / 2),
    groundY + (wallHeight / 2),
    schoolCenter.Z - (floorSize.Z / 2)
  )
  frontLeft.Material = Enum.Material.SmoothPlastic
  frontRight.Material = Enum.Material.SmoothPlastic
  frontLeft.BrickColor = BrickColor.new("Light stone grey")
  frontRight.BrickColor = BrickColor.new("Light stone grey")

  local sign = BuilderUtil.findOrCreatePart(schoolModel, "SchoolSign", "Part")
  BuilderUtil.applyPhysics(sign, true, false, false)
  sign.Size = Vector3.new(26, 4, 1)
  sign.Position =
    Vector3.new(schoolCenter.X, groundY + wallHeight + 2, schoolCenter.Z - (floorSize.Z / 2) - 0.5)
  sign.Material = Enum.Material.SmoothPlastic
  sign.BrickColor = BrickColor.new("Dark stone grey")
  ensureSurfaceLabel(sign, "Bloxsburg School")

  local hallDepth = 8
  local frontZ = schoolCenter.Z - (floorSize.Z / 2)
  local backZ = schoolCenter.Z + (floorSize.Z / 2)
  local hallBackZ = frontZ + hallDepth

  local function makeDoorFrame(model, namePrefix, centerX, centerZ, doorWidth, doorHeight)
    local sideThickness = 0.4
    local topThickness = 0.4
    local frameDepth = wallThickness

    local left = BuilderUtil.findOrCreatePart(model, namePrefix .. "FrameLeft", "Part")
    local right = BuilderUtil.findOrCreatePart(model, namePrefix .. "FrameRight", "Part")
    local top = BuilderUtil.findOrCreatePart(model, namePrefix .. "FrameTop", "Part")
    BuilderUtil.applyPhysics(left, true, true, false)
    BuilderUtil.applyPhysics(right, true, true, false)
    BuilderUtil.applyPhysics(top, true, true, false)

    left.Size = Vector3.new(sideThickness, doorHeight, frameDepth)
    right.Size = Vector3.new(sideThickness, doorHeight, frameDepth)
    top.Size = Vector3.new(doorWidth + (sideThickness * 2), topThickness, frameDepth)

    left.Position = Vector3.new(centerX - (doorWidth / 2) - (sideThickness / 2), groundY + (doorHeight / 2), centerZ)
    right.Position = Vector3.new(centerX + (doorWidth / 2) + (sideThickness / 2), groundY + (doorHeight / 2), centerZ)
    top.Position = Vector3.new(centerX, groundY + doorHeight + (topThickness / 2), centerZ)

    left.Material = Enum.Material.SmoothPlastic
    right.Material = Enum.Material.SmoothPlastic
    top.Material = Enum.Material.SmoothPlastic
    left.BrickColor = BrickColor.new("Dark stone grey")
    right.BrickColor = BrickColor.new("Dark stone grey")
    top.BrickColor = BrickColor.new("Dark stone grey")
  end

  local function makeDoor(model, name, centerX, centerZ, doorWidth, doorHeight, swingDir)
    local door = BuilderUtil.findOrCreatePart(model, name, "Part")
    BuilderUtil.applyPhysics(door, true, true, false)
    door.Size = Vector3.new(doorWidth, doorHeight, wallThickness)
    door.Material = Enum.Material.SmoothPlastic
    door.BrickColor = BrickColor.new("Dark stone grey")
    door.CFrame = CFrame.new(centerX, groundY + (doorHeight / 2), centerZ)

    local window = door:FindFirstChild("Window")
    if window and not window:IsA("Part") then
      window.Name = "Window_Unexpected"
      window = nil
    end
    if not window then
      window = Instance.new("Part")
      window.Name = "Window"
      window.Parent = door
    end
    BuilderUtil.applyPhysics(window, false, false, true)
    window.Size = Vector3.new(doorWidth * 0.6, doorHeight * 0.4, wallThickness * 0.5)
    window.Material = Enum.Material.Glass
    window.Transparency = 0.5
    window.BrickColor = BrickColor.new("Light blue")
    window.CFrame = door.CFrame * CFrame.new(0, doorHeight * 0.15, 0)

    local weld = window:FindFirstChildOfClass("WeldConstraint")
    if not weld then
      weld = Instance.new("WeldConstraint")
      weld.Parent = window
    end
    weld.Part0 = door
    weld.Part1 = window

    local hingeOffset = Vector3.new(-doorWidth / 2, 0, 0)
    local openCFrame = door.CFrame
      * CFrame.new(hingeOffset)
      * CFrame.Angles(0, math.rad(90 * (swingDir or 1)), 0)
      * CFrame.new(-hingeOffset)

    door:SetAttribute("ClosedCFrame", door.CFrame)
    door:SetAttribute("OpenCFrame", openCFrame)
    door:SetAttribute("IsOpen", false)
    BuilderUtil.applyTag(door, constants.TAGS.SchoolDoor)
  end

  local entranceDoorWidth = 6
  local entranceDoorHeight = 9
  makeDoorFrame(schoolModel, "Entrance", schoolCenter.X, frontZ, entranceDoorWidth, entranceDoorHeight)
  makeDoor(schoolModel, "EntranceDoor", schoolCenter.X, frontZ, entranceDoorWidth, entranceDoorHeight, 1)

  local roomWidth = floorSize.X / 4
  local doorWidth = 4
  local doorHeight = 8
  local wallSegmentIndex = 1
  local leftEdge = schoolCenter.X - (floorSize.X / 2)
  local rightEdge = schoolCenter.X + (floorSize.X / 2)
  local currentX = leftEdge

  for i = 1, 4 do
    local roomCenterX = schoolCenter.X - (floorSize.X / 2) + (roomWidth / 2) + (roomWidth * (i - 1))
    local doorLeft = roomCenterX - (doorWidth / 2)
    local doorRight = roomCenterX + (doorWidth / 2)

    local segmentWidth = doorLeft - currentX
    if segmentWidth > 0 then
      local segment = BuilderUtil.findOrCreatePart(schoolModel, "HallWallSegment" .. wallSegmentIndex, "Part")
      wallSegmentIndex += 1
      BuilderUtil.applyPhysics(segment, true, true, false)
      segment.Size = Vector3.new(segmentWidth, wallHeight, wallThickness)
      segment.Position = Vector3.new((currentX + doorLeft) / 2, groundY + (wallHeight / 2), hallBackZ)
      segment.Material = Enum.Material.SmoothPlastic
      segment.BrickColor = BrickColor.new("Light stone grey")
    end

    makeDoorFrame(schoolModel, "Room" .. i, roomCenterX, hallBackZ, doorWidth, doorHeight)
    makeDoor(schoolModel, "RoomDoor" .. i, roomCenterX, hallBackZ, doorWidth, doorHeight, 1)

    currentX = doorRight
  end

  local tailWidth = rightEdge - currentX
  if tailWidth > 0 then
    local segment = BuilderUtil.findOrCreatePart(schoolModel, "HallWallSegment" .. wallSegmentIndex, "Part")
    BuilderUtil.applyPhysics(segment, true, true, false)
    segment.Size = Vector3.new(tailWidth, wallHeight, wallThickness)
    segment.Position = Vector3.new((currentX + rightEdge) / 2, groundY + (wallHeight / 2), hallBackZ)
    segment.Material = Enum.Material.SmoothPlastic
    segment.BrickColor = BrickColor.new("Light stone grey")
  end

  for i = 1, 3 do
    local wall = BuilderUtil.findOrCreatePart(schoolModel, "RoomDivider" .. i, "Part")
    BuilderUtil.applyPhysics(wall, true, true, false)
    wall.Size = Vector3.new(wallThickness, wallHeight, backZ - hallBackZ)
    wall.Position = Vector3.new(
      schoolCenter.X - (floorSize.X / 2) + (i * roomWidth),
      groundY + (wallHeight / 2),
      hallBackZ + ((backZ - hallBackZ) / 2)
    )
    wall.Material = Enum.Material.SmoothPlastic
    wall.BrickColor = BrickColor.new("Light stone grey")
  end

  local roomModel = BuilderUtil.findOrCreateModel(schoolModel, "Rooms")
  local roomNumbers = { "100", "101", "102", "103" }
  for i = 1, 4 do
    local roomCenterX = schoolCenter.X - (floorSize.X / 2) + (roomWidth / 2) + (roomWidth * (i - 1))
    local room = BuilderUtil.findOrCreatePart(roomModel, "Room" .. roomNumbers[i], "Part")
    BuilderUtil.applyPhysics(room, true, true, false)
    room.Size = Vector3.new(roomWidth - 2, 1, (backZ - hallBackZ) - 2)
    room.Position = Vector3.new(roomCenterX, groundY + 0.5, hallBackZ + ((backZ - hallBackZ) / 2))
    room.Material = Enum.Material.SmoothPlastic
    room.BrickColor = BrickColor.new("Ghost grey")
    ensureSurfaceLabel(room, roomNumbers[i])
  end
end

return SchoolBuilder
