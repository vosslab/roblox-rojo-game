local BuilderUtil = require(script.Parent.BuilderUtil)

local DoorBuilder = {}

DoorBuilder.TYPES = {
  AutoSlide = "auto_slide",
  AutoSwing = "auto_swing",
  PromptSlide = "prompt_slide",
  PromptSwing = "prompt_swing",
}

local function setCFrame(part, baseCFrame, localPosition)
  part.CFrame = baseCFrame * CFrame.new(localPosition)
end

local function doorAxisVector(axis, distance)
  if axis == "x" then
    return Vector3.new(distance, 0, 0)
  end
  return Vector3.new(0, 0, distance)
end

function DoorBuilder.setDoorFrames(door, openCFrame, doorGroup, tag, autoDistance)
  if not door then
    return
  end
  door:SetAttribute("ClosedCFrame", door.CFrame)
  door:SetAttribute("OpenCFrame", openCFrame)
  door:SetAttribute("IsOpen", false)
  if doorGroup then
    door:SetAttribute("DoorGroup", doorGroup)
  else
    door:SetAttribute("DoorGroup", nil)
  end
  if autoDistance then
    door:SetAttribute("AutoDistance", autoDistance)
  end
  if tag then
    BuilderUtil.applyTag(door, tag)
  end
end

function DoorBuilder.getSlideOpenCFrame(door, axis, distance, sign)
  if not door then
    return nil
  end
  local offset = doorAxisVector(axis, distance * (sign or 1))
  return door.CFrame * CFrame.new(offset)
end

function DoorBuilder.getHingeOpenCFrame(door, axis, width, hingeSide, swingDir, angle)
  if not door then
    return nil
  end
  local hingeOffset = width / 2
  if hingeSide and string.lower(tostring(hingeSide)) == "left" then
    hingeOffset = -hingeOffset
  end
  local hingeVector = doorAxisVector(axis, hingeOffset)
  local swingAngle = math.rad((angle or 90) * (swingDir or 1))
  return door.CFrame
    * CFrame.new(hingeVector)
    * CFrame.Angles(0, swingAngle, 0)
    * CFrame.new(-hingeVector)
end

function DoorBuilder.enableAutoSlide(door, axis, distance, sign, autoDistance, tag)
  local openCFrame = DoorBuilder.getSlideOpenCFrame(door, axis, distance, sign)
  DoorBuilder.setDoorFrames(door, openCFrame, nil, tag, autoDistance)
end

function DoorBuilder.enableAutoSwing(
  door,
  axis,
  width,
  hingeSide,
  swingDir,
  angle,
  autoDistance,
  tag
)
  local openCFrame =
    DoorBuilder.getHingeOpenCFrame(door, axis, width, hingeSide, swingDir, angle)
  DoorBuilder.setDoorFrames(door, openCFrame, nil, tag, autoDistance)
end

function DoorBuilder.enablePromptDoor(door, openCFrame, doorGroup, tag)
  DoorBuilder.setDoorFrames(door, openCFrame, doorGroup, tag, nil)
end

function DoorBuilder.buildFrame(
  model,
  namePrefix,
  centerX,
  centerZ,
  doorWidth,
  doorHeight,
  style,
  wallThickness,
  baseCFrame
)
  if not model or not baseCFrame then
    return
  end

  local sideThickness = 0.4
  local topThickness = 0.4
  local frameDepth = wallThickness + 0.2

  local left = BuilderUtil.findOrCreatePart(model, namePrefix .. "FrameLeft", "Part")
  local right = BuilderUtil.findOrCreatePart(model, namePrefix .. "FrameRight", "Part")
  local top = BuilderUtil.findOrCreatePart(model, namePrefix .. "FrameTop", "Part")
  BuilderUtil.applyPhysics(left, true, true, false)
  BuilderUtil.applyPhysics(right, true, true, false)
  BuilderUtil.applyPhysics(top, true, true, false)

  left.Size = Vector3.new(sideThickness, doorHeight, frameDepth)
  right.Size = Vector3.new(sideThickness, doorHeight, frameDepth)
  top.Size = Vector3.new(doorWidth + (sideThickness * 2), topThickness, frameDepth)

  setCFrame(
    left,
    baseCFrame,
    Vector3.new(centerX - (doorWidth / 2) - (sideThickness / 2), doorHeight / 2, centerZ)
  )
  setCFrame(
    right,
    baseCFrame,
    Vector3.new(centerX + (doorWidth / 2) + (sideThickness / 2), doorHeight / 2, centerZ)
  )
  setCFrame(top, baseCFrame, Vector3.new(centerX, doorHeight + (topThickness / 2), centerZ))

  left.Material = Enum.Material.SmoothPlastic
  right.Material = Enum.Material.SmoothPlastic
  top.Material = Enum.Material.SmoothPlastic
  if style and style.accentColor then
    left.BrickColor = style.accentColor
    right.BrickColor = style.accentColor
    top.BrickColor = style.accentColor
  end
end

return DoorBuilder
