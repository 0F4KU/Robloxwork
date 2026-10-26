--!strict
-- Server authority for the obby: fall reset, checkpoints, coins and the Coins score.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RESPAWN_HEIGHT_OFFSET = 3.5

local map = Workspace:WaitForChild("Map")
local killZone = Workspace:WaitForChild("KillZone") :: BasePart
local checkpointFolder = map:WaitForChild("Checkpoints")
local coinFolder = map:WaitForChild("Coins")
local Feedback = require(ServerScriptService:WaitForChild("Feedback"))

type Progress = { Index: number, RespawnPosition: Vector3 }
local progressByUserId: { [number]: Progress } = {}

local function getPlayerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function onKillZoneTouched(hit: BasePart)
	local player = getPlayerFromHit(hit)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local progress = progressByUserId[player.UserId]
	if not progress then
		return
	end
	if character:WaitForChild("HumanoidRootPart", 5) then
		character:PivotTo(CFrame.new(progress.RespawnPosition))
	end
end

local function onCheckpointTouched(hit: BasePart, checkpoint: BasePart)
	local player = getPlayerFromHit(hit)
	if not player then
		return
	end
	local index = checkpoint:GetAttribute("Index")
	if type(index) ~= "number" then
		return
	end
	local current = progressByUserId[player.UserId]
	if current and current.Index >= index then
		return
	end
	progressByUserId[player.UserId] = {
		Index = index,
		RespawnPosition = checkpoint.Position + Vector3.new(0, RESPAWN_HEIGHT_OFFSET, 0),
	}
end

local function onCoinTouched(hit: BasePart, coin: BasePart)
	local player = getPlayerFromHit(hit)
	if not player or coin.Parent == nil then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue or not coinsValue:IsA("IntValue") then
		return
	end
	Feedback.coin(coin.Position)
	coin:Destroy()
	coinsValue.Value += 1
end

local function setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
	leaderstats.Parent = player

	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
end

local function connectParts(folder: Instance, handler: (BasePart, BasePart) -> ())
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") then
			local part = child
			part.Touched:Connect(function(hit: BasePart)
				handler(hit, part)
			end)
		end
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player: Player)
	progressByUserId[player.UserId] = nil
end)

killZone.Touched:Connect(onKillZoneTouched)
connectParts(checkpointFolder, onCheckpointTouched)
connectParts(coinFolder, onCoinTouched)
