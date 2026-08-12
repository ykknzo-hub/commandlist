local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Clean up any existing instances
local existing = pg:FindFirstChild("TouchFlingGui")
if existing then existing:Destroy() end

-------------------------------------------------
-- Theme & Layout Configuration
-------------------------------------------------
local THEME = {
	Background   = Color3.fromRGB(244, 249, 255),
	Panel        = Color3.fromRGB(255, 255, 255),
	Accent       = Color3.fromRGB(66, 140, 235),
	Stroke       = Color3.fromRGB(198, 220, 240),
	TextPrimary  = Color3.fromRGB(30, 50, 72),
	TextMuted    = Color3.fromRGB(120, 140, 162),
	ButtonIdle   = Color3.fromRGB(255, 255, 255),
	ButtonHover  = Color3.fromRGB(224, 238, 252),
	ToggleOn     = Color3.fromRGB(66, 140, 235),
	ToggleOff    = Color3.fromRGB(200, 210, 225),
}

local OPEN_SIZE        = UDim2.new(0, 310, 0, 220)
local COLLAPSED_HEIGHT = 60
local MIN_SIZE         = Vector2.new(250, 160)
local MAX_SIZE         = Vector2.new(500, 450)
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-------------------------------------------------
-- Helper Utilities
-------------------------------------------------
local function tween(instance, props, info)
	local t = TweenService:Create(instance, info or TWEEN_INFO, props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 14)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.Stroke
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function makeButton(parent, props)
	local btn = Instance.new("TextButton")
	btn.Size = props.Size or UDim2.new(0, 26, 0, 26)
	btn.BackgroundColor3 = THEME.ButtonIdle
	btn.BackgroundTransparency = 0.25
	btn.AutoButtonColor = false
	btn.Text = props.Text or ""
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = props.TextSize or 14
	btn.TextColor3 = props.TextColor3 or THEME.TextPrimary
	btn.Parent = parent
	corner(btn, UDim.new(0, 12))
	local btnStroke = stroke(btn, THEME.Stroke, 1)
	btnStroke.Transparency = 0.3

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = THEME.ButtonHover, BackgroundTransparency = 0.1 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Accent, Transparency = 0 }, HOVER_TWEEN_INFO)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = THEME.ButtonIdle, BackgroundTransparency = 0.25 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, { Size = btn.Size - UDim2.new(0, 2, 0, 2) }, HOVER_TWEEN_INFO)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, { Size = props.Size or UDim2.new(0, 26, 0, 26) }, HOVER_TWEEN_INFO)
	end)

	return btn
end

-------------------------------------------------
-- Core Physics & State Logic
-------------------------------------------------
local Config = {
	FLING_STRENGTH = 500000,
	MOVEMENT_DELTA = 0.1
}

local State = {
	isAlive = true,
	isResetting = false,
	flingEnabled = false,
	collisionEnabled = false,
	character = nil,
	root = nil,
	humanoid = nil,
	velocity = nil,
}

local function setupCharacter()
	State.character = lp.Character
	if State.character then
		State.root = State.character:FindFirstChild("HumanoidRootPart")
		State.humanoid = State.character:FindFirstChild("Humanoid")
		
		if State.humanoid then
			State.humanoid.Died:Connect(function()
				State.isAlive = false
			end)
		end
	end
end

setupCharacter()

lp.CharacterAdded:Connect(function(newCharacter)
	State.isResetting = true
	task.wait(0.2)
	if newCharacter == lp.Character then
		setupCharacter()
		State.isAlive = true
	end
	State.isResetting = false
end)

-- Fixed No-Clip Handler (Applies directly to LocalPlayer character parts)
RunService.Stepped:Connect(function()
	if not State.collisionEnabled or not State.character then return end
	
	for _, part in ipairs(State.character:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end
end)

-- Fling Physics Loop
RunService.Heartbeat:Connect(function()
	if not State.flingEnabled or State.isResetting or not State.isAlive then return end
	if not (State.character and State.character.Parent and State.root and State.root.Parent) then return end
	
	if not State.humanoid or State.humanoid.Health <= 0 then
		State.isAlive = false
		return
	end
	
	State.velocity = State.root.Velocity
	State.root.Velocity = State.velocity * Config.FLING_STRENGTH + Vector3.new(0, Config.FLING_STRENGTH, 0)
	RunService.RenderStepped:Wait()
	
	if State.character and State.character.Parent and State.root and State.root.Parent then
		State.root.Velocity = State.velocity
	end
	
	RunService.Stepped:Wait()
	
	if State.character and State.character.Parent and State.root and State.root.Parent then
		State.root.Velocity = State.velocity + Vector3.new(0, Config.MOVEMENT_DELTA, 0)
		Config.MOVEMENT_DELTA = Config.MOVEMENT_DELTA * -1
	end
end)

-------------------------------------------------
-- Main Interface Framing
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TouchFlingGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217" 
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 1
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(30, 30, 98, 98)
shadow.Size = UDim2.new(1, 50, 1, 50)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.ZIndex = 0

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -155, 0.5, -110)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.18
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 26))
local frameStroke = stroke(frame, THEME.Stroke, 1.3)
frameStroke.LineJoinMode = Enum.LineJoinMode.Round
frameStroke.Transparency = 0.15
shadow.Parent = frame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, THEME.Background),
})
gradient.Rotation = 90
gradient.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundTransparency = 1
titleBar.Size = UDim2.new(1, 0, 0, 60)
titleBar.Parent = frame

local logo = Instance.new("ImageLabel")
logo.BackgroundTransparency = 1
logo.Size = UDim2.new(0, 32, 0, 32)
logo.Position = UDim2.new(0, 14, 0.5, -16)
logo.Image = "rbxassetid://107541043103322"
logo.Parent = titleBar
corner(logo, UDim.new(0, 10))

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 160, 0, 24)
title.Position = UDim2.new(0, 56, 0.5, -12)
title.Text = "NEMESIS TOUCHFLING"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = THEME.TextPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = makeButton(titleBar, { Text = "–", Size = UDim2.new(0, 26, 0, 26) })
minBtn.Position = UDim2.new(1, -66, 0, 16)

local closeBtn = makeButton(titleBar, { Text = "×", Size = UDim2.new(0, 26, 0, 26), TextColor3 = Color3.fromRGB(220, 90, 90) })
closeBtn.Position = UDim2.new(1, -34, 0, 16)
closeBtn.TextSize = 18

local divider = Instance.new("Frame")
divider.BackgroundColor3 = THEME.Stroke
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, 60)
divider.Parent = frame

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.new(0, 14, 0, 70)
content.Size = UDim2.new(1, -28, 1, -84)
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = THEME.Accent
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = content

local resizeHandle = Instance.new("Frame")
resizeHandle.Name = "ResizeHandle"
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -4, 1, -4)
resizeHandle.Size = UDim2.new(0, 20, 0, 20)
resizeHandle.BackgroundTransparency = 1
resizeHandle.ZIndex = 5
resizeHandle.Parent = frame

for i = 0, 2 do
	for j = 0, i do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 3, 0, 3)
		dot.BackgroundColor3 = THEME.Stroke
		dot.BackgroundTransparency = 0.2
		dot.BorderSizePixel = 0
		dot.AnchorPoint = Vector2.new(1, 1)
		dot.Position = UDim2.new(1, -6 - (i * 6), 1, -6 - (j * 6))
		dot.Parent = resizeHandle
		corner(dot, UDim.new(1, 0))
	end
end

local resizeCursor = Instance.new("TextButton")
resizeCursor.BackgroundTransparency = 1
resizeCursor.Text = ""
resizeCursor.Size = UDim2.new(1, 0, 1, 0)
resizeCursor.AutoButtonColor = false
resizeCursor.Parent = resizeHandle

-------------------------------------------------
-- Interactivity (Drag, Resize, Minimize, Close)
-------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	local t = tween(frame, { Size = UDim2.new(0, 310, 0, 0), BackgroundTransparency = 1 })
	t.Completed:Connect(function()
		gui:Destroy()
	end)
end)

local minimized = false
local expandedSize = OPEN_SIZE 
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size 
		content.Visible = false
		divider.Visible = false
		resizeHandle.Visible = false
		tween(frame, { Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			divider.Visible = true
			resizeHandle.Visible = true
		end)
		minBtn.Text = "–"
	end
end)

local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then updateDrag(input) end
end)

local resizing = false
local resizeInput, resizeStart, sizeStart

local function updateResize(input)
	local delta = input.Position - resizeStart
	local newWidth = math.clamp(sizeStart.X.Offset + delta.X, MIN_SIZE.X, MAX_SIZE.X)
	local newHeight = math.clamp(sizeStart.Y.Offset + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)

	frame.Size = UDim2.new(sizeStart.X.Scale, newWidth, sizeStart.Y.Scale, newHeight)
	expandedSize = frame.Size
end

resizeCursor.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStart = input.Position
		sizeStart = frame.Size

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then resizing = false end
		end)
	end
end)

resizeCursor.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		resizeInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and input == resizeInput then updateResize(input) end
end)

resizeCursor.MouseEnter:Connect(function()
	for _, dot in ipairs(resizeHandle:GetChildren()) do
		if dot:IsA("Frame") then
			tween(dot, { BackgroundColor3 = THEME.Accent, BackgroundTransparency = 0 }, HOVER_TWEEN_INFO)
		end
	end
end)
resizeCursor.MouseLeave:Connect(function()
	for _, dot in ipairs(resizeHandle:GetChildren()) do
		if dot:IsA("Frame") then
			tween(dot, { BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.2 }, HOVER_TWEEN_INFO)
		end
	end
end)

frame.Size = UDim2.new(0, 310, 0, 0)
tween(frame, { Size = OPEN_SIZE })

-------------------------------------------------
-- UI Component Builder
-------------------------------------------------
local Window = {}

function Window:AddLabel(text)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 20)
	l.Text = text
	l.Font = Enum.Font.Gotham
	l.TextSize = 13
	l.TextColor3 = THEME.TextPrimary
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = content
	return l
end

function Window:AddToggle(text, defaultState, callback)
	local enabled = defaultState or false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundTransparency = 1
	container.Parent = content

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextColor3 = THEME.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local switchBg = Instance.new("TextButton")
	switchBg.Text = ""
	switchBg.AutoButtonColor = false
	switchBg.Size = UDim2.new(0, 44, 0, 22)
	switchBg.Position = UDim2.new(1, -44, 0.5, -11)
	switchBg.BackgroundColor3 = enabled and THEME.ToggleOn or THEME.ToggleOff
	switchBg.Parent = container
	corner(switchBg, UDim.new(1, 0))

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = switchBg
	corner(knob, UDim.new(1, 0))

	switchBg.MouseButton1Click:Connect(function()
		enabled = not enabled
		local targetPos = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		local targetBg = enabled and THEME.ToggleOn or THEME.ToggleOff
		tween(knob, { Position = targetPos }, HOVER_TWEEN_INFO)
		tween(switchBg, { BackgroundColor3 = targetBg }, HOVER_TWEEN_INFO)

		if callback then callback(enabled) end
	end)

	return container
end

-------------------------------------------------
-- Attach UI Controls
-------------------------------------------------
Window:AddLabel("noclip is buggy.. for now.")

Window:AddToggle("Enable Fling", false, function(state)
	State.flingEnabled = state
end)

Window:AddToggle("Enable No-Clip", false, function(state)
	State.collisionEnabled = state
end)

return Window