-- LocalScript inside CustomHotbar ScreenGui

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
    MotherboardSword   = "rbxassetid://YOUR_SWORD_IMAGE_ID",
    Coin    = "rbxassetid://YOUR_COIN_IMAGE_ID",
    lettuce = "rbxassetid://YOUR_LETTUCE_IMAGE_ID",
    patty    = "rbxassetid://YOUR_MEAT_IMAGE_ID",
    HotSauce = "rbxassetid://YOUR_SAUCE_IMAGE_ID",
    bun     = "rbxassetid://YOUR_BUN_IMAGE_ID",
}

local FALLBACK_IMAGE = "rbxassetid://0"  -- blank/default if no image found

-- ============================================================
-- BUILD SLOTS
-- ============================================================
local slots = {}  -- slot[i] = { button, itemName, number }
local tools = {}

local function makeSlot(index)
    local slot = slotTemplate:Clone()
    slot.Name = "Slot" .. index
    slot.Visible = true
    slot.Parent = hotbarFrame

slot.MouseButton1Click:Connect(function()
        local tool = slots[index] and tools[index]
        if not tool then return end
        local character = player.Character
        if not character then return end
        if tool.Parent == character then
            -- unequip by putting back in backpack
            tool.Parent = player.Backpack
        else
            -- equip
            tool.Parent = character
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

    -- Gather all tools: equipped one first, then backpack
    tools = {}

    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped then
        table.insert(tools, equipped)
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
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
local function watchCharacter(character)
    updateHotbar()

    -- Watch for tools being equipped/unequipped
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then updateHotbar() end
    end)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then updateHotbar() end
    end)
end

-- Watch backpack changes too
player.Backpack.ChildAdded:Connect(updateHotbar)
player.Backpack.ChildRemoved:Connect(updateHotbar)

-- Handle character spawning
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
    watchCharacter(player.Character)
end