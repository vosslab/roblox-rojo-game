local BuilderUtil = require(script.Parent.BuilderUtil)

local TycoonBuilder = {}

function TycoonBuilder.Build(_playground, constants)
  local context = BuilderUtil.getPlaygroundContext(constants)
  if not context then
    return
  end

  local houseModel = BuilderUtil.findOrCreateModel(workspace, constants.NAMES.HouseModel)
  local houseBase = BuilderUtil.findOrCreatePart(houseModel, constants.NAMES.HouseBase, "Part")
  BuilderUtil.applyPhysics(houseBase, true, true, false)
  houseBase.Size = Vector3.new(12, 6, 12)
  houseBase.Material = Enum.Material.SmoothPlastic
  houseBase.BrickColor = BrickColor.new("Bright yellow")
  houseBase.CFrame = CFrame.new(
    Vector3.new(
      context.homeSpawn.Position.X - 24,
      context.groundY + (houseBase.Size.Y / 2),
      context.homeSpawn.Position.Z + 12
    )
  )

  local coinFolder = BuilderUtil.findOrCreateFolder(workspace, constants.NAMES.CoinSpawners)
  local coinPositions = {
    houseBase.Position + Vector3.new(10, 1, 0),
    houseBase.Position + Vector3.new(-10, 1, 0),
    houseBase.Position + Vector3.new(0, 1, 10),
    houseBase.Position + Vector3.new(0, 1, -10),
  }
  for index, pos in ipairs(coinPositions) do
    local coin = BuilderUtil.findOrCreatePart(coinFolder, "Coin" .. index, "Part")
    BuilderUtil.applyPhysics(coin, true, false, false)
    coin.Size = Vector3.new(1, 1, 1)
    coin.Shape = Enum.PartType.Ball
    coin.Material = Enum.Material.Neon
    coin.BrickColor = BrickColor.new("Bright yellow")
    coin.Position = pos
  end

  local upgradePad = BuilderUtil.findOrCreatePart(workspace, constants.NAMES.UpgradePad, "Part")
  BuilderUtil.applyPhysics(upgradePad, true, true, false)
  upgradePad.Size = Vector3.new(6, 1, 6)
  upgradePad.Material = Enum.Material.SmoothPlastic
  upgradePad.BrickColor = BrickColor.new("Bright green")
  upgradePad.Position = houseBase.Position + Vector3.new(0, 0.5, 10)
end

return TycoonBuilder
