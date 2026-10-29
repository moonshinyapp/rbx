-- moonshiny.app // menu  (v2)
-- Admin / debug toolbox for your own game. Paste into the executor and press EXECUTE. Running it again replaces the menu.
--   F fly · N noclip · RightControl hide / show · Ctrl + click teleport · Fly: WASD + Space up + Ctrl/Q down
--   Phone: use the toggles; while fly is on two ▲ ▼ buttons appear.
-- Your values are kept in shared.MoonshinyMenuState, so running the script again restores them.

if shared.MoonshinyMenu then
	shared.MoonshinyMenu()
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local DEFAULT_WALK, DEFAULT_JUMP, DEFAULT_GRAVITY = 16, 50, workspace.Gravity
local TOUCH = UIS.TouchEnabled and not UIS.KeyboardEnabled

local state = shared.MoonshinyMenuState or {
	fly = false, noclip = false, infJump = false, clickTp = false, fullbright = false, antiAfk = false,
	flySpeed = 60, walk = nil, jump = nil, fov = nil, gravity = nil,
}
shared.MoonshinyMenuState = state
state.fly = false -- (a fresh character, nothing flies yet)

local conns = {}
local function on(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end
local function getHum()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function typing() return UIS:GetFocusedTextBox() ~= nil end

----------------------------------------------------------------------
-- FLY (smoothed)
----------------------------------------------------------------------
local flyAtt, flyVel, flyAlign
local climb = 0 -- phone buttons: 1 up, -1 down

local function stopFly()
	for _, o in ipairs({ flyVel, flyAlign, flyAtt }) do if o then o:Destroy() end end
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

local flyVelocity = Vector3.zero
on(RunService.RenderStepped, function(dt)
	if not (state.fly and flyVel and flyVel.Parent) then
		flyVelocity = Vector3.zero
		return
	end
	local cf = camera.CFrame
	local dir = Vector3.zero
	if not typing() then
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.yAxis end
	end
	if dir.Magnitude == 0 then
		local h = getHum() -- thumbstick
		if h and h.MoveDirection.Magnitude > 0 then dir = h.MoveDirection end
	end
	dir = dir + Vector3.yAxis * climb
	local target = dir.Magnitude > 0 and dir.Unit * state.flySpeed or Vector3.zero
	flyVelocity = flyVelocity:Lerp(target, 1 - math.exp(-10 * dt))
	flyVel.VectorVelocity = flyVelocity
	flyAlign.CFrame = CFrame.lookAt(Vector3.zero, cf.LookVector)
end)

----------------------------------------------------------------------
-- NOCLIP
----------------------------------------------------------------------
local noclipped = {}
on(RunService.Stepped, function()
	if not state.noclip then return end
	local c = player.Character
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
-- VALUES: walk, jump, gravity, field of view
----------------------------------------------------------------------
on(RunService.Heartbeat, function()
	local h = getHum()
	if h then
		if state.walk and h.WalkSpeed ~= state.walk then h.WalkSpeed = state.walk end
		if state.jump then
			h.UseJumpPower = true
			if h.JumpPower ~= state.jump then h.JumpPower = state.jump end
		end
	end
	if state.gravity and workspace.Gravity ~= state.gravity then workspace.Gravity = state.gravity end
	if state.fov and camera.FieldOfView ~= state.fov then camera.FieldOfView = state.fov end
end)

on(UIS.JumpRequest, function()
	if not state.infJump then return end
	local h = getHum()
	if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Ctrl + click teleport (ray from the cursor, ignores your own character)
on(UIS.InputBegan, function(input, processed)
	if processed or not state.clickTp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not UIS:IsKeyDown(Enum.KeyCode.LeftControl) then return end
	local root = getRoot()
	if not root then return end
	local pos = UIS:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if hit then
		root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) * root.CFrame.Rotation
	end
end)

on(player.CharacterAdded, function(c)
	noclipped = {}
	c:WaitForChild("HumanoidRootPart")
	task.wait(0.1)
	if state.fly then startFly() end
end)

----------------------------------------------------------------------
-- FULLBRIGHT + ANTI AFK + REJOIN
----------------------------------------------------------------------
local savedLight
local function setFullbright(on_)
	if on_ then
		savedLight = savedLight or {
			Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
			GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
		}
		Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows = 2, 14, 1e5, false
		Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180), Color3.fromRGB(180, 180, 180)
	elseif savedLight then
		for k, v in pairs(savedLight) do Lighting[k] = v end
		savedLight = nil
	end
end

local afkConn
local function setAntiAfk(on_)
	if afkConn then afkConn:Disconnect() afkConn = nil end
	if not on_ then return end
	local ok, VirtualUser = pcall(function() return game:GetService("VirtualUser") end)
	if not ok then return end
	afkConn = player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

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
	for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end
	o.Parent = props.Parent
	return o
end
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r), Parent = o }) end
local function outline(o) new("UIStroke", { Color = C.line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o }) end

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("MoonshinyMenu")
if old then old:Destroy() end

local gui = new("ScreenGui", { Name = "MoonshinyMenu", ResetOnSpawn = false, DisplayOrder = 101, Parent = playerGui })
local win = new("Frame", {
	Size = UDim2.fromOffset(264, 0), AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.new(0, 24, 0.5, -200), BackgroundColor3 = C.bg, Parent = gui,
})
round(win, 10)
outline(win)

local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.top, Parent = win })
round(bar, 10)
local collapse = new("TextButton", {
	Size = UDim2.fromOffset(30, 34), BackgroundTransparency = 1, Text = "☾", Font = Enum.Font.GothamBold,
	TextSize = 16, TextColor3 = C.accent, Parent = bar,
})
new("TextLabel", {
	Size = UDim2.new(1, -66, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1, RichText = true,
	Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
	Text = '<b>moonshiny</b> <font color="#5A5185">//</font> <font color="#A78BFA">menu</font>', Parent = bar,
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
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), Parent = body })

local order = 0
local function rowFrame()
	order = order + 1
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
	order = order + 1
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = order, Font = Enum.Font.Code,
		TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = body,
	})
end

local toggles = {}
local function toggle(text, key, onChange)
	local r = rowFrame()
	rowLabel(r, text)
	local sw = new("TextButton", {
		Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -46, 0.5, -10), BackgroundColor3 = C.off,
		Text = "", AutoButtonColor = false, Parent = r,
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
	if state[key] and onChange and key ~= "fly" then onChange(true) end -- a restored value is applied again
end

local boxes = {}
-- empty box = "game default" (value nil) for walk / jump / gravity / fov
local function numberBox(text, key, fallback, min, max)
	local r = rowFrame()
	rowLabel(r, text)
	local box = new("TextBox", {
		Size = UDim2.fromOffset(64, 22), Position = UDim2.new(1, -72, 0.5, -11), BackgroundColor3 = C.bg,
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.ink, PlaceholderText = "auto", PlaceholderColor3 = C.muted,
		Text = state[key] and tostring(state[key]) or "", ClearTextOnFocus = false, Parent = r,
	})
	round(box, 5)
	outline(box)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			state[key] = math.clamp(n, min, max)
			box.Text = tostring(state[key])
		elseif box.Text == "" then
			state[key] = nil
			if fallback then fallback() end
		else
			box.Text = state[key] and tostring(state[key]) or ""
		end
	end)
	boxes[key] = box
end

local function button(text, color, fn)
	order = order + 1
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.top, LayoutOrder = order, AutoButtonColor = true,
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = color or C.ink, Text = text, Parent = body,
	})
	round(b, 6)
	outline(b)
	b.Activated:Connect(fn)
end

local setClimbButtons
section("MOVEMENT")
toggle("Fly  [F]", "fly", function(v)
	if v then startFly() else stopFly() end
	setClimbButtons(v)
end)
toggle("Noclip  [N]", "noclip", function(v) if not v then restoreCollision() end end)
toggle("Infinite jump", "infJump")
toggle("Ctrl + Click teleport", "clickTp")

section("VALUES  (empty = game default)")
numberBox("Fly speed", "flySpeed", nil, 1, 1000)
numberBox("Walk speed", "walk", function()
	local h = getHum()
	if h then h.WalkSpeed = DEFAULT_WALK end
end, 0, 1000)
numberBox("Jump power", "jump", function()
	local h = getHum()
	if h then h.JumpPower = DEFAULT_JUMP end
end, 0, 1000)
numberBox("Gravity", "gravity", function() workspace.Gravity = DEFAULT_GRAVITY end, 0, 1000)
numberBox("Field of view", "fov", nil, 10, 120)

section("WORLD")
toggle("Fullbright", "fullbright", setFullbright)
toggle("Anti AFK", "antiAfk", setAntiAfk)

section("CHARACTER")
button("RESET VALUES", nil, function()
	state.walk, state.jump, state.gravity, state.fov = nil, nil, nil, nil
	local h = getHum()
	if h then h.WalkSpeed, h.JumpPower = DEFAULT_WALK, DEFAULT_JUMP end
	workspace.Gravity = DEFAULT_GRAVITY
	for _, key in ipairs({ "walk", "jump", "gravity", "fov" }) do
		if boxes[key] then boxes[key].Text = "" end
	end
end)
button("RESPAWN", C.bad, function()
	local h = getHum()
	if h then h.Health = 0 end
end)
button("REJOIN SERVER", nil, function()
	pcall(function()
		if #Players:GetPlayers() <= 1 then
			TeleportService:Teleport(game.PlaceId, player)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
		end
	end)
end)

-- phone buttons for height while flying
local climbGui
setClimbButtons = function(show)
	if climbGui then climbGui:Destroy() climbGui = nil end
	climb = 0
	if not (show and TOUCH) then return end
	climbGui = new("ScreenGui", { Name = "MoonshinyMenuClimb", ResetOnSpawn = false, DisplayOrder = 100, Parent = playerGui })
	local function hold(text, y, value)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(52, 52), Position = UDim2.new(1, -72, 0.5, y), BackgroundColor3 = C.top, BackgroundTransparency = 0.15,
			Text = text, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.ink, AutoButtonColor = false, Parent = climbGui,
		})
		round(b, 10)
		outline(b)
		b.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then climb = value end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then climb = 0 end
		end)
	end
	hold("▲", -60, 1)
	hold("▼", 8, -1)
end

-- collapse
local collapsed = false
on(collapse.Activated, function()
	collapsed = not collapsed
	body.Visible = not collapsed
end)

-- drag
local dragging, dragStart, startPos
on(bar.InputBegan, function(input)
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- hotkeys
on(UIS.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then
		toggles.fly(not state.fly)
	elseif input.KeyCode == Enum.KeyCode.N then
		toggles.noclip(not state.noclip)
	elseif input.KeyCode == Enum.KeyCode.RightControl then
		gui.Enabled = not gui.Enabled
	end
end)

----------------------------------------------------------------------
-- CLEANUP (close button, running the script again, or Stop in the executor)
----------------------------------------------------------------------
local function cleanup()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	stopFly()
	restoreCollision()
	setFullbright(false)
	setAntiAfk(false)
	if climbGui then climbGui:Destroy() end
	workspace.Gravity = DEFAULT_GRAVITY
	local h = getHum()
	if h then h.WalkSpeed, h.JumpPower = DEFAULT_WALK, DEFAULT_JUMP end
	gui:Destroy()
	shared.MoonshinyMenu = nil
end
shared.MoonshinyMenu = cleanup
closeBtn.Activated:Connect(cleanup)
if onStop then onStop(cleanup) end

print("moonshiny menu loaded · F fly · N noclip · RightControl hide")
