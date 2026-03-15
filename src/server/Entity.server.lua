
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local entitymodel = Workspace:WaitForChild("Monster1")
local entity = entitymodel:WaitForChild("Monster")
local entityHitbox = entitymodel:WaitForChild("MonsterHitbox")
local entitymusic = entity:WaitForChild("EntityChase")
local originalCFrame = entity.CFrame -- save at the top before runEntity

local glassbreak = entity:WaitForChild("GlassBreak")


local safeZone = Workspace:WaitForChild("closet")
local door = Workspace:WaitForChild("Door3")


local waypoints = {
    Workspace:WaitForChild("Waypoint1"),
    Workspace:WaitForChild("Waypoint2"),
    Workspace:WaitForChild("Waypoint3"),
    Workspace:WaitForChild("Waypoint4"),
    Workspace:WaitForChild("Waypoint5"),
    Workspace:WaitForChild("Waypoint6"),
    Workspace:WaitForChild("Waypoint7"),
    Workspace:WaitForChild("Waypoint8")
}

local SPEED = 30 -- studs per second, adjust to taste

local function isInsidePart(position, part)
    local localPos = part.CFrame:PointToObjectSpace(position)
    local size = part.Size / 2
    return math.abs(localPos.X) <= size.X
        and math.abs(localPos.Y) <= size.Y
        and math.abs(localPos.Z) <= size.Z
end

local jumpscareEvent = game:GetService("ReplicatedStorage"):WaitForChild("Jumpscare")

local function killPlayer(player)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        jumpscareEvent:FireClient(player) -- fire jumpscare before killing
        task.wait(0.5) -- brief delay so they see it
        humanoid.Health = 0
    end
end

local entitytime = false
-- build lights table after a short wait to make sure everything is loaded
task.wait(1)
local lights = {}
for _, v in pairs(Workspace:GetDescendants()) do
    if v:IsA("MeshPart") and v.Name:match("^light%d+") then
        table.insert(lights, v)
    end
end

local function runEntity()
    print("runEntity called")
    entitymusic:Play()
    entity.CFrame = waypoints[1].CFrame
    entity.Anchored = true

    local checking = true

    -- proximity light check

    -- proximity light check
    task.spawn(function()
        while checking do
            for _, light in pairs(lights) do
                local dist = (light.Position - entity.Position).Magnitude
                if dist < 20 then
                    local pointLight = light:FindFirstChildWhichIsA("PointLight", true)
                    if pointLight and pointLight.Enabled then
                        pointLight.Enabled = false
                        glassbreak:Play()
                    end
                end
            end
            task.wait(0.05)
        end
    end)

    local hitboxConnection
    hitboxConnection = entityHitbox.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and isInsidePart(root.Position, safeZone) then return end
        killPlayer(player)
    end)

    for i = 2, #waypoints do
        local distance = (waypoints[i].Position - waypoints[i-1].Position).Magnitude
        local duration = distance / SPEED
        local tween = TweenService:Create(
            entity,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {CFrame = waypoints[i].CFrame}
        )
        tween:Play()
        tween.Completed:Wait()
    end

    checking = false
    hitboxConnection:Disconnect()
    entitymusic:Stop()
    entity.CFrame = originalCFrame
end
local doorFrame3 = Workspace:WaitForChild("doorFrame3")
local doorFrame3Hinge = doorFrame3:WaitForChild("HingeConstraint")



door.Touched:Connect(function(hit)
    -- make sure its a player and not the monster or anything else
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end -- ignore anything thats not a player

    if not entitytime then
        entitytime = true
        task.spawn(function()
            runEntity()
            task.wait(60)
            entitytime = false
            doorFrame3Hinge.TargetAngle = 0
        end)
    end
end)