-- BurgerIngredients Script
-- Place in ServerScriptService
-- Moved from client to server to avoid inf yields

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")

SpawnedLevels.ChildAdded:Connect(function(level)
    if level.Name ~= "Level19" then return end

    print("Level19 spawned!")
-- Point these to your 3 parts
    local bun    = level:WaitForChild("Bun")
    local patty  = level:WaitForChild("Meat")
    local lettuce = level:WaitForChild("Lettuce")

    -- BindableEvent to tell the dialogue script ingredients are collected
    local ingredientsEvent = Instance.new("RemoteEvent")
    ingredientsEvent.Name   = "IngredientsCollected"
    ingredientsEvent.Parent = ReplicatedStorage

    -- Track which player has collected what
    local collected = {}  -- collected[player] = {bun, patty, lettuce}

    local function getCollected(player)
        if not collected[player] then
            collected[player] = {bun = false, patty = false, lettuce = false}
        end
        return collected[player]
    end

    local function checkAllCollected(player)
        local c = getCollected(player)
        if c.bun and c.patty and c.lettuce then
            print("[Burger] All ingredients collected !")
            ingredientsEvent:FireClient(player)
        end
    end

    -- Clean up when player leaves
    Players.PlayerRemoving:Connect(function(player)
        collected[player] = nil
    end)

    -- Hook up each ProximityPrompt
    bun:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
        local c = getCollected(player)
        if c.bun then return end  -- already collected
        c.bun = true
        print(player.Name .. " picked up bun")
        local bunprox = bun:WaitForChild("ProximityPrompt")
        bunprox.Enabled = false
        checkAllCollected(player)
    end)

    patty:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
        local c = getCollected(player)
        if c.patty then return end
        c.patty = true
        print(player.Name .. " picked up patty")
        local pattyprox = patty:WaitForChild("ProximityPrompt")
        pattyprox.Enabled = false
        checkAllCollected(player)
    end)

    lettuce:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
        local c = getCollected(player)
        if c.lettuce then return end
        c.lettuce = true
        print(player.Name .. " picked up lettuce")
        local lettuceprox = lettuce:WaitForChild("ProximityPrompt")
        lettuceprox.Enabled = false
        checkAllCollected(player)
    end)
end)