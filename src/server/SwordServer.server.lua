-- SwordServer (Script in ServerScriptService)


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Create the event on the server so it exists before the client looks for it
local swingEvent = Instance.new("RemoteEvent")
swingEvent.Name = "SwordSwing"
swingEvent.Parent = ReplicatedStorage
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")

print("Waiting for BossLevel...")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")
print("Waiting for BossLevel...")

local bossLevel

-- Check if already exists
for _, level in ipairs(SpawnedLevels:GetChildren()) do
    if level.Name == "BossLevel" then
        bossLevel = level
        break
    end
end

-- Wait specifically for BossLevel
if not bossLevel then
    repeat
        bossLevel = SpawnedLevels.ChildAdded:Wait()
    until bossLevel.Name == "BossLevel"
end
print("BossLevel detected")

local boss = bossLevel:WaitForChild("Boss1x")
local bossHumanoid = boss:WaitForChild("Humanoid")
local bossRootPart = boss:WaitForChild("HumanoidRootPart")

print("Boss locked:", boss:GetFullName())
print("Tracking boss at:", bossRootPart.Position)
swingEvent.OnServerEvent:Connect(function(player)
    print("[SwordServer]Swing event received from", player.Name)
end)
-- ============================================================
-- CONFIGURATION
-- ============================================================
local SWORD_REACH     = 10   -- studs — how close player needs to be to hit
local SWING_DAMAGE    = 5    -- damage per hit (adjust as needed)
local HIT_COOLDOWN    = 1    -- server-side cooldown per player (matches client)
-- ============================================================

-- Track hits per player for the boss fight stage system
-- Other scripts can read this
local HitTracker = {}
HitTracker.__index = HitTracker

-- BindableEvent so the boss fight script can listen for hits
local bossHitEvent = Instance.new("BindableEvent")
bossHitEvent.Name = "BossHit"
bossHitEvent.Parent = ServerStorage

local lastHitTime = {}  -- per player cooldown

swingEvent.OnServerEvent:Connect(function(player)
    -- Server side cooldown check
    local now = tick()
    if lastHitTime[player] and (now - lastHitTime[player]) < HIT_COOLDOWN then
        return  -- too fast, ignore
    end
    lastHitTime[player] = now

    -- Check if player is close enough to the boss
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = (root.Position - bossRootPart.Position).Magnitude

    print("[SwordServer]Distance to boss:", dist)

    if dist > SWORD_REACH then
        print("[SwordServer]Too far to hit")
        return
    end

    -- Check boss is still alive
    if bossHumanoid.Health <= 0 then return end

    -- Deal damage
    bossHumanoid:TakeDamage(SWING_DAMAGE)

    -- Fire hit event so boss fight script can track stage progress
    bossHitEvent:Fire(player)

    print(string.format("%s hit the boss! Boss HP: %.0f", player.Name, bossHumanoid.Health))
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    lastHitTime[player] = nil
end)