local ServerStorage = game:GetService("ServerStorage")

local LevelsFolder = ServerStorage:WaitForChild("Levels")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")
local LevelStartPoint = workspace:WaitForChild("LevelStartPoint")

local lastLevel = nil

local LevelManager = {}

function LevelManager.GetRandomLevel(rarity)

    local rarityFolder = LevelsFolder:FindFirstChild(rarity)

    if not rarityFolder then
        warn("Rarity folder not found:", rarity)
        return nil
    end

    local levels = rarityFolder:GetChildren()

    if #levels == 0 then
        warn("No levels in rarity:", rarity)
        return nil
    end

    return levels[math.random(1, #levels)]

end

function LevelManager.SpawnLevel(rarity)

    local levelTemplate = LevelManager.GetRandomLevel(rarity)

    if not levelTemplate then
        return
    end

    local newLevel = levelTemplate:Clone()
    newLevel.Parent = SpawnedLevels

    local newStart = newLevel:WaitForChild("Start")

    if lastLevel == nil then

        -- FIRST LEVEL
        local offset =
            LevelStartPoint.CFrame *
            newStart.CFrame:Inverse()

        newLevel:PivotTo(offset)

    else

        -- NEXT LEVELS
        local lastEnd = lastLevel:WaitForChild("End")

        local offset =
            lastEnd.CFrame *
            newStart.CFrame:Inverse()

        newLevel:PivotTo(offset)

    end

    lastLevel = newLevel

end

return LevelManager