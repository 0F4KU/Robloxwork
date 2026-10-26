--!strict
-- Client HUD: level, XP bar, stat points, stat allocation and level-up toast.
-- Every value is read from player attributes written by the server; the client never decides progression.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProgressionConfig"))
local allocateStatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AllocateStat") :: RemoteEvent

local player = Players.LocalPlayer
local screenGui = script.Parent :: ScreenGui
local stats = screenGui:WaitForChild("Stats") :: Frame
local levelLabel = stats:WaitForChild("LevelLabel") :: TextLabel
local statPointsLabel = stats:WaitForChild("StatPointsLabel") :: TextLabel
local xpBack = stats:WaitForChild("XPBack") :: Frame
local xpFill = xpBack:WaitForChild("XPFill") :: Frame
local xpText = xpBack:WaitForChild("XPText") :: TextLabel
local speedButton = stats:WaitForChild("SpeedButton") :: TextButton
local jumpButton = stats:WaitForChild("JumpButton") :: TextButton
local toast = screenGui:WaitForChild("LevelUpToast") :: TextLabel

local COLOR_GOLD = Color3.fromRGB(255, 205, 90)
local COLOR_MUTED = Color3.fromRGB(150, 155, 175)
local COLOR_ENABLED = Color3.fromRGB(70, 130, 255)
local COLOR_DISABLED = Color3.fromRGB(55, 58, 75)
local TWEEN_SMOOTH = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_PRESS = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TOAST_HOLD_SECONDS = 2.5

local function readNumber(attributeName: string): number
	local value = player:GetAttribute(attributeName)
	return if type(value) == "number" then value else 0
end

local function refreshStatButton(button: TextButton, label: string, points: number, maxPoints: number, statPoints: number)
	local canSpend = statPoints > 0 and points < maxPoints
	button.Text = string.format("%s\n%d / %d", label, points, maxPoints)
	button.BackgroundColor3 = if canSpend then COLOR_ENABLED else COLOR_DISABLED
end

local function refreshHud()
	local level = readNumber("Level")
	local xp = readNumber("XP")
	local xpNeeded = math.max(readNumber("XPToNextLevel"), 1)
	local statPoints = readNumber("StatPoints")

	levelLabel.Text = string.format("NIVEL %d", level)
	statPointsLabel.Text = string.format("Puncte: %d", statPoints)
	statPointsLabel.TextColor3 = if statPoints > 0 then COLOR_GOLD else COLOR_MUTED
	xpText.Text = string.format("XP %d / %d", xp, xpNeeded)
	TweenService:Create(xpFill, TWEEN_SMOOTH, { Size = UDim2.fromScale(math.clamp(xp / xpNeeded, 0, 1), 1) }):Play()

	refreshStatButton(speedButton, "VITEZĂ", readNumber("SpeedPoints"), Config.MAX_SPEED_POINTS, statPoints)
	refreshStatButton(jumpButton, "SĂRITURĂ", readNumber("JumpPoints"), Config.MAX_JUMP_POINTS, statPoints)
end

local toastToken = 0
local function showLevelUpToast(level: number)
	toastToken += 1
	local token = toastToken
	toast.Text = string.format("NIVEL %d! +%d punct de statistică", level, Config.STAT_POINTS_PER_LEVEL)
	TweenService:Create(toast, TWEEN_SMOOTH, { TextTransparency = 0, TextStrokeTransparency = 0.2 }):Play()
	task.delay(TOAST_HOLD_SECONDS, function()
		if token ~= toastToken then
			return
		end
		TweenService:Create(toast, TWEEN_SMOOTH, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

local function addPressFeedback(button: TextButton)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local function tweenTo(value: number)
		TweenService:Create(scale, TWEEN_PRESS, { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		tweenTo(1.04)
	end)
	button.MouseLeave:Connect(function()
		tweenTo(1)
	end)
	button.MouseButton1Down:Connect(function()
		tweenTo(0.95)
	end)
	button.MouseButton1Up:Connect(function()
		tweenTo(1.04)
	end)
end

local function requestStat(statName: string)
	if readNumber("StatPoints") <= 0 then
		return
	end
	allocateStatRemote:FireServer(statName)
end

speedButton.Activated:Connect(function()
	requestStat("Speed")
end)
jumpButton.Activated:Connect(function()
	requestStat("Jump")
end)
addPressFeedback(speedButton)
addPressFeedback(jumpButton)

local lastLevel = readNumber("Level")
for _, attributeName in { "Level", "XP", "XPToNextLevel", "StatPoints", "SpeedPoints", "JumpPoints" } do
	player:GetAttributeChangedSignal(attributeName):Connect(refreshHud)
end
player:GetAttributeChangedSignal("Level"):Connect(function()
	local level = readNumber("Level")
	if level > lastLevel then
		showLevelUpToast(level)
	end
	lastLevel = level
end)

refreshHud()
