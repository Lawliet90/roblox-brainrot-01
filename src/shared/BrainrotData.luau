-- Steal a Sigma: the brainrot cast. Original characters, each with a rarity,
-- a buy price and the Rizz it earns per second on your base.
local BrainrotData = {}

BrainrotData.CAST = {
	{
		name = "Toilet Skibidi",
		rarity = "Common",
		cost = 50,
		income = 2,
		color = Color3.fromRGB(220, 220, 230),
		accent = Color3.fromRGB(90, 140, 255),
		size = 2.4,
		blurb = "He flushes. You profit.",
	},
	{
		name = "Mewing Cat",
		rarity = "Common",
		cost = 120,
		income = 5,
		color = Color3.fromRGB(255, 200, 120),
		accent = Color3.fromRGB(255, 120, 180),
		size = 2.2,
		blurb = "Jawline so sharp it cuts rent.",
	},
	{
		name = "Ohio Rizzler",
		rarity = "Rare",
		cost = 350,
		income = 12,
		color = Color3.fromRGB(120, 255, 140),
		accent = Color3.fromRGB(255, 80, 80),
		size = 2.6,
		blurb = "Only in Ohio. Only this price.",
	},
	{
		name = "Grimace Shake",
		rarity = "Rare",
		cost = 600,
		income = 20,
		color = Color3.fromRGB(190, 120, 255),
		accent = Color3.fromRGB(255, 255, 255),
		size = 2.6,
		blurb = "Drink it. Earn from it. Fear it.",
	},
	{
		name = "Sigma Wolf",
		rarity = "Epic",
		cost = 1500,
		income = 45,
		color = Color3.fromRGB(90, 90, 110),
		accent = Color3.fromRGB(0, 220, 255),
		size = 3.0,
		blurb = "Lone wolf. Shared wallet.",
	},
	{
		name = "Fanum Tax Goblin",
		rarity = "Epic",
		cost = 2500,
		income = 70,
		color = Color3.fromRGB(80, 200, 80),
		accent = Color3.fromRGB(255, 215, 0),
		size = 2.8,
		blurb = "He taxes others. He pays you.",
	},
	{
		name = "Mewing Golem",
		rarity = "Legendary",
		cost = 6000,
		income = 150,
		color = Color3.fromRGB(150, 150, 160),
		accent = Color3.fromRGB(255, 200, 120),
		size = 3.6,
		blurb = "A statue that never skips jaw day.",
	},
	{
		name = "Skibidi Boss",
		rarity = "Legendary",
		cost = 10000,
		income = 240,
		color = Color3.fromRGB(60, 60, 90),
		accent = Color3.fromRGB(255, 60, 60),
		size = 3.8,
		blurb = "The final flush. Rare raid drop.",
	},
	{
		name = "Gigachad Prime",
		rarity = "Mythic",
		cost = 25000,
		income = 550,
		color = Color3.fromRGB(255, 220, 170),
		accent = Color3.fromRGB(255, 180, 0),
		size = 4.0,
		blurb = "Chin first. Economy second.",
	},
	{
		name = "The Rizzler",
		rarity = "Mythic",
		cost = 50000,
		income = 1100,
		color = Color3.fromRGB(255, 240, 200),
		accent = Color3.fromRGB(255, 100, 200),
		size = 4.2,
		blurb = "Rizz so strong the conveyor bows.",
	},
	{
		name = "Ohio Final Boss",
		rarity = "Secret",
		cost = 150000,
		income = 3000,
		color = Color3.fromRGB(40, 40, 40),
		accent = Color3.fromRGB(255, 0, 200),
		size = 4.6,
		blurb = "You were never meant to own this.",
	},
}

-- Pick a random cast member weighted by its rarity, for conveyor spawns.
function BrainrotData.pickRandomSpawn()
	local Config = require(script.Parent.Config)
	local total = 0
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		total += Config.RARITY_WEIGHTS[rarity]
	end
	local roll = math.random(1, total)
	local running = 0
	local pickedRarity = "Common"
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		running += Config.RARITY_WEIGHTS[rarity]
		if roll <= running then
			pickedRarity = rarity
			break
		end
	end
	local pool = {}
	for _, entry in ipairs(BrainrotData.CAST) do
		if entry.rarity == pickedRarity then
			table.insert(pool, entry)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation for a fresh spawn, weighted by Config.MUTATIONS.
function BrainrotData.rollMutation()
	local Config = require(script.Parent.Config)
	local total = 0
	for _, m in ipairs(Config.MUTATIONS) do
		total += m.weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, m in ipairs(Config.MUTATIONS) do
		running += m.weight
		if roll <= running then
			return m
		end
	end
	return Config.MUTATIONS[1]
end

function BrainrotData.findByName(name)
	for _, entry in ipairs(BrainrotData.CAST) do
		if entry.name == name then
			return entry
		end
	end
	return nil
end

return BrainrotData
