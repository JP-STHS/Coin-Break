local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
-- Only allow the game owner
if player.UserId ~= game.CreatorId then
    return
end
local character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = game.Workspace.CurrentCamera

local flying = false
local speed = 20

local function fly()

    local AlignOrientation = Instance.new("AlignOrientation", HumanoidRootPart)
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.Attachment0 = HumanoidRootPart:WaitForChild("RootAttachment")
    AlignOrientation.Responsiveness = 50

    local AlignPosition = Instance.new("AlignPosition", HumanoidRootPart)
    AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    AlignPosition.Attachment0 = HumanoidRootPart:WaitForChild("RootAttachment")

    AlignOrientation.MaxTorque = math.huge
    AlignPosition.MaxForce = math.huge

    flying = true
    while flying do
        RunService.RenderStepped:Wait()
        AlignOrientation.CFrame = CFrame.new(camera.CFrame.Position, HumanoidRootPart.Position)
        AlignPosition.Position = HumanoidRootPart.Position + ((HumanoidRootPart.Position - camera.CFrame.Position).Unit * speed)
    end
end

local function endFlying()
    local AlignPosition = HumanoidRootPart:FindFirstChildOfClass("AlignPosition")
    local AlignOrientation = HumanoidRootPart:FindFirstChildOfClass("AlignOrientation")

    if AlignOrientation and AlignPosition then
        AlignOrientation:Destroy()
        AlignPosition:Destroy()
    end
    flying = false
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.P then
        if not flying then
            fly()
        else
            endFlying()
        end
    end
end)

