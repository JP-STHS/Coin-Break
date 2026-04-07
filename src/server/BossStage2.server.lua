-- BossStage2 Script
-- Place in ServerScriptService

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
local spawnSpot = workspace:WaitForChild("Portal2"):WaitForChild("playerspot")

local smallCrystalTemplate = ServerStorage:WaitForChild("SmallCrystal")
local largeCrystalTemplate = ServerStorage:WaitForChild("LargeCrystal")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local STAGE2_HITS_REQUIRED  = 1
local CRYSTAL_DAMAGE_SMALL  = 10
local CRYSTAL_DAMAGE_LARGE  = 20
local CRYSTAL_INTERVAL      = 10
local SMALL_CRYSTAL_COUNT   = 3
local LARGE_CRYSTAL_COUNT   = 2
local BLADE_INTERVAL_MIN    = 7
local BLADE_INTERVAL_MAX    = 10
local CRYSTAL_FALL_HEIGHT   = 50
local CRYSTAL_FALL_TIME     = 1.5
local CRYSTAL_LIFETIME      = 4
local BLADE_SPEED           = 60
local BLADE_RETURN_SPEED    = 200
local BRACE_DISTANCE        = 20
-- ============================================================

local ANIMS = {
    FloatIdle     = "rbxassetid://133632260307047",
    SignalBlade   = "rbxassetid://71337937039119",
    SignalCrystal = "rbxassetid://114320886639984",
    BraceIdle     = "rbxassetid://87836652330113",
    Angry         = "rbxassetid://93788484698091",
}

local loadedAnims = {}
local function loadAnim(name, id)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    loadedAnims[name] = bossAnimator:LoadAnimation(anim)
end
for name, id in pairs(ANIMS) do loadAnim(name, id) end

-- ============================================================
-- STATE
-- ============================================================
local stage2Active      = false
local hitCount          = 0
local stage2Done        = false
local bracing           = false
local bladeAttackActive = false
local attackingCrystal  = false
local facingConnection  = nil
local braceConnection   = nil

local sword1 = boss:WaitForChild("Sword1")
local sword2 = boss:WaitForChild("Sword2")
local sword1Primary = sword1.PrimaryPart
local sword2Primary = sword2.PrimaryPart

-- ============================================================
-- HELPERS
-- ============================================================
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
    return nearest, nearestDist
end

local function stopAllAnims()
    for _, track in ipairs(bossAnimator:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end
end

local function playIdle()
    if not stage2Active then return end
    if bladeAttackActive or attackingCrystal then return end
    local _, dist = getNearestPlayer()
    if dist and dist <= BRACE_DISTANCE then
        if not loadedAnims.BraceIdle.IsPlaying then
            loadedAnims.FloatIdle:Stop(0.2)
            loadedAnims.BraceIdle:Play(0.2, 10)
        end
    else
        if not loadedAnims.FloatIdle.IsPlaying then
            loadedAnims.BraceIdle:Stop(0.2)
            loadedAnims.FloatIdle:Play(0.5, 1, 1)
        end
    end
end

-- ============================================================
-- FACING — boss always looks at player
-- ============================================================
local function startFacing()
    facingConnection = RunService.Heartbeat:Connect(function()
        if not stage2Active then return end
        local player, dist = getNearestPlayer()
        if not player or not dist then return end

        -- Update idle/brace based on distance only
        if dist <= BRACE_DISTANCE and not bracing then
            bracing = true
            if not bladeAttackActive and not attackingCrystal then
                loadedAnims.FloatIdle:Stop(0.3)
                loadedAnims.BraceIdle:Play(0.3, 10)
            end
        elseif dist > BRACE_DISTANCE and bracing then
            bracing = false
            if not bladeAttackActive and not attackingCrystal then
                loadedAnims.BraceIdle:Stop(0.3)
                loadedAnims.FloatIdle:Play(0.5)
            end
        end
    end)
end

local function stopFacing()
    if facingConnection then
        facingConnection:Disconnect()
        facingConnection = nil
    end
end
local retreatConnection = nil

local function insideBoundary(pos)
    local buffer = 3
    local size = boundary.Size / 2
    local bPos = boundary.Position
    return math.abs(pos.X - bPos.X) < size.X - buffer
       and math.abs(pos.Z - bPos.Z) < size.Z - buffer
end
local function startRetreat()
    retreatConnection = RunService.Heartbeat:Connect(function(dt)
        if not stage2Active then return end
        if bladeAttackActive or attackingCrystal then return end

        -- Out of bounds check
        if not insideBoundary(bossRoot.Position) then
            local center = boundary.Position
            bossRoot.CFrame = CFrame.new(center.X, bossRoot.Position.Y, center.Z)
        end

        local player = getNearestPlayer()
        if not player or not player.Character then return end
        local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        local awayDir = (bossRoot.Position - playerRoot.Position)
        awayDir = Vector3.new(awayDir.X, 0, awayDir.Z).Unit

        local currentY = bossRoot.Position.Y
        local newPos = Vector3.new(
            bossRoot.Position.X + awayDir.X * 8 * dt,  -- speed 8, quicker than stage 1
            currentY,
            bossRoot.Position.Z + awayDir.Z * 8 * dt
        )

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
        -- Always face player regardless of movement
        local angle = math.atan2(
            -(playerRoot.Position.X - bossRoot.Position.X),
            -(playerRoot.Position.Z - bossRoot.Position.Z)
        )

        if insideBoundary(newPos) then
            bossRoot.CFrame = CFrame.new(newPos) * CFrame.Angles(0, angle, 0)
        else
            -- Can't move but still face player
            bossRoot.CFrame = CFrame.new(bossRoot.Position) * CFrame.Angles(0, angle, 0)
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
-- PUSH PLAYER BACK
-- ============================================================
local function pushPlayersBack()
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then continue end

        hum.WalkSpeed = 0
        hum.JumpHeight = 0

        local targetCFrame = spawnSpot.CFrame + Vector3.new(0, 3, 0)
        TweenService:Create(root, TweenInfo.new(
            1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out
        ), {CFrame = targetCFrame}):Play()

        task.delay(1.5, function()
            hum.WalkSpeed = 16
            hum.JumpHeight = 7.2
        end)
    end
end

-- ============================================================
-- CRYSTAL SPAWN
-- ============================================================
local function spawnCrystal(targetPos, template, damage)
    local crystal = template:Clone()
    crystal.Parent = workspace

    local hitbox = crystal:FindFirstChild("Hitbox")

    for _, part in ipairs(crystal:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored = true end
    end

    crystal:SetPrimaryPartCFrame(CFrame.new(
        targetPos.X, targetPos.Y + CRYSTAL_FALL_HEIGHT, targetPos.Z
    ))

    local startY = crystal.PrimaryPart.Position.Y
    local endY = targetPos.Y
    local elapsed = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / CRYSTAL_FALL_TIME, 1)
        local newY = startY + (endY - startY) * (t * t)
        crystal:SetPrimaryPartCFrame(CFrame.new(targetPos.X, newY, targetPos.Z))
        if t >= 1 then conn:Disconnect() end
    end)

    if hitbox then
        local alreadyHit = {}
        hitbox.Touched:Connect(function(hit)
            local char = hit.Parent
            local p = Players:GetPlayerFromCharacter(char)
            if not p or alreadyHit[p] then return end
            alreadyHit[p] = true
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:TakeDamage(damage) end
        end)
    end

    task.delay(CRYSTAL_LIFETIME, function()
        if conn then conn:Disconnect() end
        if crystal and crystal.Parent then crystal:Destroy() end
    end)
end

local function doCrystalAttack()
    if not stage2Active then return end
    attackingCrystal = true

    -- Stop idle, play signal
    loadedAnims.FloatIdle:Stop(0.1)
    loadedAnims.BraceIdle:Stop(0.1)
    loadedAnims.SignalCrystal:Play(1, 15)

    task.delay(0.8, function()
        local groundY = boundary.Position.Y - boundary.Size.Y / 2 + 2
        local size = boundary.Size
        local pos = boundary.Position

        for i = 1, SMALL_CRYSTAL_COUNT do
            local x = pos.X + math.random(-size.X/2 * 0.8, size.X/2 * 0.8)
            local z = pos.Z + math.random(-size.Z/2 * 0.8, size.Z/2 * 0.8)
            task.delay((i-1) * 0.2, function()
                spawnCrystal(Vector3.new(x, groundY, z), smallCrystalTemplate, CRYSTAL_DAMAGE_SMALL)
            end)
        end

        for i = 1, LARGE_CRYSTAL_COUNT do
            local x = pos.X + math.random(-size.X/2 * 0.8, size.X/2 * 0.8)
            local z = pos.Z + math.random(-size.Z/2 * 0.8, size.Z/2 * 0.8)
            task.delay((i-1) * 0.4, function()
                spawnCrystal(Vector3.new(x, groundY, z), largeCrystalTemplate, CRYSTAL_DAMAGE_LARGE)
            end)
        end
    end)

    local animLength = loadedAnims.SignalCrystal.Length
    task.delay(animLength, function()
        loadedAnims.SignalCrystal:Stop(0.5)
        attackingCrystal = false
        playIdle()
    end)
end

-- ============================================================
-- BLADE ATTACK
-- ============================================================
local function doBladeAttack()
    if not stage2Active then return end
    bladeAttackActive = true

    -- Pause the sword controller so it doesn't fight the tween
    local SwordController = ReplicatedStorage:WaitForChild("SwordController")
    SwordController:Invoke("pause")

    -- Stop idle, play signal
    loadedAnims.FloatIdle:Stop(0.1)
    loadedAnims.BraceIdle:Stop(0.1)
    loadedAnims.SignalBlade:Play(1, 50, 1)
    local randomnum = math.random(1.5,2)
    task.delay(randomnum, function()
        local player, _ = getNearestPlayer()
        if not player or not player.Character then
            bladeAttackActive = false
            loadedAnims.SignalBlade:Stop(0.1)
            playIdle()
            return
        end
        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
            bladeAttackActive = false
            loadedAnims.SignalBlade:Stop(0.1)
            playIdle()
            return
        end

        local blades = {sword1Primary, sword2Primary}
        local bladesReturned = 0

        for _, blade in ipairs(blades) do
            local relativeOffset = bossRoot.CFrame:Inverse() * blade.CFrame

            for _, v in ipairs(blade:GetChildren()) do
                if v:IsA("Motor6D") or v:IsA("WeldConstraint") then v:Destroy() end
            end
            blade.Anchored = true

            local flyTarget = CFrame.new(targetRoot.Position)
            local flyDist = (targetRoot.Position - blade.Position).Magnitude
            local flyTween = TweenService:Create(blade, TweenInfo.new(
                flyDist / BLADE_SPEED, Enum.EasingStyle.Linear
            ), {CFrame = flyTarget})
            flyTween:Play()

            local returned = false
            local hitCheckConn

            local function returnBlade()
                if returned then return end
                returned = true
                if hitCheckConn then hitCheckConn:Disconnect() end
                flyTween:Cancel()

                task.delay(0.2, function()
                    local returnCFrame = bossRoot.CFrame * relativeOffset
                    local returnDist = (blade.Position - bossRoot.Position).Magnitude
                    local returnTween = TweenService:Create(blade, TweenInfo.new(
                        math.max(0.3, returnDist / BLADE_RETURN_SPEED), Enum.EasingStyle.Sine
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

                        bladesReturned = bladesReturned + 1
                        if bladesReturned >= #blades then
                            bladeAttackActive = false
                            loadedAnims.SignalBlade:Stop(0.3)
                            SwordController:Invoke("floating")
                            playIdle()
                        end
                    end)
                end)
            end

            hitCheckConn = RunService.Heartbeat:Connect(function()
                if returned then hitCheckConn:Disconnect() return end
                for _, p in ipairs(Players:GetPlayers()) do
                    local char = p.Character
                    if not char then continue end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then continue end
                    if (blade.Position - root.Position).Magnitude < 5 then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum:TakeDamage(20) end
                        returnBlade()
                        return
                    end
                end
            end)

            flyTween.Completed:Connect(function()
                if hitCheckConn then hitCheckConn:Disconnect() end
                returnBlade()
            end)
        end
    end)
end

-- ============================================================
-- ATTACK LOOPS
-- ============================================================
local function startCrystalLoop()
    task.spawn(function()
        while stage2Active do
            task.wait(CRYSTAL_INTERVAL)
            if stage2Active and not bladeAttackActive then
                doCrystalAttack()
                -- Wait for crystal attack to finish before looping
                while attackingCrystal do task.wait(0.1) end
            end
        end
    end)
end

local function startBladeLoop()
    task.spawn(function()
        while stage2Active do
            local interval = math.random(BLADE_INTERVAL_MIN, BLADE_INTERVAL_MAX)
            task.wait(interval)
            if stage2Active and not attackingCrystal then
                doBladeAttack()
                -- Wait for blade attack to finish
                while bladeAttackActive do task.wait(0.1) end
            end
        end
    end)
end

-- ============================================================
-- HIT TRACKING
-- ============================================================
local bossHitEvent = ReplicatedStorage:WaitForChild("BossHit")

bossHitEvent.Event:Connect(function(player)
    if not stage2Active or stage2Done then return end
    hitCount = hitCount + 1
    print(string.format("Stage 2 hits: %d / %d", hitCount, STAGE2_HITS_REQUIRED))

    if hitCount >= STAGE2_HITS_REQUIRED then
        stage2Done = true
        stage2Active = false
        stopFacing()
        stopRetreat()
        bossRoot.Anchored = true
        print("Stage 2 complete!")
        local stage3Event = ReplicatedStorage:WaitForChild("StartStage3")
        stage3Event:Fire()
    end
end)

-- ============================================================
-- START STAGE 2
-- ============================================================
local function startStage2()
    stage2Active = true
    hitCount = 0
    stage2Done = false
    bracing = false
    bladeAttackActive = false
    attackingCrystal = false

    -- Freeze all players and push back
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpHeight = 0
        end
    end

    pushPlayersBack()

    -- Stop all current animations
    stopAllAnims()

    -- Angry animation — boss stays still, player is frozen
    bossRoot.Anchored = true
    -- Stop ALL animations including ones from stage 1
    for _, track in ipairs(bossAnimator:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end
    task.wait(0.1)  -- tiny wait to ensure they all stopped
    loadedAnims.Angry:Play(1,100,0.5)
    task.wait(loadedAnims.Angry.Length)  -- wait for most of the anim to finish
    loadedAnims.Angry:Stop(0.3)

    -- Unfreeze players after angry anim finishes
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpHeight = 7.2
        end
    end

    -- Move boss to center
    local center = boundary.Position
    bossRoot.Anchored = false
    TweenService:Create(bossRoot, TweenInfo.new(1, Enum.EasingStyle.Sine), {
        CFrame = CFrame.new(center.X, bossRoot.Position.Y, center.Z)
    }):Play()
    task.wait(1)

    -- Start idle and all systems
    loadedAnims.FloatIdle:Play(1,1,1)
    startFacing()
    startRetreat()
    
    startCrystalLoop()
    startBladeLoop()

    print("Stage 2 started!")
end

local stage2Event = ReplicatedStorage:WaitForChild("StartStage2")
stage2Event.Event:Connect(function()
    task.wait(0.5)
    startStage2()
end)

local stage3Event = Instance.new("BindableEvent")
stage3Event.Name = "StartStage3"
stage3Event.Parent = ReplicatedStorage