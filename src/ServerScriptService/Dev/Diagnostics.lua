local RunService = game:GetService("RunService")

local Diagnostics = {}

function Diagnostics.Init()
  if not RunService:IsStudio() then
    return
  end
  print("[Diagnostics] Dev tools enabled.")
end

return Diagnostics
