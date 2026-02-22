local TweenService = game:GetService("TweenService")

ProximityPrompt = workspace:WaitForChild("wellhole").ProximityPrompt

-- Store available pets (this persists between triggers)
local availablePets = {
	workspace:WaitForChild("sadpet1"),
	workspace:WaitForChild("coolkpet2"),
	workspace:WaitForChild("jellipet3"),
	workspace:WaitForChild("epicpet4"),
	workspace:WaitForChild("schleppet5"),
	workspace:WaitForChild("cleetuspet6"),
	workspace:WaitForChild("bytepet7"),
	workspace:WaitForChild("yokaipet8"),
	workspace:WaitForChild("toothlesspet9"),
	workspace:WaitForChild("taikopet10"),
	workspace:WaitForChild("windowspet11"),
	workspace:WaitForChild("linuxpet12"),
	workspace:WaitForChild("partypet13"),
	workspace:WaitForChild("screechpet14"),
	workspace:WaitForChild("crinepet15"),
	workspace:WaitForChild("angrybirdpet16"),
	workspace:WaitForChild("happet17"),
	workspace:WaitForChild("ConorChudpet18"),
	workspace:WaitForChild("ballpet19"),
	workspace:WaitForChild("finalpet20")
}

-- Pet display positions - each pet has its own designated spot
local petLocations = {
	["sadpet1"] = {position = Vector3.new(49, 4, -46), rotation = Vector3.new(0, -180, 0)},
	["coolkpet2"] = {position = Vector3.new(46, 4, -46), rotation = Vector3.new(0, -180, 0)},
	["jellipet3"] = {position = Vector3.new(43, 4, -46), rotation = Vector3.new(0, 180, 0)},
	["epicpet4"] = {position = Vector3.new(40, 4, -46), rotation = Vector3.new(0, 180, 0)},
	["schleppet5"] = {position = Vector3.new(37, 4, -46), rotation = Vector3.new(0, 180, 0)},
	["cleetuspet6"] = {position = Vector3.new(33.959, 5.573, -46.149), rotation = Vector3.new(-4.697, 0.337, -4.112)},
	["bytepet7"] = {position = Vector3.new(31, 4, -46), rotation = Vector3.new(0, 180, 0)},
	["yokaipet8"] = {position = Vector3.new(28.096, 3.992, -46), rotation = Vector3.new(0, 180, 0)},
	["toothlesspet9"] = {position = Vector3.new(25, 4, -46), rotation = Vector3.new(0, 180, 0)},
	["taikopet10"] = {position = Vector3.new(22, 4, -46), rotation = Vector3.new(0, 180, 0)},
	-- Top row
	["windowspet11"] = {position = Vector3.new(49, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["linuxpet12"] = {position = Vector3.new(46, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["partypet13"] = {position = Vector3.new(43, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["screechpet14"] = {position = Vector3.new(40, 6.999, -51), rotation = Vector3.new(0, -180, 0)},
	["crinepet15"] = {position = Vector3.new(37, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["angrybirdpet16"] = {position = Vector3.new(31.006, 7.121, -51.046), rotation = Vector3.new(21.344, 179.943, -4.671)},
	["happet17"] = {position = Vector3.new(31, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["ConorChudpet18"] = {position = Vector3.new(28.096, 8.053, -51), rotation = Vector3.new(0, 87.96, 0)},
	["ballpet19"] = {position = Vector3.new(25, 6.999, -51), rotation = Vector3.new(0, 0, 0)},
	["finalpet20"] = {position = Vector3.new(22, 7.634, -51), rotation = Vector3.new(0, 180, 0)}
}

ProximityPrompt.Triggered:Connect(function(player)

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local effect = workspace:WaitForChild("particleforwell").wind
	
	-- Create and load the animation
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://118615925266637"
	local anim = humanoid:LoadAnimation(animation)

	local Tool = player.Backpack:FindFirstChild("Coin") or player.Character:FindFirstChild("Coin")
	if Tool and Tool.Parent == player.Character then
		print("u used a coin")
		
		-- Check if there are any pets left
		if #availablePets == 0 then
			print("No more pets available!")
			return
		end
		
		-- Save original states
		local prevWalkSpeed = humanoid.WalkSpeed
		local prevJumpHeight = humanoid.JumpHeight
		
		-- Get camera and save its state
		local camera = workspace.CurrentCamera
		local prevCameraType = camera.CameraType
		
		-- Get the camera parts
		local camera1 = workspace:WaitForChild("Camera1")
		local camera2 = workspace:WaitForChild("Camera2")
		
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
		task.wait(3)
		
		local tweenInfo1 = TweenInfo.new(
			0.5,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		local tween1 = TweenService:Create(camera, tweenInfo1, {CFrame = camera2.CFrame})
		tween1:Play()
		
		-- 🎰 ROULETTE: Pick random pet and remove it from the list
		local randomIndex = math.random(1, #availablePets)
		local selectedPet = availablePets[randomIndex]
		
		-- Remove the selected pet from the available list
		table.remove(availablePets, randomIndex)
		
		print("Selected pet:", selectedPet.Name)
		print("Pets remaining:", #availablePets)
		
		-- Get the specific display location for THIS pet
		local displayLocation = petLocations[selectedPet.Name]
		
		if displayLocation then
			local newCFrame = CFrame.new(displayLocation.position) * 
							  CFrame.Angles(
								  math.rad(displayLocation.rotation.X), 
								  math.rad(displayLocation.rotation.Y), 
								  math.rad(displayLocation.rotation.Z)
							  )
			
			-- Move the pet based on its type
			if selectedPet:IsA("Model") then
				-- For models, use PrimaryPart if available
				if selectedPet.PrimaryPart then
					selectedPet:SetPrimaryPartCFrame(newCFrame)
				else
					-- If no PrimaryPart, try to find the main part
					local mainPart = selectedPet:FindFirstChildWhichIsA("BasePart")
					if mainPart then
						selectedPet:SetPrimaryPartCFrame(newCFrame)
					end
				end
			elseif selectedPet:IsA("MeshPart") or selectedPet:IsA("Part") or selectedPet:IsA("BasePart") then
				-- For single parts (including MeshParts)
				selectedPet.CFrame = newCFrame
			end
		else
			warn("No location found for pet:", selectedPet.Name)
		end
		
		-- Clean up when animation ends
		anim.Stopped:Connect(function()
			humanoid.WalkSpeed = prevWalkSpeed
			humanoid.JumpHeight = prevJumpHeight
			camera.CameraType = prevCameraType
			animatedCoin:Destroy()
			effect:Emit(100)
		end)
	else
		print("no more coin :c")
	end
end)