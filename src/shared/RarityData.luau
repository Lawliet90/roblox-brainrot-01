-- Steal a Sigma: rarity ladder, mutation labels and rebirth maths.
local RarityData = {}
local Config = require(script.Parent.Config)

function RarityData.getColor(rarity)
	return Config.RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
end

function RarityData.getMutationColor(mutationName)
	return Config.MUTATION_COLORS[mutationName] or Color3.fromRGB(255, 255, 255)
end

-- Full display label: mutation + name + rarity, e.g. "Golden Sigma Wolf [Epic]".
function RarityData.getDisplayLabel(brainrotName, mutationName, rarity)
	if mutationName == "Normal" then
		return brainrotName .. " [" .. rarity .. "]"
	end
	return mutationName .. " " .. brainrotName .. " [" .. rarity .. "]"
end

-- Income per second after mutation and rebirth multipliers.
function RarityData.getIncomePerSecond(baseIncome, mutationMultiplier, rebirthLevel)
	local rebirthMultiplier = 1 + rebirthLevel * Config.REBIRTH_MULTIPLIER_PER_LEVEL
	return math.floor(baseIncome * mutationMultiplier * rebirthMultiplier + 0.5)
end

-- Rizz cost of the next rebirth for a player at this rebirth level.
function RarityData.getRebirthCost(rebirthLevel)
	return Config.REBIRTH_COST_BASE * (rebirthLevel + 1)
end

-- Sell price: half the buy price, mutation bumps it.
function RarityData.getSellPrice(cost, mutationMultiplier)
	return math.floor(cost * 0.5 * (1 + (mutationMultiplier - 1) * 0.5) + 0.5)
end

return RarityData
