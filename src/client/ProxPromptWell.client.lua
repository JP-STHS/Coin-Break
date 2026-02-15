local TweenService = game:GetService("TweenService")

ProximityPrompt = workspace:WaitForChild("wellhole").ProximityPrompt
ProximityPrompt.Triggered:Connect(function(player)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Create and load the animation
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://118615925266637"
	local anim = humanoid:LoadAnimation(animation)

	local Tool = player.Backpack:FindFirstChild("Coin") or player.Character:FindFirstChild("Coin")
	if Tool and Tool.Parent == player.Character then
		print("u used a coin")
		
		-- Save original states
		local prevWalkSpeed = humanoid.WalkSpeed
		local prevJumpHeight = humanoid.JumpHeight
		
		-- Get camera and save its state
		local camera = workspace.CurrentCamera
		local prevCameraType = camera.CameraType
		
		-- Get the camera parts (adjust names if different)
		local camera1 = workspace:WaitForChild("Camera1") -- First camera view
		local camera2 = workspace:WaitForChild("Camera2") -- Second camera view
		
		-- Disable movement
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		
		-- Lock the camera
		camera.CameraType = Enum.CameraType.Scriptable
		
		-- CAMERA POSITION 1: Set to first camera part
		camera.CFrame = camera1.CFrame
		
		-- Position and rotate the character
		rootPart.CFrame = CFrame.new(25, 6.786, -29) * CFrame.Angles(0, math.rad(90), 0)
		
		-- ✨ Clone and attach the animated coin
		local animatedCoin = game.ReplicatedStorage.CoinAnim:Clone()
		animatedCoin.Parent = character

		-- Find the Motor6D and connect it to RightHand
		local motor = animatedCoin:FindFirstChildOfClass("Motor6D")
		if motor then
			motor.Part0 = character:FindFirstChild("RightHand")
		end

		-- Play the animation
		anim:Play()
		Tool:Destroy()
		
		-- CAMERA TWEEN 1: Move to second camera view (when coin drops)
		task.wait(3) -- Adjust timing based on when coin drops in your animation
		
		local tweenInfo1 = TweenInfo.new(
			0.5, -- Duration (quick and snappy)
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		local tween1 = TweenService:Create(camera, tweenInfo1, {CFrame = camera2.CFrame})
		tween1:Play()
		
		-- Clean up when animation ends
		anim.Stopped:Connect(function()
			humanoid.WalkSpeed = prevWalkSpeed
			humanoid.JumpHeight = prevJumpHeight
			camera.CameraType = prevCameraType
			animatedCoin:Destroy()
		end)
	else
		print("no more coin :c")
	end
end)