local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local ArrowController = {}

local arrowGui = nil

local function ensureArrow(screenGui)
  arrowGui = screenGui:FindFirstChild("YellowArrow")
  if not arrowGui then
    arrowGui = Instance.new("BillboardGui")
    arrowGui.Name = "YellowArrow"
    arrowGui.Size = UDim2.new(0, 60, 0, 60)
    arrowGui.StudsOffset = Vector3.new(0, 5, 0)
    arrowGui.AlwaysOnTop = true
    arrowGui.Parent = screenGui
  end

  local arrowLabel = arrowGui:FindFirstChild("ArrowLabel")
  if not arrowLabel then
    arrowLabel = Instance.new("TextLabel")
    arrowLabel.Name = "ArrowLabel"
    arrowLabel.Size = UDim2.new(1, 0, 1, 0)
    arrowLabel.BackgroundTransparency = 1
    arrowLabel.TextColor3 = Color3.fromRGB(255, 230, 0)
    arrowLabel.Font = Enum.Font.SourceSansBold
    arrowLabel.TextSize = 48
    arrowLabel.Text = "^"
    arrowLabel.Parent = arrowGui
  end
end

local function findTargetByName(targetName)
  if targetName == "" then
    return nil
  end

  for _, target in ipairs(CollectionService:GetTagged(Constants.TAGS.QuestTarget)) do
    if target.Name == targetName then
      return target
    end
  end

  return workspace:FindFirstChild(targetName, true)
end

function ArrowController.Init(screenGui)
  ensureArrow(screenGui)
end

function ArrowController.SetTarget(instance)
  if not arrowGui then
    return
  end
  arrowGui.Adornee = instance
  arrowGui.Enabled = instance ~= nil
end

function ArrowController.SetTargetByName(targetName)
  local target = findTargetByName(targetName)
  ArrowController.SetTarget(target)
end

return ArrowController
