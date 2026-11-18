-- Steal a Sigma: stealing and slapping. Slap an enemy to ragdoll them, grab a
-- brainrot off their base, carry it home; if you reach your own base it is
-- yours. A bought lock blocks steals entirely.
local StealService = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local slapCooldowns = {} -- [player] = os.clock() of last slap
local carrying = {} -- [player] = record being carried

local function ragdollCharacter(character, seconds)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.Sit = true
	task.delay(seconds, function()
		if humanoid.Parent then
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- Slap: knock another player down for 2 seconds. 3s cooldown.
function StealService.slapPlayer(attacker, target)
	if attacker == target then
		return false, "You cannot slap yourself"
	end
	local last = slapCooldowns[attacker] or 0
	if os.clock() - last < Config.SLAP_COOLDOWN then
		return false, "Slap recharging..."
	end
	slapCooldowns[attacker] = os.clock()
	local character = target.Character
	if not character then
		return false, "Target has no character"
	end
	ragdollCharacter(character, Config.SLAP_RAGDOLL_TIME)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local away = (root.Position - (attacker.Character and attacker.Character:GetPivot().Position or root.Position)).Unit
		root.AssemblyLinearVelocity = away * 30 + Vector3.new(0, 18, 0)
	end
	local DataService = require(script.Parent.DataService)
	DataService.addBraincells(attacker, 2)
	return true, "SLAPPED " .. target.DisplayName .. "!"
end

-- Steal: lift a brainrot off a victim's base slot and carry it.
function StealService.stealBrainrot(thief, victim, slot)
	local BaseService = require(script.Parent.BaseService)
	local victimPlot = BaseService.getPlotOf(victim)
	if not victimPlot then
		return false, "Victim has no base"
	end
	if BaseService.isLocked(victimPlot) then
		return false, "That base is LOCKED! Buy a lock for your own base."
	end
	if carrying[thief] then
		return false, "You are already carrying one!"
	end
	local record = BaseService.removeBrainrot(victim, slot)
	if not record then
		return false, "Nothing in that slot"
	end
	record.state = "carried"
	record.owner = thief
	carrying[thief] = record
	local character = thief.Character
	if character and record.model then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			record.model:PivotTo(root.CFrame + Vector3.new(0, 4, 0))
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = record.model.PrimaryPart
			weld.Parent = record.model
			for _, part in ipairs(record.model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end
		end
	end
	-- If the thief does not reach home in time, the brainrot drops back.
	task.delay(Config.STEAL_CARRY_TIME, function()
		if carrying[thief] == record then
			StealService.dropCarried(thief)
		end
	end)
	return true, "STOLE " .. record.def.name .. "! RUN HOME!"
end

function StealService.dropCarried(thief)
	local record = carrying[thief]
	if not record then
		return
	end
	carrying[thief] = nil
	if record.model then
		for _, part in ipairs(record.model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
			if part:IsA("WeldConstraint") then
				part:Destroy()
			end
		end
		local character = thief.Character
		if character then
			record.model:PivotTo(character:GetPivot() + Vector3.new(0, 2, 0))
		end
	end
end

-- Called every second: a thief standing in their own base keeps the steal.
function StealService.checkCarriedHome()
	local BaseService = require(script.Parent.BaseService)
	for thief, record in pairs(carrying) do
		local character = thief.Character
		if not character then
			continue
		end
		if BaseService.isInsideOwnPlot(thief, character:GetPivot().Position) then
			carrying[thief] = nil
			if record.model then
				for _, part in ipairs(record.model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
					end
					if part:IsA("WeldConstraint") then
						part:Destroy()
					end
				end
			end
			record.state = "owned"
			if BaseService.placeBrainrot(thief, record) then
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				if remotes then
					local popup = remotes:FindFirstChild("IncomePopup")
					if popup then
						popup:FireClient(thief, "STEAL SECURED: " .. record.def.name, Color3.fromRGB(255, 100, 255))
					end
				end
			else
				-- Base full: the brainrot goes back to the conveyor as a free spawn.
				if record.model then
					record.model:Destroy()
				end
			end
		end
	end
end

function StealService.isCarrying(player)
	return carrying[player] ~= nil
end

Players.PlayerRemoving:Connect(function(player)
	if carrying[player] then
		StealService.dropCarried(player)
	end
end)

return StealService
