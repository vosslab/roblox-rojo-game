local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local InputController = {}

local remotes = nil

local function connectPrompt(prompt)
  if not prompt or not prompt:IsA("ProximityPrompt") then
    return
  end

  prompt.Triggered:Connect(function()
    local target = prompt.Parent
    if target and CollectionService:HasTag(target, Constants.TAGS.QuestButton) then
      remotes.RequestInteract:FireServer(target, "SwingPush")
    end
  end)
end

function InputController.Init(remoteTable)
  remotes = {
    RequestInteract = remoteTable.RequestInteract,
    RequestTurn = remoteTable.RequestTurn,
  }

  for _, instance in ipairs(CollectionService:GetTagged(Constants.TAGS.QuestButton)) do
    local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
      connectPrompt(prompt)
    end
  end

  workspace.DescendantAdded:Connect(function(child)
    if child:IsA("ProximityPrompt") and child.Parent and CollectionService:HasTag(child.Parent, Constants.TAGS.QuestButton) then
      connectPrompt(child)
    end
  end)

  UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
      return
    end

    if input.KeyCode == Enum.KeyCode.A then
      remotes.RequestTurn:FireServer(-1)
    elseif input.KeyCode == Enum.KeyCode.D then
      remotes.RequestTurn:FireServer(1)
    end
  end)
end

return InputController
