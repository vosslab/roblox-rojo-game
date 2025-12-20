local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(shared:WaitForChild("Constants"))

local InputController = {}

local remotes = nil

local function connectPrompt(prompt)
  if not prompt or not prompt:IsA("ProximityPrompt") then
    return
  end

  prompt.Triggered:Connect(function()
    local target = prompt.Parent
    if prompt.Name == "SpinPrompt" then
      remotes.RequestInteract:FireServer(target, "SpinMerryGoRound")
      return
    end

    if target and CollectionService:HasTag(target, Constants.TAGS.QuestButton) then
      remotes.RequestInteract:FireServer(target, "SwingPush")
    end
  end)
end

function InputController.Init(remoteTable)
  remotes = {
    RequestInteract = remoteTable.RequestInteract,
  }

  for _, instance in ipairs(CollectionService:GetTagged(Constants.TAGS.QuestButton)) do
    local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
      connectPrompt(prompt)
    end
  end

  for _, prompt in ipairs(workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") and prompt.Name == "SpinPrompt" then
      connectPrompt(prompt)
    end
  end

  workspace.DescendantAdded:Connect(function(child)
    if
      child:IsA("ProximityPrompt")
      and child.Parent
      and CollectionService:HasTag(child.Parent, Constants.TAGS.QuestButton)
    then
      connectPrompt(child)
    end
    if child:IsA("ProximityPrompt") and child.Name == "SpinPrompt" then
      connectPrompt(child)
    end
  end)
end

return InputController
