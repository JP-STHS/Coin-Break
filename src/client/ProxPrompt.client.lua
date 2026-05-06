-- CustomProximityPrompt LocalScript
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CustomPromptGui"
screenGui.Parent = player.PlayerGui

local activePrompts = {}
local camera = workspace.CurrentCamera
local activeTweens = {}

-- ============================================================
-- STYLING
-- ============================================================
local PROMPT_COLOR        = Color3.fromRGB(15, 15, 15)
local OUTLINE_COLOR       = Color3.fromRGB(180, 220, 255)
local OUTLINE_THICKNESS   = 2
local TEXT_COLOR          = Color3.fromRGB(255, 255, 255)
local OBJECT_TEXT_COLOR   = Color3.fromRGB(180, 220, 255)
local KEY_COLOR           = Color3.fromRGB(30, 30, 30)
local KEY_OUTLINE_COLOR   = Color3.fromRGB(180, 220, 255)
local BUBBLE_COLOR        = Color3.fromRGB(15, 15, 15)
local FONT                = Font.new("rbxassetid://12187371840")
local FONT_BOLD           = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)

-- ============================================================
-- UTILS
-- ============================================================

local function applyTransparency(data, alpha)
	-- Primary alpha (0 is visible, 1 is invisible)
	for instance, originalValue in pairs(data.objects) do
		if instance:IsA("TextLabel") then
			instance.TextTransparency = alpha
		elseif instance:IsA("UIStroke") then
			instance.Transparency = alpha
		elseif instance:IsA("Frame") then
			-- Bubbles have custom base transparency (0.2)
			local base = data.baseTransparencies[instance] or 0
			instance.BackgroundTransparency = base + (alpha * (1 - base))
		end
	end
end

local function makeCircle(parent, size, xAnchor, yAnchor, xOffset, yOffset, objects, baseTrans)
	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, size, 0, size)
	circle.Position = UDim2.new(xAnchor, xOffset, yAnchor, yOffset)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundColor3 = BUBBLE_COLOR
	circle.BackgroundTransparency = 0.2
	circle.BorderSizePixel = 0
	circle.ZIndex = 0
	circle.Parent = parent
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = circle

	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = OUTLINE_THICKNESS
	stroke.Parent = circle
	
	objects[circle] = true
	objects[stroke] = true
	baseTrans[circle] = 0.2
	return circle
end

game:GetService("RunService").RenderStepped:Connect(function()
    for prompt, data in pairs(activePrompts) do
        local part = prompt.Parent
        if not part or not part:IsA("BasePart") then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

        if onScreen then
            -- 1. Calculate position first
            data.frame.Position = UDim2.new(
                0, screenPos.X - data.frame.AbsoluteSize.X / 2,
                0, screenPos.Y - data.frame.AbsoluteSize.Y - 30
            )
            
            -- 2. Only now make it visible (prevents the top-left flicker)
            if data.frame.Visible == false then
                data.frame.Visible = true
            end
        else
            data.frame.Visible = false
        end
    end
end)

local function makePromptUI(prompt)
	local data = {
		objects = {},
		baseTransparencies = {}
	}

    local container = Instance.new("Frame")
    container.Visible = false -- Keep this false!
    container.Size = UDim2.new(0, 160, 0, 80)
    -- Start it way off-screen just in case
    container.Position = UDim2.new(0, -1000, 0, -1000) 
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
	-- Bubbles
	makeCircle(container, 44, 0, 0.5, -16, -24, data.objects, data.baseTransparencies)
	makeCircle(container, 44, 1, 1, 10, 8, data.objects, data.baseTransparencies)
	makeCircle(container, 14, 0, 0, 18, -10, data.objects, data.baseTransparencies)
	makeCircle(container, 10, 1, 1, -24, 28, data.objects, data.baseTransparencies)

	-- Main Box
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 1, 0)
	box.BackgroundColor3 = PROMPT_COLOR
	box.BorderSizePixel = 0
	box.ZIndex = 2
	box.Parent = container
	data.objects[box] = true

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0.12, 0)
	boxCorner.Parent = box

	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = OUTLINE_THICKNESS
	stroke.Parent = box
	data.objects[stroke] = true

	-- Key Badge
	local keyBadge = Instance.new("Frame")
	keyBadge.Size = UDim2.new(0, 36, 0, 36)
	keyBadge.Position = UDim2.new(0.5, 0, 0, -18)
	keyBadge.AnchorPoint = Vector2.new(0.5, 0)
	keyBadge.BackgroundColor3 = KEY_COLOR
	keyBadge.ZIndex = 3
	keyBadge.Parent = container
	data.objects[keyBadge] = true

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0.2, 0)
	kc.Parent = keyBadge

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = KEY_OUTLINE_COLOR
	keyStroke.Thickness = OUTLINE_THICKNESS
	keyStroke.Parent = keyBadge
	data.objects[keyStroke] = true

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, 0, 1, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.TextColor3 = TEXT_COLOR
	keyLabel.TextScaled = true
	keyLabel.FontFace = FONT_BOLD
	keyLabel.ZIndex = 3
	keyLabel.Text = tostring(prompt.KeyboardKeyCode):gsub("Enum.KeyCode.", "")
	keyLabel.Parent = keyBadge
	data.objects[keyLabel] = true

	-- Text Labels
	local objectLabel = Instance.new("TextLabel")
	objectLabel.Size = UDim2.new(1, -16, 0, 22)
	objectLabel.Position = UDim2.new(0, 8, 0, 22)
	objectLabel.BackgroundTransparency = 1
	objectLabel.TextColor3 = OBJECT_TEXT_COLOR
	objectLabel.TextScaled = true
	objectLabel.FontFace = FONT
	objectLabel.Text = prompt.ObjectText
	objectLabel.ZIndex = 3
	objectLabel.Parent = box
	data.objects[objectLabel] = true

	local actionLabel = Instance.new("TextLabel")
	actionLabel.Size = UDim2.new(1, -16, 0, 26)
	actionLabel.Position = UDim2.new(0, 8, 0, 44)
	actionLabel.BackgroundTransparency = 1
	actionLabel.TextColor3 = TEXT_COLOR
	actionLabel.TextScaled = true
	actionLabel.FontFace = FONT_BOLD
	actionLabel.Text = prompt.ActionText
	actionLabel.ZIndex = 3
	actionLabel.Parent = box
	data.objects[actionLabel] = true

	-- Progress Bar
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0, 0, 0, 3)
	progressBar.Position = UDim2.new(0, 8, 1, -6)
	progressBar.BackgroundColor3 = OUTLINE_COLOR
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 3
	progressBar.Parent = box
	data.objects[progressBar] = true

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(1, 0)
	pc.Parent = progressBar
    --initial transparency
    applyTransparency(data, 1)

    -- Fade Logic
    local fadeValue = Instance.new("NumberValue")
    fadeValue.Value = 1
    fadeValue.Changed:Connect(function(val)
        applyTransparency(data, val)
    end)

    -- Start the fade-in
    TweenService:Create(fadeValue, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Value = 0}):Play()

    data.frame = container
    data.progressBar = progressBar
    data.fadeValue = fadeValue
    return data
end

-- ============================================================
-- CORE LOGIC
-- ============================================================

RunService.RenderStepped:Connect(function()
	for prompt, data in pairs(activePrompts) do
		local part = prompt.Parent
		if not part or not part:IsA("BasePart") then continue end

		local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

		if onScreen then
			data.frame.Position = UDim2.new(
				0, screenPos.X - data.frame.AbsoluteSize.X / 2,
				0, screenPos.Y - data.frame.AbsoluteSize.Y - 30
			)
			data.frame.Visible = true
		else
			data.frame.Visible = false
		end
	end
end)

ProximityPromptService.PromptShown:Connect(function(prompt)
	if activePrompts[prompt] then return end
	activePrompts[prompt] = makePromptUI(prompt)
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	local data = activePrompts[prompt]
	if not data then return end
	activePrompts[prompt] = nil
	
	local tween = TweenService:Create(data.fadeValue, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Value = 1})
	tween:Play()
	tween.Completed:Connect(function()
		data.frame:Destroy()
	end)
end)

-- Hold Tweens
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, p)
	if p ~= player then return end
	local data = activePrompts[prompt]
	if not data then return end
	local tween = TweenService:Create(data.progressBar, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, -16, 0, 3)})
	activeTweens[prompt] = tween
	tween:Play()
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, p)
	if p ~= player then return end
	local data = activePrompts[prompt]
	if not data then return end
	if activeTweens[prompt] then
		activeTweens[prompt]:Cancel()
		activeTweens[prompt] = nil
	end
	data.progressBar.Size = UDim2.new(0, 0, 0, 3)
end)