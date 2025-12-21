local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local SchoolDoors = {}

local constants = nil
local doorBusy = {}

local function getDoorCFrame(door, name)
  local value = door:GetAttribute(name)
  if typeof(value) == "CFrame" then
    return value
  end
  return nil
end

local function setPromptText(prompt, isOpen)
  prompt.ActionText = isOpen and "Close" or "Open"
  prompt.ObjectText = "Door"
end

local function setupDoor(door)
  if not door or not door:IsA("BasePart") then
    return
  end

  local prompt = door:FindFirstChild("DoorPrompt")
  if prompt and not prompt:IsA("ProximityPrompt") then
    prompt.Name = "DoorPrompt_Unexpected"
    prompt = nil
  end
  if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.Name = "DoorPrompt"
    prompt.Parent = door
  end

  prompt.ActionText = "Open"
  prompt.ObjectText = "Door"
  prompt.KeyboardKeyCode = Enum.KeyCode.E
  prompt.HoldDuration = 0.5
  prompt.MaxActivationDistance = 10

  if door:GetAttribute("IsOpen") == nil then
    door:SetAttribute("IsOpen", false)
  end

  if not getDoorCFrame(door, "ClosedCFrame") then
    door:SetAttribute("ClosedCFrame", door.CFrame)
  end

  prompt.Triggered:Connect(function()
    if doorBusy[door] then
      return
    end
    doorBusy[door] = true

    local isOpen = door:GetAttribute("IsOpen") == true
    local target = isOpen and getDoorCFrame(door, "ClosedCFrame") or getDoorCFrame(door, "OpenCFrame")
    if not target then
      doorBusy[door] = nil
      return
    end

    local tween = TweenService:Create(door, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
      CFrame = target,
    })
    tween:Play()
    tween.Completed:Once(function()
      door:SetAttribute("IsOpen", not isOpen)
      setPromptText(prompt, not isOpen)
      doorBusy[door] = nil
    end)
  end)
end

function SchoolDoors.Init(constantsModule)
  constants = constantsModule

  for _, door in ipairs(CollectionService:GetTagged(constants.TAGS.SchoolDoor)) do
    setupDoor(door)
  end

  CollectionService:GetInstanceAddedSignal(constants.TAGS.SchoolDoor):Connect(function(door)
    setupDoor(door)
  end)
end

return SchoolDoors
