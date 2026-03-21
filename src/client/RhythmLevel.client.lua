-- RhythmGame LocalScript (Two tracks + mobile support)
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local cooldown = false

-- ============================================================
-- CONFIGURATION
-- ============================================================
local HIT_WINDOW  = 0.25
local NOTE_TRAVEL = 6.0

local HIT_COLOR  = Color3.fromRGB(50, 255, 100)
local MISS_COLOR = Color3.fromRGB(255, 50, 50)
local IDLE_COLOR = Color3.fromRGB(255, 255, 255)

local BPM         = 144
local interval    = 60 / BPM
local startOffset = 0.5
local SONG_DURATION = 30

-- E track beats
local beatsE = {}
local beatsQ = {}
for i = 0, math.floor((SONG_DURATION - startOffset) / interval) do
    local beatTime = startOffset + (i * interval)
    if i % 2 == 0 then
        table.insert(beatsE, beatTime)
    else
        table.insert(beatsQ, beatTime)
    end
end



-- Note colors per track
local TRACK_COLOR = {
    E = Color3.fromRGB(12, 182, 89),   -- yellow
    Q = Color3.fromRGB(100, 180, 255),  -- blue
}
-- ============================================================

local hitZoneE   = workspace:WaitForChild("HitZoneE")
local hitZoneQ   = workspace:WaitForChild("HitZoneQ")
local spawnE     = workspace:WaitForChild("SpawnPointE")
local spawnQ     = workspace:WaitForChild("SpawnPointQ")
local startButton = workspace:WaitForChild("StartButton")
local sound       = startButton:WaitForChild("Sound")

local gameActive    = false
local songStartTime = 0
local activeNotes   = { E = {}, Q = {} }
local score = 0
local totalNotes = 0
-- -------------------------------------------------------
-- Mobile GUI buttons
-- -------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local function makeMobileButton(text, xPos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 100)
    btn.Position = UDim2.new(xPos, 0, 0.75, 0)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Parent = screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = btn
    return btn
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local btnE, btnQ
if isMobile then
    btnE = makeMobileButton("E", 0.6, Color3.fromRGB(12, 206, 77))
    btnQ = makeMobileButton("Q", 0.4, Color3.fromRGB(100, 180, 255))
    btnE.Visible = false
    btnQ.Visible = false
end
-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------
local function flashZone(hitZone, color)
    hitZone.Color = color
    task.delay(0.15, function()
        hitZone.Color = IDLE_COLOR
    end)
end

local function spawnNote(beatTime, track)
    local spawnPart = track == "E" and spawnE or spawnQ
    local hitZone   = track == "E" and hitZoneE or hitZoneQ

    local note = Instance.new("Part")
    note.Size       = Vector3.new(1, 0.5, 1)
    note.Color      = TRACK_COLOR[track]
    note.Material   = Enum.Material.ForceField 
    note.Anchored   = true
    note.CanCollide = false
    note.Position   = spawnPart.Position
    note.Parent     = workspace

    local tween = TweenService:Create(
        note,
        TweenInfo.new(NOTE_TRAVEL, Enum.EasingStyle.Linear),
        {Position = hitZone.Position}
    )
    tween:Play()

    local noteData = {part = note, expectedTime = beatTime, hit = false}
    table.insert(activeNotes[track], noteData)

    task.delay(NOTE_TRAVEL + 0.3, function()
        if not noteData.hit then
            flashZone(hitZone, MISS_COLOR)
        end
        note:Destroy()
        for i, n in ipairs(activeNotes[track]) do
            if n == noteData then
                table.remove(activeNotes[track], i)
                break
            end
        end
    end)
end

-- -------------------------------------------------------
-- Hit logic
-- -------------------------------------------------------
local function tryHit(track)
    if not gameActive then return end
    local hitZone = track == "E" and hitZoneE or hitZoneQ
    local currentTime = os.clock() - songStartTime

    local bestNote, bestDist = nil, math.huge
    for _, noteData in ipairs(activeNotes[track]) do
        if not noteData.hit then
            local dist = math.abs(currentTime - noteData.expectedTime)
            if dist < bestDist then
                bestNote = noteData
                bestDist = dist
            end
        end
    end

    if bestNote and bestDist <= HIT_WINDOW then
        bestNote.hit = true
        score = score + 1  -- add this line
        bestNote.part.Color = HIT_COLOR
        flashZone(hitZone, HIT_COLOR)
        task.delay(0.1, function()
            if bestNote.part then bestNote.part:Destroy() end
        end)
        print(string.format("HIT %s! (off by %.0fms)", track, bestDist * 1000))
    else
        flashZone(hitZone, MISS_COLOR)
        print("MISS " .. track)
    end
end
totalNotes = #beatsE + #beatsQ
-- -------------------------------------------------------
-- Start the game
-- -------------------------------------------------------
local function showScoreScreen()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.05, 0)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.Position = UDim2.new(0, 0, 0.1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = string.format("Score: %d / %d", score, totalNotes)
    label.Parent = frame

    local percent = math.floor((score / math.max(totalNotes, 1)) * 100)
    local grade, gradeColor
    if percent == 100 then
        grade, gradeColor = "S", Color3.fromRGB(255, 220, 50)
    elseif percent >= 80 then
        grade, gradeColor = "A", Color3.fromRGB(100, 255, 100)
    elseif percent >= 60 then
        grade, gradeColor = "B", Color3.fromRGB(100, 180, 255)
    elseif percent >= 49 then
        grade, gradeColor = "C", Color3.fromRGB(255, 165, 50)
    else
        grade, gradeColor = "F", Color3.fromRGB(255, 50, 50)
    end

    local gradeLabel = Instance.new("TextLabel")
    gradeLabel.Size = UDim2.new(1, 0, 0.35, 0)
    gradeLabel.Position = UDim2.new(0, 0, 0.5, 0)
    gradeLabel.BackgroundTransparency = 1
    gradeLabel.TextColor3 = gradeColor
    gradeLabel.TextScaled = true
    gradeLabel.Font = Enum.Font.GothamBold
    gradeLabel.Text = grade
    gradeLabel.Parent = frame

    -- Auto dismiss after 5 seconds
    task.delay(5, function()
        sound:Stop()
        frame:Destroy()
    end)
end
local function startGame()
    if gameActive then return end
    gameActive    = true
    songStartTime = os.clock()
    activeNotes   = { E = {}, Q = {} }

    sound:Play()
    if btnE then btnE.Visible = true end
    if btnQ then btnQ.Visible = true end

    for _, beatTime in ipairs(beatsE) do
        local spawnDelay = math.max(0, beatTime - NOTE_TRAVEL)
        task.delay(spawnDelay, function()
            if gameActive then spawnNote(beatTime, "E") end
        end)
    end

    for _, beatTime in ipairs(beatsQ) do
        local spawnDelay = math.max(0, beatTime - NOTE_TRAVEL)
        task.delay(spawnDelay, function()
            if gameActive then spawnNote(beatTime, "Q") end
        end)
    end

    task.delay(SONG_DURATION, function()
        gameActive  = false
        activeNotes = { E = {}, Q = {} }
        if btnE then btnE.Visible = false end
        if btnQ then btnQ.Visible = false end
        showScoreScreen()
        local percent = math.floor((score / math.max(totalNotes, 1)) * 100)
        if percent >= 60 then
            local event = game.ReplicatedStorage:FindFirstChild("MinigameDone")
            if event then event:Fire() end
        end

        -- Wait for score screen to dismiss (5s) + cooldown (8s) before re-enabling
        task.delay(5, function()
            score = 0  -- reset after screen closes
            task.delay(8, function()
                cooldown = false
                startButton.Color = Color3.fromRGB(231, 81, 81)
            end)
        end)
    end)
end

-- -------------------------------------------------------
-- Start button
-- -------------------------------------------------------
local clickDetector = startButton:WaitForChild("ClickDetector")

clickDetector.MouseClick:Connect(function(clickingPlayer)
    if clickingPlayer ~= player then return end
    if cooldown or gameActive then return end

    cooldown = true
    startButton.Color = Color3.fromRGB(100, 0, 0)
    startGame()
end)

-- -------------------------------------------------------
-- Keyboard input
-- -------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then tryHit("E") end
    if input.KeyCode == Enum.KeyCode.Q then tryHit("Q") end
end)

-- -------------------------------------------------------
-- Mobile buttons
-- -------------------------------------------------------
if isMobile and btnE and btnQ then
    btnE.MouseButton1Down:Connect(function() tryHit("E") end)
    btnQ.MouseButton1Down:Connect(function() tryHit("Q") end)
end