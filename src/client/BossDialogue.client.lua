-- BossDialogue LocalScript
-- Place in StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local TALK_SPEED = 0.05

-- ============================================================
-- GUI SETUP
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.5, 0, 0, 140)
frame.Position = UDim2.new(0.5, 0, 0.78, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.04, 0)
corner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(206, 100, 13)
frameStroke.Thickness = 2
frameStroke.Parent = frame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -20, 0, 28)
nameLabel.Position = UDim2.new(0, 10, 0, 8)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
nameLabel.TextScaled = true
nameLabel.FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "???"
nameLabel.Parent = frame

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -20, 0, 65)
textLabel.Position = UDim2.new(0, 10, 0, 40)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.TextScaled = true
textLabel.FontFace = Font.new("rbxassetid://12187371840")
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextWrapped = true
textLabel.Text = ""
textLabel.Parent = frame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -10, 0, 18)
hintLabel.Position = UDim2.new(0, 0, 1, -22)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hintLabel.TextScaled = true
hintLabel.FontFace = Font.new("rbxassetid://12187371840")
hintLabel.TextXAlignment = Enum.TextXAlignment.Right
hintLabel.Text = "Press E to continue"
hintLabel.Parent = frame

-- ============================================================
-- BOSS FACE SETUP
-- ============================================================
local boss = workspace:WaitForChild("Boss1x")
local bossHead = boss:WaitForChild("Head")
local bossface = bossHead:WaitForChild("face")
print("[BossDialogue] bossface found:", bossface)
print("[BossDialogue] bossface class:", bossface.ClassName)
print("[BossDialogue] bossface current texture:", bossface.Texture)

local FACE_TALK_1 = "rbxassetid://109965074603600"
local FACE_TALK_2 = "rbxassetid://121067166864251"
local FACE_LAUGH_1 = "rbxassetid://125932915076983"
local FACE_LAUGH_2 = "rbxassetid://91224317945990"

-- Which lines should use the laugh faces instead of talk faces
-- (0-indexed from 1 to match the lines table below)
local LAUGH_LINES = {
    [7] = true,   -- "JUST KIDDING!!!"
    [14] = true,  -- "GAHAHAHAHAHA"
}

local faceBlink = nil  -- holds the current blink loop thread

local faceAnimRunning = false

local function stopFaceAnimation()
    faceAnimRunning = false
end

local function startFaceAnimation(isLaughing)
    stopFaceAnimation()
    
    local faceA = isLaughing and FACE_LAUGH_1 or FACE_TALK_1
    local faceB = isLaughing and FACE_LAUGH_2 or FACE_TALK_2
    local speed = isLaughing and 0.08 or 0.12

    faceAnimRunning = true
    task.spawn(function()
        while faceAnimRunning do
            bossface.Texture = faceA
            task.wait(speed)
            if not faceAnimRunning then break end
            bossface.Texture = faceB
            task.wait(speed)
        end
    end)
end

local function setFaceIdle()
    stopFaceAnimation()
    bossface.Texture = FACE_TALK_1
end
-- ============================================================
-- TYPEWRITER
-- ============================================================
local typing = false
local skipTyping = false

local function typeWrite(text)
    typing = true
    skipTyping = false
    textLabel.Text = ""
    for i = 1, #text do
        if skipTyping then
            textLabel.Text = text
            break
        end
        textLabel.Text = string.sub(text, 1, i)
        task.wait(TALK_SPEED)
    end
    typing = false
    setFaceIdle()  -- stop animating when done typing
end

-- ============================================================
-- DIALOGUE
-- ============================================================
local advanceFn = nil
local lineIndex = 0
local currentLines = {}

local function closeDialogue()
    frame.Visible = false
    advanceFn = nil
    setFaceIdle()
end

local function playLines(lines, onFinish)
    currentLines = lines
    lineIndex = 1
    frame.Visible = true

    local function showNext()
        if lineIndex > #currentLines then
            if onFinish then onFinish() end
            return
        end

        local isLaughing = LAUGH_LINES[lineIndex] == true
        startFaceAnimation(isLaughing)

        task.spawn(function() typeWrite(currentLines[lineIndex]) end)
    end

    showNext()

    return function()
        if typing then
            skipTyping = true
            return
        end
        lineIndex = lineIndex + 1
        showNext()
    end
end

-- ============================================================
-- E TO ADVANCE
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E
    or input.KeyCode == Enum.KeyCode.ButtonA then
        if advanceFn then advanceFn() end
    end
end)

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        if advanceFn then advanceFn() end
    end
end)

-- ============================================================
-- LISTEN FOR BOSS CUTSCENE
-- ============================================================
print("[BossDialogue] Ready, waiting for StartBossDialogue...")

local startBossDialogue = ReplicatedStorage:WaitForChild("StartBossDialogue", math.huge)
print("[BossDialogue] Found StartBossDialogue, connecting...")

startBossDialogue.Event:Connect(function()
    print("[BossDialogue] Fired! Playing lines...")
    advanceFn = playLines({
        "Do I know you?",             -- 1  talk
        "...",                        -- 2  talk
        "Your the one whose pets I stole right..?", -- 3  talk
        "Sorry about that, you can have them back now", -- 4  talk
        "...",                        -- 5  talk
        "...",                        -- 6  talk
        "JUST KIDDING!!!",            -- 7  LAUGH
        "Sorry, but I need their life source to get back to my true strength.",
        "Who would have thought those little bums would have so much untapped power...", -- 8  talk
        "... wait a minute, are some of them missing...?", -- 9  talk
        "... you took some back didn't you...", -- 10 talk
        "...",                        -- 11 talk
        "Whatever, I'll just kill you and get them back.", -- 12 talk
        "GAHAHAHAHAHA!!!"                -- 14 LAUGH
    }, function()
        closeDialogue()
        print("[BossDialogue] Done, firing BossDialogueDone...")
        local bossDialogueDone = ReplicatedStorage:FindFirstChild("BossDialogueDone")
        if bossDialogueDone then
            bossDialogueDone:Fire()
        else
            print("[BossDialogue] ERROR: BossDialogueDone not found!")
        end
    end)
end)