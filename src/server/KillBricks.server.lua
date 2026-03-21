local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local KILL_TAG = "KillBrick"

local function setupKillBrick(part)
    part.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end)
end

-- Handle all existing kill bricks
for _, part in ipairs(CollectionService:GetTagged(KILL_TAG)) do
    setupKillBrick(part)
end

-- Handle any kill bricks added later (e.g. spawned during gameplay)
CollectionService:GetInstanceAddedSignal(KILL_TAG):Connect(setupKillBrick)