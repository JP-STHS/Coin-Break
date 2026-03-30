local workspace = game:GetService("Workspace")
local boss = workspace:WaitForChild("Boss1x")
local rootPart = boss:WaitForChild("HumanoidRootPart")
local sword1 = boss:WaitForChild("Sword1")
local sword2 = boss:WaitForChild("Sword2")

local sword1Primary = sword1.PrimaryPart
local sword2Primary = sword2.PrimaryPart

-- ============================================================
-- CONFIGURATION
-- ============================================================
-- Floating offsets relative to boss root (stage 1 & 2)
local FLOAT_OFFSET_1 = CFrame.new(-4, 1, 0) * CFrame.Angles(0, math.rad(180), 0) --left
local FLOAT_OFFSET_2 = CFrame.new(4, 1, 0) * CFrame.Angles(0, math.rad(180), 0)    -- right side

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

function SwordController.setFloating()
    anchorSwordParts(sword1, false)
    anchorSwordParts(sword2, false)
    weldTo(sword1Primary, rootPart, FLOAT_OFFSET_1)
    weldTo(sword2Primary, rootPart, FLOAT_OFFSET_2)
    print("Swords set to floating mode")
end

function SwordController.setHeld()
    local leftHand  = boss:WaitForChild("LeftHand")
    local rightHand = boss:WaitForChild("RightHand")
    anchorSwordParts(sword1, false)
    anchorSwordParts(sword2, false)
    weldTo(sword1Primary, leftHand,  HAND_OFFSET_1)
    weldTo(sword2Primary, rightHand, HAND_OFFSET_2)
    print("Swords set to held mode")
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
    end
end