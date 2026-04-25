local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")

local function setupLevel(level)

    if level.Name ~= "Level17" then
        return
    end

    print("Level17 detected, setting up buttons")

    local button1 = level:WaitForChild("ballpart1")
    local button2 = level:WaitForChild("button2ball")
    local button3 = level:WaitForChild("button3ball")
    local chamber = level:WaitForChild("chamber")

    local keyball1 = level:WaitForChild("keyball1")
    local keyball2 = level:WaitForChild("keyball2")
    local keyball3 = level:WaitForChild("keyball3")

    local button1Touched = false
    local button2Touched = false
    local button3Touched = false

    button1.Touched:Connect(function()
        button1Touched = true
        keyball1.BrickColor = BrickColor.new("Mint")
    end)

    button2.Touched:Connect(function()
        button2Touched = true
        keyball2.BrickColor = BrickColor.new("Mint")
    end)

    button3.Touched:Connect(function()
        button3Touched = true
        keyball3.BrickColor = BrickColor.new("Mint")
    end)

    local audiostopper = false

    task.spawn(function()
        while true do

            if button1Touched and button2Touched and button3Touched then

                chamber.Transparency = 1
                chamber.CanCollide = false

                if not audiostopper then
                    audiostopper = true

                    local audio = Instance.new("Sound")
                    audio.Parent = level
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
    end)

end

-- Run for future spawned levels
SpawnedLevels.ChildAdded:Connect(setupLevel)

-- Also run for levels that already exist
for _, level in ipairs(SpawnedLevels:GetChildren()) do
    setupLevel(level)
end