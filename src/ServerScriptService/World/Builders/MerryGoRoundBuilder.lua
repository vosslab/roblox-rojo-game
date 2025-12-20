local BuilderUtil = require(script.Parent.BuilderUtil)

local MerryGoRoundBuilder = {}

function MerryGoRoundBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local GROUND_Y = context.surfaceY
  local merryModel = BuilderUtil.findOrCreateModel(playground, constants.NAMES.MerryGoRound)
  local baseCenter = Vector3.new(context.playgroundCenter.X + 30, GROUND_Y + 0.5, context.playgroundCenter.Z)

  local basePieces = BuilderUtil.findOrCreateModel(merryModel, constants.NAMES.MerryGoRoundBasePieces)
  for _, child in ipairs(basePieces:GetChildren()) do
    child:Destroy()
  end

  local baseRadius = 6
  for i = 1, 8 do
    local wedge = Instance.new("WedgePart")
    wedge.Name = "BaseWedge" .. i
    wedge.Parent = basePieces
    BuilderUtil.applyPhysics(wedge, true, true, false)
    wedge.Size = Vector3.new(6, 1, 6)
    wedge.Material = Enum.Material.SmoothPlastic
    wedge.BrickColor = BrickColor.new("Bright red")

    local angle = math.rad((i - 1) * 45)
    local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local position = baseCenter + (outward * baseRadius)
    wedge.CFrame = CFrame.lookAt(position, position + outward) * CFrame.Angles(0, math.rad(90), 0)
  end

  local merryBase = BuilderUtil.findOrCreatePart(merryModel, constants.NAMES.MerryGoRoundBase, "Part")
  BuilderUtil.applyPhysics(merryBase, true, false, false)
  merryBase.Size = Vector3.new(18, 1, 18)
  merryBase.CFrame = CFrame.new(baseCenter)
  merryBase.Transparency = 1
  merryBase.Material = Enum.Material.SmoothPlastic
  merryBase.BrickColor = BrickColor.new("Bright red")
  BuilderUtil.applyTag(merryBase, constants.TAGS.QuestTarget)
  merryModel.PrimaryPart = merryBase

  local spinPrompt = merryBase:FindFirstChild("SpinPrompt")
  if spinPrompt and not spinPrompt:IsA("ProximityPrompt") then
    spinPrompt.Name = "SpinPrompt_Unexpected"
    spinPrompt = nil
  end
  if not spinPrompt then
    spinPrompt = Instance.new("ProximityPrompt")
    spinPrompt.Name = "SpinPrompt"
    spinPrompt.Parent = merryBase
  end
  spinPrompt.ActionText = "Push"
  spinPrompt.ObjectText = "Merry-go-round"
  spinPrompt.KeyboardKeyCode = Enum.KeyCode.E
  spinPrompt.HoldDuration = 0
  spinPrompt.MaxActivationDistance = 10

  local merrySeat = BuilderUtil.findOrCreatePart(merryModel, constants.NAMES.MerryGoRoundSeat, "Seat")
  BuilderUtil.applyPhysics(merrySeat, false, true, false)
  merrySeat.Size = Vector3.new(2, 1, 2)
  merrySeat.CFrame = CFrame.new(baseCenter + Vector3.new(0, 1.5, 0))
  merrySeat.BrickColor = BrickColor.new("Bright yellow")
  BuilderUtil.applyTag(merrySeat, constants.TAGS.QuestMount)

  local spinMarker = BuilderUtil.findOrCreatePart(merryModel, "SpinMarker", "Part")
  BuilderUtil.applyPhysics(spinMarker, true, false, false)
  spinMarker.Size = Vector3.new(1, 0.5, 1)
  spinMarker.Position = baseCenter + Vector3.new(8, 1.25, 0)
  spinMarker.BrickColor = BrickColor.new("Pastel blue")
  if game:GetService("RunService"):IsStudio() then
    spinMarker.Transparency = 0.2
  else
    spinMarker.Transparency = 1
  end

  local weld = merrySeat:FindFirstChildOfClass("WeldConstraint")
  if not weld then
    weld = Instance.new("WeldConstraint")
    weld.Name = "SeatWeld"
    weld.Part0 = merryBase
    weld.Part1 = merrySeat
    weld.Parent = merrySeat
  end

  local poleModel = BuilderUtil.findOrCreateModel(merryModel, "Poles")
  local poleRadius = baseRadius + 3
  local poleHeight = 4
  local poleSize = Vector3.new(0.6, poleHeight, 0.6)
  for i = 1, 8 do
    local pole = BuilderUtil.findOrCreatePart(poleModel, "MerryPole" .. i, "Part")
    BuilderUtil.applyPhysics(pole, true, true, false)
    pole.Size = poleSize
    pole.Material = Enum.Material.Metal
    pole.BrickColor = BrickColor.new("Dark stone grey")

    local angle = math.rad((i - 1) * 45)
    local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local position = baseCenter + (outward * poleRadius)
    pole.Position = Vector3.new(position.X, baseCenter.Y + 0.5 + (poleHeight / 2), position.Z)
  end
end

return MerryGoRoundBuilder
