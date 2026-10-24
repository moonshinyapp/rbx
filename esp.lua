-- moonshiny.app // ESP
-- Admin overview: outlines every player and shows name, health and distance.
-- Run again to turn it off. Roblox draws at most 31 highlights at once.

if shared.MoonshinyESP then
	shared.MoonshinyESP()
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ACCENT = Color3.fromHex("A78BFA")

local gui = Instance.new("ScreenGui")
gui.Name = "MoonshinyESP"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local entries = {} -- [Player] = { highlight, billboard, label, conn }
local conns = {}

local function colorFor(plr)
	if plr.Team then
		return plr.TeamColor.Color
	end
	return ACCENT
end

local function clearVisuals(entry)
	if entry.highlight then entry.highlight:Destroy() end
	if entry.billboard then entry.billboard:Destroy() end
	entry.highlight, entry.billboard, entry.label = nil, nil, nil
end

local function build(plr, char)
	local entry = entries[plr]
	if not entry then return end
	clearVisuals(entry)
	local head = char:WaitForChild("Head", 5)
	if not head or not entries[plr] then return end

	local hl = Instance.new("Highlight")
	hl.Name = "MoonshinyESP"
	hl.Adornee = char
	hl.FillColor = colorFor(plr)
	hl.FillTransparency = 0.8
	hl.OutlineColor = colorFor(plr)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char

	local bb = Instance.new("BillboardGui")
	bb.Name = plr.Name
	bb.Adornee = head
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(200, 40)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.Parent = gui

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = plr.DisplayName
	label.Parent = bb

	entry.highlight, entry.billboard, entry.label = hl, bb, label
end

local function track(plr)
	if plr == player or entries[plr] then return end
	local entry = {}
	entries[plr] = entry
	entry.conn = plr.CharacterAdded:Connect(function(char)
		build(plr, char)
	end)
	if plr.Character then
		task.spawn(build, plr, plr.Character)
	end
end

local function untrack(plr)
	local entry = entries[plr]
	if not entry then return end
	if entry.conn then entry.conn:Disconnect() end
	clearVisuals(entry)
	entries[plr] = nil
end

for _, plr in ipairs(Players:GetPlayers()) do
	track(plr)
end
table.insert(conns, Players.PlayerAdded:Connect(track))
table.insert(conns, Players.PlayerRemoving:Connect(untrack))

-- update labels a few times per second
local acc = 0
table.insert(conns, RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.2 then return end
	acc = 0
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for plr, entry in pairs(entries) do
		local char = plr.Character
		if entry.label and char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			local hp = hum and math.floor(hum.Health) or 0
			local maxHp = hum and math.floor(hum.MaxHealth) or 0
			local dist = (myRoot and root) and math.floor((myRoot.Position - root.Position).Magnitude) or 0
			entry.label.Text = string.format("%s\n%d/%d HP · %dm", plr.DisplayName, hp, maxHp, dist)
			local c = colorFor(plr)
			entry.highlight.FillColor = c
			entry.highlight.OutlineColor = c
		end
	end
end))

shared.MoonshinyESP = function()
	for _, c in ipairs(conns) do c:Disconnect() end
	for plr in pairs(entries) do untrack(plr) end
	gui:Destroy()
	shared.MoonshinyESP = nil
	print("ESP off")
end

print("ESP on · run again to turn off")
