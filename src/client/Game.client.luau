-- Steal a Sigma: client. Meme HUD (Rizz / Aura / Braincells), event banners,
-- floating income popups, brainrot index + shop panel, rebirth button, and
-- the 3-second hook: a BUY prompt the moment a brainrot walks past.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local RarityData = require(ReplicatedStorage.Shared.RarityData)
local Config = require(ReplicatedStorage.Shared.Config)

local gui = Instance.new("ScreenGui")
gui.Name = "SigmaGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Top bar: Rizz, Aura, Braincells. Kept clear of the top-left Roblox menu.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 48)
topBar.Size = UDim2.fromOffset(560, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = gui
local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

local function makeStatLabel(name, text, x)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.new(0, x, 0, 0)
	label.Size = UDim2.fromOffset(180, 44)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.Parent = topBar
	return label
end

local rizzLabel = makeStatLabel("RizzLabel", "💰 Rizz: 100", 8)
local auraLabel = makeStatLabel("AuraLabel", "✨ Aura: 0", 190)
local cellsLabel = makeStatLabel("CellsLabel", "🧠 Braincells: 100", 372)

local function refreshLeaderstats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local function valueOf(name)
		local stat = leaderstats:FindFirstChild(name)
		return stat and stat.Value or 0
	end
	rizzLabel.Text = "💰 Rizz: " .. valueOf("Rizz")
	auraLabel.Text = "✨ Aura: " .. valueOf("Aura")
	cellsLabel.Text = "🧠 Braincells: " .. valueOf("Braincells")
end

player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		for _, stat in ipairs(child:GetChildren()) do
			stat:GetPropertyChangedSignal("Value"):Connect(refreshLeaderstats)
		end
		refreshLeaderstats()
	end
end)
task.delay(2, refreshLeaderstats)

-- Event banner, centre-top under the top bar.
local banner = Instance.new("TextLabel")
banner.Name = "EventBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 104)
banner.Size = UDim2.fromOffset(720, 48)
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
banner.BackgroundTransparency = 0.2
banner.Text = "🧠 STEAL A SIGMA — buy a brainrot off the conveyor!"
banner.TextColor3 = Color3.fromRGB(255, 215, 0)
banner.TextSize = 22
banner.Font = Enum.Font.GothamBold
banner.TextStrokeTransparency = 0.3
banner.Parent = gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = banner

local function showBanner(text, color)
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	banner.TextTransparency = 0
	local tween = TweenService:Create(banner, TweenInfo.new(0.3), { TextTransparency = 0 })
	tween:Play()
	task.delay(6, function()
		TweenService:Create(banner, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
	end)
end

-- Floating income popups, rising from the bottom-right.
local function showPopup(text, color)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.fromOffset(320, 36)
	popup.Position = UDim2.new(1, -340, 1, -120)
	popup.BackgroundTransparency = 1
	popup.Text = text
	popup.TextColor3 = color or Color3.fromRGB(255, 220, 80)
	popup.TextSize = 24
	popup.Font = Enum.Font.GothamBold
	popup.TextStrokeTransparency = 0.2
	popup.Parent = gui
	local rise = TweenService:Create(popup, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -340, 1, -220),
		TextTransparency = 1,
	})
	rise:Play()
	rise.Completed:Connect(function()
		popup:Destroy()
	end)
end

local eventBannerRemote = remotes:FindFirstChild("EventBanner")
if eventBannerRemote then
	eventBannerRemote.OnClientEvent:Connect(showBanner)
end
local popupRemote = remotes:FindFirstChild("IncomePopup")
if popupRemote then
	popupRemote.OnClientEvent:Connect(showPopup)
end

-- BUY prompt: appears when a conveyor brainrot is near the player.
local buyPrompt = Instance.new("TextButton")
buyPrompt.Name = "BuyPrompt"
buyPrompt.AnchorPoint = Vector2.new(0.5, 1)
buyPrompt.Position = UDim2.new(0.5, 0, 1, -140)
buyPrompt.Size = UDim2.fromOffset(420, 56)
buyPrompt.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
buyPrompt.Text = "BUY"
buyPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
buyPrompt.TextSize = 24
buyPrompt.Font = Enum.Font.GothamBold
buyPrompt.Visible = false
buyPrompt.Parent = gui
local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 14)
buyCorner.Parent = buyPrompt

local nearestBrainrot = nil
buyPrompt.MouseButton1Click:Connect(function()
	local buy = remotes:FindFirstChild("BuyBrainrot")
	if buy and nearestBrainrot then
		buy:FireServer(nearestBrainrot)
	end
end)

local function findNearestConveyorBrainrot()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best = nil
	local bestDist = 14
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("BrainrotLabel") then
			local dist = (model:GetPivot().Position - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = model
			end
		end
	end
	return best
end

-- Slap: click another player to slap them; click the boss to damage it.
local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if not target then
		return
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChild("BossHP") then
		local slapBoss = remotes:FindFirstChild("SlapBoss")
		if slapBoss then
			slapBoss:FireServer()
		end
		return
	end
	local targetPlayer = Players:GetPlayerFromCharacter(model)
	if targetPlayer and targetPlayer ~= player then
		local slap = remotes:FindFirstChild("SlapPlayer")
		if slap then
			slap:FireServer(targetPlayer)
		end
	end
end)

-- Steal key: E near an enemy base brainrot steals it; E near the conveyor buys.
local function onStealKey(_, state)
	if state ~= Enum.UserInputState.Begin then
		return
	end
	if nearestBrainrot then
		local buy = remotes:FindFirstChild("BuyBrainrot")
		if buy then
			buy:FireServer(nearestBrainrot)
		end
	end
end
ContextActionService:BindAction("SigmaStealBuy", onStealKey, false, Enum.KeyCode.E)

-- Index + shop panel (toggle with I): every brainrot, rarity, cost, $/sec.
local indexOpen = false
local indexPanel = Instance.new("ScrollingFrame")
indexPanel.Name = "BrainrotIndex"
indexPanel.AnchorPoint = Vector2.new(1, 0.5)
indexPanel.Position = UDim2.new(1, -16, 0.5, 0)
indexPanel.Size = UDim2.fromOffset(340, 420)
indexPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
indexPanel.BackgroundTransparency = 0.1
indexPanel.Visible = false
indexPanel.Parent = gui
local indexTitle = Instance.new("TextLabel")
indexTitle.Size = UDim2.new(1, 0, 0, 36)
indexTitle.BackgroundTransparency = 1
indexTitle.Text = "📖 BRAINROT INDEX — press I"
indexTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
indexTitle.TextSize = 18
indexTitle.Font = Enum.Font.GothamBold
indexTitle.Parent = indexPanel
local y = 40
for _, def in ipairs(BrainrotData.CAST) do
	local row = Instance.new("TextLabel")
	row.Position = UDim2.new(0, 8, 0, y)
	row.Size = UDim2.new(1, -16, 0, 30)
	row.BackgroundTransparency = 1
	row.Text = def.name .. " [" .. def.rarity .. "]  $" .. def.cost .. "  →  $" .. def.income .. "/s"
	row.TextColor3 = RarityData.getColor(def.rarity)
	row.TextSize = 15
	row.Font = Enum.Font.GothamBold
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = indexPanel
	y += 32
end
indexPanel.CanvasSize = UDim2.new(0, 0, 0, y + 8)

local function toggleIndex(_, state)
	if state ~= Enum.UserInputState.Begin then
		return
	end
	indexOpen = not indexOpen
	indexPanel.Visible = indexOpen
end
ContextActionService:BindAction("SigmaIndex", toggleIndex, false, Enum.KeyCode.I)

-- Rebirth + Lock buttons, bottom-left.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Position = UDim2.new(0, 16, 1, -120)
rebirthButton.Size = UDim2.fromOffset(180, 48)
rebirthButton.BackgroundColor3 = Color3.fromRGB(160, 40, 220)
rebirthButton.Text = "🔄 REBIRTH"
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 20
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.Parent = gui
rebirthButton.MouseButton1Click:Connect(function()
	local rebirth = remotes:FindFirstChild("Rebirth")
	if rebirth then
		rebirth:FireServer()
	end
end)

local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Position = UDim2.new(0, 16, 1, -64)
lockButton.Size = UDim2.fromOffset(180, 48)
lockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
lockButton.Text = "🔒 LOCK BASE ($500)"
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 18
lockButton.Font = Enum.Font.GothamBold
lockButton.Parent = gui
lockButton.MouseButton1Click:Connect(function()
	local lock = remotes:FindFirstChild("BuyLock")
	if lock then
		lock:FireServer()
	end
end)

-- Hint bar: the controls, bottom-centre.
local hint = Instance.new("TextLabel")
hint.Name = "HintBar"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -16)
hint.Size = UDim2.fromOffset(560, 28)
hint.BackgroundTransparency = 1
hint.Text = "E = buy / steal   •   Click a player to SLAP   •   I = brainrot index   •   Hide in base during Fanum Tax!"
hint.TextColor3 = Color3.fromRGB(220, 220, 220)
hint.TextSize = 15
hint.Font = Enum.Font.GothamBold
hint.TextStrokeTransparency = 0.3
hint.Parent = gui

-- Per-frame: refresh the BUY prompt from the nearest conveyor brainrot.
game:GetService("RunService").RenderStepped:Connect(function()
	nearestBrainrot = findNearestConveyorBrainrot()
	if nearestBrainrot then
		local label = nearestBrainrot:FindFirstChild("BrainrotLabel")
		local nameLabel = label and label:FindFirstChild("NameLabel")
		local incomeLabel = label and label:FindFirstChild("IncomeLabel")
		buyPrompt.Text = "🛒 BUY " .. (nameLabel and nameLabel.Text or "BRAINROT") .. " — " .. (incomeLabel and incomeLabel.Text or "")
		buyPrompt.Visible = true
	else
		buyPrompt.Visible = false
	end
end)

-- Built-in sounds only: a pop on every popup, a ping on every banner.
local popSound = Instance.new("Sound")
popSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
popSound.Volume = 0.5
popSound.Parent = gui
if popupRemote then
	popupRemote.OnClientEvent:Connect(function()
		popSound:Play()
	end)
end

print("Steal a Sigma client ready.")
