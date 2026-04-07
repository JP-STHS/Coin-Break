-- BossCutscene LocalScript
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local boss = workspace:WaitForChild("Boss1x")
local bossRootPart = boss:WaitForChild("HumanoidRootPart")
local bossHumanoid = boss:WaitForChild("Humanoid")
local bossAnimator = bossHumanoid:WaitForChild("Animator")

-- ============================================================
-- ANIMATION IDs
-- ============================================================
local DESCEND_ID    = "rbxassetid://81539087617244"
local FLOAT_IDLE_ID = "rbxassetid://133632260307047"
-- ============================================================

-- ============================================================
-- CONFIGURATION
-- Cam 1-4: short pan shots (player looking around arena)
-- Cam 5: boss descends here
-- Cam 6: close up, dialogue later
-- ============================================================
local CAM_SHOTS = {
    { part = "1xCam1", duration = 2.5, tween = 2.5 },  -- pan left
    { part = "1xCam2", duration = 2.5, tween = 2.5 },  -- pan right
    { part = "1xCam3", duration = 2.5, tween = 2.5 },  -- pan left
    { part = "1xCam4", duration = 2.5, tween = 2.5 },  -- pan right
    { part = "1xCam5", duration = 5,   tween = 3   },  -- boss descends
    { part = "1xCam6", duration = 6,   tween = 2   },  -- close up, dialogue later
}

local BOSS_START_HEIGHT = 100
local DESCEND_DURATION  = 6
-- ============================================================

local cutsceneDoneEvent = Instance.new("BindableEvent")
cutsceneDoneEvent.Name = "CutsceneDone"
cutsceneDoneEvent.Parent = ReplicatedStorage

local function loadAnim(id)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    return bossAnimator:LoadAnimation(anim)
end

local descendAnim   = loadAnim(DESCEND_ID)
local floatIdleAnim = loadAnim(FLOAT_IDLE_ID)

local function freezePlayer()
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
end

local function unfreezePlayer()
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.JumpHeight = 7.2
end

local function fadeScreen(targetTransparency, duration)
    local gui = player.PlayerGui:FindFirstChild("FadeGui")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "FadeGui"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 99
        gui.Parent = player.PlayerGui

        local frame = Instance.new("Frame")
        frame.Name = "FadeFrame"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = gui
    end

    local frame = gui:WaitForChild("FadeFrame")
    TweenService:Create(frame, TweenInfo.new(duration), {
        BackgroundTransparency = targetTransparency
    }):Play()
    task.wait(duration)
end
local function runCutscene()
    freezePlayer()

    -- Move boss above arena
    local arenaCenter = bossRootPart.Position
    bossRootPart.CFrame = CFrame.new(
        arenaCenter.X,
        arenaCenter.Y + BOSS_START_HEIGHT,
        arenaCenter.Z
    )

    -- Switch to scriptable camera and snap to cam 1 BEFORE fading in
    camera.CameraType = Enum.CameraType.Scriptable
    local firstCam = workspace:WaitForChild("1xCam1")
    camera.CFrame = firstCam.CFrame

    -- Now fade in to reveal the arena
    fadeScreen(1, 1.5)
    task.wait(0.3)

    -- Run through camera shots (skip snapping cam 1 since we already did it)
    for i, shot in ipairs(CAM_SHOTS) do
        local camPart = workspace:WaitForChild(shot.part)

        if i == 1 then
            task.wait(shot.duration)  -- just wait on cam 1, already positioned
        else
            TweenService:Create(camera, TweenInfo.new(
                shot.tween,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ), { CFrame = camPart.CFrame }):Play()

            if i == 5 then
                task.wait(0.5)
                local targetCFrame = CFrame.new(arenaCenter.X, arenaCenter.Y + 0, arenaCenter.Z)
                TweenService:Create(bossRootPart, TweenInfo.new(
                    DESCEND_DURATION,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.Out
                ), { CFrame = targetCFrame }):Play()
                descendAnim:Play(0,2,1)
                task.wait(DESCEND_DURATION)
                floatIdleAnim:Play(5,5,1)
                task.wait(shot.duration - DESCEND_DURATION - 0.5)
            else
                task.wait(shot.duration)
            end
        end
    end

    -- Fade out at end
    fadeScreen(0, 0.4)  -- fade to black (was 1, 0.4)
    task.wait(0.4)
    camera.CameraType = Enum.CameraType.Custom
    fadeScreen(1, 0.6)  -- fade to clear (was 0, 0.6)
    task.wait(0.6)

    local fadeGui = player.PlayerGui:FindFirstChild("FadeGui")
    if fadeGui then fadeGui:Destroy() end

    unfreezePlayer()
    print("Firing CutsceneDone")
    local cutsceneDone = ReplicatedStorage:WaitForChild("CutsceneDone")
    cutsceneDone:FireServer()
    print("Cutscene done!")
end

-- ============================================================
-- PORTAL TOUCH — teleport player then run cutscene
-- ============================================================
local portalparent = workspace:WaitForChild("Portal")
local portal = portalparent:WaitForChild("Portal")
local portal2 = workspace:WaitForChild("Portal2")
local spawnInArena = portal2:WaitForChild("playerspot")  -- teleport destination

local triggered = false
portal.Touched:Connect(function(hit)
    if triggered then return end
    if hit.Parent ~= character then return end
    triggered = true

    -- Instantly black screen
    fadeScreen(0, 0)
    task.wait(0.1)

    -- Teleport player while screen is black
    rootPart.CFrame = spawnInArena.CFrame + Vector3.new(0, 3, 0)
    freezePlayer()

    -- Wait a moment for the arena to fully render
    task.wait(2)

    -- Run the cutscene (starts with fade in)
    runCutscene()
end)