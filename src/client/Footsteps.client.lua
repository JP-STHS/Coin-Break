local MaterialSounds = {
    [Enum.Material.Plastic] = "rbxassetid://9114165568", -- Change the ID to the sound you want to play.
    [Enum.Material.SmoothPlastic] = "rbxassetid://9118227430",
    [Enum.Material.Cardboard] = "rbxassetid://9117986503", 
    [Enum.Material.Wood] = "rbxassetid://16480568993",
    [Enum.Material.Metal] = "rbxassetid://9118230557",
    [Enum.Material.ForceField] = "rbxassetid://9116394545",
    [Enum.Material.Marble] = "rbxassetid://9117986503",
}

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local FootstepsSound = HumanoidRootPart:WaitForChild("Running")
print("[Footsteps]: ", FootstepsSound.ClassName)
FootstepsSound.Volume = 1

function updateFootstepsSound()
    local FloorMaterial = Humanoid.FloorMaterial
    local Sound = MaterialSounds[FloorMaterial]
    if Sound then
        FootstepsSound.SoundId = Sound
    else
        FootstepsSound.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3" -- Default walk sound
    end
end

Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(updateFootstepsSound)

updateFootstepsSound()