# Changelog

## 2025-12-20
- Refactor server and client code into modular services with clear entry points.
- Add shared constants for remotes, tags, and instance names.
- Preserve playground geometry fixes and quest/economy behavior under the new structure.
- Fix playground geometry: slide ramp slopes down from the platform, swing height is reachable, and path blocks have gaps.
- Rebuild merry-go-round base as an octagon with an invisible quest target part.
- Align sand, swing area, and merry-go-round to the ground surface for clean visuals.
- Add Selene and StyLua configs, a TestEZ vendor drop, and a Lune test runner.
- Add starter QuestService unit tests and a testing guide.
- Add `docs/FILE_STRUCTURE.md` with the repo layout and generated asset notes.
- Add a Playground bootstrap failsafe to rebuild world geometry if the main entrypoint fails.
- Add a merry-go-round spin prompt and server-driven spin control via E push.
- Add a visible spin marker and rotate the merry-go-round around the base center for clearer motion debugging.
- Refactor merry-go-round control into `World/Interactables/MerryGoRound.lua` to keep quest logic focused on progression.
- Remove stale playground caching for quest lookups and add rotation debug prints with SpinMarker position checks.
- Add safe requires in Main, fix ClientMain UI module requires, and make SaveService safe at require-time.
- Add Shared/Util and Shared/Types plus Dev diagnostics modules with Studio-only loading.
- Gate merry-go-round debug prints behind a debug flag, soften the spin marker, and tune spin impulse/friction.
