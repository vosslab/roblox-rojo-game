local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(shared:WaitForChild("Constants"))

local BuilderUtil = require(script.Parent.Builders.BuilderUtil)
local BaseplateBuilder = require(script.Parent.Builders.BaseplateBuilder)
local PlaygroundBuilder = require(script.Parent.Builders.PlaygroundBuilder)
local TycoonBuilder = require(script.Parent.Builders.TycoonBuilder)
local SwingBuilder = require(script.Parent.Builders.SwingBuilder)
local SlideBuilder = require(script.Parent.Builders.SlideBuilder)
local MerryGoRoundBuilder = require(script.Parent.Builders.MerryGoRoundBuilder)
local PathBuilder = require(script.Parent.Builders.PathBuilder)
local SchoolBuilder = require(script.Parent.Builders.SchoolBuilder)

local WorldBuilder = {}

function WorldBuilder.ensureBaseplateAndSpawn()
  return BaseplateBuilder.Build(nil, Constants)
end

function WorldBuilder.ensureRemotes()
  local remotesFolder = ReplicatedStorage:FindFirstChild(Constants.NAMES.Remotes)
  if remotesFolder and not remotesFolder:IsA("Folder") then
    warn("[WorldBuilder] Remotes exists but is not a Folder. Renaming it.")
    remotesFolder.Name = Constants.NAMES.Remotes .. "_Unexpected"
    remotesFolder = nil
  end

  if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = Constants.NAMES.Remotes
    remotesFolder.Parent = ReplicatedStorage
  end

  local remotes = {}
  for _, remoteName in pairs(Constants.REMOTES) do
    local remote = remotesFolder:FindFirstChild(remoteName)
    if remote and not remote:IsA("RemoteEvent") then
      warn(
        "[WorldBuilder] Remote '" .. remoteName .. "' exists but is not a RemoteEvent. Renaming it."
      )
      remote.Name = remoteName .. "_Unexpected"
      remote = nil
    end

    if not remote then
      remote = Instance.new("RemoteEvent")
      remote.Name = remoteName
      remote.Parent = remotesFolder
    end

    remotes[remoteName] = remote
  end

  return remotes
end

function WorldBuilder.ensurePlayground(_baseplate, _homeSpawn)
  local playground = BuilderUtil.findOrCreateModel(workspace, Constants.NAMES.Playground)

  PlaygroundBuilder.Build(playground, Constants)
  TycoonBuilder.Build(playground, Constants)
  SwingBuilder.Build(playground, Constants)
  SlideBuilder.Build(playground, Constants)
  MerryGoRoundBuilder.Build(playground, Constants)
  PathBuilder.Build(playground, Constants)
  SchoolBuilder.Build(playground, Constants)

  print("Playground rebuilt")
end

return WorldBuilder
