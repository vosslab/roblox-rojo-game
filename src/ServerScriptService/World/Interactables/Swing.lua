-- Swing.lua
-- Server-side swing interactable:
-- - Ensures the swing looks correct (hinge + visible ropes, stable seat)
-- - Applies push impulse to the seat assembly (not the rider)

local Swing = {}

local constants = nil
local playground = nil

local lastPushTime = {}

local PUSH_DEBOUNCE = 0.35
local PUSH_FORCE = 18
local MAX_SWING_SPEED = 40

local DEBUG = false

local function dprint(...)
  if DEBUG then
    print("[Swing]", ...)
  end
end

local function getCharacterHumanoid(player)
  local character = player.Character
  if not character then
    return nil
  end
  return character:FindFirstChildOfClass("Humanoid")
end

local function isSeatedOn(player, seat)
  local humanoid = getCharacterHumanoid(player)
  if not humanoid then
    return false
  end
  return humanoid.SeatPart == seat and seat.Occupant == humanoid
end

local function findDescendant(root, name)
  return root and root:FindFirstChild(name, true) or nil
end

local function ensureAttachment(parent, name, position)
  local att = parent:FindFirstChild(name)
  if att and att:IsA("Attachment") then
    return att
  end

  att = Instance.new("Attachment")
  att.Name = name
  att.Position = position or Vector3.zero
  att.Parent = parent
  return att
end

local function ensureHinge(topBeam, seat)
  local hinge = topBeam:FindFirstChild("SwingHinge")
  if hinge and hinge:IsA("HingeConstraint") then
    return hinge
  end

  local topAtt = ensureAttachment(topBeam, "SwingHingeTop", Vector3.new(0, 0, 0))
  local seatAtt = ensureAttachment(seat, "SwingHingeSeat", Vector3.new(0, 0.5, 0))

  hinge = Instance.new("HingeConstraint")
  hinge.Name = "SwingHinge"
  hinge.Attachment0 = topAtt
  hinge.Attachment1 = seatAtt
  hinge.LimitsEnabled = false
  hinge.ActuatorType = Enum.ActuatorType.None
  hinge.Parent = topBeam

  return hinge
end

local function ensureRopes(topBeam, seat, seatWidthStuds)
  seatWidthStuds = seatWidthStuds or seat.Size.X

  local leftX = -math.max(0.5, seatWidthStuds * 0.4)
  local rightX = math.max(0.5, seatWidthStuds * 0.4)

  local topLeft = ensureAttachment(topBeam, "RopeTopLeft", Vector3.new(leftX, 0, 0))
  local topRight = ensureAttachment(topBeam, "RopeTopRight", Vector3.new(rightX, 0, 0))

  local seatLeft = ensureAttachment(seat, "RopeSeatLeft", Vector3.new(leftX, 0.45, 0))
  local seatRight = ensureAttachment(seat, "RopeSeatRight", Vector3.new(rightX, 0.45, 0))

  local function ensureRope(name, a0, a1)
    local rope = topBeam:FindFirstChild(name)
    if rope and rope:IsA("RopeConstraint") then
      rope.Attachment0 = a0
      rope.Attachment1 = a1
      return rope
    end

    rope = Instance.new("RopeConstraint")
    rope.Name = name
    rope.Attachment0 = a0
    rope.Attachment1 = a1
    rope.Visible = true
    rope.Thickness = 0.1
    rope.Length = math.max(3, (a0.WorldPosition - a1.WorldPosition).Magnitude)
    rope.Parent = topBeam
    return rope
  end

  ensureRope("SwingRopeLeft", topLeft, seatLeft)
  ensureRope("SwingRopeRight", topRight, seatRight)
end

local function applySeatDefaults(seat)
  seat.Anchored = false
  seat.CanCollide = true

  -- Lower friction makes sliding on/off easier and reduces sideways "stick".
  -- Lower elasticity avoids bouncy behavior.
  seat.CustomPhysicalProperties = PhysicalProperties.new(1, 0.2, 0, 1, 1)

  -- Kill any initial spin from placement.
  seat.AssemblyAngularVelocity = Vector3.zero
end

local function computePushDirection(seat)
  local v = seat.AssemblyLinearVelocity
  local speed = v.Magnitude

  if speed >= 1 then
    return v.Unit
  end

  -- Fallback direction when starting from rest:
  -- use RightVector as the swing forward axis (matches most simple swing builds).
  return seat.CFrame.RightVector
end

local function applyPush(seat)
  local direction = computePushDirection(seat)
  local v = seat.AssemblyLinearVelocity
  local newV = v + direction * PUSH_FORCE

  local mag = newV.Magnitude
  if mag > MAX_SWING_SPEED then
    newV = newV.Unit * MAX_SWING_SPEED
  end

  seat.AssemblyLinearVelocity = newV
end

local function getObjects()
  if not constants or not playground then
    return nil
  end

  local seat = findDescendant(playground, constants.NAMES.SwingSeat)
  if not seat or not seat:IsA("Seat") then
    return nil
  end

  -- Prefer an explicit top beam name, else try known fallbacks.
  local topBeam = findDescendant(playground, "SwingTopBeam")
  if (not topBeam or not topBeam:IsA("BasePart")) and constants and constants.NAMES then
    topBeam = findDescendant(playground, constants.NAMES.SwingTopBar)
  end
  if not topBeam or not topBeam:IsA("BasePart") then
    topBeam = findDescendant(playground, "TopBeam")
  end
  if not topBeam or not topBeam:IsA("BasePart") then
    return {
      swingSeat = seat,
      topBeam = nil,
    }
  end

  return {
    swingSeat = seat,
    topBeam = topBeam,
  }
end

function Swing.Init(playgroundModel, constantsModule)
  playground = playgroundModel
  constants = constantsModule
  lastPushTime = {}

  local objects = getObjects()
  if not objects or not objects.swingSeat then
    warn("[Swing] Missing SwingSeat.")
    return
  end

  applySeatDefaults(objects.swingSeat)

  if objects.topBeam then
    ensureHinge(objects.topBeam, objects.swingSeat)
    ensureRopes(objects.topBeam, objects.swingSeat, objects.swingSeat.Size.X)
    dprint("Configured hinge and ropes.")
  else
    warn("[Swing] Missing top beam (SwingTopBeam or TopBeam). Swing will move but may look wrong.")
  end
end

function Swing.Push(player)
  local objects = getObjects()
  if not objects or not objects.swingSeat then
    return false
  end

  if not isSeatedOn(player, objects.swingSeat) then
    return false
  end

  local now = os.clock()
  local last = lastPushTime[player]
  if last and (now - last) < PUSH_DEBOUNCE then
    return false
  end
  lastPushTime[player] = now

  applyPush(objects.swingSeat)
  return true
end

return Swing
