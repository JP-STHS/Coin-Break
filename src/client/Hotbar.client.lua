-- LocalScript inside CustomHotbar ScreenGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local customHotbar = playerGui:WaitForChild("CustomHotbar")
local hotbarFrame = customHotbar:WaitForChild("HotbarFrame")
local slotTemplate = hotbarFrame:WaitForChild("SlotTemplate")

-- ============================================================
-- ITEM IMAGE MAP
-- tool name (must match exactly) -> image asset id
-- ============================================================
local ITEM_IMAGES = {
    Blade   = "rbxassetid://84498132911346",
    Coin    = "rbxassetid://104951750345046",
    lettuce = "rbxassetid://98353353849824",
    patty    = "rbxassetid://111263838975521",
    HotSauce = "rbxassetid://103527008634413",
    bun     = "rbxassetid://91296991096974",
}

local FALLBACK_IMAGE = "rbxassetid://0"  -- blank/default if no image found

-- BindableEvents to show/hide hotbar from other scripts
local hideHotbarEvent = Instance.new("BindableEvent")
hideHotbarEvent.Name = "HideHotbar"
hideHotbarEvent.Parent = ReplicatedStorage
local hotbarEnabled = true

local showHotbarEvent = Instance.new("BindableEvent")
showHotbarEvent.Name = "ShowHotbar"
showHotbarEvent.Parent = ReplicatedStorage

hideHotbarEvent.Event:Connect(function()
    customHotbar.Enabled = false
    hotbarEnabled = false
end)

showHotbarEvent.Event:Connect(function()
    customHotbar.Enabled = true
    hotbarEnabled = true
end)
-- ============================================================
-- BUILD SLOTS
-- ============================================================
local slots = {}
local tools = {}
local toolSlotMap = {}  -- tool name -> slot index, so positions don't shuffle

local function makeSlot(index)
    local slot = slotTemplate:Clone()
    slot.Name = "Slot" .. index
    slot.Visible = true
    slot.Parent = hotbarFrame

slot.MouseButton1Click:Connect(function()
        if not hotbarEnabled then return end
        local tool = tools[index]
        if not tool then return end
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        if tool.Parent == character then
            humanoid:UnequipTools()
        else
            humanoid:EquipTool(tool)
        end
    end)

    return {
        button   = slot,
        itemName = slot:WaitForChild("ItemName"),
        number   = slot:WaitForChild("Number"),
    }
end


local SLOT_COUNT = 6
for i = 1, SLOT_COUNT do
    slots[i] = makeSlot(i)
    slots[i].itemName.Text = ""
    slots[i].number.Text = tostring(i)
    slots[i].button.Image = FALLBACK_IMAGE
    slots[i].button.Visible = false
end

-- ============================================================
-- UPDATE HOTBAR
-- ============================================================
local function updateHotbar()
    local character = player.Character
    local backpack = player.Backpack
    if not character or not backpack then return end

    -- Gather all tools from both character and backpack
    local allTools = {}
    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped then table.insert(allTools, equipped) end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then table.insert(allTools, item) end
    end

    -- Assign stable slot indices — once a tool gets a slot it keeps it
    local nextSlot = 1
    for _, tool in ipairs(allTools) do
        if not toolSlotMap[tool.Name] then
            -- find the next free slot
            while nextSlot <= SLOT_COUNT do
                local taken = false
                for _, v in pairs(toolSlotMap) do
                    if v == nextSlot then taken = true break end
                end
                if not taken then break end
                nextSlot += 1
            end
            if nextSlot <= SLOT_COUNT then
                toolSlotMap[tool.Name] = nextSlot
                nextSlot += 1
            end
        end
    end

    -- Remove tools from map that are gone entirely
    for name, _ in pairs(toolSlotMap) do
        local found = false
        for _, tool in ipairs(allTools) do
            if tool.Name == name then found = true break end
        end
        if not found then toolSlotMap[name] = nil end
    end

    -- Rebuild tools table using stable positions
    tools = {}
    for _, tool in ipairs(allTools) do
        local index = toolSlotMap[tool.Name]
        if index then tools[index] = tool end
    end

    -- Fill slots
    for i = 1, SLOT_COUNT do
        local tool = tools[i]
        local slot = slots[i]

        if tool then
            slot.button.Visible = true
            local image = ITEM_IMAGES[tool.Name] or FALLBACK_IMAGE
            slot.button.Image = image
            slot.itemName.Text = tool.Name
            if tool.Parent == character then
                slot.button.ImageColor3 = Color3.fromRGB(255, 220, 100)
            else
                slot.button.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end
        else
            slot.button.Visible = false  -- hide empty slots
            slot.button.Image = FALLBACK_IMAGE
            slot.itemName.Text = ""
            slot.button.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- ============================================================
-- WIRE UP EVENTS
-- ============================================================
local UserInputService = game:GetService("UserInputService")

local KEY_MAP = {
    [Enum.KeyCode.One]   = 1,
    [Enum.KeyCode.Two]   = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four]  = 4,
    [Enum.KeyCode.Five]  = 5,
    [Enum.KeyCode.Six]   = 6,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not hotbarEnabled then return end
    local index = KEY_MAP[input.KeyCode]
    if not index then return end

    local tool = tools[index]
    if not tool then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if tool.Parent == character then
        humanoid:UnequipTools()
    else
        humanoid:EquipTool(tool)
    end
end)

local connections = {}

local function clearConnections()
    for _, conn in ipairs(connections) do conn:Disconnect() end
    connections = {}
end

local function onCharacterAdded(character)
    clearConnections()
    toolSlotMap = {}
    tools = {}

    -- rebuild slots fresh
    for _, child in ipairs(hotbarFrame:GetChildren()) do
        if child.Name:match("^Slot%d+$") then child:Destroy() end
    end
    slots = {}
    for i = 1, SLOT_COUNT do
        slots[i] = makeSlot(i)
        slots[i].itemName.Text = ""
        slots[i].number.Text = tostring(i)
        slots[i].button.Image = FALLBACK_IMAGE
        slots[i].button.Visible = false
    end

    table.insert(connections, player.Backpack.ChildAdded:Connect(updateHotbar))
    table.insert(connections, player.Backpack.ChildRemoved:Connect(updateHotbar))
    table.insert(connections, character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then updateHotbar() end
    end))
    table.insert(connections, character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then updateHotbar() end
    end))

    task.wait(0.1)
    updateHotbar()
    -- second update catches late server-restored tools like the coin
    task.delay(2, updateHotbar)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end