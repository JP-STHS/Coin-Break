-- Ghost Dialogue LocalScript
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")

local npc = workspace:WaitForChild("Ghost")
local mesh = npc:WaitForChild("GhostModel")

-- ============================================================
-- QUEST FLAGS — set these from your other scripts when things happen
-- ============================================================
local Quest = {
    accepted        = false,  -- player said yes
    hasIngredients  = false,  -- set to true when player collects all 3 items
    minigameDone    = false,  -- set to true when rhythm game ends (wired below)
    hasSauce        = false,  -- set to true when player finds secret sauce
    questComplete   = false,  -- set automatically when all done
}

-- Wire minigame completion — fires when the rhythm game's song finishes
-- This uses a BindableEvent; fire it from your rhythm game script when the song ends
local minigameEvent = Instance.new("BindableEvent")
minigameEvent.Name  = "MinigameDone"
minigameEvent.Parent = game.ReplicatedStorage  -- other scripts can find it here
minigameEvent.Event:Connect(function()
    Quest.minigameDone = true
end)
local ingredientsEvent = game.ReplicatedStorage:WaitForChild("IngredientsCollected")
ingredientsEvent.Event:Connect(function(firedPlayer)
    if firedPlayer == player then
        Quest.hasIngredients = true
    end
end)
-- ============================================================

local TALK_SPEED       = 0.05
local TRIGGER_DISTANCE = 5

-- Random idle lines shown after quest is complete
local IDLE_LINES = {
    "Ghost kitchens are so gross... not this one though",
    "Don't eat here, your bowels will thank me",
    "why are the demons in demon slayer called demons when theyre clearly vampires lowk",
    "I used to braid leg hairs for a living... ahh good times",
    "amogus haha.. get it.. no?... uhhhh 67 67 67... uhhh... ... sorry",
    "I lit a guy on fire once, funniest thing ever dude",
}

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

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -20, 0, 28)
nameLabel.Position = UDim2.new(0, 10, 0, 8)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "Ghost Kitchen Chef"
nameLabel.Parent = frame

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -20, 0, 65)
textLabel.Position = UDim2.new(0, 10, 0, 40)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.Gotham
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextWrapped = true
textLabel.Text = ""
textLabel.Parent = frame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -10, 0, 18)
hintLabel.Position = UDim2.new(0, 10, 1, -22)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hintLabel.TextScaled = true
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextXAlignment = Enum.TextXAlignment.Right
hintLabel.Text = "Press E to continue"
hintLabel.Parent = frame

-- Yes/No buttons (hidden by default)
local function makeChoiceButton(text, xAnchor, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, 0, 0, 28)
    btn.Position = UDim2.new(xAnchor, 0, 1, -34)
    btn.AnchorPoint = Vector2.new(xAnchor, 0)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Visible = false
    btn.Parent = frame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.3, 0)
    c.Parent = btn
    return btn
end

local yesBtn = makeChoiceButton("erm ok", 0.15, Color3.fromRGB(50, 180, 80))
local noBtn  = makeChoiceButton("lol nah", 0.85, Color3.fromRGB(180, 50, 50))

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
end

-- ============================================================
-- DIALOGUE STATE MACHINE
-- ============================================================
local dialogueOpen = false
local inRange      = false
local currentLines = {}
local lineIndex    = 0
local choicePending = false

local function hideChoiceButtons()
    yesBtn.Visible = false
    noBtn.Visible  = false
    hintLabel.Visible = true
end

local function showChoiceButtons()
    choicePending = true
    yesBtn.Visible = true
    noBtn.Visible  = true
    hintLabel.Visible = false
end

local function closeDialogue()
    dialogueOpen  = false
    choicePending = false
    frame.Visible = false
    hideChoiceButtons()
end

local function playLines(lines, onFinish)
    currentLines = lines
    lineIndex    = 1
    dialogueOpen = true
    frame.Visible = true
    hideChoiceButtons()

    local function showNext()
        if lineIndex > #currentLines then
            if onFinish then onFinish() end
            return
        end

        local entry = currentLines[lineIndex]

        -- Entry can be a plain string or a table {text=, choice=true}
        if type(entry) == "table" and entry.choice then
            task.spawn(function() typeWrite(entry.text) end)
            task.spawn(function()
                -- Wait for typing to finish before showing buttons
                while typing do task.wait() end
                showChoiceButtons()
            end)
        else
            local text = type(entry) == "table" and entry.text or entry
            task.spawn(function() typeWrite(text) end)
        end
    end

    showNext()

    -- Return an advance function the E key will call
    return function()
        if choicePending then return end  -- block E while choice is showing
        if typing then
            skipTyping = true
            return
        end
        lineIndex = lineIndex + 1
        showNext()
    end
end

-- The current advance function (swapped out per conversation branch)
local advanceFn = nil

-- ============================================================
-- QUEST DIALOGUE BRANCHES
-- ============================================================
local function getQuestLines()
    -- Decide which branch to show based on quest state
    if Quest.questComplete then
        -- Random idle line
        local line = IDLE_LINES[math.random(1, #IDLE_LINES)]
        return {line}, function() closeDialogue() end

    elseif Quest.hasSauce and not Quest.questComplete then
        Quest.questComplete = true
        return {
            "Ok the burger is complete, thanks again dude.",
            "Your coin is up ahead.",
        }, function() closeDialogue() end

    elseif Quest.minigameDone and not Quest.hasSauce then
        return {
            "Ay the power's back on! Thank you.",
            "Oh one more thing, could you find the secret sauce?",
            "I promise the coin is yours if u get it.",
        }, function() closeDialogue() end

    elseif Quest.hasIngredients and not Quest.minigameDone then
        return {
            "Thanks, you got everything.",
            "I have a slight problem though...",
            "The power is out rn, could you play that minigame over there to fix it plz",
        }, function() closeDialogue() end

    elseif Quest.accepted and not Quest.hasIngredients then
        return {
            "Did you forget the ingredients? It's a bun, a patty, and some lettuce.",
            "Even the meat is on the shelf. It's all moldy anyways lol.",
        }, function() closeDialogue() end

    else
        -- First meeting — show yes/no choice
        return {
            "...",
            "Hi there",
            "Can u help me make a burger",
            {text = "I'll give u a coin if u do", choice = true},
        }, nil  -- onFinish handled by yes/no buttons
    end
end

local function openDialogue()
    if dialogueOpen then return end
    local lines, onFinish = getQuestLines()
    advanceFn = playLines(lines, onFinish or function() closeDialogue() end)
end

-- ============================================================
-- YES / NO HANDLERS
-- ============================================================
yesBtn.MouseButton1Click:Connect(function()
    if not choicePending then return end
    choicePending = false
    hideChoiceButtons()
    Quest.accepted = true
    -- Continue with accepted lines
    advanceFn = playLines({
        "YAY :D",
        "Here's the ingredients u need: a bun, a patty, and some lettuce.",
    }, function() closeDialogue() end)
end)

noBtn.MouseButton1Click:Connect(function()
    if not choicePending then return end
    choicePending = false
    hideChoiceButtons()
    -- Show rejection line then close — dialogue resets so they can say yes next time
    advanceFn = playLines({
        "bruh",
    }, function() closeDialogue() end)
end)

-- ============================================================
-- PROXIMITY CHECK
-- ============================================================
RunService.Heartbeat:Connect(function()
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = (root.Position - mesh.Position).Magnitude

    if dist <= TRIGGER_DISTANCE and not inRange then
        inRange = true
        openDialogue()
    elseif dist > TRIGGER_DISTANCE and inRange then
        inRange = false
        closeDialogue()
    end
end)

-- ============================================================
-- E TO ADVANCE
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E and advanceFn then
        advanceFn()
    end
end)