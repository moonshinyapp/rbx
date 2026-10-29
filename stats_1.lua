-- moonshiny.app // Stats  (v2)
-- Live overlay: FPS (avg / low), frame time, ping, memory, instances, network, players, server time + FPS graph.
-- Drag the title to move it, click ☾ to collapse, run again (or press × / Stop in the executor) to remove it.
-- Edit shared.MoonshinyStatsConfig while it runs, e.g.  shared.MoonshinyStatsConfig.Interval = 0.25

if shared.MoonshinyStats then
	shared.MoonshinyStats()
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StatsService = game:GetService("Stats")

local player = Players.LocalPlayer
local config = shared.MoonshinyStatsConfig or {}
shared.MoonshinyStatsConfig = config
for k, v in pairs({ Interval = 0.5, Graph = true, GraphSamples = 40, Network = true, Instances = true, Corner = "TopRight" }) do
	if config[k] == nil then config[k] = v end
end

local C = {
	bg = Color3.fromHex("0C0A17"), top = Color3.fromHex("141029"), line = Color3.fromHex("31295A"),
	ink = Color3.fromHex("EFEAFB"), muted = Color3.fromHex("A89FC8"), accent = Color3.fromHex("A78BFA"),
	good = "#5FD3A5", warn = "#F2B35B", bad = "#FF6B81",
}
local function level(v, goodAt, warnAt, higherIsBetter)
	if higherIsBetter then
		return v >= goodAt and C.good or (v >= warnAt and C.warn or C.bad)
	end
	return v <= goodAt and C.good or (v <= warnAt and C.warn or C.bad)
end
local function new(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end
	o.Parent = props.Parent
	return o
end

local conns = {}
local function track(c) table.insert(conns, c) return c end

local gui = new("ScreenGui", { Name = "MoonshinyStats", ResetOnSpawn = false, DisplayOrder = 103, IgnoreGuiInset = false, Parent = player:WaitForChild("PlayerGui") })
local right = config.Corner:find("Right") ~= nil
local bottom = config.Corner:find("Bottom") ~= nil
local win = new("Frame", {
	AnchorPoint = Vector2.new(right and 1 or 0, bottom and 1 or 0),
	Position = UDim2.new(right and 1 or 0, right and -12 or 12, bottom and 1 or 0, bottom and -12 or 12),
	Size = UDim2.fromOffset(190, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Parent = gui,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = win })
new("UIStroke", { Color = C.line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = win })
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = win })

local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.top, LayoutOrder = 1, Parent = win })
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = bar })
local collapse = new("TextButton", {
	Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Text = "☾", Font = Enum.Font.GothamBold,
	TextSize = 15, TextColor3 = C.accent, Parent = bar,
})
new("TextLabel", {
	Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, RichText = true,
	Font = Enum.Font.Code, TextSize = 12, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
	Text = '<b>moonshiny</b> <font color="#5A5185">// stats</font>', Parent = bar,
})
local closeBtn = new("TextButton", {
	Position = UDim2.new(1, -26, 0, 0), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1,
	Text = "×", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.muted, Parent = bar,
})

local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = win })
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 8), Parent = body })

local text = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, RichText = true,
	Font = Enum.Font.Code, TextSize = 12, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 1, Text = "", Parent = body,
})

-- FPS graph: one bar per sample
local graph, bars = nil, {}
if config.Graph then
	graph = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.top, LayoutOrder = 2, ClipsDescendants = true, Parent = body })
	new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = graph })
	local n = math.clamp(config.GraphSamples, 10, 80)
	for i = 1, n do
		bars[i] = new("Frame", {
			AnchorPoint = Vector2.new(0, 1), BorderSizePixel = 0, BackgroundColor3 = C.accent,
			Position = UDim2.new((i - 1) / n, 0, 1, 0), Size = UDim2.new(1 / n, -1, 0, 0), Parent = graph,
		})
	end
end

local collapsed = false
track(collapse.Activated:Connect(function()
	collapsed = not collapsed
	body.Visible = not collapsed
end))

-- drag by the title bar
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

-- numbers from the Stats service (a missing one is skipped, never an error)
local function stat(getter, default)
	local ok, v = pcall(getter)
	return ok and tonumber(v) or default
end

local samples, frames, acc, worst = {}, 0, 0, 0
local history = {}
track(RunService.RenderStepped:Connect(function(dt)
	frames += 1
	acc += dt
	worst = math.max(worst, dt)
	if acc < config.Interval then return end

	local fps = frames / acc
	local low = worst > 0 and 1 / worst or fps
	local frameMs = acc / frames * 1000
	frames, acc, worst = 0, 0, 0

	local ping = stat(function() return player:GetNetworkPing() * 1000 end, 0)
	local mem = stat(function() return StatsService:GetTotalMemoryUsageMb() end, 0)
	local t = math.floor(workspace.DistributedGameTime)

	local lines = {
		'<font color="#A78BFA">fps</font>      <font color="' .. level(fps, 50, 30, true) .. '">' .. math.floor(fps + 0.5) .. '</font> <font color="#6E6596">low ' .. math.floor(low + 0.5) .. "</font>",
		'<font color="#A78BFA">frame</font>    ' .. string.format("%.1f ms", frameMs),
		'<font color="#A78BFA">ping</font>     <font color="' .. level(ping, 80, 160) .. '">' .. math.floor(ping + 0.5) .. " ms</font>",
		'<font color="#A78BFA">memory</font>   ' .. math.floor(mem) .. " MB",
	}
	if config.Instances then
		table.insert(lines, '<font color="#A78BFA">objects</font>  ' .. stat(function() return StatsService.InstanceCount end, 0))
	end
	if config.Network then
		local down = stat(function() return StatsService.DataReceiveKbps end, nil)
		local up = stat(function() return StatsService.DataSendKbps end, nil)
		if down and up then
			table.insert(lines, '<font color="#A78BFA">net</font>      ' .. string.format("↓%.0f ↑%.0f kb/s", down, up))
		end
	end
	table.insert(lines, '<font color="#A78BFA">players</font>  ' .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
	table.insert(lines, '<font color="#A78BFA">server</font>   ' .. string.format("%02d:%02d:%02d", t // 3600, t % 3600 // 60, t % 60))
	text.Text = table.concat(lines, "\n")

	if #bars > 0 then
		table.insert(history, fps)
		while #history > #bars do table.remove(history, 1) end
		for i, bar in ipairs(bars) do
			local v = history[i - (#bars - #history)]
			bar.Visible = v ~= nil
			if v then
				bar.Size = UDim2.new(1 / #bars, -1, math.clamp(v / 75, 0.04, 1), 0)
				bar.BackgroundColor3 = Color3.fromHex(level(v, 50, 30, true):sub(2))
			end
		end
	end
end))

local function close()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	gui:Destroy()
	shared.MoonshinyStats = nil
	print("stats off")
end
track(closeBtn.Activated:Connect(close))
shared.MoonshinyStats = close
if onStop then onStop(close) end -- the executor's Stop button removes it too

print("stats on · drag the title · ☾ collapses · run again to turn off")
