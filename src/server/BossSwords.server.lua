local workspace = game:GetService("Workspace")
local boss = workspace:WaitForChild("Boss1x")
local rootPart = boss:WaitForChild("HumanoidRootPart")
local sword1 = boss:WaitForChild("Sword1")
local sword2 = boss:WaitForChild("Sword2")

local sword1Primary = sword1.PrimaryPart
local sword2Primary = sword2.PrimaryPart

local TweenService = game:GetService("TweenService")

local FLOAT_HEIGHT = 1.75
local FLOAT_TIME = 0.5

local weld1
local weld2

local tween1
local tween2
-- ============================================================
-- CONFIGURATION
-- ============================================================
-- Floating offsets relative to boss root (stage 1 & 2)
local FLOAT_OFFSET_1 = CFrame.new(-4, 1, 0) * CFrame.Angles(0, math.rad(180), math.rad(60)) --left
local FLOAT_OFFSET_2 = CFrame.new(4, 1, 0) * CFrame.Angles(0, math.rad(180), math.rad(-60))    -- right side

-- Hand offsets relative to Left/RightHand (stage 3)
local HAND_OFFSET_1 = CFrame.new(0, -1, 0)    -- adjust to fit your sword mesh
local HAND_OFFSET_2 = CFrame.new(0, -1, 0)
-- ============================================================

-- Weld a part to another part with an offset
local function weldTo(part, targetPart, offset)
    -- Remove any existing weld on this part first
    for _, v in ipairs(part:GetChildren()) do
        if v:IsA("WeldConstraint") or v:IsA("Motor6D") then
            v:Destroy()
        end
    end
    local weld = Instance.new("Motor6D")
    weld.Part0 = targetPart
    weld.Part1 = part
    weld.C0 = offset
    weld.C1 = CFrame.new()
    weld.Parent = part
    part.Anchored = false
    return weld
end

local function anchorSwordParts(model, anchored)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = anchored
        end
    end
end

-- ============================================================
-- Public functions called by boss fight script
-- ============================================================
local SwordController = {}
local function startFloatingTween()

    if not weld1 or not weld2 then
        return
    end

    if tween1 then tween1:Cancel() end
    if tween2 then tween2:Cancel() end

    local info = TweenInfo.new(
        FLOAT_TIME,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1,
        true
    )

    tween1 = TweenService:Create(
        weld1,
        info,
        {
            C0 = FLOAT_OFFSET_1 * CFrame.new(0, FLOAT_HEIGHT, FLOAT_HEIGHT)
        }
    )

    tween2 = TweenService:Create(
        weld2,
        info,
        {
            C0 = FLOAT_OFFSET_2 * CFrame.new(0, FLOAT_HEIGHT, FLOAT_HEIGHT)
        }
    )

    tween1:Play()
    tween2:Play()

end
local floatingMonitor

function SwordController.setFloating()
    sword1Primary.CFrame = rootPart.CFrame * FLOAT_OFFSET_1
    sword2Primary.CFrame = rootPart.CFrame * FLOAT_OFFSET_2
    -- Stop previous monitor
    if floatingMonitor then
        floatingMonitor:Disconnect()
        floatingMonitor = nil
    end

    anchorSwordParts(sword1, false)
    anchorSwordParts(sword2, false)

    weld1 = weldTo(sword1Primary, rootPart, FLOAT_OFFSET_1)
    weld2 = weldTo(sword2Primary, rootPart, FLOAT_OFFSET_2)

    startFloatingTween()

    -- Monitor weld state and restart tween if needed
    floatingMonitor = game:GetService("RunService").Heartbeat:Connect(function()

        if not weld1
        or not weld2
        or weld1.Parent == nil
        or weld2.Parent == nil
        or weld1.Part0 ~= rootPart
        or weld2.Part0 ~= rootPart then

            weld1 = weldTo(sword1Primary, rootPart, FLOAT_OFFSET_1)
            weld2 = weldTo(sword2Primary, rootPart, FLOAT_OFFSET_2)

            startFloatingTween()
        end

    end)

    print("Floating mode active")

end

function SwordController.setHeld()

    if floatingMonitor then
        floatingMonitor:Disconnect()
        floatingMonitor = nil
    end

    if tween1 then tween1:Cancel() end
    if tween2 then tween2:Cancel() end

    local leftHand  = boss:WaitForChild("LeftHand")
    local rightHand = boss:WaitForChild("RightHand")

    anchorSwordParts(sword1, false)
    anchorSwordParts(sword2, false)

    weld1 = weldTo(sword1Primary, leftHand, HAND_OFFSET_1)
    weld2 = weldTo(sword2Primary, rightHand, HAND_OFFSET_2)

    print("Held mode active")

end

-- Start in floating mode
SwordController.setFloating()

-- Store in ReplicatedStorage so boss fight script can call it later
local rs = game:GetService("ReplicatedStorage")
local swordModule = Instance.new("BindableFunction")
swordModule.Name = "SwordController"
swordModule.Parent = rs

swordModule.OnInvoke = function(mode)

    if mode == "floating" then
        SwordController.setFloating()

    elseif mode == "held" then
        SwordController.setHeld()

    elseif mode == "pause" then

        if floatingMonitor then
            floatingMonitor:Disconnect()
            floatingMonitor = nil
        end

        if tween1 then tween1:Cancel() end
        if tween2 then tween2:Cancel() end

        print("Floating paused")

    end

end