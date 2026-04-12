local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local coinGiver = workspace:WaitForChild("CoinGiver")

local givenTo = {}  -- received a coin
local usedCoin = {} -- used it at the well

local coinUsedEvent = ReplicatedStorage:WaitForChild("CoinUsed")
coinUsedEvent.OnServerEvent:Connect(function(player)
    usedCoin[player.UserId] = true
    givenTo[player.UserId] = nil -- reset so they can get another from the giver
    print("Coin used by:", player.Name)
end)

coinGiver.Touched:Connect(function(hit)
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    if givenTo[player.UserId] then return end -- already has one

    givenTo[player.UserId] = true
    local coin = ReplicatedStorage:WaitForChild("Coin"):Clone()
    coin.Parent = player.Backpack
    print("Gave coin to:", player.Name)
end)

local StarterPack = game:GetService("StarterPack")

local function restoreTools(player, character)
    print("[CoinServer] restoreTools called for:", player.Name)
    character:WaitForChild("HumanoidRootPart")
    print("[CoinServer] HumanoidRootPart found for:", player.Name)
    task.wait(1)

    print("[CoinServer] Backpack contents for", player.Name, ":")
    for _, item in ipairs(player.Backpack:GetChildren()) do
        print("  -", item.Name)
    end
    print("[CoinServer] Character contents for", player.Name, ":")
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            print("  -", item.Name)
        end
    end

    print("[CoinServer] givenTo:", givenTo[player.UserId], "usedCoin:", usedCoin[player.UserId])

    if givenTo[player.UserId] and not usedCoin[player.UserId] then
        local hasCoin = player.Backpack:FindFirstChild("Coin") or character:FindFirstChild("Coin")
        print("[CoinServer] hasCoin:", hasCoin)
        if not hasCoin then
            local coin = ReplicatedStorage:WaitForChild("Coin"):Clone()
            coin.Parent = player.Backpack
            print("[CoinServer] Restored coin for:", player.Name)
        end
    else
        print("[CoinServer] Skipping coin restore — conditions not met")
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        restoreTools(player, character)
    end)
end)

-- catch players already in game
for _, existingPlayer in ipairs(Players:GetPlayers()) do
    existingPlayer.CharacterAdded:Connect(function(character)
        restoreTools(existingPlayer, character)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    givenTo[player.UserId] = nil
    usedCoin[player.UserId] = nil
end)