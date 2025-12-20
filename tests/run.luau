-- Lune-native tests entrypoint (filesystem require, no ModuleScript require)

local Constants = require("../src/ReplicatedStorage/Shared/Constants")
assert(Constants ~= nil, "Failed to load Constants")

local TableUtil = require("../src/ReplicatedStorage/Shared/Util/Table")
assert(TableUtil ~= nil, "Failed to load Table util")

print("[Lune] Smoke tests passed")
