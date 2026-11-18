-- Steal a Sigma: the conveyor. Brainrots spawn, walk the belt with a floating
-- name / rarity / $/sec label, and can be bought with Rizz. Bought brainrots
-- move to the buyer's base and tick income every second.
local BrainrotService = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local RarityData = require(ReplicatedStorage.Shared.RarityData)

local conveyorBrainrots = {} -- [model] = record { def, mutation, income, owner }
local nextId = 1

local Remotes = nil
local function getRemotes()
	if not Remotes then
		Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	end
	return Remotes
end

-- Build a brainrot's 3D body from parts only: body, head, eyes, accent hat.
function BrainrotService.buildModel(def, mutation)
	local model = Instance.new("Model")
	model.Name = def.name
	local size = def.size
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(size, size * 1.1, size * 0.8)
	body.Color = def.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(size * 0.9, size * 0.9, size * 0.9)
	head.Color = def.color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, size * 1.05, 0)
	head.Parent = model
	-- Eyes: two white balls with black pupils, the meme stare.
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(size * 0.22, size * 0.28, size * 0.15)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = Vector3.new(side * size * 0.22, size * 1.1, size * 0.42)
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(size * 0.1, size * 0.14, size * 0.08)
		pupil.Color = Color3.fromRGB(10, 10, 10)
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Position = Vector3.new(side * size * 0.22, size * 1.08, size * 0.5)
		pupil.Parent = model
	end
	-- Accent crown / hat so every cast member reads at a glance.
	local hat = Instance.new("Part")
	hat.Name = "Hat"
	hat.Shape = Enum.PartType.Cylinder
	hat.Size = Vector3.new(size * 0.3, size * 1.0, size * 1.0)
	hat.Color = def.accent
	hat.Material = Enum.Material.Neon
	hat.Anchored = true
	hat.CanCollide = false
	hat.CFrame = CFrame.new(0, size * 1.65, 0) * CFrame.Angles(0, 0, math.rad(90))
	hat.Parent = model
	if mutation.name ~= "Normal" then
		local glow = Instance.new("PointLight")
		glow.Color = RarityData.getMutationColor(mutation.name)
		glow.Range = 8
		glow.Brightness = 1.5
		glow.Parent = body
	end
	model.PrimaryPart = body
	return model
end

-- Floating label above a brainrot: name, rarity colour, $/sec.
function BrainrotService.attachLabel(model, def, mutation, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(180, 64)
	gui.StudsOffset = Vector3.new(0, def.size * 1.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.55)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = RarityData.getDisplayLabel(def.name, mutation.name, def.rarity)
	nameLabel.TextColor3 = RarityData.getColor(def.rarity)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = gui
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Position = UDim2.fromScale(0, 0.55)
	incomeLabel.Size = UDim2.fromScale(1, 0.45)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$" .. income .. "/s  •  $" .. def.cost
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.Parent = gui
	return gui
end

function BrainrotService.spawnConveyorBrainrot()
	local def = BrainrotData.pickRandomSpawn()
	local mutation = BrainrotData.rollMutation()
	local model = BrainrotService.buildModel(def, mutation)
	local startX = -Config.CONVEYOR_LENGTH / 2
	model:PivotTo(CFrame.new(startX, 2.5, 0))
	model.Parent = workspace
	local record = {
		id = nextId,
		def = def,
		mutation = mutation,
		income = RarityData.getIncomePerSecond(def.income, mutation.multiplier, 0),
		model = model,
		state = "conveyor",
	}
	nextId += 1
	BrainrotService.attachLabel(model, def, mutation, record.income)
	conveyorBrainrots[model] = record
	-- Walk the belt with Heartbeat: the whole model pivots forward each step,
	-- then despawns at the end if nobody buys it.
	local conn
	local lastTime = os.clock()
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		if not model.Parent or conveyorBrainrots[model] == nil then
			conn:Disconnect()
			return
		end
		local now = os.clock()
		local dt = math.min(now - lastTime, 0.1)
		lastTime = now
		local pos = model:GetPivot().Position
		if pos.X >= Config.CONVEYOR_LENGTH / 2 then
			conn:Disconnect()
			conveyorBrainrots[model] = nil
			model:Destroy()
			return
		end
		model:PivotTo(CFrame.new(pos + Vector3.new(Config.CONVEYOR_SPEED * dt, 0, 0)) * CFrame.Angles(0, math.rad(90), 0))
	end)
	return record
end

-- Buy the brainrot the player is looking at on the conveyor.
function BrainrotService.buyBrainrot(player, model)
	local record = conveyorBrainrots[model]
	if not record then
		return false, "That brainrot is gone"
	end
	local DataService = require(script.Parent.DataService)
	local BaseService = require(script.Parent.BaseService)
	if not DataService.spendRizz(player, record.def.cost) then
		return false, "Need $" .. record.def.cost .. " Rizz for " .. record.def.name
	end
	if not BaseService.nextFreeSlot(player) then
		DataService.addRizz(player, record.def.cost)
		return false, "Base full! Sell one or rebirth."
	end
	conveyorBrainrots[model] = nil
	record.state = "owned"
	record.owner = player
	-- Recompute income with the buyer's rebirth level.
	local profile = DataService.getProfile(player)
	local rebirths = profile and profile.Rebirths or 0
	record.income = RarityData.getIncomePerSecond(record.def.income, record.mutation.multiplier, rebirths)
	if not BaseService.placeBrainrot(player, record) then
		DataService.addRizz(player, record.def.cost)
		return false, "Could not place it on your base"
	end
	local remotes = getRemotes()
	if remotes then
		local popup = remotes:FindFirstChild("IncomePopup")
		if popup then
			popup:FireClient(player, "BOUGHT " .. record.def.name .. "!", Color3.fromRGB(120, 255, 120))
		end
	end
	DataService.addBraincells(player, 5)
	return true, "Bought " .. RarityData.getDisplayLabel(record.def.name, record.mutation.name, record.def.rarity)
end

function BrainrotService.sellBrainrot(player, slot)
	local DataService = require(script.Parent.DataService)
	local BaseService = require(script.Parent.BaseService)
	local record = BaseService.removeBrainrot(player, slot)
	if not record then
		return false, "Nothing in that slot"
	end
	local price = RarityData.getSellPrice(record.def.cost, record.mutation.multiplier)
	DataService.addRizz(player, price)
	if record.model then
		record.model:Destroy()
	end
	return true, "Sold for $" .. price
end

-- Every second, every owned brainrot pays its owner.
function BrainrotService.startIncomeLoop()
	local DataService = require(script.Parent.DataService)
	local BaseService = require(script.Parent.BaseService)
	while true do
		task.wait(Config.INCOME_TICK)
		for _, player in ipairs(Players:GetPlayers()) do
			local total = 0
			for _, record in ipairs(BaseService.getBrainrots(player)) do
				total += record.income
			end
			if total > 0 then
				DataService.addRizz(player, total)
				local remotes = getRemotes()
				if remotes then
					local popup = remotes:FindFirstChild("IncomePopup")
					if popup then
						popup:FireClient(player, "+$" .. total, Color3.fromRGB(255, 220, 80))
					end
				end
			end
		end
	end
end

function BrainrotService.startConveyorLoop()
	while true do
		task.wait(Config.CONVEYOR_SPAWN_INTERVAL)
		BrainrotService.spawnConveyorBrainrot()
	end
end

function BrainrotService.getConveyorBrainrots()
	return conveyorBrainrots
end

return BrainrotService
