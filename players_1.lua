-- moonshiny.app // Players  (v2)
-- Admin player list: search, teleport to a player, watch them with your camera, copy their id.
-- Run again, press × or Stop in the executor to close. Drag the title to move it, ☾ collapses it.
-- While watching someone, [ and ] switch to the previous / next player.

if shared.MoonshinyPlayers then
	shared.MoonshinyPlayers()
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local C = {
	bg = Color3.fromHex("0C0A17"), top = Color3.fromHex("141029"), row = Color3.fromHex("110D22"),
	line = Color3.fromHex("31295A"), ink = Color3.fromHex("EFEAFB"), muted = Color3.fromHex("A89FC8"),
	accent = Color3.fromHex("A78BFA"), accentInk = Color3.fromHex("130B2B"),
}
local function new(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end
	o.Parent = props.Parent
	return o
end
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r), Parent = o }) end
local function outline(o) new("UIStroke", { Color = C.line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o }) end

local conns = {}
local function track(c) table.insert(conns, c) return c end
local watching = nil
local rows = {} -- [Player] = { frame, view, dist }
local query = ""

local gui = new("ScreenGui", { Name = "MoonshinyPlayers", ResetOnSpawn = false, DisplayOrder = 102, Parent = player:WaitForChild("PlayerGui") })
local win = new("Frame", {
	Size = UDim2.fromOffset(290, 360), Position = UDim2.new(1, -314, 0.5, -180), BackgroundColor3 = C.bg, Parent = gui,
})
round(win, 10)
outline(win)

local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.top, Parent = win })
round(bar, 10)
local collapse = new("TextButton", {
	Size = UDim2.fromOffset(30, 34), BackgroundTransparency = 1, Text = "☾", Font = Enum.Font.GothamBold,
	TextSize = 16, TextColor3 = C.accent, Parent = bar,
})
local title = new("TextLabel", {
	Size = UDim2.new(1, -66, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1, RichText = true,
	Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = bar,
})
local closeBtn = new("TextButton", {
	Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -32, 0, 2), BackgroundTransparency = 1,
	Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.muted, Parent = bar,
})

local content = new("Frame", { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34), BackgroundTransparency = 1, Parent = win })
local search = new("TextBox", {
	Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 26), BackgroundColor3 = C.row, Text = "",
	PlaceholderText = "search name…", PlaceholderColor3 = C.muted, TextColor3 = C.ink, Font = Enum.Font.Code,
	TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = content,
})
round(search, 6)
outline(search)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = search })

local list = new("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -50), BackgroundTransparency = 1, BorderSizePixel = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.accent, Parent = content,
})
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.Name, Parent = list })

local function myRoot()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoidOf(plr)
	return plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
end

local function updateTitle()
	local n = 0
	for _ in pairs(rows) do n = n + 1 end
	title.Text = '<b>players</b> <font color="#5A5185">//</font> ' .. (n + 1) .. " online"
end

local function stopWatching()
	watching = nil
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then camera.CameraSubject = hum end
	for _, r in pairs(rows) do r.view.Text = "VIEW"; r.view.BackgroundColor3 = C.top; r.view.TextColor3 = C.ink end
end

local function watch(plr)
	local hum = humanoidOf(plr)
	if not hum then return end
	stopWatching()
	watching = plr
	camera.CameraSubject = hum
	local r = rows[plr]
	if r then r.view.Text = "STOP"; r.view.BackgroundColor3 = C.accent; r.view.TextColor3 = C.accentInk end
end

local function applyFilter()
	local q = query:lower()
	for plr, r in pairs(rows) do
		r.frame.Visible = q == "" or plr.Name:lower():find(q, 1, true) ~= nil or plr.DisplayName:lower():find(q, 1, true) ~= nil
	end
end

local function smallButton(parent, text, x, w)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(w, 22), Position = UDim2.new(1, x, 0.5, -11), BackgroundColor3 = C.top, AutoButtonColor = true,
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.ink, Text = text, Parent = parent,
	})
	round(b, 5)
	outline(b)
	return b
end

local function addRow(plr)
	if rows[plr] or plr == player then return end
	local frame = new("Frame", { Name = plr.Name:lower(), Size = UDim2.new(1, -4, 0, 44), BackgroundColor3 = C.row, Parent = list })
	round(frame, 6)
	outline(frame)
	local teamDot = new("Frame", { Size = UDim2.fromOffset(3, 28), Position = UDim2.fromOffset(5, 8), BorderSizePixel = 0, BackgroundColor3 = plr.Team and plr.TeamColor.Color or C.line, Parent = frame })
	round(teamDot, 2)
	new("TextLabel", {
		Size = UDim2.new(1, -160, 0, 22), Position = UDim2.fromOffset(14, 3), BackgroundTransparency = 1, RichText = true,
		Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = plr.DisplayName .. ' <font color="#6E6596">@' .. plr.Name .. "</font>", Parent = frame,
	})
	local dist = new("TextLabel", {
		Size = UDim2.new(1, -160, 0, 16), Position = UDim2.fromOffset(14, 24), BackgroundTransparency = 1,
		Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "id " .. plr.UserId, Parent = frame,
	})
	local copy = smallButton(frame, "ID", -148, 30)
	local tp = smallButton(frame, "TP", -114, 34)
	local view = smallButton(frame, "VIEW", -76, 62)

	copy.Activated:Connect(function()
		if setclipboard then
			setclipboard(tostring(plr.UserId))
			copy.Text = "✓"
			task.delay(1, function() if copy.Parent then copy.Text = "ID" end end)
		else
			print(plr.Name, plr.UserId)
			copy.Text = "log"
			task.delay(1, function() if copy.Parent then copy.Text = "ID" end end)
		end
	end)
	tp.Activated:Connect(function()
		local root = myRoot()
		local target = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root and target then root.CFrame = target.CFrame * CFrame.new(0, 0, 3) end
	end)
	view.Activated:Connect(function()
		if watching == plr then stopWatching() else watch(plr) end
	end)
	rows[plr] = { frame = frame, view = view, dist = dist, teamDot = teamDot }
	applyFilter()
end

local function removeRow(plr)
	if watching == plr then stopWatching() end
	local r = rows[plr]
	if r then r.frame:Destroy() rows[plr] = nil end
	updateTitle()
end

for _, plr in ipairs(Players:GetPlayers()) do addRow(plr) end
updateTitle()
track(Players.PlayerAdded:Connect(function(plr) addRow(plr) updateTitle() end))
track(Players.PlayerRemoving:Connect(removeRow))
track(search:GetPropertyChangedSignal("Text"):Connect(function() query = search.Text applyFilter() end))

-- distance + team colour, twice a second
local acc = 0
track(RunService.Heartbeat:Connect(function(dt)
	acc = acc + dt
	if acc < 0.5 then return end
	acc = 0
	local root = myRoot()
	for plr, r in pairs(rows) do
		local target = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local d = (root and target) and math.floor((root.Position - target.Position).Magnitude) or nil
		r.dist.Text = "id " .. plr.UserId .. (d and ("  ·  " .. d .. "m") or "")
		r.teamDot.BackgroundColor3 = plr.Team and plr.TeamColor.Color or C.line
	end
	-- the watched player respawned: follow the new humanoid
	if watching then
		local hum = humanoidOf(watching)
		if hum and camera.CameraSubject ~= hum then camera.CameraSubject = hum end
	end
end))

-- [ and ] switch the watched player
local function cycle(dir)
	if not watching then return end
	local names = {}
	for plr in pairs(rows) do table.insert(names, plr) end
	table.sort(names, function(a, b) return a.Name:lower() < b.Name:lower() end)
	local idx = table.find(names, watching) or 1
	local nextPlr = names[(idx - 1 + dir) % #names + 1]
	if nextPlr then watch(nextPlr) end
end
track(UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftBracket then cycle(-1)
	elseif input.KeyCode == Enum.KeyCode.RightBracket then cycle(1) end
end))

-- collapse / drag
local collapsed = false
track(collapse.Activated:Connect(function()
	collapsed = not collapsed
	content.Visible = not collapsed
	win.Size = collapsed and UDim2.fromOffset(290, 34) or UDim2.fromOffset(290, 360)
end))
local dragging, dragStart, startPos
track(bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, win.Position
	end
end))
track(UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end))
track(UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end))

local function close()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	if watching then stopWatching() end
	gui:Destroy()
	shared.MoonshinyPlayers = nil
end
track(closeBtn.Activated:Connect(close))
shared.MoonshinyPlayers = close
if onStop then onStop(close) end
