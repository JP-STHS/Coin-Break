-- BossStage3 Script
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
-- ============================================================
-- CONFIGURATION
-- ============================================================
local STAGE3_HITS_REQUIRED  = 2
local CHASE_SPEED           = 15   -- how fast boss walks toward player
local SLASH_DAMAGE          = 5
local SLASH_RANGE           = 3    -- studs to trigger slash
local SLASH_COOLDOWN        = 10    -- seconds between slashes
local TELEPORT_CHANCE       = 0.009 -- chance each heartbeat to teleport
local TELEPORT_OFFSET       = 5    -- studs behind player to teleport to

-- Add these near the top with the other state variables
local charging        = false
local lastChargeTime  = 0
local CHARGE_COOLDOWN_MIN = 10
local CHARGE_COOLDOWN_MAX = 20
local CHARGE_SPEED    = 60
local CHARGE_DURATION = 0.6
local CHARGE_DAMAGE   = 25
local nextChargeTime  = math.random(CHARGE_COOLDOWN_MIN, CHARGE_COOLDOWN_MAX)
-- ============================================================

local ANIMS = {
    Transition = "rbxassetid://104805103586671", -- transition from stage 2 to 3
    Chase      = "rbxassetid://114203667939022", -- run towards player
    Slash      = "rbxassetid://96237208071002",
    Charge     = "rbxassetid://82317883478238", -- every 15-20 seconds, goes in straight line then stops
    Teleport   = "rbxassetid://96739801257877", -- every few seconds
    Fall       = "rbxassetid://75418700894162", -- death animation
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
local stage3Active   = false
local hitCount       = 0
local stage3Done     = false
local slashing       = false
local teleporting    = false
local lastSlashTime  = 0
local chaseConnection = nil

local SwordController = ReplicatedStorage:WaitForChild("SwordController")

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

local function insideBoundary(pos)
    local buffer = 3
    local size = boundary.Size / 2
    local bPos = boundary.Position
    return math.abs(pos.X - bPos.X) < size.X - buffer
       and math.abs(pos.Z - bPos.Z) < size.Z - buffer
end
-- ============================================================
-- CHARGE ATTACK
-- ============================================================
local function doCharge()
    if charging or slashing or teleporting then return end
    charging = true
    lastChargeTime = tick()
    nextChargeTime = math.random(CHARGE_COOLDOWN_MIN, CHARGE_COOLDOWN_MAX)
    -- Charge attack on timer
    local player, _ = getNearestPlayer()
    if not player or not player.Character then
        charging = false
        return
    end
    local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        charging = false
        return
    end

    -- Stop chase, play charge anim
    loadedAnims.Chase:Stop(0.1)
    loadedAnims.Charge:Play(0.2, 30)

    -- Direction toward player locked in at start of charge
    local chargeDir = (playerRoot.Position - bossRoot.Position)
    chargeDir = Vector3.new(chargeDir.X, 0, chargeDir.Z).Unit

    local elapsed = 0
    local chargeConn
    local alreadyHit = {}

    chargeConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= CHARGE_DURATION then
            chargeConn:Disconnect()
            charging = false
            loadedAnims.Charge:Stop(0.3)
            if stage3Active and not stage3Done then
                loadedAnims.Chase:Play(0.2,10)
            end
            return
        end

        -- Move in straight line
        local newPos = Vector3.new(
            bossRoot.Position.X + chargeDir.X * CHARGE_SPEED * dt,
            bossRoot.Position.Y,
            bossRoot.Position.Z + chargeDir.Z * CHARGE_SPEED * dt
        )

        if insideBoundary(newPos) then
            bossRoot.CFrame = CFrame.new(newPos) * CFrame.Angles(
                0, math.atan2(-chargeDir.X, -chargeDir.Z), 0
            )
        else
            -- Hit the wall, stop charge
            chargeConn:Disconnect()
            charging = false
            loadedAnims.Charge:Stop(0.3)
            if stage3Active and not stage3Done then
                loadedAnims.Chase:Play(0.2,10)
            end
            return
        end

        -- Damage players in path
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            if not char or alreadyHit[p] then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            if (bossRoot.Position - root.Position).Magnitude < 6 then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:TakeDamage(CHARGE_DAMAGE)
                    alreadyHit[p] = true
                end
            end
        end
    end)
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
-- HEALTH RESTORE
-- ============================================================
local function restorePlayerHealth()
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local restore = hum.MaxHealth / 3
            hum.Health = math.min(hum.Health + restore, hum.MaxHealth)
        end
    end
end

-- ============================================================
-- SLASH ATTACK
-- ============================================================
local function doSlash()
    if slashing then return end
    slashing = true
    lastSlashTime = tick()

    -- Stop chase anim, play slash
    loadedAnims.Chase:Stop(0.1)
    loadedAnims.Slash:Play(0.3, 30, 0.6)

    -- Damage check during slash
    local hitConn
    local slashHit = {}  -- track who has been hit this slash

    hitConn = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if slashHit[p] then continue end  -- only hit each player once per slash
            local char = p.Character
            if not char then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            if (bossRoot.Position - root.Position).Magnitude < SLASH_RANGE then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:TakeDamage(SLASH_DAMAGE)
                    slashHit[p] = true  -- mark as hit so they can't be hit again this slash
                end
            end
        end
    end)

    -- Wait for slash animation to finish
    task.delay(loadedAnims.Slash.Length > 0 and loadedAnims.Slash.Length or 1, function()
        if hitConn then hitConn:Disconnect() end
        loadedAnims.Slash:Stop(0.2)
        slashing = false
        if stage3Active and not stage3Done then
            loadedAnims.Chase:Play(0.2)
        end
    end)
end

-- ============================================================
-- TELEPORT
-- ============================================================
local function doTeleport(playerRoot)
    if teleporting then return end
    teleporting = true

    loadedAnims.Chase:Stop(0.1)
    loadedAnims.Teleport:Play(0.1, 5)

    -- Fade out
    for _, part in ipairs(boss:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            TweenService:Create(part, TweenInfo.new(0.15), {Transparency = 1}):Play()
        end
    end

    task.delay(0.25, function()
        -- Teleport while invisible
        local behindPos = playerRoot.Position - playerRoot.CFrame.LookVector * TELEPORT_OFFSET
        behindPos = Vector3.new(behindPos.X, bossRoot.Position.Y, behindPos.Z)

        if not insideBoundary(behindPos) then
            behindPos = Vector3.new(boundary.Position.X, bossRoot.Position.Y, boundary.Position.Z)
        end

        bossRoot.CFrame = CFrame.new(behindPos) * CFrame.Angles(
            0,
            playerRoot.CFrame.Rotation.Y + math.rad(180),
            0
        )

        -- Fade back in
        for _, part in ipairs(boss:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                TweenService:Create(part, TweenInfo.new(0.2), {Transparency = 0}):Play()
            end
        end

        task.delay(0.3, function()
            loadedAnims.Teleport:Stop(0.2)
            teleporting = false
            if stage3Active and not stage3Done then
                loadedAnims.Chase:Play(0.2)
            end
        end)
    end)
end

-- ============================================================
-- CHASE LOOP
-- ============================================================
local function startChase()
    loadedAnims.Chase:Play(0.3, 10)

    chaseConnection = RunService.Heartbeat:Connect(function(dt)
        
        if not stage3Active then return end
        if slashing or teleporting or charging then return end        

        local player, dist = getNearestPlayer()
        if not player or not player.Character then return end
        local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        -- Face and move toward player
        local direction = (playerRoot.Position - bossRoot.Position)
        local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
        local angle = math.atan2(-flatDir.X, -flatDir.Z)

        local newPos = Vector3.new(
            bossRoot.Position.X + flatDir.X * CHASE_SPEED * dt,
            bossRoot.Position.Y,
            bossRoot.Position.Z + flatDir.Z * CHASE_SPEED * dt
        )

        if insideBoundary(newPos) then
            bossRoot.CFrame = CFrame.new(newPos) * CFrame.Angles(0, angle, 0)
        else
            bossRoot.CFrame = CFrame.new(bossRoot.Position) * CFrame.Angles(0, angle, 0)
        end

        -- Slash when close enough and cooldown passed
        if dist and dist < SLASH_RANGE and tick() - lastSlashTime >= SLASH_COOLDOWN then
            doSlash()
        end

        -- Random teleport behind player
        if math.random() < TELEPORT_CHANCE then
            doTeleport(playerRoot)
        end

        -- Charge attack on timer
        if tick() - lastChargeTime >= nextChargeTime and not charging then
            doCharge()
        end
        -- Out of bounds snap
        if not insideBoundary(bossRoot.Position) then
            bossRoot.CFrame = CFrame.new(
                boundary.Position.X,
                bossRoot.Position.Y,
                boundary.Position.Z
            )
        end
    end)
end

local function stopChase()
    if chaseConnection then
        chaseConnection:Disconnect()
        chaseConnection = nil
    end
end

-- ============================================================
-- HIT TRACKING
-- ============================================================
local bossHitEvent = ReplicatedStorage:WaitForChild("BossHit")

bossHitEvent.Event:Connect(function(player)
    if not stage3Active or stage3Done then return end
    hitCount = hitCount + 1
    print(string.format("Stage 3 hits: %d / %d", hitCount, STAGE3_HITS_REQUIRED))

    if hitCount >= STAGE3_HITS_REQUIRED then
        stage3Done = true
        stage3Active = false
        stopChase()
        stopAllAnims()
        bossRoot.Anchored = true
        bossHumanoid.PlatformStand = true
        local animateScript = boss:FindFirstChild("Animate")
        if animateScript then animateScript.Disabled = true end

        -- Play fall
        local track = loadedAnims.Fall

        track.Looped = false
        track.Priority = Enum.AnimationPriority.Action4

        track:Play(0, 100)

        -- When animation naturally finishes
        track.Stopped:Connect(function()

            -- Snap exactly to final frame
            track.TimePosition = track.Length

            -- Freeze there
            track:AdjustSpeed(0)

            print("Boss defeated and frozen on final frame")

        end)
    end
end)

-- ============================================================
-- START STAGE 3
-- ============================================================
local function startStage3()
    stage3Active  = true
    hitCount      = 0
    stage3Done    = false
    slashing      = false
    teleporting   = false
    lastSlashTime = 0

    -- Freeze and push players back
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

    -- Stop all anims
    stopAllAnims()

    -- Restore player health
    restorePlayerHealth()
    -- Cancel any active blade tweens from previous stages
    -- by invoking pause first, waiting a moment, then switching to held
    SwordController:Invoke("pause")
    task.wait(1)  -- wait for any in-flight tweens to settle
    SwordController:Invoke("held")

    -- Boss comes down to ground level
    bossRoot.Anchored = false
    local groundY = boundary.Position.Y - boundary.Size.Y / 2 + 3
    TweenService:Create(bossRoot, TweenInfo.new(
        1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out
    ), {CFrame = CFrame.new(bossRoot.Position.X, groundY, bossRoot.Position.Z)}):Play()
    task.wait(1.5)

    -- play transition then go to chase
    loadedAnims.Transition:Play(0.3, 60)
    task.wait(loadedAnims.Transition.Length > 0 and loadedAnims.Transition.Length or 1.5)
    loadedAnims.Transition:Stop(0.3)

    -- Unfreeze players
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpHeight = 7.2
        end
    end

    -- Start chasing
    startChase()
    print("Stage 3 started!")
end

-- Listen for stage 3 start
local stage3Event = ReplicatedStorage:WaitForChild("StartStage3")
stage3Event.Event:Connect(function()
    task.wait(0.5)
    startStage3()
end)

-- Create defeated event for end screen
local defeatedEvent = Instance.new("RemoteEvent")
defeatedEvent.Name = "BossDefeated"
defeatedEvent.Parent = ReplicatedStorage