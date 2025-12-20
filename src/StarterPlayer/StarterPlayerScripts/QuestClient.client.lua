-- QuestClient.client.lua
-- Client-side UI, arrow target, and input capture for Q1_PLAYGROUND.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RequestInteract = remotesFolder:WaitForChild("RequestInteract")
local RequestTurn = remotesFolder:WaitForChild("RequestTurn")
local QuestStateUpdated = remotesFolder:WaitForChild("QuestStateUpdated")
local ShowToast = remotesFolder:WaitForChild("ShowToast")
local ShowAgeSplash = remotesFolder:WaitForChild("ShowAgeSplash")

local playerGui = player:WaitForChild("PlayerGui")

-- UI setup (uses existing StarterGui/QuestGui if present, otherwise creates it)
local screenGui = playerGui:FindFirstChild("QuestGui")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
end

local questLabel = screenGui:FindFirstChild("QuestTextLabel")
if not questLabel then
	questLabel = Instance.new("TextLabel")
	questLabel.Name = "QuestTextLabel"
	questLabel.Size = UDim2.new(0, 320, 0, 90)
	questLabel.Position = UDim2.new(0, 10, 0, 10)
	questLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	questLabel.BackgroundTransparency = 0.2
	questLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	questLabel.Font = Enum.Font.SourceSansBold
	questLabel.TextSize = 18
	questLabel.TextXAlignment = Enum.TextXAlignment.Left
	questLabel.TextYAlignment = Enum.TextYAlignment.Top
	questLabel.Parent = screenGui
end
questLabel.Text = "Objective: ...\nSwing pushes: 0/10\nSpin time: 0/20s"

local toastLabel = screenGui:FindFirstChild("ToastLabel")
if not toastLabel then
	toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "ToastLabel"
	toastLabel.Size = UDim2.new(0, 240, 0, 40)
	toastLabel.Position = UDim2.new(0.5, -120, 0, 120)
	toastLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
	toastLabel.Font = Enum.Font.SourceSansBold
	toastLabel.TextSize = 20
	toastLabel.Text = ""
	toastLabel.Visible = false
	toastLabel.Parent = screenGui
end

local ageSplash = screenGui:FindFirstChild("AgeSplash")
if not ageSplash then
	ageSplash = Instance.new("TextLabel")
	ageSplash.Name = "AgeSplash"
	ageSplash.Size = UDim2.new(0, 360, 0, 80)
	ageSplash.Position = UDim2.new(0.5, -180, 0.5, -40)
	ageSplash.BackgroundColor3 = Color3.fromRGB(255, 245, 200)
	ageSplash.BackgroundTransparency = 0.1
	ageSplash.TextColor3 = Color3.fromRGB(30, 30, 30)
	ageSplash.Font = Enum.Font.SourceSansBold
	ageSplash.TextSize = 28
	ageSplash.Text = ""
	ageSplash.Visible = false
	ageSplash.Parent = screenGui
end

-- Yellow arrow billboard that points to the current quest target
local arrowGui = screenGui:FindFirstChild("YellowArrow")
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

local function findTargetByName(targetName)
	if targetName == "" then
		return nil
	end

	for _, target in ipairs(CollectionService:GetTagged("QuestTarget")) do
		if target.Name == targetName then
			return target
		end
	end
	return workspace:FindFirstChild(targetName, true)
end

local function updateArrowTarget(targetName)
	local target = findTargetByName(targetName)
	arrowGui.Adornee = target
	arrowGui.Enabled = target ~= nil
end

local function showToast(message)
	toastLabel.Text = message or ""
	toastLabel.Visible = true
	task.delay(2, function()
		toastLabel.Visible = false
	end)
end

local function showAgeSplash(title)
	ageSplash.Text = title or ""
	ageSplash.Visible = true
	task.delay(3, function()
		ageSplash.Visible = false
	end)
end

QuestStateUpdated.OnClientEvent:Connect(function(objectiveText, swingCount, swingGoal, spinTime, spinGoal, targetName)
	local swingLine = string.format("Swing pushes: %d/%d", swingCount or 0, swingGoal or 10)
	local spinLine = string.format("Spin time: %d/%ds", math.floor(spinTime or 0), spinGoal or 20)
	questLabel.Text = string.format("Objective: %s\n%s\n%s", objectiveText or "", swingLine, spinLine)

	updateArrowTarget(targetName or "")
end)

ShowToast.OnClientEvent:Connect(showToast)
ShowAgeSplash.OnClientEvent:Connect(showAgeSplash)

-- ProximityPrompt interactions for the swing push button
local function connectPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end

	prompt.Triggered:Connect(function()
		local target = prompt.Parent
		if target and CollectionService:HasTag(target, "QuestButton") then
			RequestInteract:FireServer(target, "SwingPush")
		end
	end)
end

for _, instance in ipairs(CollectionService:GetTagged("QuestButton")) do
	local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		connectPrompt(prompt)
	end
end

workspace.DescendantAdded:Connect(function(child)
	if child:IsA("ProximityPrompt") and child.Parent and CollectionService:HasTag(child.Parent, "QuestButton") then
		connectPrompt(child)
	end
end)

-- Input capture for merry-go-round turning
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.A then
		RequestTurn:FireServer(-1)
	elseif input.KeyCode == Enum.KeyCode.D then
		RequestTurn:FireServer(1)
	end
end)
