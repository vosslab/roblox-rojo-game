local RunService = game:GetService("RunService")

local OverlapValidator = {}

function OverlapValidator.Init()
  if not RunService:IsStudio() then
    return
  end
  print("[OverlapValidator] Ready.")
end

return OverlapValidator
