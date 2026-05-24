pcall(function()
    queue_on_teleport([[
        task.wait(5)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/trezzywezzy/dri/refs/heads/main/loader2.lua"))()
    ]])
end)

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
------------------------------------------------
-- WHITELIST BYPASS (add your UserIds here)
------------------------------------------------
local whitelistedUsers = {
	10368423380,  -- your UserId
	4039158737,  -- friend's UserId
}

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

for _, id in ipairs(whitelistedUsers) do
	if localPlayer.UserId == id then
		print("Whitelisted user — bypassing key check")
		loadstring(game:HttpGet("https://raw.githubusercontent.com/trezzywezzy/dri/refs/heads/main/obf_Cdwdb33d745j0avJHweE1gFnI0Su5VW846ngZKTWn2zyT3f3T75h4ZtvAKxvzAiF.lua"))()
		return
	end
end

local KEYS_URL = "https://gist.githubusercontent.com/trezzywezzy/c67c3e949a03f78db7304eb264fe1729/raw/fc22999ab385309b9c0527fc74067654a63fd605/gistfile1.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/trezzywezzy/dri/refs/heads/main/obf_Cdwdb33d745j0avJHweE1gFnI0Su5VW846ngZKTWn2zyT3f3T75h4ZtvAKxvzAiF.lua"
local KEY_FILE = "MyScript_Key.txt"

------------------------------------------------
-- FETCH VALID KEYS
------------------------------------------------
local validKeys = {}
local ok, raw = pcall(function()
	return game:HttpGet(KEYS_URL)
end)
if not ok or not raw then
	warn("Failed to reach key server")
	return
end

for line in raw:gmatch("[^\r\n]+") do
	local key = line:match("^%s*(.-)%s*$")
	if key ~= "" then
		validKeys[key] = true
	end
end

------------------------------------------------
-- CHECK SAVED KEY
------------------------------------------------
local savedKey = nil
pcall(function()
	savedKey = readfile(KEY_FILE):match("^%s*(.-)%s*$")
end)

if savedKey and validKeys[savedKey] then
	print("Key valid — loading script...")
	loadstring(game:HttpGet(SCRIPT_URL))()
	return
end
------------------------------------------------
-- HARDCODED KEY CHECK
------------------------------------------------
-- (kept separate from the key file for convenience)
local hardcodedKeys = {
	["trez67"] = true,
}
------------------------------------------------
-- KEY INPUT GUI
------------------------------------------------
local playerGui = localPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "KeySystem"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 130)
frame.Position = UDim2.new(0.5, -130, 0.5, -65)
frame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 55, 80)
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Enter Key"
title.TextColor3 = Color3.fromRGB(180, 180, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -24, 0, 30)
keyBox.Position = UDim2.new(0, 12, 0, 42)
keyBox.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
keyBox.TextColor3 = Color3.new(1, 1, 1)
keyBox.PlaceholderText = "XXXX-XXXX-XXXX"
keyBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
keyBox.Text = ""
keyBox.ClearTextOnFocus = true
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 12
keyBox.BorderSizePixel = 0
keyBox.Parent = frame
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 1, -20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.Parent = frame

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, -24, 0, 28)
submitBtn.Position = UDim2.new(0, 12, 0, 80)
submitBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
submitBtn.TextColor3 = Color3.new(1, 1, 1)
submitBtn.Text = "Submit"
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextSize = 12
submitBtn.BorderSizePixel = 0
submitBtn.Parent = frame
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 6)

submitBtn.MouseButton1Click:Connect(function()
	local input = keyBox.Text:match("^%s*(.-)%s*$")

	if validKeys[input] or hardcodedKeys[input] then
		statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
		statusLabel.Text = "Key valid — loading..."

		pcall(function()
			writefile(KEY_FILE, input)
		end)

		task.wait(1)
		gui:Destroy()
		loadstring(game:HttpGet(SCRIPT_URL))()
	else
		statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		statusLabel.Text = "Invalid key"
	end
end)