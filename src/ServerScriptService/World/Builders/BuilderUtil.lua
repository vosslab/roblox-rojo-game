local CollectionService = game:GetService("CollectionService")

local BuilderUtil = {}

BuilderUtil.SAND_THICKNESS = 1

function BuilderUtil.applyTag(instance, tag)
  if instance and not CollectionService:HasTag(instance, tag) then
    CollectionService:AddTag(instance, tag)
  end
end

function BuilderUtil.applyPhysics(part, anchored, canCollide, massless)
  if not part or not part:IsA("BasePart") then
    return
  end
  part.Anchored = anchored
  part.CanCollide = canCollide
  part.Massless = massless or false
end

function BuilderUtil.findOrCreateModel(parent, name)
  local model = parent:FindFirstChild(name)
  if model and not model:IsA("Model") then
    warn("[WorldBuilder] '" .. name .. "' exists but is not a Model. Renaming it.")
    model.Name = name .. "_Unexpected"
    model = nil
  end

  if not model then
    model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
  end

  return model
end

function BuilderUtil.findOrCreatePart(parent, name, className)
  local part = parent:FindFirstChild(name)
  if part and not part:IsA(className) then
    warn("[WorldBuilder] '" .. name .. "' exists but is not a " .. className .. ". Renaming it.")
    part.Name = name .. "_Unexpected"
    part = nil
  end

  if not part then
    part = Instance.new(className)
    part.Name = name
    part.Parent = parent
  end

  return part
end

function BuilderUtil.findOrCreateFolder(parent, name)
  local folder = parent:FindFirstChild(name)
  if folder and not folder:IsA("Folder") then
    warn("[WorldBuilder] '" .. name .. "' exists but is not a Folder. Renaming it.")
    folder.Name = name .. "_Unexpected"
    folder = nil
  end

  if not folder then
    folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
  end

  return folder
end

function BuilderUtil.findOrCreateAttachment(parent, name, position, axis, secondaryAxis)
  local attachment = parent:FindFirstChild(name)
  if attachment and not attachment:IsA("Attachment") then
    warn("[WorldBuilder] '" .. name .. "' exists but is not an Attachment. Renaming it.")
    attachment.Name = name .. "_Unexpected"
    attachment = nil
  end

  if not attachment then
    attachment = Instance.new("Attachment")
    attachment.Name = name
    attachment.Parent = parent
  end

  if position then
    attachment.Position = position
  end
  if axis then
    attachment.Axis = axis
  end
  if secondaryAxis then
    attachment.SecondaryAxis = secondaryAxis
  end

  return attachment
end

function BuilderUtil.getBaseplateAndSpawn(constants)
  local baseplate = workspace:FindFirstChild(constants.NAMES.Baseplate)
  local homeSpawn = workspace:FindFirstChild(constants.NAMES.HomeSpawn)
  if not baseplate or not baseplate:IsA("BasePart") then
    return nil, nil
  end
  if not homeSpawn or not homeSpawn:IsA("SpawnLocation") then
    return nil, nil
  end
  return baseplate, homeSpawn
end

function BuilderUtil.getPlaygroundContext(constants)
  local baseplate, homeSpawn = BuilderUtil.getBaseplateAndSpawn(constants)
  if not baseplate or not homeSpawn then
    return nil
  end

  local groundY = baseplate.Position.Y + (baseplate.Size.Y / 2)
  local surfaceY = groundY + BuilderUtil.SAND_THICKNESS
  local playgroundCenter = Vector3.new(homeSpawn.Position.X + 80, groundY, homeSpawn.Position.Z)

  return {
    baseplate = baseplate,
    homeSpawn = homeSpawn,
    groundY = groundY,
    surfaceY = surfaceY,
    playgroundCenter = playgroundCenter,
    sandThickness = BuilderUtil.SAND_THICKNESS,
  }
end

return BuilderUtil
