-- moonshiny.app // ESP  (v2)
-- Admin overview: outlines players and shows name, health bar and distance. Run again to turn it off.
-- Roblox draws at most 31 highlights at once, so the NEAREST ones get the outline and everyone gets the label.
-- Change settings while it runs:  shared.MoonshinyESPConfig.MaxDistance = 300

if shared.MoonshinyESP then
	shared.MoonshinyESP()
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local config = shared.MoonshinyESPConfig or {}
shared.MoonshinyESPConfig = config
local defaults = {
	MaxDistance = 2000,       -- studs; further players get nothing
	MaxHighlights = 30,       -- Roblox limit is 31
	ShowTeammates = true,
	ShowHealth = true,
	ShowDistance = true,
	ColorBy = "team",         -- "team" or "health"
	Interval = 0.1,           -- seconds between updates
	FillTransparency = 0.8,
	Accent = Color3.fromHex("A78BFA"),
}
for k, v in pairs(defaults) do
	if config[k] == nil then config[k] = v end
end

local gui = Instance.new("ScreenGui")
gui.Name = "MoonshinyESP"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local entries = {} -- [Player] = { char, head, highlight, billboard, name, hp, hpFill, conn }
local conns = {}

local function colorFor(plr, health01)
	if config.ColorBy == "health" and health01 then
		return Color3.fromHSV(math.clamp(health01, 0, 1) * 0.33, 0.75, 1)
	end
	if plr.Team then return plr.TeamColor.Color end
	return config.Accent
end

local function clearVisuals(e)
	if e.highlight then e.highlight:Destroy() end
	if e.billboard then e.billboard:Destroy() end
	e.highlight, e.billboard, e.name, e.hp, e.hpFill, e.char, e.head = nil, nil, nil, nil, nil, nil, nil
end

local function build(plr, char)
	local e = entries[plr]
	if not e then return end
	clearVisuals(e)
	local head = char:WaitForChild("Head", 5)
	if not head or entries[plr] ~= e or plr.Character ~= char then return end
	e.char, e.head = char, head

	local bb = Instance.new("BillboardGui")
	bb.Name = plr.Name
	bb.Adornee = head
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(180, 46)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.Parent = gui

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 28)
	name.Font = Enum.Font.Code
	name.TextSize = 13
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Text = plr.DisplayName
	name.Parent = bb

	local hpBack = Instance.new("Frame")
	hpBack.AnchorPoint = Vector2.new(0.5, 0)
	hpBack.Position = UDim2.new(0.5, 0, 0, 32)
	hpBack.Size = UDim2.fromOffset(70, 5)
	hpBack.BackgroundColor3 = Color3.fromHex("0C0A17")
	hpBack.BorderSizePixel = 0
	hpBack.Parent = bb
	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BorderSizePixel = 0
	hpFill.BackgroundColor3 = Color3.fromHex("5FD3A5")
	hpFill.Parent = hpBack
	e.hp, e.hpFill, e.billboard, e.name = hpBack, hpFill, bb, name
end

local function track(plr)
	if plr == player or entries[plr] then return end
	local e = {}
	entries[plr] = e
	e.conn = plr.CharacterAdded:Connect(function(char) build(plr, char) end)
	if plr.Character then task.spawn(build, plr, plr.Character) end
end
local function untrack(plr)
	local e = entries[plr]
	if not e then return end
	if e.conn then e.conn:Disconnect() end
	clearVisuals(e)
	entries[plr] = nil
end

for _, plr in ipairs(Players:GetPlayers()) do track(plr) end
table.insert(conns, Players.PlayerAdded:Connect(track))
table.insert(conns, Players.PlayerRemoving:Connect(untrack))

local acc = 0
table.insert(conns, RunService.RenderStepped:Connect(function(dt)
	acc = acc + dt
	if acc < config.Interval then return end
	acc = 0

	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	-- distance of everyone (for the "nearest N" rule)
	local list = {}
	for plr, e in pairs(entries) do
		local char = e.char
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if e.billboard and root and char.Parent then
			local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0
			local hidden = dist > config.MaxDistance or (not config.ShowTeammates and plr.Team ~= nil and plr.Team == player.Team)
			e.billboard.Enabled = not hidden
			if not hidden then table.insert(list, { plr = plr, e = e, dist = dist }) end
		end
	end
	table.sort(list, function(a, b) return a.dist < b.dist end)

	for i, item in ipairs(list) do
		local plr, e = item.plr, item.e
		local hum = e.char:FindFirstChildOfClass("Humanoid")
		local hp = hum and hum.Health or 0
		local maxHp = hum and math.max(hum.MaxHealth, 1) or 1
		local frac = math.clamp(hp / maxHp, 0, 1)
		local color = colorFor(plr, frac)

		local text = plr.DisplayName
		if config.ShowHealth then text = text .. string.format("\n%d/%d HP", math.floor(hp), math.floor(maxHp)) end
		if config.ShowDistance then text = text .. string.format("%s%dm", config.ShowHealth and " · " or "\n", math.floor(item.dist)) end
		e.name.Text = text
		e.hp.Visible = config.ShowHealth
		e.hpFill.Size = UDim2.fromScale(frac, 1)
		e.hpFill.BackgroundColor3 = Color3.fromHSV(frac * 0.33, 0.7, 1)

		-- outline only for the nearest ones (the engine limit)
		if i <= math.min(config.MaxHighlights, 31) then
			if not e.highlight then
				local hl = Instance.new("Highlight")
				hl.Name = "MoonshinyESP"
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.OutlineTransparency = 0
				hl.Adornee = e.char
				hl.Parent = e.char
				e.highlight = hl
			end
			e.highlight.FillColor = color
			e.highlight.OutlineColor = color
			e.highlight.FillTransparency = config.FillTransparency
		elseif e.highlight then
			e.highlight:Destroy()
			e.highlight = nil
		end
	end
end))

local function stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	for plr in pairs(entries) do untrack(plr) end
	gui:Destroy()
	shared.MoonshinyESP = nil
	print("ESP off")
end
shared.MoonshinyESP = stop
if onStop then onStop(stop) end

print("ESP on · run again to turn off · settings: shared.MoonshinyESPConfig")
