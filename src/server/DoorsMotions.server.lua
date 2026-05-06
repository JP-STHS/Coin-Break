local Workspace = game:GetService("Workspace")
local SpawnedLevels = Workspace:WaitForChild("SpawnedLevels")

SpawnedLevels.ChildAdded:Connect(function(level)
    if level.Name ~= "Level18" then return end


    local door1 = level:WaitForChild("Door1")
    local doorFrame1 = level:WaitForChild("doorFrame1")
    local doorFrame1Hinge = doorFrame1:WaitForChild("HingeConstraint")
    local door2 = level:WaitForChild("Door2")
    local doorFrame2 = level:WaitForChild("doorFrame2")
    local doorFrame2Hinge = doorFrame2:WaitForChild("HingeConstraint")
    local door3 = level:WaitForChild("Door3")
    local doorFrame3 = level:WaitForChild("doorFrame3")
    local doorFrame3Hinge = doorFrame3:WaitForChild("HingeConstraint")
    local door4 = level:WaitForChild("Door4")
    local doorFrame4 = level:WaitForChild("doorFrame4")
    local doorFrame4Hinge = doorFrame4:WaitForChild("HingeConstraint")
    local door5 = level:WaitForChild("Door5")
    local doorFrame5 = level:WaitForChild("doorFrame5")
    local doorFrame5Hinge = doorFrame5:WaitForChild("HingeConstraint")
    local door6 = level:WaitForChild("Door6")
    local doorFrame6 = level:WaitForChild("doorFrame6")
    local doorFrame6Hinge = doorFrame6:WaitForChild("HingeConstraint")
    local doorAudio = Workspace:WaitForChild("DoorOpen")

    local closet = level:WaitForChild("closet")
    local closetdoor1 = level:WaitForChild("closetd1")
    local closetdoor2 = level:WaitForChild("closetd2")
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
end)