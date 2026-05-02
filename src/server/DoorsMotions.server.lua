local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local LevelsFolder = ServerStorage:WaitForChild("Levels")
local EpicCategory = LevelsFolder:WaitForChild("Epic")
local Level18 = EpicCategory:WaitForChild("Level18")


local door1 = Level18:WaitForChild("Door1")
local doorFrame1 = Level18:WaitForChild("doorFrame1")
local doorFrame1Hinge = doorFrame1:WaitForChild("HingeConstraint")
local door2 = Level18:WaitForChild("Door2")
local doorFrame2 = Level18:WaitForChild("doorFrame2")
local doorFrame2Hinge = doorFrame2:WaitForChild("HingeConstraint")
local door3 = Level18:WaitForChild("Door3")
local doorFrame3 = Level18:WaitForChild("doorFrame3")
local doorFrame3Hinge = doorFrame3:WaitForChild("HingeConstraint")
local door4 = Level18:WaitForChild("Door4")
local doorFrame4 = Level18:WaitForChild("doorFrame4")
local doorFrame4Hinge = doorFrame4:WaitForChild("HingeConstraint")
local door5 = Level18:WaitForChild("Door5")
local doorFrame5 = Level18:WaitForChild("doorFrame5")
local doorFrame5Hinge = doorFrame5:WaitForChild("HingeConstraint")
local door6 = Level18:WaitForChild("Door6")
local doorFrame6 = Level18:WaitForChild("doorFrame6")
local doorFrame6Hinge = doorFrame6:WaitForChild("HingeConstraint")
local doorAudio = Workspace:WaitForChild("DoorOpen")

local closet = Level18:WaitForChild("closet")
local closetdoor1 = Level18:WaitForChild("closetd1")
local closetdoor2 = Level18:WaitForChild("closetd2")
local closetdoor1Hinge = closetdoor1:WaitForChild("HingeConstraint")
local closetdoor2Hinge = closetdoor2:WaitForChild("HingeConstraint")

closet.ProximityPrompt.Triggered:Connect(function()
    if closetdoor1Hinge.TargetAngle == 0 then
        doorAudio:Play()
    end
    closetdoor1Hinge.TargetAngle = 100
    closetdoor2Hinge.TargetAngle = -100
    task.wait(1)
    closetdoor1Hinge.TargetAngle = 0
    closetdoor2Hinge.TargetAngle = 0
end)

door1.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        if doorFrame1Hinge.TargetAngle == 0 then
            doorAudio:Play()
        end
        doorFrame1Hinge.TargetAngle = -100
    end
end)

door2.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        if doorFrame2Hinge.TargetAngle == 0 then
            doorAudio:Play()
        end
        doorFrame2Hinge.TargetAngle = -100
    end
end)

door3.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        if doorFrame3Hinge.TargetAngle == 0 then
            doorAudio:Play()
        end
        doorFrame3Hinge.TargetAngle = -100
    end
end)

door4.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        if doorFrame4Hinge.TargetAngle == 0 then
            doorAudio:Play()
        end
        doorFrame4Hinge.TargetAngle = -100
    end
end)

door5.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        if doorFrame5Hinge.TargetAngle == 0 then
            doorAudio:Play()
        end
        doorFrame5Hinge.TargetAngle = -100
    end
end)

door6.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        if doorFrame6Hinge.TargetAngle == 0 then
            doorAudio:Play()
        end
        doorFrame6Hinge.TargetAngle = -100
    end
end)