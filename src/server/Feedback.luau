--!strict
-- Server-side VFX and SFX for pickups, checkpoints, finishes, level-ups and deaths.
-- Each effect spawns on an invisible anchor part that is removed automatically.
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local EFFECT_LIFETIME = 3
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SOUND_VOLUME = 0.6

type EffectStyle = {
	color: Color3,
	soundId: string,
	particleCount: number,
	pitch: number,
}

local STYLES: { [string]: EffectStyle } = {
	Coin = { color = Color3.fromRGB(255, 215, 60), soundId = "rbxasset://sounds/electronicpingshort.wav", particleCount = 14, pitch = 1.1 },
	Checkpoint = { color = Color3.fromRGB(90, 220, 255), soundId = "rbxasset://sounds/action_get_up.mp3", particleCount = 30, pitch = 1 },
	Finish = { color = Color3.fromRGB(255, 120, 230), soundId = "rbxasset://sounds/action_jump.mp3", particleCount = 60, pitch = 1 },
	LevelUp = { color = Color3.fromRGB(140, 255, 150), soundId = "rbxasset://sounds/electronicpingshort.wav", particleCount = 50, pitch = 1.4 },
	Death = { color = Color3.fromRGB(255, 70, 70), soundId = "rbxasset://sounds/uuhhh.mp3", particleCount = 25, pitch = 1 },
}

local Feedback = {}

local function spawnEffect(position: Vector3, styleName: string)
	local style = STYLES[styleName]
	if not style then
		return
	end

	local anchor = Instance.new("Part")
	anchor.Name = "FxAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = Workspace
	Debris:AddItem(anchor, EFFECT_LIFETIME)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(style.color)
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(style.particleCount)

	local sound = Instance.new("Sound")
	sound.SoundId = style.soundId
	sound.Volume = SOUND_VOLUME
	sound.PlaybackSpeed = style.pitch
	sound.RollOffMaxDistance = 80
	sound.Parent = anchor
	sound:Play()
end

function Feedback.coin(position: Vector3)
	spawnEffect(position, "Coin")
end

function Feedback.checkpoint(position: Vector3)
	spawnEffect(position, "Checkpoint")
end

function Feedback.finish(position: Vector3)
	spawnEffect(position, "Finish")
end

function Feedback.levelUp(position: Vector3)
	spawnEffect(position, "LevelUp")
end

function Feedback.death(position: Vector3)
	spawnEffect(position, "Death")
end

return Feedback
