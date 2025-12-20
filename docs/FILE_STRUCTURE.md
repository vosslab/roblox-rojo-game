# File structure

## Repository root
- `AGENTS.md`: agent instructions and workflow notes.
- `README.md`: project overview and quick start.
- `LICENSE`: licensing terms.
- `default.project.json`: Rojo project file.
- `docs/`: documentation.
- `src/`: Rojo-synced source tree (authoritative).

## src/
- `ServerScriptService/`: server entry and server-side modules.
  - `Main.server.lua`: server entry point (wires services).
  - `World/WorldBuilder.lua`: world geometry and required instances.
  - `Economy/`: coins, upgrades, and passive income.
  - `Quests/`: quest definitions and quest state logic.
  - `Persistence/`: DataStore load/save utilities.
  - `Dev/`: Studio-only diagnostics and validators (loaded only in Studio).
- `ReplicatedStorage/`:
  - `Shared/Constants.lua`: shared names, tags, and remote names.
  - `Shared/Types.lua`: optional shared type definitions.
  - `Shared/Util/`: tiny shared helpers safe for client/server.
  - `Remotes/`: RemoteEvents (authored in src when possible; created at runtime as fallback).
- `StarterPlayer/StarterPlayerScripts/`:
  - `ClientMain.client.lua`: client entry point.
  - `UI/`: quest UI and stats UI modules.
  - `Input/`: input capture and remote requests.
- `StarterGui/`: optional static UI instances (if authored).
- `Workspace/`: optional static world instances (if authored).

## docs/
- `CHANGELOG.md`: dated changes.
- `REPO_STYLE.md`: repo conventions.
- `ROBLOX_LUA_STYLE.md`: Luau conventions.
- `FILE_STRUCTURE.md`: this document.

## Generated assets
- Rojo sync artifacts are created by Roblox Studio at runtime and are not stored in git.
- Instances created by scripts (e.g., playground geometry, remotes) appear in Studio but not in `src/`.
