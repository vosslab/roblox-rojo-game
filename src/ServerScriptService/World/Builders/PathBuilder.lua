local BuilderUtil = require(script.Parent.BuilderUtil)

local PathBuilder = {}

function PathBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local pathModel = BuilderUtil.findOrCreateModel(playground, constants.NAMES.Path)
  local pathSegments = 6
  local PATH_W = 10
  local PATH_H = 1
  local PATH_L = 8
  local PATH_GAP = 0.5
  local stepDistance = PATH_L + PATH_GAP
  local startPos = Vector3.new(context.homeSpawn.Position.X, context.surfaceY + 0.5, context.homeSpawn.Position.Z)
  local endPos = Vector3.new(context.playgroundCenter.X, context.surfaceY + 0.5, context.playgroundCenter.Z)
  local pathAxis = (endPos - startPos).Unit

  local lastPos = nil
  local secondLastPos = nil
  for i = 1, pathSegments do
    local segmentName = "PathSegment" .. i
    local segment = BuilderUtil.findOrCreatePart(pathModel, segmentName, "Part")
    BuilderUtil.applyPhysics(segment, true, true, false)
    segment.Size = Vector3.new(PATH_W, PATH_H, PATH_L)
    segment.Material = Enum.Material.Concrete
    segment.BrickColor = BrickColor.new("Medium stone grey")
    local centerPos = startPos + (pathAxis * (stepDistance * i))
    segment.CFrame = CFrame.new(centerPos)
    secondLastPos = lastPos
    lastPos = centerPos
  end

  if secondLastPos and lastPos then
    print("[Path] Last two segment centers:", secondLastPos, lastPos)
  end
end

return PathBuilder
