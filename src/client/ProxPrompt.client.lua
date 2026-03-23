-- CustomProximityPrompt LocalScript
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CustomPromptGui"
screenGui.Parent = player.PlayerGui

local activePrompts = {}
local camera = workspace.CurrentCamera
local activeTweens = {}

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, p)
    if p ~= player then return end
    local data = activePrompts[prompt]
    if not data then return end
    local tween = TweenService:Create(data.progressBar, TweenInfo.new(
        prompt.HoldDuration, Enum.EasingStyle.Linear
    ), {Size = UDim2.new(1, -16, 0, 3)})
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

game:GetService("RunService").RenderStepped:Connect(function()
    for prompt, data in pairs(activePrompts) do
        local part = prompt.Parent
        if not part or not part:IsA("BasePart") then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

        if onScreen then
            data.frame.Visible = true
            -- Offset upward so it floats above the part
            data.frame.Position = UDim2.new(
                0, screenPos.X - data.frame.AbsoluteSize.X / 2,
                0, screenPos.Y - data.frame.AbsoluteSize.Y - 30
            )
            data.frame.Visible = true  -- show AFTER position is set
        else
            data.frame.Visible = false
        end
    end
end)

-- ============================================================
-- STYLING
-- ============================================================
local PROMPT_COLOR        = Color3.fromRGB(15, 15, 15)
local OUTLINE_COLOR       = Color3.fromRGB(180, 220, 255)  -- blue outline
local OUTLINE_THICKNESS   = 2
local TEXT_COLOR          = Color3.fromRGB(255, 255, 255)
local OBJECT_TEXT_COLOR   = Color3.fromRGB(180, 220, 255)
local KEY_COLOR           = Color3.fromRGB(30, 30, 30)
local KEY_OUTLINE_COLOR   = Color3.fromRGB(180, 220, 255)
local BUBBLE_COLOR        = Color3.fromRGB(15, 15, 15)
local FONT                = Font.new("rbxassetid://12187371840")
local FONT_BOLD           = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
-- ============================================================

local function makeCircle(parent, size, xAnchor, yAnchor, xOffset, yOffset, transparency)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, size, 0, size)
    circle.Position = UDim2.new(xAnchor, xOffset, yAnchor, yOffset)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.BackgroundColor3 = BUBBLE_COLOR
    circle.BackgroundTransparency = transparency or 0.2
    circle.BorderSizePixel = 0
    circle.ZIndex = 0  -- behind the main frame
    circle.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = circle

    -- Outline on bubble
    local stroke = Instance.new("UIStroke")
    stroke.Color = OUTLINE_COLOR
    stroke.Thickness = OUTLINE_THICKNESS
    stroke.Parent = circle
    return circle
end

local function makePromptUI(prompt)
    -- Outer container (just for positioning)
    local container = Instance.new("Frame")
    container.Visible = false  -- hide until RenderStepped positions it
    container.Size = UDim2.new(0, 160, 0, 80)
    container.Position = UDim2.new(0, -9999, 0, -9999)  -- offscreen until RenderStepped kicks in    container.AnchorPoint = Vector2.new(0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = screenGui

    -- Bubbles (parented to container, behind main box)
    makeCircle(container, 44, 0, 0.5, -16, -24)   -- big left
    makeCircle(container, 44, 1, 1, 10, 8)   -- big bottom right
    makeCircle(container, 14, 0, 0, 18, -10)   -- small top left
    makeCircle(container, 10, 1, 1, -24, 28)   -- small bottom right

    -- Main box
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 1, 0)
    box.Position = UDim2.new(0, 0, 0, 0)
    box.BackgroundColor3 = PROMPT_COLOR
    box.BackgroundTransparency = 0
    box.BorderSizePixel = 0
    box.ZIndex = 2
    box.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0.12, 0)
    boxCorner.Parent = box

    -- Outline on main box
    local stroke = Instance.new("UIStroke")
    stroke.Color = OUTLINE_COLOR
    stroke.Thickness = OUTLINE_THICKNESS
    stroke.Parent = box

    -- Key badge (top center, like default Roblox prompt)
    local keyBadge = Instance.new("Frame")
    keyBadge.Size = UDim2.new(0, 36, 0, 36)
    keyBadge.Position = UDim2.new(0.5, 0, 0, -18)
    keyBadge.AnchorPoint = Vector2.new(0.5, 0)
    keyBadge.BackgroundColor3 = KEY_COLOR
    keyBadge.BorderSizePixel = 0
    keyBadge.ZIndex = 3
    keyBadge.Parent = container

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0.2, 0)
    kc.Parent = keyBadge

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = KEY_OUTLINE_COLOR
    keyStroke.Thickness = OUTLINE_THICKNESS
    keyStroke.Parent = keyBadge

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, 0, 1, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.TextColor3 = TEXT_COLOR
    keyLabel.TextScaled = true
    keyLabel.FontFace = FONT_BOLD
    keyLabel.ZIndex = 3
    local keyName = tostring(prompt.KeyboardKeyCode):gsub("Enum.KeyCode.", "")
    keyLabel.Text = keyName
    keyLabel.Parent = keyBadge

    -- Object text
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

    -- Action text
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

    -- Progress bar for hold prompts
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 8, 1, -6)
    progressBar.BackgroundColor3 = OUTLINE_COLOR
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 3
    progressBar.Parent = box
    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(1, 0)
    pc.Parent = progressBar

    -- Tween in
    -- container.GroupTransparency = 1
    TweenService:Create(container, TweenInfo.new(0.15), {
        -- GroupTransparency = 0
    }):Play()

    return { frame = container, progressBar = progressBar, prompt = prompt }
end

-- ============================================================
-- Show / Hide / Progress
-- ============================================================
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    if activePrompts[prompt] then return end
    activePrompts[prompt] = makePromptUI(prompt)
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    local data = activePrompts[prompt]
    if not data then return end
    local tween = TweenService:Create(data.frame, TweenInfo.new(0.1), {
        -- GroupTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        data.frame:Destroy()
    end)
    activePrompts[prompt] = nil
end)

