--!strict
-- Server authority for XP, levels, and stat points.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProgressionConfig"))
local allocateStatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AllocateStat") :: RemoteEvent
local checkpointFolder = Workspace:WaitForChild("Map"):WaitForChild("Checkpoints")
local Feedback = require(ServerScriptService:WaitForChild("Feedback"))

type PlayerData = {
	XP: number,
	Level: number,
	StatPoints: number,
	SpeedPoints: number,
	JumpPoints: number,
	Checkpoints: { [number]: boolean },
	Finishes: { [string]: boolean },
	LastCoins: number,
}

local playerData: { [number]: PlayerData } = {}

local function getPlayerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function syncAttributes(player: Player, data: PlayerData)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("XPToNextLevel", Config.xpToNextLevel(data.Level))
	player:SetAttribute("StatPoints", data.StatPoints)
	player:SetAttribute("SpeedPoints", data.SpeedPoints)
	player:SetAttribute("JumpPoints", data.JumpPoints)
	local leaderstats = player:FindFirstChild("leaderstats")
	local levelValue = leaderstats and leaderstats:FindFirstChild("Level")
	if levelValue and levelValue:IsA("IntValue") then
		levelValue.Value = data.Level
	end
end

local function applyStats(player: Player, character: Model)
	local data = playerData[player.UserId]
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not data or not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.WalkSpeed = Config.BASE_WALK_SPEED + data.SpeedPoints * Config.WALK_SPEED_PER_POINT
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Config.BASE_JUMP_POWER + data.JumpPoints * Config.JUMP_POWER_PER_POINT
end

local function getRootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function addXp(player: Player, data: PlayerData, amount: number)
	local startLevel = data.Level
	data.XP += amount
	while data.XP >= Config.xpToNextLevel(data.Level) do
		data.XP -= Config.xpToNextLevel(data.Level)
		data.Level += 1
		data.StatPoints += Config.STAT_POINTS_PER_LEVEL
	end
	syncAttributes(player, data)
	if data.Level > startLevel then
		local position = getRootPosition(player)
		if position then
			Feedback.levelUp(position)
		end
	end
end

local function onCheckpointTouched(hit: BasePart, checkpoint: BasePart)
	local player = getPlayerFromHit(hit)
	local data = player and playerData[player.UserId]
	local index = checkpoint:GetAttribute("Index")
	if not player or not data or type(index) ~= "number" or data.Checkpoints[index] then
		return
	end
	data.Checkpoints[index] = true
	addXp(player, data, Config.XP_PER_CHECKPOINT)
	Feedback.checkpoint(checkpoint.Position)
end

local function onFinishTouched(hit: BasePart, finish: BasePart)
	local player = getPlayerFromHit(hit)
	local data = player and playerData[player.UserId]
	local finishId = finish:GetAttribute("FinishId")
	if not player or not data or type(finishId) ~= "string" or data.Finishes[finishId] then
		return
	end
	data.Finishes[finishId] = true
	local reward = finish:GetAttribute("FinishReward")
	addXp(player, data, if type(reward) == "number" then reward else Config.XP_PER_FINISH)
	Feedback.finish(finish.Position)
end

local function watchCoins(player: Player, leaderstats: Instance)
	local coins = leaderstats:WaitForChild("Coins")
	if not coins:IsA("IntValue") then
		return
	end
	coins.Changed:Connect(function(newValue: number)
		local data = playerData[player.UserId]
		if not data then
			return
		end
		local gained = newValue - data.LastCoins
		data.LastCoins = newValue
		if gained > 0 then
			addXp(player, data, gained * Config.XP_PER_COIN)
		end
	end)
end

local function watchDeath(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			Feedback.death(root.Position)
		end
	end)
end

local function setupPlayer(player: Player)
	local data: PlayerData = {
		XP = 0,
		Level = 1,
		StatPoints = 0,
		SpeedPoints = 0,
		JumpPoints = 0,
		Checkpoints = {},
		Finishes = {},
		LastCoins = 0,
	}
	playerData[player.UserId] = data
	syncAttributes(player, data)

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if not leaderstats then
			return
		end
		local levelValue = Instance.new("IntValue")
		levelValue.Name = "Level"
		levelValue.Value = data.Level
		levelValue.Parent = leaderstats
		watchCoins(player, leaderstats)
	end)

	player.CharacterAdded:Connect(function(character: Model)
		applyStats(player, character)
		task.spawn(watchDeath, character)
	end)
	if player.Character then
		applyStats(player, player.Character)
		task.spawn(watchDeath, player.Character)
	end
end

allocateStatRemote.OnServerEvent:Connect(function(player: Player, statName: unknown)
	if typeof(statName) ~= "string" then
		return
	end
	local data = playerData[player.UserId]
	if not data or data.StatPoints <= 0 then
		return
	end
	if statName == "Speed" then
		if data.SpeedPoints >= Config.MAX_SPEED_POINTS then
			return
		end
		data.SpeedPoints += 1
	elseif statName == "Jump" then
		if data.JumpPoints >= Config.MAX_JUMP_POINTS then
			return
		end
		data.JumpPoints += 1
	else
		return
	end
	data.StatPoints -= 1
	syncAttributes(player, data)
	if player.Character then
		applyStats(player, player.Character)
	end
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player: Player)
	playerData[player.UserId] = nil
end)

for _, child in checkpointFolder:GetChildren() do
	if child:IsA("BasePart") then
		local part = child :: BasePart
		part.Touched:Connect(function(hit: BasePart)
			onCheckpointTouched(hit, part)
		end)
	end
end

for _, descendant in Workspace:WaitForChild("Map"):GetDescendants() do
	if descendant:IsA("BasePart") and descendant:GetAttribute("FinishId") ~= nil then
		local finish = descendant
		finish.Touched:Connect(function(hit: BasePart)
			onFinishTouched(hit, finish)
		end)
	end
end
