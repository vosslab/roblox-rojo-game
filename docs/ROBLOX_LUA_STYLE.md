# ROBLOX_LUA_STYLE.md

## Goals
- Make code easy to read, easy to change, and hard to misuse.
- Prefer simple patterns over clever ones.
- Keep gameplay logic server authoritative.

## Language and naming
- Use Luau.
- Use PascalCase for module names and class-like tables: `QuestService`.
- Use camelCase for functions and locals: `getPlayerState`, `currentQuestId`.
- Use UPPER_SNAKE_CASE for constants: `DEFAULT_SAVE_INTERVAL_SEC`.
- Use descriptive names. Avoid `data`, `temp`, `thing`.

## File layout
- One responsibility per file.
- Prefer small modules over one giant script.
- Suggested top-level folders:
  - `ServerScriptService/Main.server.lua` for server entry.
  - `ServerScriptService/**` modules for services.
  - `ServerScriptService/World/WorldBuilder.lua` as the world orchestrator.
  - `ServerScriptService/World/Builders/**` for geometry-only builders (Parts, Models, folders).
  - `ServerScriptService/World/Interactables/**` for physics/controllers (no geometry creation).
  - `ReplicatedStorage/Shared/**` for shared constants and types.
  - `StarterPlayerScripts/ClientMain.client.lua` for client entry.
  - `StarterPlayerScripts/UI/**` for UI code.

## World building pattern
- Keep `WorldBuilder.lua` tiny: ensure the `Playground` model exists, then call sub-builders.
- Each builder exports a single function: `Build(playgroundModel, constants)`.
- Builders are idempotent: find by name, update or create, never duplicate.
- No gameplay logic inside builders. Only Instances and properties.
- Interactables assume geometry exists by name and handle physics/input only.

## Ordering inside a file
1) Services `local Players = game:GetService("Players")`
2) Requires
3) Constants
4) Private helpers
5) Public API
6) Return module

## Formatting
- Indent with 2 spaces.
- One statement per line.
- No semicolons.
- Keep lines under ~100 characters when reasonable.
- Use blank lines to separate logical blocks.

## Comments
- Comment intent, not mechanics.
- Good: `-- Server owns coins to prevent exploits`
- Avoid obvious: `-- Increment coins by 1`

## Roblox instance names
- Use explicit instance names and keep them stable.
- Centralize names and tags in a constants module where possible.
- Do not scatter string literals across the codebase.

## RemoteEvents and networking
- Client sends requests. Server validates. Server applies state changes.
- Never let the client set currency, stats, quest completion, or purchases.
- Validate on server:
  - Player exists
  - Character exists
  - Distance to target
  - Target tags
  - Cooldowns and debounces
- Remotes naming:
  - `Request*` for client to server.
  - `*Updated` for server to client state pushes.
  - `Show*` for server to client UI commands.

## State management
- Store per-player state in a server table keyed by `Player`.
- Clear state on `PlayerRemoving`.
- Keep state fields small and explicit:
  - `coins`, `age`, `smarts`, `fun`, `currentQuestId`, `subtasks`.
- Prefer Attributes for simple instance state when helpful, but keep the server table as the source of truth.

## Errors and defensive code
- Use `assert` for programmer errors in development.
- Use `warn` for recoverable runtime issues.
- Use `pcall` for DataStore calls.
- Do not crash the server for one player’s save failure.

## DataStore saving
- Save minimal data only.
- Throttle saves. Prefer periodic save plus on leave.
- Use a single key per player: `player.UserId`.
- Handle missing or partial data gracefully.
- Never kick players for save errors.

## Physics and constraints
- Anchor structural parts by default.
- For moving parts, use constraints and attachments.
- Avoid unanchored decorative parts unless necessary.

## UI
- UI logic stays on the client.
- UI reads state from server pushed events.
- Keep UI simple and readable. One screen, a few labels.

## Module interface conventions
- Each service module exposes:
  - `Init(remotes)` if it needs remotes
  - `Start()` if it needs to connect events
- Keep public functions small and predictable.
- Do not expose internal tables.

## Testing and debugging
- Keep Output open. Fix the first red error first.
- Use `print` for short tracing, remove or gate noisy prints.
- Prefer toggles:
  - `local DEBUG = true`
  - `if DEBUG then print(...) end`

## Safety checks checklist
- Any time you accept a client request:
  - Verify tags and distance
  - Debounce on server
  - Re-check required quest state
  - Apply changes on server only
  - Push updated state to client

## Style preference summary
- Clean names, small functions, clear module boundaries.
- Server authoritative gameplay.
- Minimal magic strings.
- Simple patterns that a grade school kid can follow with guidance.
