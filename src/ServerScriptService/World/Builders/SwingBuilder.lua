local BuilderUtil = require(script.Parent.BuilderUtil)

local SwingBuilder = {}

function SwingBuilder.Build(playground, constants)
  if not playground then
    return
  end

  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local groundY = context.surfaceY
  local playgroundCenter = context.playgroundCenter

  local swingArea = BuilderUtil.findOrCreatePart(playground, constants.NAMES.SwingArea, "Part")
  BuilderUtil.applyPhysics(swingArea, true, true, false)
  swingArea.Size = Vector3.new(20, 1, 20)
  swingArea.CFrame = CFrame.new(Vector3.new(playgroundCenter.X, groundY + 0.5, playgroundCenter.Z))
  swingArea.Material = Enum.Material.SmoothPlastic
  swingArea.BrickColor = BrickColor.new("Sand yellow")
  BuilderUtil.applyTag(swingArea, constants.TAGS.QuestTarget)

  local swingSeat = BuilderUtil.findOrCreatePart(playground, constants.NAMES.SwingSeat, "Seat")
  BuilderUtil.applyPhysics(swingSeat, false, true, false)
  swingSeat.Size = Vector3.new(2, 1, 2)
  swingSeat.BrickColor = BrickColor.new("Bright blue")
  BuilderUtil.applyTag(swingSeat, constants.TAGS.QuestMount)

  local pushButton = BuilderUtil.findOrCreatePart(playground, constants.NAMES.PushButton, "Part")
  BuilderUtil.applyPhysics(pushButton, true, true, false)
  pushButton.Size = Vector3.new(2, 1, 2)
  pushButton.CFrame =
    CFrame.new(Vector3.new(swingArea.Position.X + 6, groundY + 0.5, swingArea.Position.Z))
  pushButton.Material = Enum.Material.SmoothPlastic
  pushButton.BrickColor = BrickColor.new("Bright green")
  BuilderUtil.applyTag(pushButton, constants.TAGS.QuestButton)

  local prompt = pushButton:FindFirstChildOfClass("ProximityPrompt")
  if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.Parent = pushButton
  end
  prompt.ActionText = "Push"
  prompt.ObjectText = "Swing"
  prompt.KeyboardKeyCode = Enum.KeyCode.E
  prompt.HoldDuration = 0

  local swingSet = BuilderUtil.findOrCreateModel(playground, constants.NAMES.SwingSet)
  local leftPost = BuilderUtil.findOrCreatePart(swingSet, "SwingPostLeft", "Part")
  local rightPost = BuilderUtil.findOrCreatePart(swingSet, "SwingPostRight", "Part")
  local topBar = BuilderUtil.findOrCreatePart(swingSet, constants.NAMES.SwingTopBar, "Part")

  BuilderUtil.applyPhysics(leftPost, true, true, false)
  BuilderUtil.applyPhysics(rightPost, true, true, false)
  BuilderUtil.applyPhysics(topBar, true, true, false)

  local beamHeight = 10
  local beamLength = 12
  local swingSetCenter = Vector3.new(swingArea.Position.X, groundY, swingArea.Position.Z - 4)
  local ropeLength = 6

  leftPost.Size = Vector3.new(1, beamHeight, 1)
  rightPost.Size = Vector3.new(1, beamHeight, 1)
  topBar.Size = Vector3.new(beamLength, 1, 1)

  leftPost.CFrame = CFrame.new(
    Vector3.new(
      swingSetCenter.X - (beamLength / 2) + 1,
      groundY + (beamHeight / 2),
      swingSetCenter.Z
    )
  )
  rightPost.CFrame = CFrame.new(
    Vector3.new(
      swingSetCenter.X + (beamLength / 2) - 1,
      groundY + (beamHeight / 2),
      swingSetCenter.Z
    )
  )
  topBar.CFrame = CFrame.new(Vector3.new(swingSetCenter.X, groundY + 10, swingSetCenter.Z))

  leftPost.Material = Enum.Material.Metal
  rightPost.Material = Enum.Material.Metal
  topBar.Material = Enum.Material.Metal

  leftPost.BrickColor = BrickColor.new("Dark stone grey")
  rightPost.BrickColor = BrickColor.new("Dark stone grey")
  topBar.BrickColor = BrickColor.new("Dark stone grey")

  swingSeat.CFrame = CFrame.new(Vector3.new(topBar.Position.X, groundY + 2.5, topBar.Position.Z))

  local ropeTopLeft =
    BuilderUtil.findOrCreateAttachment(topBar, "RopeTopLeft", Vector3.new(-1.5, -1.5, 0))
  local ropeTopRight =
    BuilderUtil.findOrCreateAttachment(topBar, "RopeTopRight", Vector3.new(1.5, -1.5, 0))
  local ropeSeatLeft =
    BuilderUtil.findOrCreateAttachment(swingSeat, "RopeSeatLeft", Vector3.new(-0.5, 0.5, 0))
  local ropeSeatRight =
    BuilderUtil.findOrCreateAttachment(swingSeat, "RopeSeatRight", Vector3.new(0.5, 0.5, 0))

  local ropeLeft = topBar:FindFirstChild("RopeLeft")
  if not ropeLeft or not ropeLeft:IsA("RopeConstraint") then
    if ropeLeft then
      ropeLeft.Name = "RopeLeft_Unexpected"
    end
    ropeLeft = Instance.new("RopeConstraint")
    ropeLeft.Name = "RopeLeft"
    ropeLeft.Parent = topBar
  end
  ropeLeft.Attachment0 = ropeTopLeft
  ropeLeft.Attachment1 = ropeSeatLeft
  ropeLeft.Length = ropeLength
  ropeLeft.Visible = true
  ropeLeft.Thickness = 0.05

  local ropeRight = topBar:FindFirstChild("RopeRight")
  if not ropeRight or not ropeRight:IsA("RopeConstraint") then
    if ropeRight then
      ropeRight.Name = "RopeRight_Unexpected"
    end
    ropeRight = Instance.new("RopeConstraint")
    ropeRight.Name = "RopeRight"
    ropeRight.Parent = topBar
  end
  ropeRight.Attachment0 = ropeTopRight
  ropeRight.Attachment1 = ropeSeatRight
  ropeRight.Length = ropeLength
  ropeRight.Visible = true
  ropeRight.Thickness = 0.05

  local hingeTop = BuilderUtil.findOrCreateAttachment(
    topBar,
    "HingeTop",
    Vector3.new(0, -1.5, 0),
    Vector3.new(1, 0, 0),
    Vector3.new(0, 1, 0)
  )
  local hingeSeat = BuilderUtil.findOrCreateAttachment(
    swingSeat,
    "HingeSeat",
    Vector3.new(0, 0.5, 0),
    Vector3.new(1, 0, 0),
    Vector3.new(0, 1, 0)
  )

  local hinge = topBar:FindFirstChild("SwingHinge")
  if not hinge or not hinge:IsA("HingeConstraint") then
    if hinge then
      hinge.Name = "SwingHinge_Unexpected"
    end
    hinge = Instance.new("HingeConstraint")
    hinge.Name = "SwingHinge"
    hinge.Parent = topBar
  end
  hinge.Attachment0 = hingeTop
  hinge.Attachment1 = hingeSeat
end

return SwingBuilder
