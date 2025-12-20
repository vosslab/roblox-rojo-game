# Testing

## Linting
- Install Selene: `brew install selene`.
- Run: `selene src`.
- Script: `tests/run-selene.sh`.

Configuration lives at `selene.toml`.

## Formatting
- Install StyLua: `brew install stylua`.
- Run: `stylua src`.
- Script: `tests/run-stylua.sh`.

Configuration lives at `stylua.toml`.

## Unit tests
- Install Lune: `brew install lune`.
- Run: `lune run tests/run.luau`.
- Script: `tests/run-lune-tests.sh`.

Notes:
- TestEZ is vendored under `src/ReplicatedStorage/TestEZ`.
- Tests live under `src/ServerScriptService/**/__tests__`.
- The `tests.luau` runner builds a minimal in-memory tree for logic tests.
