local QuestUI = {}

local screenGui = nil
local questLabel = nil
local toastLabel = nil
local ageSplash = nil

local function ensureGui(playerGui)
  screenGui = playerGui:FindFirstChild("QuestGui")
  if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "QuestGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
  end

  questLabel = screenGui:FindFirstChild("QuestTextLabel")
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

  toastLabel = screenGui:FindFirstChild("ToastLabel")
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

  ageSplash = screenGui:FindFirstChild("AgeSplash")
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
end

function QuestUI.Init(playerGui)
  ensureGui(playerGui)
  questLabel.Text = "Objective: ...\nSwing pushes: 0/10\nSpin time: 0/20s"
end

function QuestUI.SetQuestText(text)
  if questLabel then
    questLabel.Text = text
  end
end

function QuestUI.ShowToast(text, seconds)
  if not toastLabel then
    return
  end
  toastLabel.Text = text or ""
  toastLabel.Visible = true
  task.delay(seconds or 2, function()
    if toastLabel then
      toastLabel.Visible = false
    end
  end)
end

function QuestUI.ShowAgeSplash(text, seconds)
  if not ageSplash then
    return
  end
  ageSplash.Text = text or ""
  ageSplash.Visible = true
  task.delay(seconds or 3, function()
    if ageSplash then
      ageSplash.Visible = false
    end
  end)
end

function QuestUI.GetScreenGui()
  return screenGui
end

return QuestUI
