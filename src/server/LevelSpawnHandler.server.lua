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

    local character = hit:FindFirstAncestorOfClass("Model")
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if hit ~= root then return end

    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end

    touched = true
    partchange.CanTouch = false

    print("Boss portal touched — spawning boss level")
    LevelManager.SpawnLevel("Boss")

    local bossLevel = workspace:WaitForChild("SpawnedLevels"):WaitForChild("BossLevel")
    local portal2 = bossLevel:WaitForChild("Portal2")
    local spawn = portal2:WaitForChild("playerspot")

    print("Boss spawn position:", spawn.Position)

    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")

    root.CFrame = spawn.CFrame

    task.wait(0.2) -- let position replicate

    ReplicatedStorage
        :WaitForChild("BossLevelReady")
        :FireClient(player)

end)

end

spawnEvent.OnServerEvent:Connect(function(player, rarity)
    print("SERVER received rarity:", rarity)

    print("About to call SpawnLevel")
    LevelManager.SpawnLevel(rarity)
    print("SpawnLevel finished")

    levelsCompleted += 1

    print("Levels completed:", levelsCompleted)

    if levelsCompleted >= 1 and not bossUnlocked then

        bossUnlocked = true

        unlockBossPortal()

    end

end)