-- BurgerIngredients Script
-- Place in ServerScriptService
-- Moved from client to server to avoid inf yields

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")
-- get audio from toolbox
local audio = Instance.new("Sound")
audio.SoundId = "rbxassetid://17208396156"
audio.Volume = 0.5
audio.Parent = ReplicatedStorage

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
        checkAllCollected(player)
        audio:Play()  -- Play sound when bun is collected
        bun:WaitForChild("ProximityPrompt"):Destroy()
    end)

    patty:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
        local c = getCollected(player)
        if c.patty then return end
        c.patty = true
        print(player.Name .. " picked up patty")
        checkAllCollected(player)
        audio:Play()  -- Play sound when patty is collected
        patty:WaitForChild("ProximityPrompt"):Destroy()
    end)

    lettuce:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
        local c = getCollected(player)
        if c.lettuce then return end
        c.lettuce = true
        print(player.Name .. " picked up lettuce")
        checkAllCollected(player)
        audio:Play()  -- Play sound when lettuce is collected
        lettuce:WaitForChild("ProximityPrompt"):Destroy()
    end)
end)