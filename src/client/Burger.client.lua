-- BurgerIngredients Script
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Point these to your 3 parts
local bun    = workspace:WaitForChild("Bun")
local patty  = workspace:WaitForChild("Meat")
local lettuce = workspace:WaitForChild("Lettuce")

-- BindableEvent to tell the dialogue script ingredients are collected
local ingredientsEvent = Instance.new("BindableEvent")
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
        ingredientsEvent:Fire(player)
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
end)

patty:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
    local c = getCollected(player)
    if c.patty then return end
    c.patty = true
    print(player.Name .. " picked up patty")
    checkAllCollected(player)
end)

lettuce:WaitForChild("ProximityPrompt").Triggered:Connect(function(player)
    local c = getCollected(player)
    if c.lettuce then return end
    c.lettuce = true
    print(player.Name .. " picked up lettuce")
    checkAllCollected(player)
end)