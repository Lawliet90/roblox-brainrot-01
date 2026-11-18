-- Steal a Sigma: shared tuning. One place for every number the game balances on.
local Config = {}

Config.START_RIZZ = 100
Config.MAX_BASE_SLOTS = 6
Config.PLOT_COUNT = 8
Config.INCOME_TICK = 1 -- seconds between income payouts
Config.CONVEYOR_SPAWN_INTERVAL = 8 -- seconds between brainrots walking in (32 studs apart at speed 4, keeps 120px labels from overlapping)
Config.CONVEYOR_LENGTH = 120
Config.CONVEYOR_SPEED = 4 -- studs per second
Config.STEAL_CARRY_TIME = 30 -- seconds to carry a stolen brainrot home
Config.BASE_LOCK_DURATION = 30 -- seconds a bought lock protects a base
Config.BASE_LOCK_COST = 500
Config.SLAP_COOLDOWN = 3
Config.SLAP_RAGDOLL_TIME = 2
Config.REBIRTH_COST_BASE = 25000
Config.REBIRTH_MULTIPLIER_PER_LEVEL = 0.5 -- +50% income per rebirth
Config.EVENT_INTERVAL = 90 -- seconds between random events
Config.FANUM_TAX_RATE = 0.10
Config.BOSS_HP = 500
Config.BOSS_REWARD_RARITY = "Legendary"

-- Rarity ladder, cheapest first. Weight drives conveyor spawns.
Config.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
Config.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(180, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic = Color3.fromRGB(255, 60, 120),
	Secret = Color3.fromRGB(0, 255, 200),
}
Config.RARITY_WEIGHTS = {
	Common = 40,
	Rare = 26,
	Epic = 16,
	Legendary = 10,
	Mythic = 6,
	Secret = 2,
}

-- Mutations roll on spawn: name, income multiplier, roll weight.
Config.MUTATIONS = {
	{ name = "Normal", multiplier = 1, weight = 70 },
	{ name = "Golden", multiplier = 2, weight = 16 },
	{ name = "Diamond", multiplier = 5, weight = 8 },
	{ name = "Rainbow", multiplier = 10, weight = 4 },
	{ name = "Glitched", multiplier = 25, weight = 2 },
}
Config.MUTATION_COLORS = {
	Normal = Color3.fromRGB(255, 255, 255),
	Golden = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(120, 220, 255),
	Rainbow = Color3.fromRGB(255, 100, 255),
	Glitched = Color3.fromRGB(120, 255, 120),
}

return Config
