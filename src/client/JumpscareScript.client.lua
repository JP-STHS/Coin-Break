local jumpscareEvent = game:GetService("ReplicatedStorage"):WaitForChild("Jumpscare")
local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")
local jumpscareAudio = Workspace:WaitForChild("Jumpy")

jumpscareEvent.OnClientEvent:Connect(function()
    local gui = player.PlayerGui:WaitForChild("JumpscareGui")
    local frame = gui:WaitForChild("Frame")
    local image = frame:WaitForChild("JumpscareImage")
    jumpscareAudio:Play()

    -- show instantly
    frame.Visible = true
    image.ImageTransparency = 0

    -- hold for a moment then fade out
    task.wait(3)
    frame.Visible = false
end)