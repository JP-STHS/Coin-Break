local Workspace = game:GetService("Workspace")
local button1 = Workspace:WaitForChild("ballpart1")
local button2 = Workspace:WaitForChild("button2ball")
local button3 = Workspace:WaitForChild("button3ball")
local chamber = Workspace:WaitForChild("chamber")
local button1Touched = false
local button2Touched = false
local button3Touched = false
local keyball1 = Workspace:WaitForChild("keyball1")
local keyball2 = Workspace:WaitForChild("keyball2")
local keyball3 = Workspace:WaitForChild("keyball3")

button1.Touched:Connect(function(hit)
    button1Touched = true
    keyball1.BrickColor = BrickColor.new("Mint")
end)

button2.Touched:Connect(function(hit)
    button2Touched = true
    keyball2.BrickColor = BrickColor.new("Mint")
end)

button3.Touched:Connect(function(hit)
    button3Touched = true
    keyball3.BrickColor = BrickColor.new("Mint")
end)
local audiostopper = false
while true do
    if button1Touched and button2Touched and button3Touched then
        chamber.Transparency = 1
        chamber.CanCollide = false
        if audiostopper == false then
            audiostopper = true
            local audio = Instance.new("Sound", Workspace)
            audio.SoundId = "rbxassetid://17208335138"
            audio:Play()
            audio.Ended:Connect(function()
            audio:Destroy()
        end)
        end
    else
        chamber.Transparency = 0
        chamber.CanCollide = true
    end
    task.wait(0.1)
end