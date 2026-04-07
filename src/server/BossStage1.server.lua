
local bladeAttackActive = false
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local boss = workspace:WaitForChild("Boss1x")
local bossHumanoid = boss:WaitForChild("Humanoid")
local bossAnimator = bossHumanoid:WaitForChild("Animator")
local bossRoot = boss:WaitForChild("HumanoidRootPart")
local boundary = workspace:WaitForChild("1xBoundary")
local SwordController = ReplicatedStorage:WaitForChild("SwordController")

local crystalTemplate = ServerStorage:WaitForChild("SmallCrystal")
-- no letting boss die off early
bossHumanoid.MaxHealth = math.huge
bossHumanoid.Health = math.huge
bossHumanoid:SetAttribute("Invincible", true)
bossHumanoid.HealthChanged:Connect(function()
    bossHumanoid.Health = math.huge
end)
-- ============================================================
-- CONFIGURATION
-- ============================================================
local STAGE1_HITS_REQUIRED  = 1
local CRYSTAL_DAMAGE         = 20
local CRYSTAL_INTERVAL       = 7   -- seconds between crystal drops
local CRYSTAL_COUNT_S1       = 3    -- how many crystals drop at once
local BLADE_INTERVAL_MIN     = 10   -- min seconds between blade attacks
local BLADE_INTERVAL_MAX     = 15   -- max seconds between blade attacks
local BOSS_RETREAT_SPEED     = 8    -- how fast boss moves away from player
local CRYSTAL_FALL_HEIGHT    = 50   -- how high above crystals spawn
local CRYSTAL_FALL_TIME      = 1.5  -- seconds to fall down
local CRYSTAL_LIFETIME       = 4    -- seconds before crystal disappears
local BLADE_SPEED            = 40   -- how fast blades fly
local BLADE_RETURN_SPEED     = 200   -- how fast blades return
-- ============================================================

-- Animation IDs
local ANIMS = {
    FloatIdle     = "rbxassetid://133632260307047",
    SignalBlade   = "rbxassetid://71337937039119",
    SignalCrystal = "rbxassetid://114320886639984",
}

local loadedAnims = {}
local function loadAnim(name, id)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    loadedAnims[name] = bossAnimator:LoadAnimation(anim)
end

for name, id in pairs(ANIMS) do
    loadAnim(name, id)
end

-- ============================================================
-- STATE
-- ============================================================
local stage1Active = false
local hitCount     = 0
local stage1Done   = false

local sword1 = boss:WaitForChild("Sword1")
local sword2 = boss:WaitForChild("Sword2")
local sword1Primary = sword1.PrimaryPart
local sword2Primary = sword2.PrimaryPart

-- ============================================================
-- HELPERS
-- ============================================================

-- Get a random position inside the boundary part
local function randomBoundaryPos(yLevel)
    local size = boundary.Size
    local pos  = boundary.Position
    local x = pos.X + math.random(-size.X/2 * 0.8, size.X/2 * 0.8)
    local z = pos.Z + math.random(-size.Z/2 * 0.8, size.Z/2 * 0.8)
    return Vector3.new(x, yLevel or pos.Y, z)
end

-- Check if a position is inside the boundary
local function insideBoundary(pos)
    local buffer = 7  -- stops this many studs before the edge
    local size = boundary.Size / 2
    local bPos = boundary.Position
    return math.abs(pos.X - bPos.X) < size.X - buffer
       and math.abs(pos.Z - bPos.Z) < size.Z - buffer
end

-- Get the nearest player
local function getNearestPlayer()
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local dist = (root.Position - bossRoot.Position).Magnitude
        if dist < nearestDist then
            nearest = p
            nearestDist = dist
        end
    end
    return nearest
end

-- ============================================================
-- CRYSTAL DROP
-- ============================================================
local function spawnCrystal(targetPos)
    local crystal = crystalTemplate:Clone()
    crystal.Parent = workspace

    local hitbox = crystal:FindFirstChild("Hitbox")
    if not hitbox then
        -- search descendants if not direct child
        hitbox = crystal:FindFirstChildWhichIsA("BasePart", true)
    end

    -- Anchor all parts
    for _, part in ipairs(crystal:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end

    -- Set start position high above target
    crystal:SetPrimaryPartCFrame(CFrame.new(
        targetPos.X,
        targetPos.Y + CRYSTAL_FALL_HEIGHT,
        targetPos.Z
    ))

    local primaryPart = crystal.PrimaryPart
    local fallTarget = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)

    -- Use RunService to move entire model each frame
    local startY = primaryPart.Position.Y
    local endY = targetPos.Y
    local elapsed = 0

    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / CRYSTAL_FALL_TIME, 1)
        -- Quad ease in
        local eased = t * t
        local newY = startY + (endY - startY) * eased
        crystal:SetPrimaryPartCFrame(CFrame.new(targetPos.X, newY, targetPos.Z))
        if t >= 1 then
            conn:Disconnect()
        end
    end)

    -- Damage on hitbox touch
    if hitbox then
        local alreadyHit = {}
        hitbox.Touched:Connect(function(hit)
            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if not player then return end
            if alreadyHit[player] then return end
            alreadyHit[player] = true
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:TakeDamage(CRYSTAL_DAMAGE)
            end
        end)
    end

    task.delay(CRYSTAL_LIFETIME, function()
        if conn then conn:Disconnect() end
        if crystal and crystal.Parent then
            crystal:Destroy()
        end
    end)
end

local function doCrystalAttack(count)
    if not stage1Active then return end
    loadedAnims.SignalCrystal:Play()

    task.delay(0.8, function()
        -- Drop crystals at random positions around arena
        local groundY = boundary.Position.Y - boundary.Size.Y / 2  -- bottom of boundary = floor
        for i = 1, count do
            local pos = randomBoundaryPos(groundY)
            task.delay((i - 1) * 0.3, function()
                spawnCrystal(pos)
            end)
        end
    end)

    task.delay(loadedAnims.SignalCrystal.Length, function()
        loadedAnims.SignalCrystal:Stop()
    end)
end

-- ============================================================
-- BLADE ATTACK
-- ============================================================
local function doBladeAttack()
     if not stage1Active then return end
    bladeAttackActive = true
    SwordController:Invoke("pause")
    loadedAnims.SignalBlade:Play(1, 50, 0.5)
    task.delay(0.8, function()
        local player = getNearestPlayer()
        if not player or not player.Character then return end
        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        local blades = {sword1Primary, sword2Primary}

        for _, blade in ipairs(blades) do
            -- Store the relative offset from boss root BEFORE removing weld
            local relativeOffset = bossRoot.CFrame:Inverse() * blade.CFrame

            -- Remove weld
            for _, v in ipairs(blade:GetChildren()) do
                if v:IsA("Motor6D") or v:IsA("WeldConstraint") then
                    v:Destroy()
                end
            end
            blade.Anchored = true

            local flyTarget = CFrame.new(targetRoot.Position)
            local flyDist = (targetRoot.Position - blade.Position).Magnitude
            local flyTween = TweenService:Create(blade, TweenInfo.new(
                flyDist / BLADE_SPEED,
                Enum.EasingStyle.Linear
            ), {CFrame = flyTarget})
            flyTween:Play()

            local hitCheckConn
            local returned = false

            local function returnBlade()
                if returned then return end
                returned = true
                if hitCheckConn then hitCheckConn:Disconnect() end
                flyTween:Cancel()
                task.delay(0.2, function()
                    -- Return to current boss position using stored relative offset
                    local returnCFrame = bossRoot.CFrame * relativeOffset
                    local returnDist = (blade.Position - bossRoot.Position).Magnitude
                    local returnTween = TweenService:Create(blade, TweenInfo.new(
                        math.max(0.3, returnDist / BLADE_RETURN_SPEED),
                        Enum.EasingStyle.Sine
                    ), {CFrame = returnCFrame})
                    returnTween:Play()

                    returnTween.Completed:Connect(function()

                        local weld = Instance.new("Motor6D")
                        weld.Part0 = bossRoot
                        weld.Part1 = blade
                        weld.C0 = relativeOffset
                        weld.C1 = CFrame.new()
                        weld.Parent = blade
                        blade.Anchored = false

                        -- Resume floating once both blades are back
                        if blade == sword2Primary then
                            bladeAttackActive = false
                            SwordController:Invoke("floating")
                        end

                    end)
                end)
            end

            -- Check proximity every frame instead of relying on Touched
        hitCheckConn = game:GetService("RunService").Heartbeat:Connect(function()
            if returned then
                hitCheckConn:Disconnect()
                return
            end
            for _, p in ipairs(Players:GetPlayers()) do
                local char = p.Character
                if not char then continue end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local dist = (blade.Position - root.Position).Magnitude
                if dist < 4 then  -- hit radius, increase if still hard to hit
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:TakeDamage(15) end
                    returnBlade()
                    hitCheckConn:Disconnect()
                    return
                end
            end
        end)

        flyTween.Completed:Connect(function()
            hitCheckConn:Disconnect()
            returnBlade()
        end)
        end
    end)

    task.delay(loadedAnims.SignalBlade.Length, function()
        if loadedAnims.SignalBlade.IsPlaying then
            loadedAnims.SignalBlade:Stop()
        end
    end)
    task.delay(2, function()  -- rough estimate, adjust to match your blade travel time
        bladeAttackActive = false
    end)
end

-- ============================================================
-- BOSS RETREAT
-- ============================================================
local retreatConnection = nil

local function startRetreat()
    retreatConnection = RunService.Heartbeat:Connect(function(dt)
        -- If boss somehow escapes boundary, teleport back to center
        if not insideBoundary(bossRoot.Position) then
            local center = boundary.Position
            bossRoot.CFrame = CFrame.new(center.X, bossRoot.Position.Y, center.Z)
        end
        if bladeAttackActive then return end  -- pause during blade attack
        local player = getNearestPlayer()
        if not player or not player.Character then return end
        local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        -- Move away from player
        local awayDir = (bossRoot.Position - playerRoot.Position)
        awayDir = Vector3.new(awayDir.X, 0, awayDir.Z).Unit

        local currentY = bossRoot.Position.Y
        local newPos = Vector3.new(
            bossRoot.Position.X + awayDir.X * BOSS_RETREAT_SPEED * dt,
            currentY,  -- lock Y so boss stays at same height
            bossRoot.Position.Z + awayDir.Z * BOSS_RETREAT_SPEED * dt
        )
        
        -- Only move if staying inside boundary
        if insideBoundary(newPos) then
            bossRoot.CFrame = CFrame.new(newPos) * CFrame.Angles(
                0,
                math.atan2(
                    -(playerRoot.Position.X - bossRoot.Position.X),
                    -(playerRoot.Position.Z - bossRoot.Position.Z)
                ),
                0
            )
        end
    end)
end

local function stopRetreat()
    if retreatConnection then
        retreatConnection:Disconnect()
        retreatConnection = nil
    end
end

-- ============================================================
-- ATTACK LOOPS
-- ============================================================
local function startCrystalLoop()
    task.spawn(function()
        while stage1Active do
            task.wait(CRYSTAL_INTERVAL)
            if stage1Active then
                doCrystalAttack(CRYSTAL_COUNT_S1)
            end
        end
    end)
end

local function startBladeLoop()
    task.spawn(function()
        while stage1Active do
            local interval = math.random(BLADE_INTERVAL_MIN, BLADE_INTERVAL_MAX)
            task.wait(interval)
            if stage1Active then
                doBladeAttack()
            end
        end
    end)
end

-- ============================================================
-- HIT TRACKING
-- ============================================================
local bossHitEvent = ReplicatedStorage:WaitForChild("BossHit")

bossHitEvent.Event:Connect(function(player)
    if not stage1Active or stage1Done then return end
    hitCount = hitCount + 1
    print(string.format("Stage 1 hits: %d / %d", hitCount, STAGE1_HITS_REQUIRED))

    if hitCount >= STAGE1_HITS_REQUIRED then
        stage1Done = true
        stage1Active = false
        stopRetreat()
        print("Stage 1 complete!")

        -- Fire stage 2 start event
        local stage2Event = ReplicatedStorage:WaitForChild("StartStage2")
        stage2Event:Fire()
    end
end)

-- ============================================================
-- START STAGE 1
-- ============================================================
local function startStage1()
    stage1Active = true
    hitCount = 0
    stage1Done = false

    loadedAnims.FloatIdle:Play()
    startRetreat()
    startCrystalLoop()
    startBladeLoop()

    print("Stage 1 started!")
end

local cutsceneDone = Instance.new("RemoteEvent")
cutsceneDone.Name = "CutsceneDone"
cutsceneDone.Parent = ReplicatedStorage

cutsceneDone.OnServerEvent:Connect(function(player)
    print("CutsceneDone received from", player.Name)
    task.wait(1)
    startStage1()
end)

-- Create stage 2 start event for later
local stage2Event = Instance.new("BindableEvent")
stage2Event.Name = "StartStage2"
stage2Event.Parent = ReplicatedStorage