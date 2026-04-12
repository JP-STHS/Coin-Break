local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TransitionGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = player.PlayerGui

local iris = Instance.new("ImageLabel")
iris.AnchorPoint = Vector2.new(0.5, 0.5)
iris.Position = UDim2.new(0.5, 0, 0.5, 0)
iris.Size = UDim2.new(0, 0, 0, 0)
iris.BackgroundTransparency = 1
iris.Image = "rbxassetid://113703150394452"  -- replace this
iris.ScaleType = Enum.ScaleType.Stretch
iris.Visible = false
iris.Parent = gui

local busy = false

local function getFullSize()
    local vp = workspace.CurrentCamera.ViewportSize
    return math.sqrt(vp.X^2 + vp.Y^2) * 1.5  -- extra overshoot so black edges cover screen
end

local function circleClose(duration)
    if busy then return end
    busy = true
    duration = duration or 0.8

    local fullPx = getFullSize()
    iris.Size = UDim2.new(0, fullPx, 0, fullPx)
    iris.Visible = true

    TweenService:Create(iris, TweenInfo.new(
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    ), { Size = UDim2.new(0, 0, 0, 0) }):Play()

-- create solidBg if it doesn't exist
    local solidBg = gui:FindFirstChild("SolidBg")
    if not solidBg then
        solidBg = Instance.new("Frame")
        solidBg.Name = "SolidBg"
        solidBg.Size = UDim2.new(1, 0, 1, 0)
        solidBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        solidBg.BorderSizePixel = 0
        solidBg.ZIndex = 0  -- behind iris
        solidBg.Parent = gui
    end

    -- start fading bg in halfway through the iris closing
    solidBg.BackgroundTransparency = 1
    solidBg.Visible = true
    task.delay(duration * 0.5, function()
        TweenService:Create(solidBg, TweenInfo.new(
            duration * 0.8,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), { BackgroundTransparency = 0 }):Play()
    end)

    task.wait(duration + 0.1)
    iris.Visible = false
    busy = false
end

local function circleOpen(duration)
    if busy then return end
    busy = true
    duration = duration or 0.2

    local fullPx = getFullSize()

    local solidBg = gui:FindFirstChild("SolidBg")
    if not solidBg then
        solidBg = Instance.new("Frame")
        solidBg.Name = "SolidBg"
        solidBg.Size = UDim2.new(1, 0, 1, 0)
        solidBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        solidBg.BorderSizePixel = 0
        solidBg.ZIndex = 0
        solidBg.Parent = gui
    end
    solidBg.BackgroundTransparency = 0
    solidBg.Visible = true

    iris.Size = UDim2.new(0, 0, 0, 0)
    iris.ImageTransparency = 0
    iris.Visible = true

    -- fade bg out and grow iris simultaneously from the start
    TweenService:Create(solidBg, TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear
    ), { BackgroundTransparency = 1 }):Play()

    local growTween = TweenService:Create(iris, TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear
    ), { Size = UDim2.new(0, fullPx + 500, 0, fullPx + 500) })
    growTween:Play()

    -- fade iris out near the end so it disappears smoothly
    task.delay(duration * 0.7, function()
        TweenService:Create(iris, TweenInfo.new(
            duration * 0.35,
            Enum.EasingStyle.Linear
        ), { ImageTransparency = 1 }):Play()
    end)

    growTween.Completed:Connect(function()
        iris.Visible = false
        iris.ImageTransparency = 0
        solidBg.Visible = false
        busy = false
    end)
end

-- ============================================================
-- BINDABLE EVENTS
-- ============================================================
local circleCloseEvent = Instance.new("BindableEvent")
circleCloseEvent.Name = "CircleClose"
circleCloseEvent.Parent = ReplicatedStorage

local circleOpenEvent = Instance.new("BindableEvent")
circleOpenEvent.Name = "CircleOpen"
circleOpenEvent.Parent = ReplicatedStorage

circleCloseEvent.Event:Connect(function(duration) circleClose(duration) end)
circleOpenEvent.Event:Connect(function(duration) circleOpen(duration) end)

-- ============================================================
-- AUTO ON DEATH / RESPAWN
-- ============================================================
local function watchCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        circleClose(0.8)
    end)
end

player.CharacterAdded:Connect(function(character)
    task.wait(0.3)
    circleOpen(0.2)
    watchCharacter(character)
end)

if player.Character then
    iris.Visible = false
    watchCharacter(player.Character)
end