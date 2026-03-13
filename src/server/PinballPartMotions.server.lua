local Workspace = game:GetService("Workspace")
local flipper = Workspace:WaitForChild("flippercore1")
local flipper2 = Workspace:WaitForChild("flippercore2")
local hinge = flipper:WaitForChild("HingeConstraint")
local hinge2 = flipper2:WaitForChild("HingeConstraint")
print(hinge.CurrentAngle)
while true do
	-- Flip up
	hinge.TargetAngle = 90
    hinge2.TargetAngle = 90
	task.wait(1)
	-- Flip down
	hinge.TargetAngle = 0
    hinge2.TargetAngle = 0
	task.wait(1)
end
