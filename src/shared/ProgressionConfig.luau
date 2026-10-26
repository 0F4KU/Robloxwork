--!strict
-- Tuning values for XP, levels, and stat points. Read by server scripts.
local Config = {}

Config.XP_PER_COIN = 10
Config.XP_PER_CHECKPOINT = 25
Config.XP_PER_FINISH = 50
Config.STAT_POINTS_PER_LEVEL = 1
Config.XP_BASE_PER_LEVEL = 100

Config.BASE_WALK_SPEED = 16
Config.WALK_SPEED_PER_POINT = 2
Config.MAX_SPEED_POINTS = 10

Config.BASE_JUMP_POWER = 50
Config.JUMP_POWER_PER_POINT = 5
Config.MAX_JUMP_POINTS = 10

function Config.xpToNextLevel(level: number): number
	return Config.XP_BASE_PER_LEVEL * level
end

return Config
