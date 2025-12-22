# Code architecture

## Overview
- The world is built server-side by `WorldBuilder.lua`, which calls geometry builders.
- Builders create and update Models/Parts only. Interactables handle input and movement.
- Shared names and tags live in `src/ReplicatedStorage/Shared/Constants.lua`.

## Core toolkits

### BuilderUtil
- Location: `src/ServerScriptService/World/Builders/BuilderUtil.lua`.
- Role: Shared builder plumbing for idempotent creation and context lookup.
- Responsibilities:
  - Find or create models, parts, folders, and attachments by name.
  - Apply physics defaults in one place (anchored, can collide, massless).
  - Fetch the baseplate and home spawn safely.
  - Build a shared playground context (ground/surface Y, layout, centers).
- When to use:
  - Any time you need to create or reuse a part or model.
  - Any time you need consistent physics settings for static geometry.
  - Any time you need the baseplate or HomeSpawn.
- Notes:
  - All builder modules should be idempotent. Use find-or-create helpers so repeated builds
    update instead of duplicate.
  - The playground context is the standard way to get `groundY`, `surfaceY`, and `layout`.

### CityLayout
- Location: `src/ServerScriptService/World/Builders/CityLayout.lua`.
- Role: Top level city zoning and spacing.
- Responsibilities:
  - Define zone centers for major areas (spawn, playground, school, gas, shopping, neighborhood).
  - Define zone footprints (width and length) for layout spacing.
  - Provide anchors and bounds for connecting areas without overlap.
- Key API:
  - `getLayout(baseplate)`: returns centers, zone sizes, and facing vectors.
  - `getZoneBounds(layout, zoneName)`: returns center, size, min, max for a zone footprint.
  - `getZoneAnchor(layout, zoneName, side, offset)`: returns edge anchor on a zone.
  - `getZoneFootprints(layout)`: map of all zone bounds.
  - `getOverlaps(layout)`: list of overlapping zones for debugging.
- When to use:
  - Any placement that depends on spacing between major areas.
  - Paths or links between zones (spawn to playground, school to plaza, etc).
- Non-goals:
  - Does not place internal building geometry, windows, or room walls.

### LayoutUtil
- Location: `src/ServerScriptService/World/Builders/LayoutUtil.lua`.
- Role: Small helper layer for height and anchor math.
- Responsibilities:
  - Compute ground and surface Y using the baseplate.
  - Provide a thin wrapper for CityLayout anchors.
  - Normalize positioning on the surface for consistent Y offsets.
  - Provide shared layer offsets to reduce z-fighting on stacked floors.
- Key API:
  - `getGroundY(baseplate)`.
  - `getLayerOffset(layerKey)` and `getLayerY(baseplate, layerKey)`.
  - `getSurfaceY(baseplate, thickness)`.
  - `anchor(layout, zoneName, side, offset)`.
  - `placeOnSurface(position, surfaceY, yOffset)`.
  - `getTopSurfaceY(referencePart, gap)`, `getStackedCenterY(referencePart, height, gap)`.
  - `placeAbove(referencePart, position, height, gap)`.
- When to use:
  - Any time you need to align a part to the baseplate surface.
  - Any time you need a stable anchor on a zone edge.
  - Any time you need a stable vertical layer (baseplate, asphalt, room floor).

### WallBuilder
- Location: `src/ServerScriptService/World/Builders/WallBuilder.lua`.
- Role: Modular wall segments with openings.
- Responsibilities:
  - Build a wall along a single axis (x or z) with any number of openings.
  - Add lintels and sills around openings.
  - Return opening frames so doors or windows can be placed precisely.
- Key inputs:
  - `center`: world-space center of the wall.
  - `length`, `height`, `thickness`.
  - `axis`: "x" for east-west walls, "z" for north-south walls.
  - `openings`: table (or list) with `width`, `height`, `bottom`, and `offset`.
- Outputs:
  - Array of opening frames with `cframe`, `normal`, `width`, and `height`.
- When to use:
  - Any wall that needs a window, door, or large opening.
  - Any time doors must align with a real wall gap.

### RoomBuilder
- Location: `src/ServerScriptService/World/Builders/RoomBuilder.lua`.
- Role: Build a rectangular shell using WallBuilder on all four sides.
- Responsibilities:
  - Compose north, south, east, and west walls.
  - Accept per-side openings and pass them to WallBuilder.
  - Return opening frame lists by side for door/window placement.
- When to use:
  - Simple building shells or rooms that are axis-aligned.
  - Any structure that needs consistent door or window openings on multiple sides.
- Notes:
  - `RoomBuilder.buildWalls` returns a table keyed by side name with opening frames.

## World building pattern
- `WorldBuilder.lua` is the orchestrator; each builder exports `Build(playground, constants)`.
- Builders should be idempotent: find existing items by name and update them in place.
- Geometry stays in Builders; movement/interaction goes in Interactables.

## Height layers
- LayoutUtil defines shared layer offsets for stacked surfaces:
  - `baseplate` = 0
  - `asphalt` = 1
  - `room_floor` = 2
- `LayoutUtil.LAYER_UNIT` defines the stud height for one layer (currently 0.2 studs).
- Use `getLayerOffset` and `getStackedCenterY` to avoid overlapping floors and z-fighting.

## Interactables
- Location: `src/ServerScriptService/World/Interactables/`.
- Handles prompts, physics movement, and gameplay input for doors, slides, swings, etc.
- Interactables assume their geometry exists and is named consistently.

## When to add a new toolkit
- If the same spatial pattern appears in two or more builders (walls, anchors, or repeated
  layouts), create a toolkit module to centralize it.
- Keep toolkits small, with simple inputs and predictable outputs.
