local ServerStorage = game:GetService("ServerStorage")

local LevelsFolder = ServerStorage:WaitForChild("Levels")
local BossLevel = LevelsFolder:WaitForChild("Boss")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")
local LevelStartPoint = workspace:WaitForChild("LevelStartPoint")

local lastLevel = nil

local LevelManager = {}
math.randomseed(os.clock())
-- coin stuff
local CoinGiver = workspace:WaitForChild("CoinGiver")

-- function LevelManager.GetRandomLevel(rarity)

--     local rarityFolder = LevelsFolder:FindFirstChild(rarity)

--     if not rarityFolder then
--         warn("Rarity folder not found:", rarity)
--         return nil
--     end

--     local levels = rarityFolder:GetChildren()

--     if #levels == 0 then
--         warn("No levels in rarity:", rarity)
--         return nil
--     end

--     return levels[math.random(1, #levels)]

-- end
function LevelManager.GetRandomLevel(rarity)
    local forcedLevel = LevelsFolder:FindFirstChild("Level20", true)

    if forcedLevel then
        print("FORCING Level20 spawn")
        return forcedLevel
    else
        warn("Level20 not found anywhere in LevelsFolder")
        return nil
    end
end
function LevelManager.SpawnLevel(rarity)
    
    -- HANDLE BOSS PROPERLY
    if rarity == "Boss" then
        local bossTemplate = BossLevel:FindFirstChild("BossLevel")

        if not bossTemplate then
            warn("BossLevel not found in ServerStorage.Levels")
            return
        end

        local bossLevel = bossTemplate:Clone()
        bossLevel.Parent = SpawnedLevels

        print("Boss level spawned")

        return bossLevel -- IMPORTANT
    end
    local levelTemplate = LevelManager.GetRandomLevel(rarity)

    if not levelTemplate then
        warn("No level template found")
        return
    end

    local newLevel = levelTemplate:Clone()
    newLevel.Parent = SpawnedLevels
    -- print("Children inside level:")
    -- for _, obj in ipairs(newLevel:GetDescendants()) do
    --     print(obj.Name)
    -- end
    local newStart = newLevel:FindFirstChild("Start", true)

    if not newStart then
        warn("No Start part found in:", newLevel.Name)
        return
    end

    print("Spawning level:", newLevel.Name)

    if lastLevel == nil then

        print("FIRST LEVEL placement")

        local offset =
            LevelStartPoint.CFrame *
            (newLevel:GetPivot() * newStart.CFrame:Inverse())

        newLevel:PivotTo(offset)

    else

        print("STACKING onto previous level:", lastLevel.Name)

        local lastEnd = lastLevel:FindFirstChild("End", true)

        if not lastEnd then
            warn("No End part found in:", lastLevel.Name)

            local offset =
                LevelStartPoint.CFrame *
                (newLevel:GetPivot() * newStart.CFrame:Inverse())

            newLevel:PivotTo(offset)

            lastLevel = newLevel
            return
        end

        local offset =
            lastEnd.CFrame *
            (newLevel:GetPivot() * newStart.CFrame:Inverse())

        newLevel:PivotTo(offset)

    end

    lastLevel = newLevel
    local coinSpot = newLevel:FindFirstChild("CoinSpot", true)

    if coinSpot then
        print("Moving CoinGiver to:", coinSpot.Name)

        CoinGiver:PivotTo(coinSpot.CFrame)

    else
        warn("No CoinSpot found in:", newLevel.Name)
    end

end

return LevelManager