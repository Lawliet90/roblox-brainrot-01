-- Steal a Sigma: base plots. 8 plots ring the conveyor; each player claims one
-- on join, fills up to 6 slots with bought brainrots, and can buy a lock that
-- blocks stealing for 30 seconds.
local BaseService = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local plots = {} -- [plotIndex] = { owner, model, slots = { [slot] = brainrotRecord }, lockedUntil }
local playerPlot = {} -- [player] = plotIndex

function BaseService.init()
	local map = workspace:WaitForChild("Map", 10)
	if not map then
		warn("Steal a Sigma: Map folder missing, plots disabled")
		return
	end
	local plotsFolder = map:WaitForChild("Plots", 10)
	if not plotsFolder then
		warn("Steal a Sigma: Plots folder missing")
		return
	end
	for _, plotModel in ipairs(plotsFolder:GetChildren()) do
		if plotModel:IsA("Model") then
			local index = tonumber(string.match(plotModel.Name, "(%d+)$")) or #plots + 1
			plots[index] = { owner = nil, model = plotModel, slots = {}, lockedUntil = 0 }
		end
	end
end

function BaseService.claimPlot(player)
	for index, plot in ipairs(plots) do
		if plot.owner == nil then
			plot.owner = player
			playerPlot[player] = index
			local sign = plot.model:FindFirstChild("OwnerSign", true)
			if sign and sign:IsA("TextLabel") then
				sign.Text = player.DisplayName .. "'s BASE"
			end
			return index
		end
	end
	return nil
end

function BaseService.getPlotOf(player)
	local index = playerPlot[player]
	if index then
		return plots[index]
	end
	return nil
end

function BaseService.getPlotIndexOf(player)
	return playerPlot[player]
end

-- Is this position inside the player's own plot? Used by Fanum Tax hiding.
function BaseService.isInsideOwnPlot(player, position)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return false
	end
	local floor = plot.model:FindFirstChild("Floor")
	if not floor then
		return false
	end
	local half = floor.Size / 2
	return math.abs(position.X - floor.Position.X) <= half.X
		and math.abs(position.Z - floor.Position.Z) <= half.Z
end

function BaseService.isLocked(plot)
	return os.clock() < plot.lockedUntil
end

-- Next free slot position inside a plot, or nil when the base is full.
function BaseService.nextFreeSlot(player)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return nil
	end
	for slot = 1, Config.MAX_BASE_SLOTS do
		if plot.slots[slot] == nil then
			return slot
		end
	end
	return nil
end

function BaseService.placeBrainrot(player, record)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return false
	end
	local slot = BaseService.nextFreeSlot(player)
	if not slot then
		return false
	end
	plot.slots[slot] = record
	record.slot = slot
	local pad = plot.model:FindFirstChild("Pad" .. slot)
	if pad and record.model then
		record.model:PivotTo(pad.CFrame + Vector3.new(0, 2, 0))
	end
	return true
end

function BaseService.removeBrainrot(player, slot)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return nil
	end
	local record = plot.slots[slot]
	plot.slots[slot] = nil
	return record
end

function BaseService.getBrainrots(player)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return {}
	end
	local list = {}
	for _, record in pairs(plot.slots) do
		table.insert(list, record)
	end
	return list
end

-- Buy a 30-second lock with Rizz. Returns ok, message.
function BaseService.buyLock(player)
	local DataService = require(script.Parent.DataService)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return false, "No base yet"
	end
	if BaseService.isLocked(plot) then
		return false, "Base already locked"
	end
	if not DataService.spendRizz(player, Config.BASE_LOCK_COST) then
		return false, "Need " .. Config.BASE_LOCK_COST .. " Rizz for a lock"
	end
	plot.lockedUntil = os.clock() + Config.BASE_LOCK_DURATION
	local gate = plot.model:FindFirstChild("LockGate")
	if gate then
		gate.Transparency = 0.3
	end
	task.delay(Config.BASE_LOCK_DURATION, function()
		if gate then
			gate.Transparency = 0.85
		end
	end)
	return true, "Base locked for 30s! No steals allowed."
end

function BaseService.releasePlot(player)
	local index = playerPlot[player]
	if index and plots[index] then
		local plot = plots[index]
		for _, record in pairs(plot.slots) do
			if record.model then
				record.model:Destroy()
			end
		end
		plot.slots = {}
		plot.owner = nil
		plot.lockedUntil = 0
		local sign = plot.model:FindFirstChild("OwnerSign", true)
		if sign and sign:IsA("TextLabel") then
			sign.Text = "EMPTY PLOT - CLAIM ME"
		end
	end
	playerPlot[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	BaseService.releasePlot(player)
end)

return BaseService
