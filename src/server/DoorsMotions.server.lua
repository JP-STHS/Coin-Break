local Workspace = game:GetService("Workspace")
local door1 = Workspace:WaitForChild("Door1")
local doorFrame1 = Workspace:WaitForChild("doorFrame1")
local doorFrame1Hinge = doorFrame1:WaitForChild("HingeConstraint")
local door2 = Workspace:WaitForChild("Door2")
local doorFrame2 = Workspace:WaitForChild("doorFrame2")
local doorFrame2Hinge = doorFrame2:WaitForChild("HingeConstraint")
local door3 = Workspace:WaitForChild("Door3")
local doorFrame3 = Workspace:WaitForChild("doorFrame3")
local doorFrame3Hinge = doorFrame3:WaitForChild("HingeConstraint")
local door4 = Workspace:WaitForChild("Door4")
local doorFrame4 = Workspace:WaitForChild("doorFrame4")
local doorFrame4Hinge = doorFrame4:WaitForChild("HingeConstraint")
local door5 = Workspace:WaitForChild("Door5")
local doorFrame5 = Workspace:WaitForChild("doorFrame5")
local doorFrame5Hinge = doorFrame5:WaitForChild("HingeConstraint")
local door6 = Workspace:WaitForChild("Door6")
local doorFrame6 = Workspace:WaitForChild("doorFrame6")
local doorFrame6Hinge = doorFrame6:WaitForChild("HingeConstraint")

door1.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        doorFrame1Hinge.TargetAngle = -100
    end
end)

door2.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        doorFrame2Hinge.TargetAngle = -100
    end
end)

door3.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        doorFrame3Hinge.TargetAngle = -100
    end
end)

door4.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        doorFrame4Hinge.TargetAngle = -100
    end
end)

door5.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        doorFrame5Hinge.TargetAngle = -100
    end
end)

door6.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        doorFrame6Hinge.TargetAngle = -100
    end
end)