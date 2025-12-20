local MerryGoRound = {}

local constants = nil
local playground = nil

local merryAngularSpeed = 0
local pushTimes = {}
local lastPrintSecond = nil

local DEBUG_MERRY = false

local PUSH_DEBOUNCE = 0.35
local SPEED_INCREMENT = 2.0
local MAX_SPEED = 12
local FRICTION = 0.96
local STOP_THRESHOLD = 0.05

local function isValidSeat(seat)
  return seat and seat:IsA("Seat")
end

local function getObjects()
  if not constants then
    return nil
  end

  if not playground then
    playground = workspace:FindFirstChild(constants.NAMES.Playground)
  end
  if not playground then
    return nil
  end

  local merryModel = playground:FindFirstChild(constants.NAMES.MerryGoRound)
  if not merryModel then
    return nil
  end

  local merryBase = merryModel:FindFirstChild(constants.NAMES.MerryGoRoundBase)
  local merrySeat = merryModel:FindFirstChild(constants.NAMES.MerryGoRoundSeat)
  if not merryBase or not isValidSeat(merrySeat) then
    return nil
  end

  return {
    merryModel = merryModel,
    merryBase = merryBase,
    merrySeat = merrySeat,
  }
end

local function isSeatedOn(player, seat)
  if not player then
    return false
  end

  local character = player.Character
  if not character then
    return false
  end

  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    return false
  end

  return humanoid.SeatPart == seat and seat.Occupant == humanoid
end

function MerryGoRound.Init(playgroundModel, constantsModule, _remotes)
  constants = constantsModule
  playground = playgroundModel
  merryAngularSpeed = 0
  pushTimes = {}
  lastPrintSecond = nil
  if DEBUG_MERRY then
    print("[MerryGoRound] Update loop connected")
  end
end

function MerryGoRound.Push(player)
  local cached = getObjects()
  if not cached then
    return false
  end

  if not isSeatedOn(player, cached.merrySeat) then
    return false
  end

  local now = os.clock()
  local last = pushTimes[player]
  if last and (now - last) < PUSH_DEBOUNCE then
    return false
  end
  pushTimes[player] = now

  merryAngularSpeed = math.min(merryAngularSpeed + SPEED_INCREMENT, MAX_SPEED)
  if DEBUG_MERRY then
    print("SpinPush accepted", player.Name, "speed", merryAngularSpeed)
  end
  return true
end

function MerryGoRound.Update(dt)
  local cached = getObjects()
  if not cached then
    return
  end

  if math.abs(merryAngularSpeed) > 0 then
    local now = os.clock()
    local wholeSecond = math.floor(now)
    local doPrint = false
    if lastPrintSecond ~= wholeSecond then
      lastPrintSecond = wholeSecond
      doPrint = true
    end

    local center = cached.merryBase.Position
    local deltaAngle = merryAngularSpeed * dt

    if doPrint and DEBUG_MERRY then
      print("[MerryGoRound] rotating", merryAngularSpeed)
    end

    local marker = cached.merryModel:FindFirstChild("SpinMarker", true)
    if doPrint and DEBUG_MERRY and marker and marker:IsA("BasePart") then
      print("SpinMarker before", marker.Position)
    end

    if cached.merryModel.PrimaryPart then
      local baseCf = cached.merryBase.CFrame
      local newBase = CFrame.new(center)
        * CFrame.Angles(0, deltaAngle, 0)
        * CFrame.new(-center)
        * baseCf
      cached.merryModel:SetPrimaryPartCFrame(newBase)
    else
      local current = cached.merryModel:GetPivot()
      local rotated = CFrame.new(center)
        * CFrame.Angles(0, deltaAngle, 0)
        * CFrame.new(-center)
        * current
      cached.merryModel:PivotTo(rotated)
    end

    if doPrint and DEBUG_MERRY and marker and marker:IsA("BasePart") then
      print("SpinMarker after", marker.Position)
    end

    merryAngularSpeed = merryAngularSpeed * FRICTION
    if math.abs(merryAngularSpeed) < STOP_THRESHOLD then
      merryAngularSpeed = 0
    end
  end
end

function MerryGoRound.GetAngularSpeed()
  return merryAngularSpeed
end

function MerryGoRound.GetSeat()
  local cached = getObjects()
  return cached and cached.merrySeat or nil
end

function MerryGoRound.IsRiding(player)
  local cached = getObjects()
  if not cached then
    return false
  end

  return isSeatedOn(player, cached.merrySeat)
end

return MerryGoRound
