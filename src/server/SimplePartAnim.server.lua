local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")

SpawnedLevels.ChildAdded:Connect(function(level)
    if level.Name ~= "Level1" then return end

    print("Level1 spawned!")

    local part = level:WaitForChild("platform"):WaitForChild("rotation")
    local TweenService = game:GetService("TweenService")

    task.spawn(function()
        while level.Parent do
            local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

            local tween = TweenService:Create(part, tweenInfo, {
                Size = Vector3.new(70, 5, 50)
            })
            tween:Play()
            tween.Completed:Wait()

            local tween2 = TweenService:Create(part, tweenInfo, {
                Size = Vector3.new(40, 5, 25)
            })
            tween2:Play()
            tween2.Completed:Wait()
        end
    end)
end)