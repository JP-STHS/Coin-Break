local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LevelManager = require(
    game:GetService("ServerScriptService")
        :WaitForChild("Server")
        :WaitForChild("LevelManager")
)

local spawnEvent = ReplicatedStorage:WaitForChild("SpawnLevelRequest")

local levelsCompleted = 0
local bossUnlocked = false

local function unlockBossPortal()

    local portal = workspace:WaitForChild("Portal")
    local partchange = portal:WaitForChild("Door")
    local windparent = portal:WaitForChild("HighPolyBeveledBrick")
    local effect = windparent:WaitForChild("wind")
    partchange.CanTouch = true
    partchange.Transparency = 0
    effect.Enabled = true
    print("Boss portal unlocked!")
    local touched = false

    partchange.Touched:Connect(function(hit)

        if touched then return end

        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if not player then return end

        touched = true

        print("Boss portal touched — spawning boss level")

        LevelManager.SpawnLevel("Boss")

    end)

end

spawnEvent.OnServerEvent:Connect(function(player, rarity)
    print("SERVER received rarity:", rarity)

    print("About to call SpawnLevel")
    LevelManager.SpawnLevel(rarity)
    print("SpawnLevel finished")

    levelsCompleted += 1

    print("Levels completed:", levelsCompleted)

    if levelsCompleted >= 2 and not bossUnlocked then

        bossUnlocked = true

        unlockBossPortal()

    end

end)