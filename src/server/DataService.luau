-- Steal a Sigma: player data. leaderstats Rizz / Aura / Braincells, saved
-- to a DataStore with an in-memory fallback when Studio runs offline.
local DataService = {}
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("StealASigma_v1")
end)

local profiles = {} -- [player] = { Rizz, Aura, Braincells, Rebirths, Owned = {brainrot ids} }

function DataService.getProfile(player)
	return profiles[player]
end

function DataService.createLeaderstats(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local function makeStat(name, value)
		local stat = Instance.new("IntValue")
		stat.Name = name
		stat.Value = value
		stat.Parent = leaderstats
		return stat
	end
	makeStat("Rizz", profile.Rizz)
	makeStat("Aura", profile.Aura)
	makeStat("Braincells", profile.Braincells)
end

function DataService.loadProfile(player)
	local data = nil
	if store then
		pcall(function()
			data = store:GetAsync("player_" .. player.UserId)
		end)
	end
	local profile = {
		Rizz = Config.START_RIZZ,
		Aura = 0,
		Braincells = 100,
		Rebirths = 0,
		Owned = {},
	}
	if type(data) == "table" then
		profile.Rizz = data.Rizz or profile.Rizz
		profile.Aura = data.Aura or 0
		profile.Braincells = data.Braincells or 100
		profile.Rebirths = data.Rebirths or 0
	end
	profiles[player] = profile
	DataService.createLeaderstats(player)
	return profile
end

function DataService.saveProfile(player)
	local profile = profiles[player]
	if not profile or not store then
		return
	end
	pcall(function()
		store:SetAsync("player_" .. player.UserId, {
			Rizz = profile.Rizz,
			Aura = profile.Aura,
			Braincells = profile.Braincells,
			Rebirths = profile.Rebirths,
		})
	end)
end

function DataService.addRizz(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Rizz += amount
	profile.Aura += amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rizz = leaderstats:FindFirstChild("Rizz")
		local aura = leaderstats:FindFirstChild("Aura")
		if rizz then
			rizz.Value = profile.Rizz
		end
		if aura then
			aura.Value = profile.Aura
		end
	end
end

function DataService.spendRizz(player, amount)
	local profile = profiles[player]
	if not profile or profile.Rizz < amount then
		return false
	end
	profile.Rizz -= amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rizz = leaderstats:FindFirstChild("Rizz")
		if rizz then
			rizz.Value = profile.Rizz
		end
	end
	return true
end

function DataService.addBraincells(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Braincells = math.clamp(profile.Braincells + amount, 0, 999)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stat = leaderstats:FindFirstChild("Braincells")
		if stat then
			stat.Value = profile.Braincells
		end
	end
end

-- Rebirth: reset Rizz and owned brainrots for a permanent income multiplier.
function DataService.rebirth(player)
	local profile = profiles[player]
	if not profile then
		return false, "No profile"
	end
	local RarityData = require(ReplicatedStorage.Shared.RarityData)
	local cost = RarityData.getRebirthCost(profile.Rebirths)
	if profile.Rizz < cost then
		return false, "Need " .. cost .. " Rizz to rebirth"
	end
	profile.Rizz = Config.START_RIZZ
	profile.Rebirths += 1
	profile.Braincells = 100
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rizz = leaderstats:FindFirstChild("Rizz")
		local cells = leaderstats:FindFirstChild("Braincells")
		if rizz then
			rizz.Value = profile.Rizz
		end
		if cells then
			cells.Value = profile.Braincells
		end
	end
	return true, "Rebirth " .. profile.Rebirths .. "! Income x" .. (1 + profile.Rebirths * Config.REBIRTH_MULTIPLIER_PER_LEVEL)
end

function DataService.removeProfile(player)
	DataService.saveProfile(player)
	profiles[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	DataService.removeProfile(player)
end)

return DataService
