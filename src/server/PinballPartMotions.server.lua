local workspace = game:GetService("Workspace")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")

SpawnedLevels.ChildAdded:Connect(function(level)
    if level.Name ~= "Level17" then return end
	local flipper = level:WaitForChild("flippercore1")
	local flipper2 = level:WaitForChild("flippercore2")
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
end)
