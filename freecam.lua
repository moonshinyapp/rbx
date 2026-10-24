-- moonshiny.app // Freecam
-- Detach the camera and fly it around. Your character stays where it is.
-- WASD move · E/Space up · Q down · hold right mouse to look · Shift = fast · P or run again = exit

if shared.MoonshinyFreecam then
	shared.MoonshinyFreecam()
	return
end

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")

local camera = workspace.CurrentCamera
local oldType = camera.CameraType
local SPEED, FAST = 40, 3
local SENS = 0.004

local pos = camera.CFrame.Position
local pitch, yaw = camera.CFrame:ToEulerAnglesYXZ()

camera.CameraType = Enum.CameraType.Scriptable

-- stop the character from walking while the keys drive the camera
local SINK = "MoonshinyFreecamSink"
CAS:BindActionAtPriority(SINK, function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 1,
	Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight,
	Enum.PlayerActions.CharacterJump)

local conns = {}
local function key(k)
	return UIS:IsKeyDown(k)
end

table.insert(conns, RunService.RenderStepped:Connect(function(dt)
	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		local d = UIS:GetMouseDelta()
		yaw -= d.X * SENS
		pitch = math.clamp(pitch - d.Y * SENS, -1.5, 1.5)
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end

	local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local dir = Vector3.zero
	if UIS:GetFocusedTextBox() == nil then
		if key(Enum.KeyCode.W) then dir += rot.LookVector end
		if key(Enum.KeyCode.S) then dir -= rot.LookVector end
		if key(Enum.KeyCode.D) then dir += rot.RightVector end
		if key(Enum.KeyCode.A) then dir -= rot.RightVector end
		if key(Enum.KeyCode.E) or key(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if key(Enum.KeyCode.Q) then dir -= Vector3.yAxis end
	end
	if dir.Magnitude > 0 then
		local speed = SPEED * ((key(Enum.KeyCode.LeftShift) or key(Enum.KeyCode.RightShift)) and FAST or 1)
		pos += dir.Unit * speed * dt
	end
	camera.CFrame = CFrame.new(pos) * rot
end))

local function stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	CAS:UnbindAction(SINK)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	camera.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
	shared.MoonshinyFreecam = nil
	print("freecam off")
end

table.insert(conns, UIS.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
		stop()
	end
end))

shared.MoonshinyFreecam = stop
print("freecam on · WASD/E/Q · right mouse to look · Shift fast · P to exit")
