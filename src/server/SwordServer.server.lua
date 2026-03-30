-- SwordServer (Script in ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create the event on the server so it exists before the client looks for it
local swingEvent = Instance.new("RemoteEvent")
swingEvent.Name = "SwordSwing"
swingEvent.Parent = ReplicatedStorage

local boss = workspace:WaitForChild("Boss1x")
local bossHumanoid = boss:WaitForChild("Humanoid")
local bossRootPart = boss:WaitForChild("HumanoidRootPart")

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
bossHitEvent.Parent = ReplicatedStorage

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
    if dist > SWORD_REACH then
        return  -- too far away
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