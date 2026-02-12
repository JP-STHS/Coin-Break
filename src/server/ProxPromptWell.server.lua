ProximityPrompt = workspace.wellhole.ProximityPrompt
ProximityPrompt.Triggered:Connect(function(player)
	local Tool = player.Backpack:FindFirstChild("Coin")  or player.Character:FindFirstChild("Coin")
	if Tool and Tool.Parent == player.Character then
		print("u used a coin")
		Tool:Destroy()
	else
		print("no more coin :c")
	end
end)