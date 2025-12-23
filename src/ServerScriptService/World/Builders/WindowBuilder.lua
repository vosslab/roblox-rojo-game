local BuilderUtil = require(script.Parent.BuilderUtil)

local WindowBuilder = {}

local function ensurePart(parent, name, oldName)
  local part = parent:FindFirstChild(name)
  if part and not part:IsA("BasePart") then
    part.Name = name .. "_Unexpected"
    part = nil
  end
  if not part and oldName then
    part = parent:FindFirstChild(oldName)
    if part and part:IsA("BasePart") then
      part.Name = name
    else
      if part then
        part.Name = oldName .. "_Unexpected"
      end
      part = nil
    end
  end
  if not part then
    part = Instance.new("Part")
    part.Name = name
    part.Parent = parent
  end
  return part
end

local function ensureWeld(part, parent)
  local weld = part:FindFirstChildOfClass("WeldConstraint")
  if not weld then
    weld = Instance.new("WeldConstraint")
    weld.Parent = part
  end
  weld.Part0 = parent
  weld.Part1 = part
end

function WindowBuilder.buildPanelWindow(model, name, cframe, size, style)
  if not model or not cframe or not size then
    return nil
  end

  local window = BuilderUtil.findOrCreatePart(model, name, "Part")
  BuilderUtil.applyPhysics(window, true, false, false)
  window.Size = size
  window.CFrame = cframe
  window.Material = (style and style.material) or Enum.Material.Glass
  window.Transparency = (style and style.transparency) or 0.4
  window.BrickColor = (style and style.color) or BrickColor.new("Light blue")
  return window
end

function WindowBuilder.buildSixPaneWindow(parent, name, windowCFrame, windowSize, style)
  if not parent or not name or not windowCFrame or not windowSize or not style then
    return nil
  end

  local frameThickness = math.min(windowSize.X, windowSize.Y) * 0.08
  local mullionThickness = frameThickness * 0.8
  local frameDepth = windowSize.Z

  local windowModel = BuilderUtil.findOrCreateModel(parent, name)

  local function styleFrame(part)
    BuilderUtil.applyPhysics(part, true, false, true)
    part.Material = Enum.Material.SmoothPlastic
    part.BrickColor = style.frameColor
  end

  local glass = BuilderUtil.findOrCreatePart(windowModel, "Glass", "Part")
  BuilderUtil.applyPhysics(glass, true, false, true)
  glass.Size = Vector3.new(
    windowSize.X - (frameThickness * 2),
    windowSize.Y - (frameThickness * 2),
    math.max(0.2, frameDepth * 0.6)
  )
  glass.Material = Enum.Material.Glass
  glass.Transparency = style.glassTransparency
  glass.BrickColor = style.glassColor
  glass.CFrame = windowCFrame

  local top = BuilderUtil.findOrCreatePart(windowModel, "FrameTop", "Part")
  local bottom = BuilderUtil.findOrCreatePart(windowModel, "FrameBottom", "Part")
  local left = BuilderUtil.findOrCreatePart(windowModel, "FrameLeft", "Part")
  local right = BuilderUtil.findOrCreatePart(windowModel, "FrameRight", "Part")
  styleFrame(top)
  styleFrame(bottom)
  styleFrame(left)
  styleFrame(right)
  top.Size = Vector3.new(windowSize.X, frameThickness, frameDepth)
  bottom.Size = Vector3.new(windowSize.X, frameThickness, frameDepth)
  local sideHeight = windowSize.Y - (frameThickness * 2)
  left.Size = Vector3.new(frameThickness, sideHeight, frameDepth)
  right.Size = Vector3.new(frameThickness, sideHeight, frameDepth)
  top.CFrame = windowCFrame * CFrame.new(0, (windowSize.Y / 2) - (frameThickness / 2), 0)
  bottom.CFrame = windowCFrame * CFrame.new(0, -(windowSize.Y / 2) + (frameThickness / 2), 0)
  left.CFrame = windowCFrame * CFrame.new(-(windowSize.X / 2) + (frameThickness / 2), 0, 0)
  right.CFrame = windowCFrame * CFrame.new((windowSize.X / 2) - (frameThickness / 2), 0, 0)

  local mullionV = BuilderUtil.findOrCreatePart(windowModel, "MullionV", "Part")
  styleFrame(mullionV)
  mullionV.Size = Vector3.new(mullionThickness, glass.Size.Y, frameDepth)
  mullionV.CFrame = windowCFrame

  local mullionH1 = BuilderUtil.findOrCreatePart(windowModel, "MullionH1", "Part")
  local mullionH2 = BuilderUtil.findOrCreatePart(windowModel, "MullionH2", "Part")
  styleFrame(mullionH1)
  styleFrame(mullionH2)
  mullionH1.Size = Vector3.new(glass.Size.X, mullionThickness, frameDepth)
  mullionH2.Size = Vector3.new(glass.Size.X, mullionThickness, frameDepth)
  local offsetY = glass.Size.Y / 6
  mullionH1.CFrame = windowCFrame * CFrame.new(0, offsetY, 0)
  mullionH2.CFrame = windowCFrame * CFrame.new(0, -offsetY, 0)
end

function WindowBuilder.buildSixPaneInset(basePart, namePrefix, size, offset, depth, style)
  if not basePart or not namePrefix or not size or not offset or not depth or not style then
    return nil
  end

  local glass = ensurePart(basePart, namePrefix .. "Glass", "Window")
  BuilderUtil.applyPhysics(glass, false, false, true)
  glass.Size = Vector3.new(size.X, size.Y, depth)
  glass.Material = Enum.Material.Glass
  glass.Transparency = style.glassTransparency
  glass.BrickColor = style.glassColor
  glass.CFrame = basePart.CFrame * CFrame.new(offset)
  ensureWeld(glass, basePart)

  local mullionThickness = math.min(size.X, size.Y) * 0.08

  local mullionV = BuilderUtil.findOrCreatePart(basePart, namePrefix .. "MullionV", "Part")
  BuilderUtil.applyPhysics(mullionV, false, false, true)
  mullionV.Size = Vector3.new(mullionThickness, size.Y, depth)
  mullionV.Material = Enum.Material.SmoothPlastic
  mullionV.BrickColor = style.frameColor
  mullionV.CFrame = basePart.CFrame * CFrame.new(offset)
  ensureWeld(mullionV, basePart)

  local mullionH1 = BuilderUtil.findOrCreatePart(basePart, namePrefix .. "MullionH1", "Part")
  local mullionH2 = BuilderUtil.findOrCreatePart(basePart, namePrefix .. "MullionH2", "Part")
  BuilderUtil.applyPhysics(mullionH1, false, false, true)
  BuilderUtil.applyPhysics(mullionH2, false, false, true)
  mullionH1.Size = Vector3.new(size.X, mullionThickness, depth)
  mullionH2.Size = Vector3.new(size.X, mullionThickness, depth)
  mullionH1.Material = Enum.Material.SmoothPlastic
  mullionH2.Material = Enum.Material.SmoothPlastic
  mullionH1.BrickColor = style.frameColor
  mullionH2.BrickColor = style.frameColor

  local offsetY = size.Y / 6
  mullionH1.CFrame = basePart.CFrame * CFrame.new(offset + Vector3.new(0, offsetY, 0))
  mullionH2.CFrame = basePart.CFrame * CFrame.new(offset + Vector3.new(0, -offsetY, 0))
  ensureWeld(mullionH1, basePart)
  ensureWeld(mullionH2, basePart)
end

return WindowBuilder
