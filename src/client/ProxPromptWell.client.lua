local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

ProximityPrompt = workspace:WaitForChild("wellhole").ProximityPrompt

-- Store available pets with weights (higher weight = more common)
local availablePets = {
	[workspace:WaitForChild("sadpet1")] = 0.9,
	[workspace:WaitForChild("coolkpet2")] = 0.9,
	[workspace:WaitForChild("jellipet3")] = 0.9,
	[workspace:WaitForChild("epicpet4")] = 0.9,
	[workspace:WaitForChild("schleppet5")] = 0.9,
	[workspace:WaitForChild("cleetuspet6")] = 0.7,
	[workspace:WaitForChild("bytepet7")] = 0.7,
	[workspace:WaitForChild("yokaipet8")] = 0.7,
	[workspace:WaitForChild("toothlesspet9")] = 0.7,
	[workspace:WaitForChild("taikopet10")] = 0.7,
	[workspace:WaitForChild("windowspet11")] = 0.3,
	[workspace:WaitForChild("linuxpet12")] = 0.3,
	[workspace:WaitForChild("partypet13")] = 0.3,
	[workspace:WaitForChild("screechpet14")] = 0.3,
	[workspace:WaitForChild("crinepet15")] = 0.3,
	[workspace:WaitForChild("angrybirdpet16")] = 0.1,
	[workspace:WaitForChild("happet17")] = 0.1,
	[workspace:WaitForChild("ConorChudpet18")] = 0.1,
	[workspace:WaitForChild("ballpet19")] = 0.1,
	[workspace:WaitForChild("finalpet20")] = 0.001
}
local petImages = {
    ["sadpet1"] = "rbxassetid://117424553745950",
    ["coolkpet2"] = "rbxassetid://74239884632300",
	["jellipet3"] = "rbxassetid://91554313926300",
	["epicpet4"] = "rbxassetid://75782673162601",
	["schleppet5"] = "rbxassetid://79851485437684",
	["cleetuspet6"] = "rbxassetid://131817626345866",
	["bytepet7"] = "rbxassetid://128988683118106",
	["yokaipet8"] = "rbxassetid://96088495057261",
	["toothlesspet9"] = "rbxassetid://73037793852239",
	["taikopet10"] = "rbxassetid://119050067395782",
	["windowspet11"] = "rbxassetid://112284783769998",
	["linuxpet12"] = "rbxassetid://94395338632861",
	["partypet13"] = "rbxassetid://105242273291663",
	["screechpet14"] = "rbxassetid://71180874056561",
	["crinepet15"] = "rbxassetid://133880147682370",
	["angrybirdpet16"] = "rbxassetid://8989817133",
	["happet17"] = "rbxassetid://93707348604530",
	["ConorChudpet18"] = "rbxassetid://126422228814757",
	["ballpet19"] = "rbxassetid://44121271",
    ["finalpet20"]    = "rbxassetid://17358449907",
}
local mysterybox = workspace:WaitForChild("boxmyst")
local confetti = workspace.boxmyst:WaitForChild("confettiparticle")
local og_mystboxloc = mysterybox.CFrame
-- Function to move a pet (Model / Part / MeshPart) safely
local function playPetAnimation(pet)
    local controller = pet:FindFirstChildWhichIsA("AnimationController", true)
    local humanoid = pet:FindFirstChildWhichIsA("Humanoid", true)

    -- If it has a rig, play the real animation
    if controller or humanoid then
        local animation = pet:FindFirstChildWhichIsA("Animation", true)
        if animation then
            local animator
            if humanoid then
                animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
                animator.Parent = humanoid
            else
                animator = controller:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
                animator.Parent = controller
            end
            local track = animator:LoadAnimation(animation)
            track.Looped = true
            track:Play()
            return
        end
    end

    -- Fallback for single parts: looping bob
    local part = pet:IsA("Model") and pet.PrimaryPart or pet
    local originCFrame = part.CFrame
    task.spawn(function()
        while part and part.Parent do
            local t = tick()
            part.CFrame = originCFrame * CFrame.new(0, math.sin(t * 2) * 0.3, 0)
            task.wait(0.03)
        end
    end)
end
local function popOutPet(pet, boxCFrame, displayLocation)
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local pivotCFrame
    local petPrimary -- part we will tween

    if pet:IsA("Model") then
        -- Make sure PrimaryPart exists
        if not pet.PrimaryPart then
            local mainPart = pet:FindFirstChildWhichIsA("BasePart")
            if mainPart then
                pet.PrimaryPart = mainPart
            else
                warn("No BasePart found for pet:", pet.Name)
                return
            end
        end
        petPrimary = pet.PrimaryPart
        pivotCFrame = petPrimary.CFrame
    else
        petPrimary = pet
        pivotCFrame = pet.CFrame
    end

    -- Spawn above box
    petPrimary.CFrame = boxCFrame * CFrame.new(0, 3, 0)

    -- Flip 180° on X-axis for pop-out
    petPrimary.CFrame = petPrimary.CFrame * CFrame.Angles(math.rad(180), 0, math.rad(180))

    -- Float up 2 studs
    local floatTween = TweenService:Create(
        petPrimary,
        tweenInfo,
        {CFrame = petPrimary.CFrame * CFrame.new(0, 2, 0)}
    )
    floatTween:Play()
    floatTween.Completed:Wait()
    task.wait(0.5)

    -- Move to display location
    if displayLocation then
        local targetCFrame = CFrame.new(displayLocation.position) *
            CFrame.Angles(
                math.rad(displayLocation.rotation.X),
                math.rad(displayLocation.rotation.Y),
                math.rad(displayLocation.rotation.Z)
            )
        if pet:IsA("Model") then
            pet:SetPrimaryPartCFrame(targetCFrame)
        else
            pet.CFrame = targetCFrame
        end
    end
end

local petDisplayScreen = game.Players.LocalPlayer.PlayerGui:WaitForChild("PetDisplayScreen")
local frame = petDisplayScreen:WaitForChild("Frame")
local okayButton = frame:WaitForChild("TextButton")
local petImage = frame:WaitForChild("PetLogo")
local rarityText = frame:WaitForChild("PetRarity")
local function fadeGuiElement(element, targetAlpha, duration)
    local tween = TweenService:Create(
        element,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = targetAlpha}
    )
    tween:Play()
    tween.Completed:Wait()
end

local function petdisplay(petName, weight)
    -- Set the pet image
    petImage.Image = petImages[petName] or ""
    petImage.ImageTransparency = 1  -- start invisible
    frame.BackgroundTransparency = 1

    petDisplayScreen.Enabled = true
    frame.Visible = true
	if weight == 0.9 then
		rarityText.Text = "Common Pet!"
	elseif weight == 0.7 then
		rarityText.Text = "Uncommon Pet!"
	elseif weight == 0.3 then
		rarityText.Text = "Rare Pet!"
	elseif weight == 0.1 then
		rarityText.Text = "Epic Pet!"
	elseif weight == 0.001 then
		rarityText.Text = "Legendary Pet!"
	else
		rarityText.Text = "u shouldnt be seeing this!!! lol!!!"
	end
    -- Fade the frame IN
    TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
    TweenService:Create(petImage, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
    -- Also fade in any TextLabels inside the frame
    for _, v in pairs(frame:GetDescendants()) do
        if v:IsA("TextLabel") then
            TweenService:Create(v, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        end
    end

    -- Wait for okay button click, then fade OUT
    local connection
    connection = okayButton.MouseButton1Click:Connect(function()
        connection:Disconnect()

        TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(petImage, TweenInfo.new(0.4), {ImageTransparency = 1}):Play()
        for _, v in pairs(frame:GetDescendants()) do
            if v:IsA("TextLabel") then
                TweenService:Create(v, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            end
        end
        task.wait(0.4)
        frame.Visible = false
        petDisplayScreen.Enabled = false
    end)
end
-- Pet display positions
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
	["windowspet11"] = {position = Vector3.new(49, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["linuxpet12"] = {position = Vector3.new(46, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["partypet13"] = {position = Vector3.new(43, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["screechpet14"] = {position = Vector3.new(40, 6.999, -51), rotation = Vector3.new(0, -180, 0)},
	["crinepet15"] = {position = Vector3.new(37, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["angrybirdpet16"] = {position = Vector3.new(34.007, 7.17, -50.872), rotation = Vector3.new(-24.736, 176.245, -4.768)},
	["happet17"] = {position = Vector3.new(31, 6.999, -51), rotation = Vector3.new(0, 180, 0)},
	["ConorChudpet18"] = {position = Vector3.new(28.096, 8.053, -51), rotation = Vector3.new(0, 87.96, 0)},
	["ballpet19"] = {position = Vector3.new(25, 6.999, -51), rotation = Vector3.new(0, 0, 0)},
	["finalpet20"] = {position = Vector3.new(21.5, 7.634, -51), rotation = Vector3.new(0, 180, 0)}
}

local function selectWeightedPet()
	local totalWeight = 0
	for pet, weight in pairs(availablePets) do
		totalWeight = totalWeight + weight
	end
	
	local randomValue = math.random() * totalWeight
	
	local cumulativeWeight = 0
	for pet, weight in pairs(availablePets) do
		cumulativeWeight = cumulativeWeight + weight
		if randomValue <= cumulativeWeight then
			return pet
		end
	end
	
	return next(availablePets)
end

-- Function to fade a part or model and its decals/textures
local function fadePartOrModel(partOrModel, targetTransparency, tweenTime)
    local tweenInfo = TweenInfo.new(tweenTime or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Tween the part itself
    local tweenProps = TweenService:Create(partOrModel, tweenInfo, {Transparency = targetTransparency})
    tweenProps:Play()

    -- If it’s a model, also tween all BaseParts inside
    if partOrModel:IsA("Model") then
        for _, v in pairs(partOrModel:GetDescendants()) do
            if v:IsA("BasePart") then
                -- Tween the part itself
                TweenService:Create(v, tweenInfo, {Transparency = targetTransparency}):Play()
                -- Tween any decals/textures on the part
                for _, decal in pairs(v:GetDescendants()) do
                    if decal:IsA("Decal") or decal:IsA("Texture") then
                        TweenService:Create(decal, tweenInfo, {Transparency = targetTransparency}):Play()
                    end
                end
            end
        end
    else
        -- If it’s a single part, tween its decals/textures
        for _, decal in pairs(partOrModel:GetDescendants()) do
            if decal:IsA("Decal") or decal:IsA("Texture") then
                TweenService:Create(decal, tweenInfo, {Transparency = targetTransparency}):Play()
            end
        end
    end

    tweenProps.Completed:Wait()
end

ProximityPrompt.Triggered:Connect(function(player)

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local effect = workspace:WaitForChild("particleforwell").wind
	
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://118615925266637"
	local anim = humanoid:LoadAnimation(animation)

	local Tool = player.Backpack:FindFirstChild("Coin") or player.Character:FindFirstChild("Coin")
	if Tool and Tool.Parent == player.Character then
		print("u used a coin")
		
		local petsRemaining = 0
		for _ in pairs(availablePets) do
			petsRemaining = petsRemaining + 1
		end
		
		if petsRemaining == 0 then
			print("No more pets available!")
			return
		end
		
		local prevWalkSpeed = humanoid.WalkSpeed
		local prevJumpHeight = humanoid.JumpHeight
		
		local camera = workspace.CurrentCamera
		local prevCameraType = camera.CameraType
		
		local camera1 = workspace:WaitForChild("Camera1")
		local camera2 = workspace:WaitForChild("Camera2")
		
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camera1.CFrame
		
		rootPart.CFrame = CFrame.new(25, 6.786, -29) * CFrame.Angles(0, math.rad(90), 0)
		
		local animatedCoin = game.ReplicatedStorage.CoinAnim:Clone()
		animatedCoin.Parent = character

		local motor = animatedCoin:FindFirstChildOfClass("Motor6D")
		if motor then
			motor.Part0 = character:FindFirstChild("RightHand")
		end

		anim:Play()
		Tool:Destroy()
		
		task.wait(3)
		
		local tweenInfo1 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween1 = TweenService:Create(camera, tweenInfo1, {CFrame = camera2.CFrame})
		tween1:Play()
		
		local selectedPet = selectWeightedPet()
		local selectedWeight = availablePets[selectedPet]  -- save weight first
		availablePets[selectedPet] = nil                   -- now remove it
		
		print("Selected pet:", selectedPet.Name)
		print("Pets remaining:", petsRemaining - 1)
		
		local displayLocation = petLocations[selectedPet.Name]
		
		anim.Stopped:Connect(function()
			humanoid.WalkSpeed = prevWalkSpeed
			humanoid.JumpHeight = prevJumpHeight
			camera.CameraType = prevCameraType
			animatedCoin:Destroy()
			effect:Emit(100)
			
			-- Move and play box animation
			
			mysterybox.CFrame = CFrame.new(18.697, 6.469, -29.021)
			-- Move box into position
			if mysterybox:IsA("Model") then
				if mysterybox.PrimaryPart then
					mysterybox:SetPrimaryPartCFrame(CFrame.new(18.697, 6.469, -29.021))
				else
					warn("Mystery box model has no PrimaryPart set!")
					return
				end
			else
				mysterybox.CFrame = CFrame.new(18.697, 6.469, -29.021)
			end

			local boxPart = mysterybox
			if mysterybox:IsA("Model") then
				boxPart = mysterybox.PrimaryPart
			end

			local originalCFrame = boxPart.CFrame

			-- 🎬 SHAKE EFFECT
			for i = 1, 10 do
				local offset = CFrame.new(math.random(-1,1)*0.25, 0, math.random(-1,1)*0.25)
				boxPart.CFrame = originalCFrame * offset
				task.wait(0.04)
			end

			boxPart.CFrame = originalCFrame

			-- 🎬 BOUNCE UP
			local bounceUp = TweenService:Create(
				boxPart,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = boxPart.Position + Vector3.new(0, 2, 0)}
			)

			local bounceDown = TweenService:Create(
				boxPart,
				TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				{Position = originalCFrame.Position}
			)

			bounceUp:Play()
			bounceUp.Completed:Wait()
			bounceDown:Play()
			bounceDown.Completed:Wait()

			-- 🎬 SPIN
			local spinTween = TweenService:Create(
				boxPart,
				TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{CFrame = originalCFrame * CFrame.Angles(0, math.rad(360), 0)}
			)

			spinTween:Play()
			spinTween.Completed:Wait()
			-- mysterybox.Transparency = 1
			-- confetti:Emit(200)
			
			-- boxPart.CFrame = originalCFrame
			-- task.wait(1)
			-- mysterybox.CFrame = og_mystboxloc
			-- mysterybox.Transparency = 0
			-- 🎬 Fade box out smoothly
			local fadeOut = TweenService:Create(
				boxPart,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			)

			-- ✨ CLONE PET FOR REVEAL
			local revealPet = selectedPet:Clone()
			revealPet.Parent = workspace

			-- Spawn the pet above the box immediately
			confetti:Emit(200)
			popOutPet(revealPet, boxPart.CFrame, displayLocation)
			playPetAnimation(revealPet)
			-- 🎬 Fade box out smoothly (decals included)
			fadePartOrModel(boxPart, 1, 0.4)

			-- Reset box CFrame
			boxPart.CFrame = og_mystboxloc
			petdisplay(selectedPet.Name, selectedWeight)
			-- 🎬 Fade box back in
			fadePartOrModel(boxPart, 0, 0.4)
		end)
	else
		print("no more coin :c")
	end
end)

