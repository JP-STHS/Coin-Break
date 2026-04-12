-- LocalScript in StarterPlayerScripts
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function hideBackpack()
    -- retry in a loop because SetCoreGuiEnabled can fail silently if called too early
    local success = false
    while not success do
        success = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if not success then task.wait(0.1) end
    end
end

-- Hide on first load
hideBackpack()

-- On each respawn: let Roblox populate backpack first, THEN hide the GUI
player.CharacterAdded:Connect(function()
    task.wait(0.2)  -- let StarterPack clone into backpack
    hideBackpack()
end)