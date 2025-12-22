local CityLayout = require(script.Parent.CityLayout)

local LayoutUtil = {}

LayoutUtil.LAYER_UNIT = 0.2
LayoutUtil.LAYERS = {
  baseplate = 0,
  asphalt = 1,
  room_floor = 2,
}

function LayoutUtil.getGroundY(baseplate)
  if not baseplate then
    return nil
  end
  return baseplate.Position.Y + (baseplate.Size.Y / 2)
end

function LayoutUtil.getLayerOffset(layerKey)
  local layer = LayoutUtil.LAYERS[layerKey]
  if not layer then
    return 0
  end
  return layer * LayoutUtil.LAYER_UNIT
end

function LayoutUtil.getLayerY(baseplate, layerKey)
  local groundY = LayoutUtil.getGroundY(baseplate)
  if not groundY then
    return nil
  end
  return groundY + LayoutUtil.getLayerOffset(layerKey)
end

function LayoutUtil.getSurfaceY(baseplate, thickness)
  local groundY = LayoutUtil.getGroundY(baseplate)
  if not groundY then
    return nil
  end
  return groundY + (thickness or 0)
end

function LayoutUtil.getTopSurfaceY(referencePart, gap)
  if not referencePart or not referencePart:IsA("BasePart") then
    return nil
  end
  return referencePart.Position.Y + (referencePart.Size.Y / 2) + (gap or 0)
end

function LayoutUtil.getStackedCenterY(referencePart, height, gap)
  if not height then
    return nil
  end
  local topY = LayoutUtil.getTopSurfaceY(referencePart, gap)
  if not topY then
    return nil
  end
  return topY + (height / 2)
end

function LayoutUtil.placeAbove(referencePart, position, height, gap)
  if not position or not height then
    return nil
  end
  local centerY = LayoutUtil.getStackedCenterY(referencePart, height, gap)
  if not centerY then
    return nil
  end
  return Vector3.new(position.X, centerY, position.Z)
end

function LayoutUtil.anchor(layout, zoneName, side, offset)
  if not layout then
    return nil
  end
  return CityLayout.getZoneAnchor(layout, zoneName, side, offset)
end

function LayoutUtil.placeOnSurface(position, surfaceY, yOffset)
  if not position or not surfaceY then
    return nil
  end
  return Vector3.new(position.X, surfaceY + (yOffset or 0), position.Z)
end

return LayoutUtil
