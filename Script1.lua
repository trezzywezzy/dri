pcall(function()
    queue_on_teleport([[
        task.wait(5)
        local src = readfile("autoexec/Script1.lua") or readfile("autoexec\\Script1.lua") or readfile("Script1.lua")
        if src then
            loadstring(src)()
        else
            print("readfile failed - could not find Script1.lua")
        end
    ]])
end)
-- Auto-rejoin on disconnect (retries every 10 seconds)
task.spawn(function()
    game:GetService("CoreGui")
        :WaitForChild("RobloxPromptGui")
        :WaitForChild("promptOverlay")
        :WaitForChild("ErrorPrompt")

    task.wait(2)
    while true do
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
        print("Reconnect attempt, retrying in 10s...")
        task.wait(10)
    end
end)
local iyLoaded = false
local hooked = false
local function runScript()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(3)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rollRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("Roll")

local VariantsRolled = player
	:WaitForChild("Data")
	:WaitForChild("Stats")
	:WaitForChild("Variants Rolled")

------------------------------------------------
-- STARTUP LOADS (RUN ON EXECUTION)
------------------------------------------------
pcall(function()
	player:WaitForChild("PlayerScripts"):WaitForChild("Rolling").Disabled = true
	print("Rolling script disabled")
end)
if not iyLoaded then
        iyLoaded = true
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
local crateAnimRemote = nil
local crateAnimUI = nil
pcall(function()
	crateAnimRemote = ReplicatedStorage
		:WaitForChild("Remotes", 5)
		:WaitForChild("CrateAnimation", 5)
end)
--loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()

------------------------------------------------
-- STATE (ALL ON BY DEFAULT)
------------------------------------------------
local State = {
	AutoRoll_Glyphs = false,
	ResetLoop = false,
	HitboxExpand = true,
	RaritiesConsole = true,
	RunesConsole = true,
	ResetsConsole = true,
	CurrentRarityTracker = true,
	QuestRerollTimer = true,
	GlyphsConsole = true,
	AutoQuestReroll = true,
	AutoRoll_Dice = true,
	VariantTest = false,
	AutoInsaneReroll = false,
	AutoCrates = false, -- OFF by default
	WeatherEquip = true,
	AntiAFK = true,
	UseItems = false,
	AutoClick = false,
	SpeedBoost = false
}
local PredictionHours = 2
local Threads = {}
local selectedCrates = {
    ["Basic Crate"] = false,
    ["Golden Crate"] = false,
    ["Rainbow Crate"] = false,
    ["Galaxy Crate"] = false,
}
local selectedAmount = 3
local crateTypes = {
	"Basic Crate",
	"Golden Crate",
	"Rainbow Crate",
	"Galaxy Crate"
}

local crateIndex = 3
local selectedRune = "Hype"
local RollDelay = 0.3
local rollFireCount = 0
local UI = nil

local weatherLoadouts = {
	Syzygy    = { skin = "Hypnosis", glyph1 = "Reawakening IV", glyph2 = "Hyperdrive IV" },
	Wasteland = { skin = "Hypnosis", glyph1 = "Compaction IV",  glyph2 = "Catalysis IV" },
	Glitch    = { skin = "Hypnosis", glyph1 = "Compaction IV",  glyph2 = "Catalysis IV" },
	Evil      = { skin = "Hypnosis", glyph1 = "Compaction IV",  glyph2 = "Catalysis IV" },
	Sanguis   = { skin = "Hypnosis", glyph1 = "Compaction IV",  glyph2 = "Catalysis IV" },
}
local defaultLoadout = { skin = "Exotic", glyph1 = "Expansion IV", glyph2 = "Bounty IV" }

------------------------------------------------
-- APPLY HITBOX IMMEDIATELY
------------------------------------------------
local function setHitboxes(enabled)
	local expandSize = Vector3.new(2048, 2048, 2048)
	local normalSize = Vector3.new(6, 12, 6)
	local size = enabled and expandSize or normalSize

	pcall(function()
		workspace.Boards.Energy["Energy Pad"].Hitbox.Size = size
	end)
	pcall(function()
		workspace.Boards.Rarities["Rarity Pad"].Hitbox.Size = size
	end)
	local success, err = pcall(function()
		workspace.Runes[selectedRune].Hitbox.Size = size
	end)
	if not success then
		print("Rune hitbox error:", err)
	end
end

------------------------------------------------
-- UI
------------------------------------------------
local function createUI()

	local gui = Instance.new("ScreenGui")
	gui.Name = "ControlPanel"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 280, 0, 34)
	frame.Position = UDim2.new(0, 20, 0.3, 0)
	frame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Parent = gui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent = frame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(55, 55, 80)
	frameStroke.Thickness = 1
	frameStroke.Parent = frame

	------------------------------------------------
	-- TITLE BAR
	------------------------------------------------
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 34)
	titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	local titleBarCorner = Instance.new("UICorner")
	titleBarCorner.CornerRadius = UDim.new(0, 10)
	titleBarCorner.Parent = titleBar

	local titleBarFix = Instance.new("Frame")
	titleBarFix.Size = UDim2.new(1, 0, 0.5, 0)
	titleBarFix.Position = UDim2.new(0, 0, 0.5, 0)
	titleBarFix.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	titleBarFix.BorderSizePixel = 0
	titleBarFix.Parent = titleBar

	-- TAB BUTTONS IN TITLE BAR
	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, -34, 0, 24)
	tabContainer.Position = UDim2.new(0, 4, 0, 5)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = titleBar

	local tabBarLayout = Instance.new("UIListLayout")
	tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
	tabBarLayout.Padding = UDim.new(0, 4)
	tabBarLayout.Parent = tabContainer

	local tabBtns = {}
	local tabNames = { "Main", "Crates", "Stats" }
	for i, name in ipairs(tabNames) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1 / #tabNames, -3, 1, 0)
		btn.BackgroundColor3 = i == 1 and Color3.fromRGB(55, 55, 80) or Color3.fromRGB(28, 28, 42)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.BorderSizePixel = 0
		btn.Text = name
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.Parent = tabContainer

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		tabBtns[i] = btn
	end

	local minimized = false

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 24, 0, 24)
	toggleBtn.Position = UDim2.new(1, -30, 0, 5)
	toggleBtn.Text = "−"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 14
	toggleBtn.Parent = titleBar

	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 6)
	tc.Parent = toggleBtn

	------------------------------------------------
	-- CONTENT FRAME
	------------------------------------------------
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Size = UDim2.new(1, -12, 1, -42)
	contentFrame.Position = UDim2.new(0, 6, 0, 38)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 4
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentFrame.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = contentFrame

	local bottomPad = Instance.new("UIPadding")
	bottomPad.PaddingBottom = UDim.new(0, 8)
	bottomPad.Parent = contentFrame

	local function updateSize()
		task.wait()
		frame.Size = UDim2.new(0, 280, 0, layout.AbsoluteContentSize.Y + 50)
	end

	------------------------------------------------
	-- DRAGGABLE
	------------------------------------------------
	local UIS = game:GetService("UserInputService")
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)

	local pageElements = { {}, {}, {} }
	local buildingPage = 1
	local function setPage(n) buildingPage = n end

	------------------------------------------------
	-- HELPERS
	------------------------------------------------
	local function makeButton(text, color)
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 52)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 11

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		return btn
	end

	-- places one item full width into contentFrame
	local function addFull(item)
		item.Size = UDim2.new(1, 0, 0, 28)
		item.Parent = contentFrame
		if buildingPage > 0 then table.insert(pageElements[buildingPage], item) end
		return item
	end

	-- places two items side by side in a row
	local function addRow(left, right)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundTransparency = 1
		row.Parent = contentFrame
		if buildingPage > 0 then table.insert(pageElements[buildingPage], row) end

		left.Size = UDim2.new(0.5, -2, 1, 0)
		left.Position = UDim2.new(0, 0, 0, 0)
		left.Parent = row

		right.Size = UDim2.new(0.5, -2, 1, 0)
		right.Position = UDim2.new(0.5, 2, 0, 0)
		right.Parent = row
	end

	local function makeSection(text)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 16)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = Color3.fromRGB(100, 100, 140)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = contentFrame
		if buildingPage > 0 then table.insert(pageElements[buildingPage], lbl) end
	end

	local function makeTextBox(placeholder, default)
		local box = Instance.new("TextBox")
		box.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
		box.TextColor3 = Color3.new(1, 1, 1)
		box.PlaceholderColor3 = Color3.fromRGB(120, 120, 150)
		box.BorderSizePixel = 0
		box.Text = default or ""
		box.PlaceholderText = placeholder
		box.ClearTextOnFocus = false
		box.Font = Enum.Font.Gotham
		box.TextSize = 11

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = box

		return box
	end

	local function makeLabel(text)
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
		lbl.TextColor3 = Color3.fromRGB(160, 160, 210)
		lbl.BorderSizePixel = 0
		lbl.Text = text
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 11

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = lbl

		return lbl
	end

	------------------------------------------------
	-- BUILD LAYOUT
	------------------------------------------------

	local function switchPage(n)
		for i, elements in pairs(pageElements) do
			local visible = (i == n)
			for _, elem in ipairs(elements) do
				elem.Visible = visible
			end
		end
		for i, btn in ipairs(tabBtns) do
			btn.BackgroundColor3 = i == n and Color3.fromRGB(55, 55, 80) or Color3.fromRGB(28, 28, 42)
		end
	end

	for i, btn in ipairs(tabBtns) do
		btn.MouseButton1Click:Connect(function()
			switchPage(i)
		end)
	end

	-- PAGE 1: MAIN
	setPage(1)
	makeSection("  ROLLING")
	local autoBtn     = makeButton("Glyphs: OFF")
	local rollDiceBtn = makeButton("Roll Dice: ON")
	addRow(autoBtn, rollDiceBtn)

	local rollingScriptBtn = makeButton("Rolling Script: OFF")
	addFull(rollingScriptBtn)

	makeSection("  AUTOMATION")
	local resetBtn       = makeButton("ResetLoop: OFF")
	local insaneBtn      = makeButton("Insane: OFF")
	addRow(resetBtn, insaneBtn)

	local questRerollBtn = makeButton("Quest Reroll: OFF")
	local hitboxBtn      = makeButton("Hitbox: ON")
	addRow(questRerollBtn, hitboxBtn)

	local antiAFKBtn = makeButton("Anti-AFK: ON")
	local speedBoostBtn = makeButton("Speed: OFF")
	addRow(antiAFKBtn, speedBoostBtn)

	local useItemsBtn = makeButton("Use Items: OFF")
	local autoClickBtn = makeButton("Auto Clicks: OFF")
	addRow(useItemsBtn, autoClickBtn)

	local miniChestBtn = makeButton("Use Mini Chests")
	addFull(miniChestBtn)

		makeSection("  RUNE")
	local runeBox = makeTextBox("Rune name...", selectedRune)
	local nextRuneBtn = makeButton("Next Rune")
	addRow(runeBox, nextRuneBtn)

	-- PAGE 3: STATS
	setPage(3)
	makeSection("  CONSOLE")
	local rarityBtn        = makeButton("Rarities: ON")
	local resetsConsoleBtn = makeButton("Resets: ON")
	addRow(rarityBtn, resetsConsoleBtn)

	local runesConsoleBtn = makeButton("Runes: ON")
	addFull(runesConsoleBtn)

	-- PAGE 2: CRATES
	setPage(2)
	makeSection("  CRATES")
	local crateBtn       = makeButton("Auto Crates: OFF")
	local crateAmountBtn = makeButton("Amount: 3")
	addRow(crateBtn, crateAmountBtn)

	local basicCrateBtn  = makeButton("Basic: OFF")
	local goldenCrateBtn = makeButton("Golden: OFF")
	addRow(basicCrateBtn, goldenCrateBtn)

	local rainbowCrateBtn = makeButton("Rainbow: OFF")
	local galaxyCrateBtn  = makeButton("Galaxy: OFF")
	addRow(rainbowCrateBtn, galaxyCrateBtn)

	local removeAnimBtn  = makeButton("Remove Anim")
	local restoreAnimBtn = makeButton("Restore Anim")
	addRow(removeAnimBtn, restoreAnimBtn)

	makeSection("  MANUAL OPEN")
	local crateSelectBtn = makeButton("Basic Crate")
	local crateOpenBox = makeTextBox("Amount...", "1")
	addRow(crateSelectBtn, crateOpenBox)

	local crateOpenBtn = makeButton("Open Crates")
	addFull(crateOpenBtn)

	-- BACK TO PAGE 3: STATS
	setPage(3)
	makeSection("  WEATHER")
	local weatherEquipBtn = makeButton("Weather Equip: ON")
	local weatherLabel = makeLabel("Weather: ---")
	addRow(weatherEquipBtn, weatherLabel)

	local skinLabel = makeLabel("Skin: ---")
	local glyphLabel = makeLabel("G1: --- | G2: ---")
	addRow(skinLabel, glyphLabel)

	makeSection("  SETTINGS")
	local delayBox = makeTextBox("Roll Delay", tostring(RollDelay))
	local hoursBox = makeTextBox("Predict Hrs", tostring(PredictionHours) .. "h")
	addRow(delayBox, hoursBox)

	local rpsLabel = makeLabel("Roll RPS: 0")
	addFull(rpsLabel)

	makeSection("  TESTING")
	local variantTestBtn = makeButton("Start 10m Variant Test")
	addFull(variantTestBtn)

	-- ALWAYS VISIBLE
	setPage(0)
	makeSection("")
	local resetAllBtn = makeButton("RESET ALL", Color3.fromRGB(110, 25, 25))
	resetAllBtn.Size = UDim2.new(1, 0, 0, 28)
	resetAllBtn.Parent = contentFrame

	switchPage(1)
	updateSize()
		------------------------------------------------
	-- RESIZABLE
	------------------------------------------------
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Size = UDim2.new(0, 16, 0, 16)
	resizeHandle.Position = UDim2.new(1, -16, 1, -16)
	resizeHandle.AnchorPoint = Vector2.new(0, 0)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Text = "◢"
	resizeHandle.TextColor3 = Color3.fromRGB(80, 80, 120)
	resizeHandle.Font = Enum.Font.GothamBold
	resizeHandle.TextSize = 12
	resizeHandle.ZIndex = 10
	resizeHandle.Parent = frame

	local minWidth = 200
	local maxWidth = 500
	local minHeight = 100
	local maxHeight = 800
	local resizing = false
	local resizeStart, startSize

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			resizeStart = input.Position
			startSize = frame.Size

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - resizeStart
			local newWidth = math.clamp(
				startSize.X.Offset + delta.X,
				minWidth,
				maxWidth
			)
			local newHeight = math.clamp(
				startSize.Y.Offset + delta.Y,
				minHeight,
				maxHeight
			)

			frame.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)
	------------------------------------------------
	-- MINIMIZE
	------------------------------------------------
	toggleBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			contentFrame.Visible = false
			frame.Size = UDim2.new(0, 280, 0, 34)
			toggleBtn.Text = "+"
		else
			contentFrame.Visible = true
			updateSize()
			toggleBtn.Text = "−"
		end
	end)

	UI = gui

	return autoBtn, resetBtn, hitboxBtn, runeBox, rarityBtn, resetsConsoleBtn, runesConsoleBtn, questRerollBtn, rollDiceBtn, delayBox, variantTestBtn, resetAllBtn, insaneBtn, crateBtn, basicCrateBtn, goldenCrateBtn, rainbowCrateBtn, galaxyCrateBtn, crateAmountBtn, removeAnimBtn, restoreAnimBtn, rpsLabel, nextRuneBtn, weatherEquipBtn, weatherLabel, skinLabel, glyphLabel, antiAFKBtn, rollingScriptBtn, useItemsBtn, autoClickBtn, speedBoostBtn, crateSelectBtn, crateOpenBox, crateOpenBtn, hoursBox, miniChestBtn
end

------------------------------------------------
-- RESET LOOP
------------------------------------------------
local function startResetLoop()
	if Threads.Reset then return end

	Threads.Reset = task.spawn(function()
		while true do
			if not State.ResetLoop then break end

			pcall(function()
				ReplicatedStorage.Remotes.Reset:FireServer("Time Machine")
			end)
			task.wait(0)
		end

		Threads.Reset = nil
	end)
end

local function startAutoRoll_Dice()
	if Threads.AutoRoll_Dice then return end

	Threads.AutoRoll_Dice = task.spawn(function()
		while State.AutoRoll_Dice do
			pcall(function()
				rollRemote:FireServer()
			end)

			task.wait(RollDelay)
		end

		Threads.AutoRoll_Dice = nil
	end)
end


------------------------------------------------
-- AUTO ROLL GLYPHS
------------------------------------------------
local function startAutoRoll_Glyphs()
	if Threads.AutoRoll_Glyphs then return end

	Threads.AutoRoll_Glyphs = task.spawn(function()

		local lastGlyph = nil
		local count = 0

		while true do
			if not State.AutoRoll_Glyphs then break end

			local result

			pcall(function()
				result = ReplicatedStorage.Remotes.RollGlyph:InvokeServer()
			end)

			task.wait(0)
		end
		Threads.AutoRoll_Glyphs = nil
	end)
end

------------------------------------------------
-- RARITIES ROLLED CONSOLE
------------------------------------------------
local function formatNumber(n)
	local suffixes = {
		"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
	}

	local i = 1

	while n >= 1000 and i < #suffixes do
		n = n / 1000
		i += 1
	end

	-- no decimals for small numbers
	if i == 1 then
		return tostring(math.floor(n))
	end

	return string.format("%.2f%s", n, suffixes[i])
end
local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)

	return string.format("%02d:%02d", mins, secs)
end
local function formatCommas(n)
	local formatted = tostring(math.floor(n))

	while true do
		local k
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")

		if k == 0 then
			break
		end
	end

	return formatted
end
local function startVariantTest(variantTestBtn)
	if Threads.VariantTest then return end

	State.VariantTest = true
	variantTestBtn.Text = "Variant Test Running..."

	Threads.VariantTest = task.spawn(function()
		print("Variant test thread started")

		local ok, err = pcall(function()
			local testDuration = 10 * 60
			local updateEvery = 30

			local startVariants = VariantsRolled.Value
			local startTime = os.clock()

			print("===== 10 MINUTE VARIANT TEST STARTED =====")
			print("Starting Variants:", formatCommas(startVariants))
			print("------------------------------------------")

			while State.VariantTest do
				local elapsed = os.clock() - startTime
				local remaining = math.max(testDuration - elapsed, 0)

				local currentVariants = VariantsRolled.Value
				local gainedVariants = currentVariants - startVariants

				local minutesElapsed = math.max(elapsed / 60, 0.0001)
				local variantsPerMin = gainedVariants / minutesElapsed

				print("Time Left:", formatTime(remaining))
				print(
					"Variants Gained:",
					formatCommas(gainedVariants),
					"|",
					formatCommas(math.floor(variantsPerMin)),
					"/min"
				)
				print("------------------------------------------")

				if elapsed >= testDuration then
					break
				end

				for i = 1, updateEvery do
					if not State.VariantTest then
						break
					end
					task.wait(1)
				end
			end

			local finalVariants = VariantsRolled.Value
			local totalVariants = finalVariants - startVariants

			print("===== 10 MINUTE VARIANT TEST FINISHED =====")
			print("Total Variants Gained:", formatCommas(totalVariants))
			print("Average Variants/min:", formatCommas(totalVariants / 10))
			print("===========================================")
		end)

		if not ok then
			print("Variant test ERROR:", err)
		end

		State.VariantTest = false
		Threads.VariantTest = nil
		variantTestBtn.Text = "Start 10m Variant Test"
	end)
end
local function startRaritiesConsole()
	if Threads.RaritiesConsole then return end

	local raritiesRolled = player
		:WaitForChild("Data")
		:WaitForChild("Stats")
		:WaitForChild("Rarities Rolled")

	Threads.RaritiesConsole = task.spawn(function()

		local interval = 60
		local previousValue = raritiesRolled.Value

		print("Rarities Started:", formatNumber(previousValue))

		while true do
			if not State.RaritiesConsole then break end

			task.wait(interval)

			local currentValue = raritiesRolled.Value
			local difference = currentValue - previousValue

			local rate = difference
			local predictedTotal = currentValue + (rate * PredictionHours * 60)

			print(
				"Rarities:",
				formatNumber(currentValue),
				"|",
				formatNumber(rate) .. " /min",
				"|",
				tostring(PredictionHours) .. "h:",
				formatNumber(predictedTotal),
				"\n"
			)

			previousValue = currentValue
		end
		
		Threads.RaritiesConsole = nil
	end)
end
local function startGlyphsConsole()
	if Threads.GlyphsConsole then return end

	local glyphsRolled = player
		:WaitForChild("Data")
		:WaitForChild("Stats")
		:WaitForChild("Glyphs Rolled")

	Threads.GlyphsConsole = task.spawn(function()
		local interval = 60
		local previousValue = glyphsRolled.Value

		print("Glyphs Started:", formatCommas(previousValue))

		while true do
			if not State.GlyphsConsole then break end

			task.wait(interval)

			local currentValue = glyphsRolled.Value
			local difference = currentValue - previousValue
			local rate = difference
			local predictedTotal = currentValue + (rate * PredictionHours * 60)

			print(
				"Glyphs:",
				formatNumber(currentValue),
				"|",
				formatNumber(rate) .. " /min",
				"|",
				tostring(PredictionHours) .. "h:",
				formatNumber(predictedTotal),
				"\n\n------------------------------\n"
			)
			previousValue = currentValue
		end

		Threads.GlyphsConsole = nil
	end)
end
local function startRunesConsole()
	if Threads.RunesConsole then return end

	local runesRolled = player
		:WaitForChild("Data")
		:WaitForChild("Stats")
		:WaitForChild("Runes Opened")

	Threads.RunesConsole = task.spawn(function()

		local interval = 60
		local previousValue = runesRolled.Value

		print("Runes Started:", formatNumber(previousValue))

		while true do
			if not State.RunesConsole then break end

			task.wait(interval)

			local currentValue = runesRolled.Value
			local difference = currentValue - previousValue

			local rate = difference
			local predictedTotal = currentValue + (rate * PredictionHours * 60)

			print(
				"Runes:",
				formatNumber(currentValue),
				"|",
				formatNumber(rate) .. " /min",
				"|",
				tostring(PredictionHours) .. "h:",
				formatNumber(predictedTotal),
				"\n"
			)

			previousValue = currentValue
		end
		
		Threads.RunesConsole = nil
	end)
end
local function startResetsConsole()
	if Threads.ResetsConsole then return end

	local resetsPerformed = player
		:WaitForChild("Data")
		:WaitForChild("Stats")
		:WaitForChild("Resets Performed")

	Threads.ResetsConsole = task.spawn(function()
		local interval = 60
		local previousValue = resetsPerformed.Value

		print("Resets Started:", formatCommas(previousValue))

		while true do
			if not State.ResetsConsole then break end

			task.wait(interval)

			local currentValue = resetsPerformed.Value
			local difference = currentValue - previousValue
			local rate = difference
			local predictedTotal = currentValue + (rate * PredictionHours * 60)

			print(
				"Resets:",
				formatCommas(currentValue),
				"|",
				formatNumber(rate) .. " /min",
				"|",
				tostring(PredictionHours) .. "h:",
				formatNumber(predictedTotal),
				"\n"
			)
			previousValue = currentValue
		end

		Threads.ResetsConsole = nil
	end)
end
local function startCurrentRarityTracker()
	if Threads.CurrentRarity then return end

	local currentRarity = player
		:WaitForChild("Data")
		:WaitForChild("Stats")
		:WaitForChild("Current Rarity")

	local interval = 120 -- 2 minutes

	Threads.CurrentRarity = true

	local previousValue = currentRarity.Value

	print("Starting Rarity:", previousValue)

	------------------------------------------------
	-- CHANGE TRACKER (instant updates)
	------------------------------------------------
	currentRarity:GetPropertyChangedSignal("Value"):Connect(function()

		if not State.CurrentRarityTracker then
			Threads.CurrentRarity = nil
			return
		end

		local newValue = currentRarity.Value

		print(
			"Rarity Changed:",
			previousValue,
			"→",
			newValue
		)

		previousValue = newValue
	end)

	------------------------------------------------
	-- PERIODIC STATUS (every 2 mins)
	------------------------------------------------
	task.spawn(function()
		while Threads.CurrentRarity do
			if not State.CurrentRarityTracker then
				Threads.CurrentRarity = nil
				break
			end

			task.wait(interval)

			print(
				"Current Rarity (2m check):",
				currentRarity.Value
			)
		end
	end)
end
local function rerollQuest(difficulty)
	local args = {
		difficulty
	}

	game:GetService("ReplicatedStorage")
		:WaitForChild("Remotes")
		:WaitForChild("RerollQuest")
		:FireServer(unpack(args))
end
local function startAutoQuestReroll()
	if Threads.AutoQuestReroll then return end

	Threads.AutoQuestReroll = task.spawn(function()
		while State.AutoQuestReroll do

			pcall(function()
				rerollQuest("Easy")
				task.wait(0.5)

				rerollQuest("Medium")
				task.wait(0.5)

				rerollQuest("Hard")
			end)

			print("Quest reroll cycle done. Waiting 15 minutes.")

			for i = 1, 15 * 60 do
				if not State.AutoQuestReroll then
					break
				end

				task.wait(1)
			end
		end

		Threads.AutoQuestReroll = nil
	end)
end
------------------------------------------------
-- INSANE QUEST REROLL
------------------------------------------------
local function startInsaneReroll()
	if Threads.InsaneReroll then return end

	Threads.InsaneReroll = task.spawn(function()

		while State.AutoInsaneReroll do

			pcall(function()
				ReplicatedStorage.Remotes.RerollQuest:FireServer("Insane")
			end)

			print("Insane quest rerolled")

			for i = 1, 120 do
				if not State.AutoInsaneReroll then
					break
				end

				task.wait(1)
			end
		end

		Threads.InsaneReroll = nil
	end)
end

------------------------------------------------
-- AUTO CRATES
------------------------------------------------
local function openSelectedCrates()
	for crateName, enabled in pairs(selectedCrates) do
		if enabled then
			pcall(function()
				ReplicatedStorage
					:WaitForChild("Remotes")
					:WaitForChild("OpenCrate")
					:FireServer(crateName, selectedAmount)
			end)
			print("Opened:", crateName, selectedAmount)
		end
	end
end

local function startAutoCrates()
	if Threads.AutoCrates then return end

	Threads.AutoCrates = task.spawn(function()

		while State.AutoCrates do
			openSelectedCrates()
			task.wait(0)
		end

		Threads.AutoCrates = nil
	end)
end
------------------------------------------------
-- WEATHER EQUIP
------------------------------------------------
local function startWeatherEquip(weatherLabel, skinLabel, glyphLabel)
	local weatherValue = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Current Weather")
	local stats = player:WaitForChild("Data"):WaitForChild("Stats")
	local equippedSkin = stats:WaitForChild("Equipped Skin")
	local equippedGlyph1 = stats:WaitForChild("Equipped Glyph")
	local equippedGlyph2 = stats:WaitForChild("Equipped Glyph #2")

	local function updateLabels()
		pcall(function()
			weatherLabel.Text = "Weather: " .. tostring(weatherValue.Value)
			skinLabel.Text = "Skin: " .. tostring(equippedSkin.Value)
			glyphLabel.Text = "G1: " .. tostring(equippedGlyph1.Value) .. " | G2: " .. tostring(equippedGlyph2.Value)
		end)
	end

	local equipSkinRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipSkin")
	local equipGlyphRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipGlyph")
	local wasSpecialWeather = false

	local function applyLoadout(loadout)
		pcall(function() equipSkinRemote:FireServer(loadout.skin) end)
		task.wait(0.167)
		pcall(function() equipGlyphRemote:FireServer(loadout.glyph1, 1) end)
		task.wait(0.51)
		pcall(function() equipGlyphRemote:FireServer(loadout.glyph2, 2) end)
		task.wait(0.51)
		updateLabels()
	end

	local function handleWeather(weather)
		local special = weatherLoadouts[weather]
		if special then
			wasSpecialWeather = true
			applyLoadout(special)
			print("Weather:", weather, "| Skin:", special.skin, "| G1:", special.glyph1, "| G2:", special.glyph2)
		elseif wasSpecialWeather then
			wasSpecialWeather = false
			applyLoadout(defaultLoadout)
			print("Weather:", weather, "-> reverting to default | Skin:", defaultLoadout.skin, "| G1:", defaultLoadout.glyph1, "| G2:", defaultLoadout.glyph2)
		else
			print("Weather:", weather, "| no change")
		end
	end

	updateLabels()

	if State.WeatherEquip then
		local current = weatherValue.Value
		if weatherLoadouts[current] then
			handleWeather(current)
		else
			applyLoadout(defaultLoadout)
			print("Startup: normal weather (" .. current .. ") -> applying default | Skin:", defaultLoadout.skin, "| G1:", defaultLoadout.glyph1, "| G2:", defaultLoadout.glyph2)
		end
	end

	Threads.WeatherEquip = weatherValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateLabels()
		if State.WeatherEquip then
			handleWeather(weatherValue.Value)
		end
	end)

	equippedSkin:GetPropertyChangedSignal("Value"):Connect(function() updateLabels() end)
	equippedGlyph1:GetPropertyChangedSignal("Value"):Connect(function() updateLabels() end)
	equippedGlyph2:GetPropertyChangedSignal("Value"):Connect(function() updateLabels() end)
end
local function startQuestRerollTimer()
	if Threads.QuestRerollTimer then return end

	local questReroll = player
		:WaitForChild("Data")
		:WaitForChild("Items")
		:WaitForChild("Quest Reroll")

	local cooldown = 5 * 60
	local updateEvery = 15
	local timerId = 0
	local previousValue = questReroll.Value

	local function formatTime(seconds)
		local minutes = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%02d:%02d", minutes, secs)
	end

	local function startCooldownTimer()
		timerId += 1
		local thisTimer = timerId

		task.spawn(function()
			for remaining = cooldown, 0, -updateEvery do
				if thisTimer ~= timerId or not State.QuestRerollTimer then
					return
				end

				print("Next Quest Reroll in:", formatTime(remaining))
				task.wait(updateEvery)
			end

			if State.QuestRerollTimer then
				print("Quest Reroll should be ready now.")
			end
		end)
	end

	Threads.QuestRerollTimer =
		questReroll:GetPropertyChangedSignal("Value"):Connect(function()
			if not State.QuestRerollTimer then
				Threads.QuestRerollTimer:Disconnect()
				Threads.QuestRerollTimer = nil
				return
			end

			local currentValue = questReroll.Value
			local difference = currentValue - previousValue

			print("Quest Rerolls:", currentValue, "| Change:", difference)

			if currentValue > previousValue then
				print("Quest Reroll gained. Starting 5-minute timer.")
				startCooldownTimer()
			end

			previousValue = currentValue
		end)

	print("Quest Rerolls:", previousValue)
end
------------------------------------------------
-- USE ITEMS
------------------------------------------------
local function startUseItems()
	if Threads.UseItems then return end

	Threads.UseItems = task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem")
		local items = player:WaitForChild("Data"):WaitForChild("Items")

		while State.UseItems do
			for _, item in ipairs(items:GetChildren()) do
				if not State.UseItems then break end
				local name = item.Name
				if not name:find("Dice") and not name:find("Chest") and not name:find("Crate") and not name:find("Reroll") then
					pcall(function()
						remote:FireServer(name, true)
					end)
				end
			end
			task.wait(0.1)
		end
		Threads.UseItems = nil
		print("Use items loop stopped")
	end)
end
------------------------------------------------
-- AUTO CLICK
------------------------------------------------
local function startAutoClick()
	if Threads.AutoClick then return end

	Threads.AutoClick = task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Click")

		while State.AutoClick do
			pcall(function()
				remote:FireServer(1)
			end)
			task.wait()
		end
		Threads.AutoClick = nil
		print("Click loop stopped")
	end)
end
------------------------------------------------
-- SPEED BOOST
------------------------------------------------
local function startSpeedBoost()
	if Threads.SpeedBoost then return end

	Threads.SpeedBoost = task.spawn(function()
		while State.SpeedBoost do
			pcall(function()
				player.Character.Humanoid.WalkSpeed = 50
			end)
			task.wait(0.1)
		end
		Threads.SpeedBoost = nil
		print("Speed boost stopped")
	end)
end
------------------------------------------------
-- ANTI AFK
------------------------------------------------
local function startAntiAFK()
	if Threads.AntiAFK then return end

	local VirtualUser = game:GetService("VirtualUser")

	player.Idled:Connect(function()
		if State.AntiAFK then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
			print("Anti-AFK: idle kick prevented")
		end
	end)

	Threads.AntiAFK = task.spawn(function()
		while State.AntiAFK do
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
			print("Anti-AFK: input simulated")

			for i = 1, 600 do
				if not State.AntiAFK then break end
				task.wait(1)
			end
		end
		Threads.AntiAFK = nil
	end)
end
------------------------------------------------
-- RESET ALL
------------------------------------------------
local function resetAll()

	State.AutoRoll_Glyphs = false
	State.ResetLoop = false
	State.HitboxExpand = false
	State.RaritiesConsole = false
	State.ResetsConsole = false
	State.RunesConsole = false
	State.QuestRerollTimer = false
	State.GlyphsConsole = false
	State.CurrentRarityTracker = false
	State.AutoQuestReroll = false
	State.AutoRoll_Dice = false
	State.VariantTest = false
	State.AutoInsaneReroll = false
	State.AutoCrates = false
	State.WeatherEquip = false
	State.AntiAFK = false
	State.UseItems = false
	State.AutoClick = false
	State.SpeedBoost = false

	if Threads.QuestRerollTimer then
		Threads.QuestRerollTimer:Disconnect()
		Threads.QuestRerollTimer = nil
	end
	if Threads.WeatherEquip then
		Threads.WeatherEquip:Disconnect()
		Threads.WeatherEquip = nil
	end
	setHitboxes(false)

	if UI then
		UI:Destroy()
		UI = nil
	end

	Threads = {}

	print("Reset complete")
end
 if not hooked then
        hooked = true
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall

        setreadonly(mt, false)

        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self == rollRemote then
                rollFireCount += 1
            end
            return oldNamecall(self, ...)
        end

        setreadonly(mt, true)
end
------------------------------------------------
-- MAIN
------------------------------------------------
local function main()

local autoBtn, resetBtn, hitboxBtn, runeBox, rarityBtn, resetsConsoleBtn, runesConsoleBtn, questRerollBtn, rollDiceBtn, delayBox, variantTestBtn, resetAllBtn, insaneBtn, crateBtn, basicCrateBtn, goldenCrateBtn, rainbowCrateBtn, galaxyCrateBtn, crateAmountBtn, removeAnimBtn, restoreAnimBtn, rpsLabel, nextRuneBtn, weatherEquipBtn, weatherLabel, skinLabel, glyphLabel, antiAFKBtn, rollingScriptBtn, useItemsBtn, autoClickBtn, speedBoostBtn, crateSelectBtn, crateOpenBox, crateOpenBtn, hoursBox, miniChestBtn = createUI()
task.spawn(function()
 	   while true do
    	    task.wait(1)
     	   rpsLabel.Text = "Roll RPS: " .. rollFireCount
     	   rollFireCount = 0
  	  end
	end)
	setHitboxes(State.HitboxExpand)
	startRaritiesConsole()
	startResetsConsole()
	startRunesConsole()
	startQuestRerollTimer()
	startGlyphsConsole()
	startCurrentRarityTracker()
	startAutoRoll_Dice()
	startWeatherEquip(weatherLabel, skinLabel, glyphLabel)
	startAntiAFK()
	delayBox.FocusLost:Connect(function()
		local newDelay = tonumber(delayBox.Text)

		if newDelay and newDelay >= 0 then
			RollDelay = newDelay
		end

		delayBox.Text = tostring(RollDelay)
		print("New Roll Delay:", RollDelay)
	end)

	hoursBox.FocusLost:Connect(function()
		local raw = hoursBox.Text:gsub("h", "")
		local value = tonumber(raw)
		if value and value > 0 then PredictionHours = value end
		hoursBox.Text = tostring(PredictionHours) .. "h"
	end)

	rollingScriptBtn.MouseButton1Click:Connect(function()
		pcall(function()
			local rollingScript = player:WaitForChild("PlayerScripts"):WaitForChild("Rolling")
			rollingScript.Disabled = not rollingScript.Disabled
			local state = rollingScript.Disabled and "OFF" or "ON"
			rollingScriptBtn.Text = "Rolling Script: " .. state
			print("Rolling script " .. (rollingScript.Disabled and "disabled" or "enabled"))
		end)
	end)

	rollDiceBtn.MouseButton1Click:Connect(function()
		State.AutoRoll_Dice = not State.AutoRoll_Dice

		rollDiceBtn.Text =
			"Roll Dice: "
			.. (State.AutoRoll_Dice and "ON" or "OFF")

		if State.AutoRoll_Dice then
			startAutoRoll_Dice()
		end
	end)
		------------------------------------------------
	-- INSANE REROLL
	------------------------------------------------
	insaneBtn.MouseButton1Click:Connect(function()

		State.AutoInsaneReroll = not State.AutoInsaneReroll

		insaneBtn.Text =
			"Insane Reroll: "
			.. (State.AutoInsaneReroll and "ON" or "OFF")

		if State.AutoInsaneReroll then
			startInsaneReroll()
		end
	end)

	------------------------------------------------
	-- ANTI AFK
	------------------------------------------------
	antiAFKBtn.MouseButton1Click:Connect(function()
		State.AntiAFK = not State.AntiAFK
		antiAFKBtn.Text = "Anti-AFK: " .. (State.AntiAFK and "ON" or "OFF")
		if State.AntiAFK then
			startAntiAFK()
		end
	end)

	------------------------------------------------
	-- USE ITEMS
	------------------------------------------------
	useItemsBtn.MouseButton1Click:Connect(function()
		State.UseItems = not State.UseItems
		useItemsBtn.Text = "Use Items: " .. (State.UseItems and "ON" or "OFF")
		if State.UseItems then
			startUseItems()
		end
	end)

	------------------------------------------------
	-- AUTO CLICK
	------------------------------------------------
	autoClickBtn.MouseButton1Click:Connect(function()
		State.AutoClick = not State.AutoClick
		autoClickBtn.Text = "Auto Clicks: " .. (State.AutoClick and "ON" or "OFF")
		if State.AutoClick then
			startAutoClick()
		end
	end)

	------------------------------------------------
	-- MINI CHESTS
	------------------------------------------------
	miniChestBtn.MouseButton1Click:Connect(function()
		local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem")
		local chests = {"Mini Chest", "Mini Chest II", "Mini Chest III", "Mini Chest IV"}
		for _, chest in ipairs(chests) do
			pcall(function()
				remote:FireServer(chest, true)
			end)
		end
		print("Used all Mini Chests")
	end)

	------------------------------------------------
	-- SPEED BOOST
	------------------------------------------------
	speedBoostBtn.MouseButton1Click:Connect(function()
		State.SpeedBoost = not State.SpeedBoost
		speedBoostBtn.Text = "Speed: " .. (State.SpeedBoost and "ON" or "OFF")
		if State.SpeedBoost then
			startSpeedBoost()
		end
	end)

	------------------------------------------------
	-- WEATHER EQUIP
	------------------------------------------------
	weatherEquipBtn.MouseButton1Click:Connect(function()
		State.WeatherEquip = not State.WeatherEquip
		weatherEquipBtn.Text = "Weather Equip: " .. (State.WeatherEquip and "ON" or "OFF")
	end)

	------------------------------------------------
	-- AUTO CRATES
	------------------------------------------------
	crateBtn.MouseButton1Click:Connect(function()

		State.AutoCrates = not State.AutoCrates

		crateBtn.Text =
			"Auto Crates: "
			.. (State.AutoCrates and "ON" or "OFF")

		if State.AutoCrates then
			startAutoCrates()
		end
	end)

	------------------------------------------------
	-- CRATE TYPE
	------------------------------------------------
	local function makeCrateToggle(btn, crateName)
		btn.MouseButton1Click:Connect(function()
			selectedCrates[crateName] = not selectedCrates[crateName]
			btn.Text = crateName .. ": " .. (selectedCrates[crateName] and "ON" or "OFF")
			btn.BackgroundColor3 = selectedCrates[crateName] 
				and Color3.fromRGB(0, 120, 0) 
				or Color3.fromRGB(50, 50, 50)
		end)
	end

	makeCrateToggle(basicCrateBtn, "Basic Crate")
	makeCrateToggle(goldenCrateBtn, "Golden Crate")
	makeCrateToggle(rainbowCrateBtn, "Rainbow Crate")
	makeCrateToggle(galaxyCrateBtn, "Galaxy Crate")

	------------------------------------------------
	-- CRATE AMOUNT
	------------------------------------------------
	crateAmountBtn.MouseButton1Click:Connect(function()

		if selectedAmount == 1 then
			selectedAmount = 3
		else
			selectedAmount = 1
		end

		crateAmountBtn.Text =
			"Amount: "
			.. tostring(selectedAmount)
	end)

	------------------------------------------------
	-- MANUAL CRATE OPEN
	------------------------------------------------
	local manualCrateIndex = 1
	local manualCrateTypes = { "Basic Crate", "Golden Crate", "Rainbow Crate", "Galaxy Crate" }

	crateSelectBtn.MouseButton1Click:Connect(function()
		manualCrateIndex = (manualCrateIndex % #manualCrateTypes) + 1
		crateSelectBtn.Text = manualCrateTypes[manualCrateIndex]
	end)

	crateOpenBtn.MouseButton1Click:Connect(function()
		local amount = tonumber(crateOpenBox.Text)
		if not amount or amount < 1 then
			print("Invalid amount")
			return
		end
		local crateName = manualCrateTypes[manualCrateIndex]
		pcall(function()
			ReplicatedStorage
				:WaitForChild("Remotes")
				:WaitForChild("OpenCrate")
				:FireServer(crateName, amount)
		end)
		print("Opened:", crateName, "x" .. amount)
	end)

	removeAnimBtn.MouseButton1Click:Connect(function()
    	if not crateAnimRemote or not crateAnimRemote.Parent then
    	    pcall(function()
    	        crateAnimRemote = ReplicatedStorage
    	            :WaitForChild("Remotes", 5)
    	            :WaitForChild("CrateAnimation", 5)
    	    end)
    	end
    	if crateAnimRemote and crateAnimRemote.Parent then
    	    crateAnimRemote.Parent = nil
    	    print("Crate animation remote disabled")
    	else
    	    print("CrateAnimation remote not found")
    	end

    	pcall(function()
    	    local found = playerGui:FindFirstChild("Interface")
    	        and playerGui.Interface:FindFirstChild("CrateAnimation")
    	    if found then
    	        crateAnimUI = found
    	        crateAnimUI.Parent = nil
    	        print("Crate animation UI disabled")
    	    else
    	        print("CrateAnimation UI not found")
    	    end
    	end)
	end)

	restoreAnimBtn.MouseButton1Click:Connect(function()
    	if crateAnimRemote then
    	    crateAnimRemote.Parent = ReplicatedStorage.Remotes
    	    print("Crate animation remote restored")
    	else
    	    print("No stored remote reference to restore")
    	end

    	if crateAnimUI then
    	    crateAnimUI.Parent = playerGui.Interface
    	    print("Crate animation UI restored")
    	else
    	    print("No stored UI reference to restore")
    	end
	end)

	variantTestBtn.MouseButton1Click:Connect(function()
		if State.VariantTest then
			State.VariantTest = false
			variantTestBtn.Text = "Stopping Test..."
		else
			startVariantTest(variantTestBtn)
		end
	end)
	questRerollBtn.MouseButton1Click:Connect(function()
		State.AutoQuestReroll = not State.AutoQuestReroll

		questRerollBtn.Text =
			"AutoQuestReroll: "
			.. (State.AutoQuestReroll and "ON" or "OFF")

		if State.AutoQuestReroll then
			startAutoQuestReroll()
		end
	end)
	------------------------------------------------
	-- RUNES CONSOLE TOGGLE
	------------------------------------------------
	runesConsoleBtn.MouseButton1Click:Connect(function()
		State.RunesConsole = not State.RunesConsole

		runesConsoleBtn.Text =
			"RunesConsole: "
			.. (State.RunesConsole and "ON" or "OFF")

		if State.RunesConsole then
			startRunesConsole()
		end
	end)

	------------------------------------------------
	-- AUTO ROLL TOGGLE
	------------------------------------------------
	autoBtn.MouseButton1Click:Connect(function()
		State.AutoRoll_Glyphs = not State.AutoRoll_Glyphs
		autoBtn.Text = "AutoRoll_Glyphs: " .. (State.AutoRoll_Glyphs and "ON" or "OFF")

		if State.AutoRoll_Glyphs then
			startAutoRoll_Glyphs()
		end
	end)

	------------------------------------------------
	-- RESET LOOP TOGGLE
	------------------------------------------------
	resetBtn.MouseButton1Click:Connect(function()
		State.ResetLoop = not State.ResetLoop
		resetBtn.Text = "ResetLoop: " .. (State.ResetLoop and "ON" or "OFF")

		if State.ResetLoop then
			startResetLoop()
		end
	end)
	local runeSwitching = false
	nextRuneBtn.MouseButton1Click:Connect(function()
		if runeSwitching then return end
		runeSwitching = true

		local runes = {}
		pcall(function()
			for _, child in ipairs(workspace.Runes:GetChildren()) do
				table.insert(runes, child.Name)
			end
		end)

		if #runes == 0 then
			runeSwitching = false
			return
		end
		table.sort(runes)

		local currentIndex = 0
		for i, name in ipairs(runes) do
			if name == selectedRune then
				currentIndex = i
				break
			end
		end

		local nextIndex = (currentIndex % #runes) + 1
		local newRune = runes[nextIndex]

		pcall(function()
			workspace.Runes[selectedRune].Hitbox.Size = Vector3.new(6, 12, 6)
		end)

		selectedRune = newRune
		runeBox.Text = selectedRune

		task.wait()

		if State.HitboxExpand then
			setHitboxes(true)
		end

		print("Rune set to: " .. selectedRune)

		task.wait(0.3)
		runeSwitching = false
	end)
	runeBox.FocusLost:Connect(function()
		local name = runeBox.Text

		if name and name ~= "" then
			-- reset the old rune first
			pcall(function()
				workspace.Runes[selectedRune].Hitbox.Size = Vector3.new(6, 12, 6)
			end)

			selectedRune = name
			print("Rune set to: " .. selectedRune)

			if State.HitboxExpand then
				setHitboxes(true)
			end
		else
			runeBox.Text = selectedRune
		end
	end)
	------------------------------------------------
	-- HITBOX TOGGLE
	------------------------------------------------
	hitboxBtn.MouseButton1Click:Connect(function()
		State.HitboxExpand = not State.HitboxExpand
		hitboxBtn.Text = "HitboxExpand: " .. (State.HitboxExpand and "ON" or "OFF")

		setHitboxes(State.HitboxExpand)
	end)

	------------------------------------------------
	-- RARITIES CONSOLE TOGGLE
	------------------------------------------------
	rarityBtn.MouseButton1Click:Connect(function()
		State.RaritiesConsole = not State.RaritiesConsole

		rarityBtn.Text =
			"RaritiesConsole: "
			.. (State.RaritiesConsole and "ON" or "OFF")

		if State.RaritiesConsole then
			startRaritiesConsole()
		end
	end)

	------------------------------------------------
	-- RESET ALL
	------------------------------------------------
	resetAllBtn.MouseButton1Click:Connect(function()
		resetAll()
	end)

	------------------------------------------------
-- RESETS CONSOLE TOGGLE
------------------------------------------------
	resetsConsoleBtn.MouseButton1Click:Connect(function()
		State.ResetsConsole = not State.ResetsConsole

		resetsConsoleBtn.Text =
			"ResetsConsole: "
			.. (State.ResetsConsole and "ON" or "OFF")

		if State.ResetsConsole then
			startResetsConsole()
		end
	end)
end
------------------------------------------------
-- START
------------------------------------------------
main()
end

-- first run
runScript()