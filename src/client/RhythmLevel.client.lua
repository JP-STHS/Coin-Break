local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local workspace = game:GetService("Workspace")
local SpawnedLevels = workspace:WaitForChild("SpawnedLevels")

SpawnedLevels.ChildAdded:Connect(function(level)
    if level.Name ~= "Level19" then return end
    
    -- ============================================================
    -- 🥁 SONG CONFIGURATION
    -- ============================================================
    local SONG_DATA = {
        {0.789, 'Q'}, {1.216, 'Q'}, {1.621, 'Q'}, {2.027, 'Q'}, {2.453, 'Q'},
        {2.859, 'Q'}, {3.285, 'Q'}, {3.712, 'Q'}, {4.096, 'Q'}, {4.587, 'Q'},
        {4.929, 'Q'}, {5.334, 'Q'}, {5.782, 'E'}, {6.166, 'Q'}, {6.593, 'E'},
        {7.019, 'Q'}, {7.425, 'E'}, {7.659, 'Q'}, {7.83, 'E'}, {8.278, 'Q'},
        {8.683, 'E'}, {9.11, 'Q'}, {9.537, 'E'}, {9.942, 'Q'}, {10.347, 'E'},
        {10.795, 'Q'}, {11.158, 'E'}, {11.606, 'Q'}, {11.99, 'E'}, {12.459, 'Q'},
        {12.737, 'Q'}, {13.035, 'Q'}, {13.313, 'E'}, {13.739, 'Q'}, {14.187, 'Q'},
        {14.358, 'E'}, {14.55, 'Q'}, {14.977, 'Q'}, {15.254, 'E'}, {15.425, 'Q'},
        {15.873, 'Q'}, {16.235, 'E'}, {16.662, 'Q'}, {16.833, 'E'}, {17.046, 'Q'},
        {17.473, 'Q'}, {17.686, 'E'}, {17.857, 'Q'}, {18.07, 'E'}, {18.305, 'Q'},
        {18.518, 'E'}, {18.731, 'Q'}, {18.881, 'E'}, {19.115, 'Q'}, {19.457, 'Q'},
        {19.713, 'Q'}, {19.926, 'E'}, {20.353, 'Q'}, {20.779, 'E'}, {21.249, 'Q'},
        {21.633, 'E'}, {22.081, 'Q'}, {22.422, 'E'}, {22.891, 'Q'}, {23.297, 'E'},
        {23.702, 'Q'}, {24.107, 'E'}, {24.534, 'E'}, {24.961, 'E'}, {25.366, 'E'},
        {25.814, 'Q'}, {26.241, 'Q'}, {26.646, 'Q'}, {27.073, 'Q'}, {27.478, 'Q'},
        {27.862, 'E'}, {28.289, 'Q'}, {28.673, 'E'}, {29.099, 'Q'}, {29.505, 'E'}
    }

    local NOTE_SPEED = 2.0   
    local HIT_WINDOW = 0.3  
    local SONG_DURATION = 31 
    local CHART_OFFSET = 0.15 
    -- ============================================================

    local startButton = level:WaitForChild("StartButton")
    local sound = startButton:WaitForChild("Sound")
    local gameActive = false
    local canStart = true -- Logic to lock the ClickDetector
    local score = 0
    local misses = 0 -- Spam penalty counter
    local startTime = 0
    local activeNotes = {}

    -- ============================================================
    -- GUI SETUP
    -- ============================================================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TaikoGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local trackFrame = Instance.new("Frame")
    trackFrame.Size = UDim2.new(0.8, 0, 0, 100)
    trackFrame.Position = UDim2.new(0.5, 0, 0.35, 0)
    trackFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    trackFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    trackFrame.BorderSizePixel = 0
    trackFrame.Parent = screenGui
    Instance.new("UICorner", trackFrame).CornerRadius = UDim.new(0.2, 0)

    -- Indicators
    local function makeLabel(txt, color, xPos)
        local l = Instance.new("TextLabel")
        l.Text = txt; l.TextColor3 = color; l.BackgroundTransparency = 1
        l.Position = UDim2.new(xPos, 0, 0, -35); l.Size = UDim2.new(0, 100, 0, 20)
        l.FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
        l.Parent = trackFrame
    end
    makeLabel("Q - RED", Color3.fromRGB(235, 64, 52), 0.1)
    makeLabel("E - BLUE", Color3.fromRGB(52, 183, 235), 0.3)

    local target = Instance.new("Frame")
    target.Size = UDim2.new(0, 80, 0, 80)
    target.Position = UDim2.new(0, 0, 0.5, 0)
    target.AnchorPoint = Vector2.new(0.5, 0.5)
    target.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    target.BackgroundTransparency = 0.7
    target.ZIndex = 2
    target.Parent = trackFrame
    Instance.new("UICorner", target).CornerRadius = UDim.new(1, 0)

    -- Rounded Result Overlay
    local resultFrame = Instance.new("Frame")
    resultFrame.Size = UDim2.new(0, 400, 0, 200)
    resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    resultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    resultFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    resultFrame.BackgroundTransparency = 0.1
    resultFrame.BorderSizePixel = 0
    resultFrame.Visible = false
    resultFrame.Parent = screenGui
    Instance.new("UICorner", resultFrame).CornerRadius = UDim.new(0.1, 0)
    local frameStroke = Instance.new("UIStroke", resultFrame)
    frameStroke.Color = Color3.fromRGB(206, 100, 13)
    frameStroke.Thickness = 3

    local resultText = Instance.new("TextLabel")
    resultText.Size = UDim2.new(0.9, 0, 0.8, 0)
    resultText.Position = UDim2.new(0.5, 0, 0.5, 0)
    resultText.AnchorPoint = Vector2.new(0.5, 0.5)
    resultText.BackgroundTransparency = 1; resultText.TextColor3 = Color3.new(1,1,1)
    resultText.FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold)
    resultText.TextScaled = true; resultText.Parent = resultFrame

    -- Mobile Buttons
    local function createBtn(name, color, xPos, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 130, 0, 130); btn.Position = UDim2.new(xPos, 0, 0.75, 0)
        btn.AnchorPoint = Vector2.new(0.5, 0.5); btn.BackgroundColor3 = color
        btn.Text = name .. "\n(" .. key .. ")"; btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true; btn.Parent = screenGui; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        return btn
    end
    local btnQ = createBtn("RED", Color3.fromRGB(235, 64, 52), 0.35, "Q")
    local btnE = createBtn("BLUE", Color3.fromRGB(52, 183, 235), 0.65, "E")
    if not UserInputService.TouchEnabled then btnQ.Visible = false; btnE.Visible = false end

    -- ============================================================
    -- GAME LOGIC
    -- ============================================================
    local function spawnNote(noteType, hitTime)
        local note = Instance.new("Frame")
        note.Size = UDim2.new(0, 75, 0, 75); note.AnchorPoint = Vector2.new(0.5, 0.5)
        note.Position = UDim2.new(1.15, 0, 0.5, 0)
        note.BackgroundColor3 = (noteType == "Q") and Color3.fromRGB(235, 64, 52) or Color3.fromRGB(52, 183, 235)
        Instance.new("UICorner", note).CornerRadius = UDim.new(1, 0)
        note.Parent = trackFrame

        local noteData = {Gui = note, Type = noteType, HitTime = hitTime, Hit = false}
        table.insert(activeNotes, noteData)

        local t = TweenService:Create(note, TweenInfo.new(NOTE_SPEED, Enum.EasingStyle.Linear), {
            Position = UDim2.new(-0.15, 0, 0.5, 0)
        })
        t:Play()

        task.delay(NOTE_SPEED + 0.5, function()
            if note then note:Destroy() end
            local idx = table.find(activeNotes, noteData)
            if idx then table.remove(activeNotes, idx) end
        end)
    end

    local function tryHit(inputType)
        if not gameActive then return end
        local currentTime = os.clock() - startTime
        local bestNote = nil
        local minDiff = HIT_WINDOW

        for _, nd in ipairs(activeNotes) do
            local diff = math.abs((nd.HitTime + CHART_OFFSET) - currentTime)
            if diff < minDiff and not nd.Hit then
                bestNote = nd
                minDiff = diff
            end
        end

        if bestNote and bestNote.Type == inputType then
            bestNote.Hit = true; score += 1
            bestNote.Gui:Destroy() 
            target.BackgroundColor3 = Color3.new(0, 1, 0)
        else
            -- SPAM PENALTY: Increment misses if no note is found or wrong key pressed
            misses += 1 
            target.BackgroundColor3 = Color3.new(1, 0, 0)
        end
        task.delay(0.1, function() target.BackgroundColor3 = Color3.new(1, 1, 1); target.BackgroundTransparency = 0.7 end)
    end

    local function startGame()
        if not canStart or gameActive then return end
        gameActive = true
        canStart = false -- Lock the button
        score = 0
        misses = 0 
        activeNotes = {}
        resultFrame.Visible = false; screenGui.Enabled = true
        
        sound.TimePosition = 0; sound:Play()
        startTime = os.clock()

        for _, data in ipairs(SONG_DATA) do
            local spawnDelay = (data[1] + CHART_OFFSET) - NOTE_SPEED
            task.delay(math.max(0, spawnDelay), function()
                if gameActive then spawnNote(data[2], data[1]) end
            end)
        end

        task.wait(SONG_DURATION)
        gameActive = false; sound:Stop()
        
        -- Evaluation (Subtract misses from score for accuracy)
        local rawAccuracy = (score - (misses * 0.5)) / #SONG_DATA -- Misses hurt your score!
        local accuracy = math.clamp(rawAccuracy * 100, 0, 100)
        
        local grade = (accuracy >= 85 and "S") or (accuracy >= 70 and "A") or (accuracy >= 55 and "B") or "C"
        
        resultText.Text = "FINAL SCORE: " .. score .. "\nACCURACY: " .. math.floor(accuracy) .. "%\nGRADE: " .. grade
        resultText.TextColor3 = (grade ~= "C") and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
        resultFrame.Visible = true

        if grade ~= "C" then
            local ev = ReplicatedStorage:FindFirstChild("MinigameDone")
            if ev then ev:Fire() end 
        end
        
        task.wait(4)
        screenGui.Enabled = false
        canStart = true -- Unlock the button for retries
    end

    local function onDetectorAdded(cd)
        if not cd:IsA("ClickDetector") then return end
        cd.MouseClick:Connect(function(who) 
            if who == player and canStart then startGame() end 
        end)
    end
    local existing = startButton:FindFirstChildOfClass("ClickDetector")
    if existing then onDetectorAdded(existing) end
    startButton.ChildAdded:Connect(onDetectorAdded)

    UserInputService.InputBegan:Connect(function(io, proc)
        if proc then return end
        if io.KeyCode == Enum.KeyCode.Q then tryHit("Q")
        elseif io.KeyCode == Enum.KeyCode.E then tryHit("E") end
    end)
    btnQ.MouseButton1Down:Connect(function() tryHit("Q") end)
    btnE.MouseButton1Down:Connect(function() tryHit("E") end)
end)