-- moonshiny.app // Stats
-- Small overlay with FPS, ping, memory, players and time in server.
-- Run again to turn it off.

if shared.MoonshinyStats then
	shared.MoonshinyStats()
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MoonshinyStats"
gui.ResetOnSpawn = false
gui.DisplayOrder = 103
gui.Parent = player.PlayerGui

local box = Instance.new("TextLabel")
box.AnchorPoint = Vector2.new(1, 0)
box.Position = UDim2.new(1, -12, 0, 12)
box.Size = UDim2.fromOffset(0, 0)
box.AutomaticSize = Enum.AutomaticSize.XY
box.BackgroundColor3 = Color3.fromHex("0C0A17")
box.BackgroundTransparency = 0.1
box.RichText = true
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextColor3 = Color3.fromHex("EFEAFB")
box.TextXAlignment = Enum.TextXAlignment.Left
box.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = box
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromHex("31295A")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = box
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
pad.Parent = box

local function colorFps(fps)
	if fps >= 50 then return "#5FD3A5" elseif fps >= 30 then return "#F2B35B" end
	return "#FF6B81"
end
local function colorPing(ms)
	if ms <= 80 then return "#5FD3A5" elseif ms <= 160 then return "#F2B35B" end
	return "#FF6B81"
end

local frames, acc = 0, 0
local conn = RunService.RenderStepped:Connect(function(dt)
	frames += 1
	acc += dt
	if acc < 0.5 then return end
	local fps = math.floor(frames / acc + 0.5)
	frames, acc = 0, 0

	local ping = math.floor(player:GetNetworkPing() * 1000 + 0.5)
	local mem = math.floor(Stats:GetTotalMemoryUsageMb())
	local t = math.floor(workspace.DistributedGameTime)
	box.Text = table.concat({
		'<font color="#A78BFA">☾ moonshiny.app</font> <font color="#5A5185">// stats</font>',
		string.format('fps      <font color="%s">%d</font>', colorFps(fps), fps),
		string.format('ping     <font color="%s">%d ms</font>', colorPing(ping), ping),
		string.format("memory   %d MB", mem),
		string.format("players  %d / %d", #Players:GetPlayers(), Players.MaxPlayers),
		string.format("server   %02d:%02d:%02d", t // 3600, t % 3600 // 60, t % 60),
	}, "\n")
end)

shared.MoonshinyStats = function()
	conn:Disconnect()
	gui:Destroy()
	shared.MoonshinyStats = nil
	print("stats off")
end
print("stats on · run again to turn off")
