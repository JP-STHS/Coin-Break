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

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        -- restore coin on respawn only if they got one but havent used it yet
        if givenTo[player.UserId] and not usedCoin[player.UserId] then
            local hasCoin = player.Backpack:FindFirstChild("Coin") or character:FindFirstChild("Coin")
            if not hasCoin then
                local coin = ReplicatedStorage:WaitForChild("Coin"):Clone()
                coin.Parent = player.Backpack
                print("Restored coin for:", player.Name)
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    givenTo[player.UserId] = nil
    usedCoin[player.UserId] = nil
end)