-- moonshiny.app // menu
-- Paste into the executor and press EXECUTE. Running it again replaces the old menu.
-- Hotkeys: F = fly, N = noclip, RightControl = hide/show menu
-- Fly: WASD + Space (up) + LeftControl/Q (down)

if shared.MoonshinyMenu then
	shared.MoonshinyMenu()
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local DEFAULT_WALK, DEFAULT_JUMP = 16, 50
local state = {
	fly = false,
	noclip = false,
	infJump = false,
	clickTp = false,
	flySpeed = 60,
	walk = nil, -- nil = game default, number = forced
	jump = nil,
}

local conns = {}
local function on(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local function getChar() return player.Character end
local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function typing()
	return UIS:GetFocusedTextBox() ~= nil
end

----------------------------------------------------------------------
-- FLY
----------------------------------------------------------------------
local flyAtt, flyVel, flyAlign

local function stopFly()
	if flyVel then flyVel:Destroy() end
	if flyAlign then flyAlign:Destroy() end
	if flyAtt then flyAtt:Destroy() end
	flyAtt, flyVel, flyAlign = nil, nil, nil
	local h = getHum()
	if h then h.PlatformStand = false end
end

local function startFly()
	stopFly()
	local root, h = getRoot(), getHum()
	if not (root and h) then return end
	flyAtt = Instance.new("Attachment")
	flyAtt.Name = "MoonshinyFly"
	flyAtt.Parent = root

	flyVel = Instance.new("LinearVelocity")
	flyVel.Attachment0 = flyAtt
	flyVel.MaxForce = math.huge
	flyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	flyVel.RelativeTo = Enum.ActuatorRelativeTo.World
	flyVel.VectorVelocity = Vector3.zero
	flyVel.Parent = root

	flyAlign = Instance.new("AlignOrientation")
	flyAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flyAlign.Attachment0 = flyAtt
	flyAlign.RigidityEnabled = true
	flyAlign.CFrame = root.CFrame.Rotation
	flyAlign.Parent = root

	h.PlatformStand = true
end

on(RunService.RenderStepped, function()
	if not (state.fly and flyVel) then return end
	local cf = camera.CFrame
	local dir = Vector3.zero
	if not typing() then
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then dir -= Vector3.yAxis end
	end
	if dir.Magnitude == 0 then
		local h = getHum() -- mobile thumbstick
		if h and h.MoveDirection.Magnitude > 0 then dir = h.MoveDirection end
	end
	flyVel.VectorVelocity = dir.Magnitude > 0 and dir.Unit * state.flySpeed or Vector3.zero
	flyAlign.CFrame = CFrame.lookAt(Vector3.zero, cf.LookVector)
end)

----------------------------------------------------------------------
-- NOCLIP
----------------------------------------------------------------------
local noclipped = {}

on(RunService.Stepped, function()
	if not state.noclip then return end
	local c = getChar()
	if not c then return end
	for _, part in ipairs(c:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			noclipped[part] = true
			part.CanCollide = false
		end
	end
end)

local function restoreCollision()
	for part in pairs(noclipped) do
		if part.Parent then part.CanCollide = true end
	end
	noclipped = {}
end

----------------------------------------------------------------------
-- SPEED / JUMP / INFINITE JUMP / CLICK TP
----------------------------------------------------------------------
on(RunService.Heartbeat, function()
	local h = getHum()
	if not h then return end
	if state.walk and h.WalkSpeed ~= state.walk then h.WalkSpeed = state.walk end
	if state.jump then
		h.UseJumpPower = true
		if h.JumpPower ~= state.jump then h.JumpPower = state.jump end
	end
end)

on(UIS.JumpRequest, function()
	if not state.infJump then return end
	local h = getHum()
	if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local mouse = player:GetMouse()
on(UIS.InputBegan, function(input, gameProcessed)
	if gameProcessed or not state.clickTp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		local root = getRoot()
		if root and mouse.Hit then
			root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) * root.CFrame.Rotation
		end
	end
end)

on(player.CharacterAdded, function(c)
	noclipped = {}
	c:WaitForChild("HumanoidRootPart")
	task.wait(0.1)
	if state.fly then startFly() end
end)

----------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------
local C = {
	bg = Color3.fromHex("0C0A17"), top = Color3.fromHex("141029"), row = Color3.fromHex("110D22"),
	line = Color3.fromHex("31295A"), ink = Color3.fromHex("EFEAFB"), muted = Color3.fromHex("A89FC8"),
	accent = Color3.fromHex("A78BFA"), off = Color3.fromHex("2A2350"), bad = Color3.fromHex("FF6B81"),
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

local old = player.PlayerGui:FindFirstChild("MoonshinyMenu")
if old then old:Destroy() end

local gui = new("ScreenGui", { Name = "MoonshinyMenu", ResetOnSpawn = false, DisplayOrder = 101, Parent = player.PlayerGui })
local win = new("Frame", {
	Size = UDim2.fromOffset(250, 0), AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.new(0, 24, 0.5, -170), BackgroundColor3 = C.bg, Parent = gui,
})
round(win, 10)
outline(win)

local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.top, Parent = win })
round(bar, 10)
new("TextLabel", {
	Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
	RichText = true, Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
	Text = '<font color="#A78BFA">☾</font> <b>moonshiny.app</b> <font color="#5A5185">//</font> <font color="#A78BFA">menu</font>',
	Parent = bar,
})
local closeBtn = new("TextButton", {
	Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -32, 0, 2), BackgroundTransparency = 1,
	Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.muted, Parent = bar,
})

local body = new("Frame", {
	Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Parent = win,
})
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), Parent = body })

local order = 0
local function rowFrame()
	order += 1
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.row, LayoutOrder = order, Parent = body })
	round(r, 6)
	outline(r)
	return r
end
local function rowLabel(r, text)
	new("TextLabel", {
		Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
		Text = text, Parent = r,
	})
end
local function section(text)
	order += 1
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = order,
		Font = Enum.Font.Code, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
		Text = text, Parent = body,
	})
end

local toggles = {}
local function toggle(text, key, onChange)
	local r = rowFrame()
	rowLabel(r, text)
	local sw = new("TextButton", {
		Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -46, 0.5, -10),
		BackgroundColor3 = C.off, Text = "", AutoButtonColor = false, Parent = r,
	})
	round(sw, 10)
	local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.muted, Parent = sw })
	round(knob, 7)
	local function render()
		local v = state[key]
		sw.BackgroundColor3 = v and C.accent or C.off
		knob.Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
		knob.BackgroundColor3 = v and C.bg or C.muted
	end
	local function set(v)
		state[key] = v
		render()
		if onChange then onChange(v) end
	end
	sw.Activated:Connect(function() set(not state[key]) end)
	toggles[key] = set
	render()
end

local function numberBox(text, get, set)
	local r = rowFrame()
	rowLabel(r, text)
	local box = new("TextBox", {
		Size = UDim2.fromOffset(64, 22), Position = UDim2.new(1, -72, 0.5, -11), BackgroundColor3 = C.bg,
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.ink, Text = tostring(get()), ClearTextOnFocus = false, Parent = r,
	})
	round(box, 5)
	outline(box)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then set(math.clamp(n, 0, 1000)) end
		box.Text = tostring(get())
	end)
	return box
end

local function button(text, color, fn)
	order += 1
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.top, LayoutOrder = order, AutoButtonColor = true,
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = color or C.ink, Text = text, Parent = body,
	})
	round(b, 6)
	outline(b)
	b.Activated:Connect(fn)
end

section("MOVEMENT")
toggle("Fly  [F]", "fly", function(v) if v then startFly() else stopFly() end end)
toggle("Noclip  [N]", "noclip", function(v) if not v then restoreCollision() end end)
toggle("Infinite jump", "infJump")
toggle("Ctrl + Click teleport", "clickTp")

section("VALUES")
numberBox("Fly speed", function() return state.flySpeed end, function(n) state.flySpeed = n end)
local walkBox = numberBox("Walk speed", function()
	local h = getHum()
	return state.walk or (h and h.WalkSpeed) or DEFAULT_WALK
end, function(n) state.walk = n end)
local jumpBox = numberBox("Jump power", function()
	local h = getHum()
	return state.jump or (h and h.UseJumpPower and h.JumpPower) or DEFAULT_JUMP
end, function(n) state.jump = n end)

section("CHARACTER")
button("RESET VALUES", nil, function()
	state.walk, state.jump = nil, nil
	local h = getHum()
	if h then
		h.WalkSpeed = DEFAULT_WALK
		h.JumpPower = DEFAULT_JUMP
	end
	walkBox.Text, jumpBox.Text = tostring(DEFAULT_WALK), tostring(DEFAULT_JUMP)
end)
button("KILL MYSELF (RESPAWN)", C.bad, function()
	local h = getHum()
	if h then h.Health = 0 end
end)

-- drag
local dragging, dragStart, startPos
bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, win.Position
	end
end)
on(UIS.InputChanged, function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
on(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- hotkeys
on(UIS.InputBegan, function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		toggles.fly(not state.fly)
	elseif input.KeyCode == Enum.KeyCode.N then
		toggles.noclip(not state.noclip)
	elseif input.KeyCode == Enum.KeyCode.RightControl then
		gui.Enabled = not gui.Enabled
	end
end)

----------------------------------------------------------------------
-- CLEANUP (close button or running the script again)
----------------------------------------------------------------------
local function cleanup()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	stopFly()
	restoreCollision()
	state.walk, state.jump = nil, nil
	if gui then gui:Destroy() end
	shared.MoonshinyMenu = nil
end
shared.MoonshinyMenu = cleanup
closeBtn.Activated:Connect(cleanup)

print("moonshiny menu loaded · F fly · N noclip · RightControl hide")
