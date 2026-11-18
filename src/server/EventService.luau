-- Steal a Sigma: random events. Every ~90s the server picks one: Fanum Tax,
-- Ohio Storm, or a Skibidi Boss raid. Each one is announced to every client
-- with a banner before it lands.
local EventService = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)

local activeEvent = nil

local function broadcastBanner(text, color)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		return
	end
	local banner = remotes:FindFirstChild("EventBanner")
	if banner then
		banner:FireAllClients(text, color)
	end
end

-- Fanum Tax: the Goblin walks the plaza and takes 10% of every player's Rizz,
-- unless they hide inside their own base.
function EventService.runFanumTax()
	broadcastBanner("⚠️ WARNING: FANUM TAX INCOMING! HIDE IN YOUR BASE!", Color3.fromRGB(255, 200, 0))
	task.wait(5)
	local DataService = require(script.Parent.DataService)
	local BaseService = require(script.Parent.BaseService)
	local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
	local goblinDef = BrainrotData.findByName("Fanum Tax Goblin")
	local BrainrotService = require(script.Parent.BrainrotService)
	local goblin = BrainrotService.buildModel(goblinDef, { name = "Golden", multiplier = 2 })
	goblin:PivotTo(CFrame.new(0, 3, 40))
	goblin.Parent = workspace
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		if BaseService.isInsideOwnPlot(player, character:GetPivot().Position) then
			broadcastBanner(player.DisplayName .. " dodged the Fanum Tax!", Color3.fromRGB(120, 255, 120))
		else
			local profile = DataService.getProfile(player)
			if profile then
				local tax = math.floor(profile.Rizz * Config.FANUM_TAX_RATE)
				DataService.spendRizz(player, tax)
			end
		end
	end
	task.wait(8)
	goblin:Destroy()
	broadcastBanner("💰 FANUM TAX COLLECTED. The Goblin leaves...", Color3.fromRGB(255, 200, 0))
end

-- Ohio Storm: a tornado spins over the arena and meteors fall. Players caught
-- outside their base get ragdolled; inside is safe.
function EventService.runOhioStorm()
	broadcastBanner("🌪️ OHIO STORM! DASH HOME OR GET RAGDOLLED!", Color3.fromRGB(255, 80, 80))
	local map = workspace:FindFirstChild("Map")
	local tornado = nil
	if map then
		tornado = map:FindFirstChild("Tornado")
	end
	if tornado then
		tornado.Transparency = 0
		local spin = TweenService:Create(
			tornado,
			TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
			{ CFrame = tornado.CFrame * CFrame.Angles(0, math.rad(360), 0) }
		)
		spin:Play()
		task.delay(12, function()
			spin:Cancel()
			tornado.Transparency = 1
		end)
	end
	local BaseService = require(script.Parent.BaseService)
	for _ = 1, 10 do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character then
				continue
			end
			if not BaseService.isInsideOwnPlot(player, character:GetPivot().Position) then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:ChangeState(Enum.HumanoidStateType.Physics)
					humanoid.Sit = true
					task.delay(1.5, function()
						if humanoid.Parent then
							humanoid.Sit = false
							humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
						end
					end)
				end
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					root.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), 15, math.random(-20, 20))
				end
			end
		end
	end
	broadcastBanner("☀️ The Ohio Storm passes... for now.", Color3.fromRGB(120, 255, 120))
end

-- Skibidi Boss raid: a giant boss spawns in the plaza. Slap it to damage it;
-- when its HP hits zero it drops a Legendary brainrot onto the conveyor.
function EventService.runBossRaid()
	broadcastBanner("🚽 SKIBIDI BOSS RAID! SLAP HIM DOWN FOR A RARE DROP!", Color3.fromRGB(255, 60, 60))
	local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
	local BrainrotService = require(script.Parent.BrainrotService)
	local bossDef = BrainrotData.findByName("Skibidi Boss")
	local boss = BrainrotService.buildModel(bossDef, { name = "Glitched", multiplier = 25 })
	boss:PivotTo(CFrame.new(0, 5, 30))
	boss.Parent = workspace
	local hp = Config.BOSS_HP
	local hpGui = Instance.new("BillboardGui")
	hpGui.Name = "BossHP"
	hpGui.Size = UDim2.fromOffset(240, 40)
	hpGui.StudsOffset = Vector3.new(0, 6, 0)
	hpGui.AlwaysOnTop = true
	hpGui.Parent = boss
	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HPLabel"
	hpLabel.Size = UDim2.fromScale(1, 1)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "SKIBIDI BOSS: " .. hp .. " HP"
	hpLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
	hpLabel.TextScaled = true
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.Parent = hpGui
	activeEvent = { kind = "boss", model = boss, hp = hp, label = hpLabel }
	task.delay(60, function()
		if activeEvent and activeEvent.kind == "boss" then
			activeEvent = nil
			boss:Destroy()
			broadcastBanner("The Skibidi Boss escaped...", Color3.fromRGB(255, 200, 0))
		end
	end)
end

-- Slapping the boss during a raid damages it. Returns true when it dies.
function EventService.damageBoss(player, amount)
	if not activeEvent or activeEvent.kind ~= "boss" then
		return false
	end
	activeEvent.hp -= amount
	activeEvent.label.Text = "SKIBIDI BOSS: " .. math.max(activeEvent.hp, 0) .. " HP"
	if activeEvent.hp <= 0 then
		local boss = activeEvent.model
		activeEvent = nil
		boss:Destroy()
		local BrainrotService = require(script.Parent.BrainrotService)
		BrainrotService.spawnConveyorBrainrot()
		BrainrotService.spawnConveyorBrainrot()
		broadcastBanner("🔥 BOSS DEFEATED! " .. player.DisplayName .. " landed the final slap! Rare brainrots on the conveyor!", Color3.fromRGB(255, 215, 0))
		local DataService = require(script.Parent.DataService)
		DataService.addRizz(player, 5000)
		DataService.addBraincells(player, 25)
		return true
	end
	return false
end

function EventService.startEventLoop()
	while true do
		task.wait(Config.EVENT_INTERVAL)
		local roll = math.random(1, 3)
		if roll == 1 then
			EventService.runFanumTax()
		elseif roll == 2 then
			EventService.runOhioStorm()
		else
			EventService.runBossRaid()
		end
	end
end

return EventService
