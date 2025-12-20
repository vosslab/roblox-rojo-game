local BuilderUtil = require(script.Parent.BuilderUtil)

local BaseplateBuilder = {}

function BaseplateBuilder.Build(_playgroundModel, constants)
  local baseplate = BuilderUtil.findOrCreatePart(workspace, constants.NAMES.Baseplate, "Part")
  BuilderUtil.applyPhysics(baseplate, true, true, false)
  baseplate.Size = Vector3.new(768, 10, 768)
  baseplate.Position = Vector3.new(0, -5, 0)
  baseplate.Material = Enum.Material.Grass
  baseplate.BrickColor = BrickColor.new("Medium green")

  local spawn = BuilderUtil.findOrCreatePart(workspace, constants.NAMES.HomeSpawn, "SpawnLocation")
  BuilderUtil.applyPhysics(spawn, true, true, false)
  local topY = baseplate.Position.Y + (baseplate.Size.Y / 2)
  spawn.Position = Vector3.new(0, topY + 3, 0)

  return baseplate, spawn
end

return BaseplateBuilder
