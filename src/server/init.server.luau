-- Steal a Sigma: server bootstrap. Loads player data, claims a base plot per
-- player, wires every RemoteEvent, and starts the conveyor, income, event
-- and steal-check loops.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.DataService)
local BaseService = require(script.BaseService)
local BrainrotService = require(script.BrainrotService)
local StealService = require(script.StealService)
local EventService = require(script.EventService)

BaseService.init()

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function wireRemote(name, handler)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		warn("Steal a Sigma: missing RemoteEvent " .. name)
		return
	end
	remote.OnServerEvent:Connect(handler)
end

local function notify(player, msg, color)
	local popup = remotes:FindFirstChild("IncomePopup")
	if popup then
		popup:FireClient(player, msg, color)
	end
end

-- Buy the conveyor brainrot the client points at.
wireRemote("BuyBrainrot", function(player, model)
	local ok, msg = BrainrotService.buyBrainrot(player, model)
	notify(player, msg, ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 80, 80))
end)

wireRemote("SellBrainrot", function(player, slot)
	local ok, msg = BrainrotService.sellBrainrot(player, slot)
	notify(player, msg, ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 80, 80))
end)

wireRemote("SlapPlayer", function(player, target)
	if target and target:IsA("Player") then
		local ok, msg = StealService.slapPlayer(player, target)
		notify(player, msg, ok and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(255, 80, 80))
	end
end)

wireRemote("StealBrainrot", function(player, victim, slot)
	local ok, msg = StealService.stealBrainrot(player, victim, slot)
	notify(player, msg, ok and Color3.fromRGB(255, 100, 255) or Color3.fromRGB(255, 80, 80))
end)

wireRemote("BuyLock", function(player)
	local ok, msg = BaseService.buyLock(player)
	notify(player, msg, ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 80, 80))
end)

wireRemote("Rebirth", function(player)
	local ok, msg = DataService.rebirth(player)
	if ok then
		-- Rebirth clears the base: owned brainrots are removed.
		for slot = 1, 6 do
			local record = BaseService.removeBrainrot(player, slot)
			if record and record.model then
				record.model:Destroy()
			end
		end
	end
	notify(player, msg, ok and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80))
end)

wireRemote("SlapBoss", function(player)
	EventService.damageBoss(player, 25)
end)

local function onPlayerAdded(player)
	DataService.loadProfile(player)
	local plotIndex = BaseService.claimPlot(player)
	local banner = remotes:FindFirstChild("EventBanner")
	if banner then
		if plotIndex then
			banner:FireClient(player, "🧠 WELCOME TO STEAL A SIGMA! Buy a brainrot off the conveyor!", Color3.fromRGB(120, 255, 120))
		else
			banner:FireClient(player, "All bases are full - you are spectating!", Color3.fromRGB(255, 200, 0))
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Game loops, each on its own thread.
task.spawn(BrainrotService.startConveyorLoop)
task.spawn(BrainrotService.startIncomeLoop)
task.spawn(EventService.startEventLoop)
task.spawn(function()
	while true do
		task.wait(1)
		StealService.checkCarriedHome()
	end
end)

print("Steal a Sigma server ready: conveyor, bases, steals and events live.")
