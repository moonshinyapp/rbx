-- moonshiny.app // Players
-- Admin player list: teleport to a player or watch them with your camera.
-- Run again or press × to close.

if shared.MoonshinyPlayers then
	shared.MoonshinyPlayers()
	return
end

local Players = game:GetService("Players")
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
	for k, v in pairs(props) do
		if k ~= "Parent" then o[k] = v end
	end
	o.Parent = props.Parent
	return o
end
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r), Parent = o }) end
local function outline(o) new("UIStroke", { Color = C.line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o }) end

local conns = {}
local watching = nil

local gui = new("ScreenGui", { Name = "MoonshinyPlayers", ResetOnSpawn = false, DisplayOrder = 102, Parent = player.PlayerGui })
local win = new("Frame", {
	Size = UDim2.fromOffset(270, 320), Position = UDim2.new(1, -294, 0.5, -160),
	BackgroundColor3 = C.bg, Parent = gui,
})
round(win, 10)
outline(win)

local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.top, Parent = win })
round(bar, 10)
local title = new("TextLabel", {
	Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
	RichText = true, Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "", Parent = bar,
})
local closeBtn = new("TextButton", {
	Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -32, 0, 2), BackgroundTransparency = 1,
	Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.muted, Parent = bar,
})

local list = new("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -50),
	BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, Parent = win,
})
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.Name, Parent = list })

local function myRoot()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function stopWatching()
	watching = nil
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then camera.CameraSubject = hum end
end

local render

local function smallButton(parent, text, x, filled)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(46, 22), Position = UDim2.new(1, x, 0.5, -11),
		BackgroundColor3 = filled and C.accent or C.top, AutoButtonColor = true,
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = filled and C.accentInk or C.ink,
		Text = text, Parent = parent,
	})
	round(b, 5)
	if not filled then outline(b) end
	return b
end

render = function()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local all = Players:GetPlayers()
	title.Text = '<font color="#A78BFA">☾</font> <b>players</b> <font color="#5A5185">//</font> ' .. #all .. " online"
	for _, plr in ipairs(all) do
		local rowF = new("Frame", {
			Name = plr.Name:lower(), Size = UDim2.new(1, -4, 0, 34), BackgroundColor3 = C.row, Parent = list,
		})
		round(rowF, 6)
		outline(rowF)
		new("TextLabel", {
			Size = UDim2.new(1, -112, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1,
			RichText = true, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.ink,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = plr.DisplayName .. ' <font color="#6E6596">@' .. plr.Name .. "</font>" .. (plr == player and " (you)" or ""),
			Parent = rowF,
		})
		if plr ~= player then
			local tp = smallButton(rowF, "TP", -102, false)
			local view = smallButton(rowF, watching == plr and "STOP" or "VIEW", -52, watching == plr)
			tp.Activated:Connect(function()
				local root = myRoot()
				local target = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if root and target then
					root.CFrame = target.CFrame * CFrame.new(0, 0, 3)
				end
			end)
			view.Activated:Connect(function()
				if watching == plr then
					stopWatching()
				else
					local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						watching = plr
						camera.CameraSubject = hum
					end
				end
				render()
			end)
		end
	end
end

table.insert(conns, Players.PlayerAdded:Connect(render))
table.insert(conns, Players.PlayerRemoving:Connect(function(plr)
	if watching == plr then stopWatching() end
	task.defer(render)
end))
render()

-- drag
local dragging, dragStart, startPos
table.insert(conns, bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, win.Position
	end
end))
table.insert(conns, UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end))
table.insert(conns, UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end))

local function close()
	for _, c in ipairs(conns) do c:Disconnect() end
	if watching then stopWatching() end
	gui:Destroy()
	shared.MoonshinyPlayers = nil
end
closeBtn.Activated:Connect(close)
shared.MoonshinyPlayers = close
