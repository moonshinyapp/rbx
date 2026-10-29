-- moonshiny.app // Freecam  (v2)
-- Detach the camera and fly it around. Your character stays where it is (frozen while the freecam is on).
--   PC     WASD move · E / Space up · Q down · hold right mouse to look · Shift fast · Ctrl slow
--          mouse wheel = speed · Ctrl + wheel = field of view · P or run again = exit
--   Phone  thumbstick moves · drag the right half of the screen to look · ▲ ▼ buttons for height · × to exit
-- Tune live:  shared.MoonshinyFreecamConfig.Speed = 80

if shared.MoonshinyFreecam then
	shared.MoonshinyFreecam()
	return
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local config = shared.MoonshinyFreecamConfig or {}
shared.MoonshinyFreecamConfig = config
for k, v in pairs({ Speed = 40, Fast = 3, Slow = 0.25, Sensitivity = 0.004, TouchSensitivity = 0.006, Smooth = 12, Fov = nil }) do
	if config[k] == nil then config[k] = v end
end

local TOUCH = UIS.TouchEnabled and not UIS.KeyboardEnabled
local old = { type = camera.CameraType, subject = camera.CameraSubject, fov = camera.FieldOfView }

local pitch, yaw = camera.CFrame:ToEulerAnglesYXZ()
local pos = camera.CFrame.Position
local velocity = Vector3.zero
local fov = config.Fov or camera.FieldOfView
local conns = {}
local function track(c) table.insert(conns, c) return c end

-- freeze the character (client side) so it does not walk or fall while the camera is away
local frozen = {}
local function freeze()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and not frozen.root then
		frozen.root, frozen.anchored = root, root.Anchored
		root.Anchored = true
	end
end
local function unfreeze()
	if frozen.root and frozen.root.Parent then frozen.root.Anchored = frozen.anchored end
	frozen = {}
end
freeze()
track(player.CharacterAdded:Connect(function() task.wait(0.2) freeze() end))

camera.CameraType = Enum.CameraType.Scriptable

-- the movement keys must not reach the character
local SINK = "MoonshinyFreecamSink"
CAS:BindActionAtPriority(SINK, function() return Enum.ContextActionResult.Sink end, false,
	Enum.ContextActionPriority.High.Value + 1,
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.Space,
	Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

local function down(k) return UIS:IsKeyDown(k) end

-- on-screen buttons (phone only)
local gui, climb = nil, 0
local function makeTouchUi(close)
	gui = Instance.new("ScreenGui")
	gui.Name = "MoonshinyFreecamUi"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 102
	gui.Parent = player:WaitForChild("PlayerGui")
	local function button(text, pos, onDown, onUp)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(52, 52)
		b.Position = pos
		b.BackgroundColor3 = Color3.fromHex("141029")
		b.BackgroundTransparency = 0.15
		b.TextColor3 = Color3.fromHex("EFEAFB")
		b.Font = Enum.Font.GothamBold
		b.TextSize = 20
		b.Text = text
		b.AutoButtonColor = false
		b.Parent = gui
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromHex("31295A")
		b.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then onDown() end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then onUp() end
		end)
		return b
	end
	button("▲", UDim2.new(1, -72, 0.5, -60), function() climb = 1 end, function() climb = 0 end)
	button("▼", UDim2.new(1, -72, 0.5, 8), function() climb = -1 end, function() climb = 0 end)
	local x = button("×", UDim2.new(1, -72, 0, 12), function() end, function() close() end)
	x.TextColor3 = Color3.fromHex("FF6B81")
end

-- touch look: drag on the right half of the screen
local lookTouch, lastPos
track(UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.Touch and input.Position.X > camera.ViewportSize.X * 0.5 and not lookTouch then
		lookTouch, lastPos = input, input.Position
	end
end))
track(UIS.InputChanged:Connect(function(input)
	if input == lookTouch and lastPos then
		local d = input.Position - lastPos
		lastPos = input.Position
		yaw -= d.X * config.TouchSensitivity
		pitch = math.clamp(pitch - d.Y * config.TouchSensitivity, -1.5, 1.5)
	elseif input.UserInputType == Enum.UserInputType.MouseWheel and not UIS:GetFocusedTextBox() then
		if down(Enum.KeyCode.LeftControl) or down(Enum.KeyCode.RightControl) then
			fov = math.clamp(fov - input.Position.Z * 4, 10, 120)
		else
			config.Speed = math.clamp(config.Speed * (input.Position.Z > 0 and 1.15 or 1 / 1.15), 2, 600)
		end
	end
end))
track(UIS.InputEnded:Connect(function(input)
	if input == lookTouch then lookTouch, lastPos = nil, nil end
end))

local stop
track(RunService.RenderStepped:Connect(function(dt)
	-- look (PC: hold right mouse)
	if not TOUCH then
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local d = UIS:GetMouseDelta()
			yaw -= d.X * config.Sensitivity
			pitch = math.clamp(pitch - d.Y * config.Sensitivity, -1.5, 1.5)
		else
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local dir = Vector3.zero
	if not UIS:GetFocusedTextBox() then
		if down(Enum.KeyCode.W) then dir = dir + (rot.LookVector) end
		if down(Enum.KeyCode.S) then dir = dir - (rot.LookVector) end
		if down(Enum.KeyCode.D) then dir = dir + (rot.RightVector) end
		if down(Enum.KeyCode.A) then dir = dir - (rot.RightVector) end
		if down(Enum.KeyCode.E) or down(Enum.KeyCode.Space) then dir = dir + (Vector3.yAxis) end
		if down(Enum.KeyCode.Q) then dir = dir - (Vector3.yAxis) end
	end
	if TOUCH then
		-- the thumbstick still drives the humanoid's MoveDirection (world space): use it relative to the camera
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local move = hum and hum.MoveDirection or Vector3.zero
		if move.Magnitude > 0 then
			local flat = Vector3.new(rot.LookVector.X, 0, rot.LookVector.Z)
			flat = flat.Magnitude > 0 and flat.Unit or Vector3.zAxis
			local right = flat:Cross(Vector3.yAxis).Unit * -1
			dir += flat * move:Dot(flat) + right * move:Dot(right)
		end
		dir += Vector3.yAxis * climb
	end

	local speed = config.Speed
	if down(Enum.KeyCode.LeftShift) or down(Enum.KeyCode.RightShift) then speed = speed * config.Fast end
	if down(Enum.KeyCode.LeftControl) or down(Enum.KeyCode.RightControl) then speed = speed * config.Slow end
	local target = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
	-- smoothing: the velocity eases towards the wanted one (frame rate independent)
	velocity = velocity:Lerp(target, 1 - math.exp(-config.Smooth * dt))
	pos += velocity * dt

	camera.CFrame = CFrame.new(pos) * rot
	camera.FieldOfView = fov
end))

stop = function()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	CAS:UnbindAction(SINK)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	unfreeze()
	if gui then gui:Destroy() end
	camera.FieldOfView = old.fov
	camera.CameraType = old.type == Enum.CameraType.Scriptable and Enum.CameraType.Custom or old.type
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	camera.CameraSubject = (hum or old.subject)
	shared.MoonshinyFreecam = nil
	print("freecam off")
end

track(UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.P then stop() end
end))
if TOUCH then makeTouchUi(stop) end

shared.MoonshinyFreecam = stop
if onStop then onStop(stop) end -- the executor's Stop button ends it too
print(TOUCH and "freecam on · thumbstick moves · drag right side to look · × exits"
	or "freecam on · WASD/E/Q · right mouse look · wheel = speed · Ctrl+wheel = FOV · Shift fast · P exit")
