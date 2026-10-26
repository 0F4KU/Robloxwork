--!strict
-- Runs moving, vanishing and spinning hazards for Zone2 and Zone3 (configured by HazardType attributes).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type Mover = { part: BasePart, base: Vector3, amplitude: number, period: number }
type Sweeper = { part: BasePart, center: Vector3, spin: number }

local movers: { Mover } = {}
local sweepers: { Sweeper } = {}

local function killCharacterFromPart(hit: BasePart)
	local model = hit:FindFirstAncestorOfClass("Model")
	local player = model and Players:GetPlayerFromCharacter(model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if player and humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local function startVanishing(part: BasePart)
	local solidTime: number = part:GetAttribute("SolidTime") or 2
	local goneTime: number = part:GetAttribute("GoneTime") or 1.5
	task.spawn(function()
		while part.Parent do
			part.CanCollide = true
			part.Transparency = 0
			task.wait(solidTime)
			part.CanCollide = false
			part.Transparency = 0.85
			task.wait(goneTime)
		end
	end)
end

for _, descendant in Workspace:WaitForChild("Map"):GetDescendants() do
	if descendant:IsA("BasePart") then
		local hazardType = descendant:GetAttribute("HazardType")
		if hazardType == "Mover" then
			table.insert(movers, {
				part = descendant,
				base = descendant.Position,
				amplitude = descendant:GetAttribute("MoveZ") or 8,
				period = descendant:GetAttribute("Period") or 4,
			})
		elseif hazardType == "Vanish" then
			startVanishing(descendant)
		elseif hazardType == "Sweeper" then
			table.insert(sweepers, {
				part = descendant,
				center = descendant.Position,
				spin = descendant:GetAttribute("Spin") or 1.2,
			})
			descendant.Touched:Connect(killCharacterFromPart)
		end
	end
end

RunService.Heartbeat:Connect(function()
	local now = Workspace:GetServerTimeNow()
	for _, mover in movers do
		local phase = math.sin(2 * math.pi * now / mover.period)
		mover.part.Position = mover.base + Vector3.new(0, 0, mover.amplitude * phase)
	end
	for _, sweeper in sweepers do
		sweeper.part.CFrame = CFrame.new(sweeper.center) * CFrame.Angles(0, now * sweeper.spin, 0)
	end
end)
