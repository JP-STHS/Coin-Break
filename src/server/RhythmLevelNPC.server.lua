local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local LevelsFolder = ServerStorage:WaitForChild("Levels")
local EpicCategory = LevelsFolder:WaitForChild("Epic")
local Level19 = EpicCategory:WaitForChild("Level19")

local npc = Level19:WaitForChild("Ghost")
local TweenService = game:GetService("TweenService")
local mesh = npc:WaitForChild("GhostModel")

local startY = mesh.Position.Y
local hoverHeight = 1.5  -- how many studs it bobs up and down

local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local tween = TweenService:Create(mesh, tweenInfo, {
    Position = Vector3.new(mesh.Position.X, startY + hoverHeight, mesh.Position.Z)
})
tween:Play()