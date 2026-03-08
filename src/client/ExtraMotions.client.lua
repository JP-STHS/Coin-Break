local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local character, humanoid, animator

local canDoubleJumpAfter = 0
local jumpPower = 50
local jumpCount = 0
local isDiving = false
local diveTrack = nil
local doubleJumpTrack = nil

local DOUBLE_JUMP_ANIM_ID = "rbxassetid://126942515817919"
local DIVE_ANIM_ID = "rbxassetid://127817629246125"

local function setupCharacter(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    animator = humanoid:WaitForChild("Animator")
    jumpCount = 0
    isDiving = false
    diveTrack = nil

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
            jumpCount = 0
            -- cancel dive anim immediately on landing
            if isDiving and diveTrack then
                diveTrack:Stop(0.3) -- 0 = instant stop, no fadeout
                diveTrack = nil
            end
            isDiving = false
        end
    end)
end

local function playAnim(id, speed)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local track = animator:LoadAnimation(anim)
    track:Play(0)
    track:AdjustSpeed(speed or 1)
    return track
end
local function stopDefaultAnims()
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        -- stop fall and jump default anims instantly
        if track.Name == "Fall" or track.Name == "Jump" then
            track:Stop(0)
        end
    end
end
local function onJumpRequest()
    if not humanoid then return end
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall and jumpCount < 1 then
        jumpCount += 1
        stopDefaultAnims()
        doubleJumpTrack = playAnim(DOUBLE_JUMP_ANIM_ID, 1)
        local doubleJumpSpeed = 1
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        humanoid:Move(Vector3.new(0, jumpPower, 0))

        -- fade out after anim finishes so default fall takes over
        task.spawn(function()
            local track = doubleJumpTrack
            if track then
                task.wait(track.Length / doubleJumpSpeed)
                track:Stop(0.2)
                doubleJumpTrack = nil
            end
        end)
    end
end

local function onDive()
    if not humanoid then return end
    local state = humanoid:GetState()
    if (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping) and not isDiving then
        isDiving = true
        stopDefaultAnims()
        if doubleJumpTrack then
            doubleJumpTrack:Stop(0.3) -- stop double jump anim immediately if diving, no fadeout
            doubleJumpTrack = nil
        end
        diveTrack = playAnim(DIVE_ANIM_ID,1) -- plays instantly, save track for cancelling
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local diveDirection = rootPart.CFrame.LookVector
            rootPart.AssemblyLinearVelocity = (diveDirection * 60) + Vector3.new(0, -20, 0)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        onJumpRequest()
    elseif input.KeyCode == Enum.KeyCode.Q then
        onDive()
    end
end)

player.CharacterAdded:Connect(function(char)
    setupCharacter(char)
end)

if player.Character then
    setupCharacter(player.Character)
end