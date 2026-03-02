local part = workspace:WaitForChild("platform").rotation
local tweenService = game:GetService("TweenService")
--grow and shrink the part
while true do
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local tween = tweenService:Create(part, tweenInfo, {Size = Vector3.new(70, 5, 50)})
    tween:Play()
    tween.Completed:Wait()
    local tween2 = tweenService:Create(part, tweenInfo, {Size = Vector3.new(40, 5, 25)})
    tween2:Play()
    tween2.Completed:Wait()
end