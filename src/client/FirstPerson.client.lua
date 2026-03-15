local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local firstpersonpart = Workspace:WaitForChild("firstperson")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function isInsidePart(position, part)
    local localPos = part.CFrame:PointToObjectSpace(position)
    local size = part.Size / 2
    return math.abs(localPos.X) <= size.X
        and math.abs(localPos.Y) <= size.Y
        and math.abs(localPos.Z) <= size.Z
end

-- check every frame if player is inside the part
game:GetService("RunService").Heartbeat:Connect(function()
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if isInsidePart(root.Position, firstpersonpart) then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        player.CameraMode = Enum.CameraMode.Classic
    end
end)