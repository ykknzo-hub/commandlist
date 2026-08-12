-- Combined NEMESIS Template UI + AIMLOCK Script
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local pg = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate UI instances
local existing = pg:FindFirstChild("AimlockGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- UI THEME & SIZING CONFIGURATION
--------------------------------------------------------------------------------
local THEME = {
	Background   = Color3.fromRGB(244, 249, 255),
	Panel        = Color3.fromRGB(255, 255, 255),
	Accent       = Color3.fromRGB(66, 140, 235),
	Stroke       = Color3.fromRGB(198, 220, 240),
	TextPrimary  = Color3.fromRGB(30, 50, 72),
	TextMuted    = Color3.fromRGB(120, 140, 162),
	ButtonIdle   = Color3.fromRGB(255, 255, 255),
	ButtonHover  = Color3.fromRGB(224, 238, 252),
	ToggleOn     = Color3.fromRGB(46, 204, 113),
	ToggleOff    = Color3.fromRGB(200, 210, 225),
}

local OPEN_SIZE        = UDim2.new(0, 340, 0, 600)
local COLLAPSED_HEIGHT = 60
local MIN_SIZE         = Vector2.new(280, 220)
local MAX_SIZE         = Vector2.new(560, 520)
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS FOR UI STYLING
--------------------------------------------------------------------------------
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

local function makeToggle(parent, label, defaultState, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Text = label
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextColor3 = THEME.TextPrimary
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = container

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 50, 0, 24)
	toggleBg.Position = UDim2.new(1, -60, 0.5, -12)
	toggleBg.BackgroundColor3 = defaultState and THEME.ToggleOn or THEME.ToggleOff
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	corner(toggleBg, UDim.new(1, 0))

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = defaultState and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = toggleBg
	corner(knob, UDim.new(1, 0))

	local state = defaultState
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.Parent = toggleBg

	toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		tween(toggleBg, { BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff })
		tween(knob, { Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) })
		if callback then callback(state) end
	end)

	return container, function() return state end
end

--------------------------------------------------------------------------------
-- UI CONSTRUCTION
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AimlockGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -170, 0.5, -210)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.18
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 26))
local frameStroke = stroke(frame, THEME.Stroke, 1.3)
frameStroke.LineJoinMode = Enum.LineJoinMode.Round
frameStroke.Transparency = 0.15

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
title.Size = UDim2.new(0, 180, 0, 24)
title.Position = UDim2.new(0, 56, 0.5, -12)
title.Text = "NEMESIS AIMLOCK"
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

--------------------------------------------------------------------------------
-- AIMLOCK CONFIGURATION & LOGIC
--------------------------------------------------------------------------------
local aimlockConfig = {
	Enabled = false,
	TargetPlayer = nil,
	Smoothness = 0.5,
	Sensitivity = 1.0,
	VisibleOnly = true,
	TargetTeam = false,
	Keybind = Enum.KeyCode.E,
	ToggleKeybind = Enum.KeyCode.T,
	FOVRadius = 150,
	ShowFOV = true,
	FOVColor = Color3.fromRGB(66, 140, 235),
	FOVTransparency = 0.5,
	FOVThickness = 2,
	FOVFilled = false,
	TargetPartMode = "Head",
}

local camera = workspace.CurrentCamera
local renderConnection = nil
local targetListUpdated = false

local function getAimCenter()
	local mouse = LocalPlayer:GetMouse()
	return Vector2.new(mouse.X, mouse.Y)
end

-- FOV Circle Setup
local fovCircle = nil
local function createFOVCircle()
	if fovCircle then pcall(function() fovCircle:Remove() end) end
	if not aimlockConfig.ShowFOV then return end
	
	if typeof(Drawing) == "userdata" or Drawing then
		fovCircle = Drawing.new("Circle")
		fovCircle.Visible = true
		fovCircle.Position = getAimCenter()
		fovCircle.Radius = aimlockConfig.FOVRadius
		fovCircle.Color = aimlockConfig.FOVColor
		fovCircle.Transparency = aimlockConfig.FOVTransparency
		fovCircle.Thickness = aimlockConfig.FOVThickness
		fovCircle.Filled = aimlockConfig.FOVFilled
	end
end

local function updateFOVCircle()
	if not aimlockConfig.ShowFOV or not fovCircle then return end
	if fovCircle then
		fovCircle.Position = getAimCenter()
		fovCircle.Radius = aimlockConfig.FOVRadius
		fovCircle.Color = aimlockConfig.FOVColor
		fovCircle.Transparency = aimlockConfig.FOVTransparency
		fovCircle.Thickness = aimlockConfig.FOVThickness
		fovCircle.Filled = aimlockConfig.FOVFilled
	end
end

-- Status Display
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, 0, 0, 24)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Inactive"
StatusText.TextColor3 = Color3.fromRGB(200, 50, 50)
StatusText.TextSize = 12
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = content

-- Create Toggles
local toggleEnabled, getToggleEnabled = makeToggle(content, "Enable Aimlock", false, function(state)
	aimlockConfig.Enabled = state
	if state then
		tween(StatusText, { TextColor3 = Color3.fromRGB(46, 204, 113) })
		StatusText.Text = "Status: Active (no target)"
		startAimlock()
	else
		StatusText.Text = "Status: Inactive"
		tween(StatusText, { TextColor3 = Color3.fromRGB(200, 50, 50) })
		stopAimlock()
	end
end)

local toggleVisibleOnly, getToggleVisibleOnly = makeToggle(content, "Visible Only", true, function(state)
	aimlockConfig.VisibleOnly = state
end)

local toggleTeamCheck, getToggleTeamCheck = makeToggle(content, "Ignore Team", false, function(state)
	aimlockConfig.TargetTeam = state
end)

-- Sensitivity Slider
local sensitivityContainer = Instance.new("Frame")
sensitivityContainer.Size = UDim2.new(1, 0, 0, 28)
sensitivityContainer.BackgroundTransparency = 1
sensitivityContainer.Parent = content

local sensitivityLabel = Instance.new("TextLabel")
sensitivityLabel.BackgroundTransparency = 1
sensitivityLabel.Size = UDim2.new(0.5, 0, 1, 0)
sensitivityLabel.Text = "Smoothness: 0.5x"
sensitivityLabel.Font = Enum.Font.Gotham
sensitivityLabel.TextSize = 12
sensitivityLabel.TextColor3 = THEME.TextPrimary
sensitivityLabel.TextXAlignment = Enum.TextXAlignment.Left
sensitivityLabel.Parent = sensitivityContainer

local sensitivitySlider = Instance.new("Frame")
sensitivitySlider.Size = UDim2.new(0.4, 0, 0, 4)
sensitivitySlider.Position = UDim2.new(0.55, 0, 0.5, -2)
sensitivitySlider.BackgroundColor3 = THEME.Stroke
sensitivitySlider.BorderSizePixel = 0
sensitivitySlider.Parent = sensitivityContainer
corner(sensitivitySlider, UDim.new(1, 0))

local sensitivityFill = Instance.new("Frame")
sensitivityFill.Size = UDim2.new(0.5, 0, 1, 0)
sensitivityFill.BackgroundColor3 = THEME.Accent
sensitivityFill.BorderSizePixel = 0
sensitivityFill.Parent = sensitivitySlider
corner(sensitivityFill, UDim.new(1, 0))

local sensitivityButton = Instance.new("TextButton")
sensitivityButton.BackgroundColor3 = THEME.Accent
sensitivityButton.BorderSizePixel = 0
sensitivityButton.Text = ""
sensitivityButton.Size = UDim2.new(0, 12, 1, 6)
sensitivityButton.Position = UDim2.new(0.5, -6, 0.5, -3)
sensitivityButton.AutoButtonColor = false
sensitivityButton.Parent = sensitivitySlider
corner(sensitivityButton, UDim.new(1, 0))

local isDragging = false
sensitivityButton.MouseButton1Down:Connect(function()
	isDragging = true
	local mouse = LocalPlayer:GetMouse()
	
	while isDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - sensitivitySlider.AbsolutePosition.X) / sensitivitySlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.Smoothness = math.round(relX * 100) / 100
		sensitivityFill.Size = UDim2.new(relX, 0, 1, 0)
		sensitivityButton.Position = UDim2.new(relX, -6, 0.5, -3)
		sensitivityLabel.Text = "Smoothness: " .. string.format("%.2f", aimlockConfig.Smoothness) .. "x"
		task.wait()
	end
	isDragging = false
end)

-- FOV Radius Slider
local fovContainer = Instance.new("Frame")
fovContainer.Size = UDim2.new(1, 0, 0, 28)
fovContainer.BackgroundTransparency = 1
fovContainer.Parent = content

local fovLabel = Instance.new("TextLabel")
fovLabel.BackgroundTransparency = 1
fovLabel.Size = UDim2.new(0.5, 0, 1, 0)
fovLabel.Text = "FOV Radius: 150"
fovLabel.Font = Enum.Font.Gotham
fovLabel.TextSize = 12
fovLabel.TextColor3 = THEME.TextPrimary
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Parent = fovContainer

local fovSlider = Instance.new("Frame")
fovSlider.Size = UDim2.new(0.4, 0, 0, 4)
fovSlider.Position = UDim2.new(0.55, 0, 0.5, -2)
fovSlider.BackgroundColor3 = THEME.Stroke
fovSlider.BorderSizePixel = 0
fovSlider.Parent = fovContainer
corner(fovSlider, UDim.new(1, 0))

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(0.5, 0, 1, 0)
fovFill.BackgroundColor3 = THEME.Accent
fovFill.BorderSizePixel = 0
fovFill.Parent = fovSlider
corner(fovFill, UDim.new(1, 0))

local fovButton = Instance.new("TextButton")
fovButton.BackgroundColor3 = THEME.Accent
fovButton.BorderSizePixel = 0
fovButton.Text = ""
fovButton.Size = UDim2.new(0, 12, 1, 6)
fovButton.Position = UDim2.new(0.5, -6, 0.5, -3)
fovButton.AutoButtonColor = false
fovButton.Parent = fovSlider
corner(fovButton, UDim.new(1, 0))

local isFovDragging = false
fovButton.MouseButton1Down:Connect(function()
	isFovDragging = true
	local mouse = LocalPlayer:GetMouse()
	
	while isFovDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - fovSlider.AbsolutePosition.X) / fovSlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.FOVRadius = math.round(50 + relX * 400)
		fovFill.Size = UDim2.new(relX, 0, 1, 0)
		fovButton.Position = UDim2.new(relX, -6, 0.5, -3)
		fovLabel.Text = "FOV Radius: " .. aimlockConfig.FOVRadius
		task.wait()
	end
	isFovDragging = false
end)

-- FOV Display Toggle
local toggleFOV, getToggleFOV = makeToggle(content, "Show FOV Circle", true, function(state)
	aimlockConfig.ShowFOV = state
	if aimlockConfig.Enabled then
		if state then
			createFOVCircle()
		else
			if fovCircle then
				pcall(function() fovCircle:Remove() end)
				fovCircle = nil
			end
		end
	end
end)

-- FOV Transparency Slider
local fovTransContainer = Instance.new("Frame")
fovTransContainer.Size = UDim2.new(1, 0, 0, 28)
fovTransContainer.BackgroundTransparency = 1
fovTransContainer.Parent = content

local fovTransLabel = Instance.new("TextLabel")
fovTransLabel.BackgroundTransparency = 1
fovTransLabel.Size = UDim2.new(0.5, 0, 1, 0)
fovTransLabel.Text = "Transparency: 0.50"
fovTransLabel.Font = Enum.Font.Gotham
fovTransLabel.TextSize = 12
fovTransLabel.TextColor3 = THEME.TextPrimary
fovTransLabel.TextXAlignment = Enum.TextXAlignment.Left
fovTransLabel.Parent = fovTransContainer

local fovTransSlider = Instance.new("Frame")
fovTransSlider.Size = UDim2.new(0.4, 0, 0, 4)
fovTransSlider.Position = UDim2.new(0.55, 0, 0.5, -2)
fovTransSlider.BackgroundColor3 = THEME.Stroke
fovTransSlider.BorderSizePixel = 0
fovTransSlider.Parent = fovTransContainer
corner(fovTransSlider, UDim.new(1, 0))

local fovTransFill = Instance.new("Frame")
fovTransFill.Size = UDim2.new(0.5, 0, 1, 0)
fovTransFill.BackgroundColor3 = THEME.Accent
fovTransFill.BorderSizePixel = 0
fovTransFill.Parent = fovTransSlider
corner(fovTransFill, UDim.new(1, 0))

local fovTransButton = Instance.new("TextButton")
fovTransButton.BackgroundColor3 = THEME.Accent
fovTransButton.BorderSizePixel = 0
fovTransButton.Text = ""
fovTransButton.Size = UDim2.new(0, 12, 1, 6)
fovTransButton.Position = UDim2.new(0.5, -6, 0.5, -3)
fovTransButton.AutoButtonColor = false
fovTransButton.Parent = fovTransSlider
corner(fovTransButton, UDim.new(1, 0))

local isTransDragging = false
fovTransButton.MouseButton1Down:Connect(function()
	isTransDragging = true
	local mouse = LocalPlayer:GetMouse()
	
	while isTransDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - fovTransSlider.AbsolutePosition.X) / fovTransSlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.FOVTransparency = math.round(relX * 100) / 100
		fovTransFill.Size = UDim2.new(relX, 0, 1, 0)
		fovTransButton.Position = UDim2.new(relX, -6, 0.5, -3)
		fovTransLabel.Text = "Transparency: " .. string.format("%.2f", aimlockConfig.FOVTransparency)
		task.wait()
	end
	isTransDragging = false
end)

-- FOV Thickness Slider
local fovThickContainer = Instance.new("Frame")
fovThickContainer.Size = UDim2.new(1, 0, 0, 28)
fovThickContainer.BackgroundTransparency = 1
fovThickContainer.Parent = content

local fovThickLabel = Instance.new("TextLabel")
fovThickLabel.BackgroundTransparency = 1
fovThickLabel.Size = UDim2.new(0.5, 0, 1, 0)
fovThickLabel.Text = "Thickness: 2"
fovThickLabel.Font = Enum.Font.Gotham
fovThickLabel.TextSize = 12
fovThickLabel.TextColor3 = THEME.TextPrimary
fovThickLabel.TextXAlignment = Enum.TextXAlignment.Left
fovThickLabel.Parent = fovThickContainer

local fovThickSlider = Instance.new("Frame")
fovThickSlider.Size = UDim2.new(0.4, 0, 0, 4)
fovThickSlider.Position = UDim2.new(0.55, 0, 0.5, -2)
fovThickSlider.BackgroundColor3 = THEME.Stroke
fovThickSlider.BorderSizePixel = 0
fovThickSlider.Parent = fovThickContainer
corner(fovThickSlider, UDim.new(1, 0))

local fovThickFill = Instance.new("Frame")
fovThickFill.Size = UDim2.new(0.5, 0, 1, 0)
fovThickFill.BackgroundColor3 = THEME.Accent
fovThickFill.BorderSizePixel = 0
fovThickFill.Parent = fovThickSlider
corner(fovThickFill, UDim.new(1, 0))

local fovThickButton = Instance.new("TextButton")
fovThickButton.BackgroundColor3 = THEME.Accent
fovThickButton.BorderSizePixel = 0
fovThickButton.Text = ""
fovThickButton.Size = UDim2.new(0, 12, 1, 6)
fovThickButton.Position = UDim2.new(0.5, -6, 0.5, -3)
fovThickButton.AutoButtonColor = false
fovThickButton.Parent = fovThickSlider
corner(fovThickButton, UDim.new(1, 0))

local isThickDragging = false
fovThickButton.MouseButton1Down:Connect(function()
	isThickDragging = true
	local mouse = LocalPlayer:GetMouse()
	
	while isThickDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - fovThickSlider.AbsolutePosition.X) / fovThickSlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.FOVThickness = math.max(1, math.round(relX * 8))
		fovThickFill.Size = UDim2.new(relX, 0, 1, 0)
		fovThickButton.Position = UDim2.new(relX, -6, 0.5, -3)
		fovThickLabel.Text = "Thickness: " .. aimlockConfig.FOVThickness
		task.wait()
	end
	isThickDragging = false
end)

-- FOV Color Picker
local colorOptions = {
	Color3.fromRGB(66, 140, 235),   -- Blue
	Color3.fromRGB(255, 0, 0),      -- Red
	Color3.fromRGB(0, 255, 0),      -- Green
	Color3.fromRGB(255, 255, 0),    -- Yellow
	Color3.fromRGB(255, 165, 0),    -- Orange
	Color3.fromRGB(255, 0, 255),    -- Magenta
	Color3.fromRGB(0, 255, 255),    -- Cyan
}
local colorIndex = 1

local fovColorContainer = Instance.new("Frame")
fovColorContainer.Size = UDim2.new(1, 0, 0, 28)
fovColorContainer.BackgroundTransparency = 1
fovColorContainer.Parent = content

local fovColorLabel = Instance.new("TextLabel")
fovColorLabel.BackgroundTransparency = 1
fovColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
fovColorLabel.Text = "Circle Color"
fovColorLabel.Font = Enum.Font.Gotham
fovColorLabel.TextSize = 12
fovColorLabel.TextColor3 = THEME.TextPrimary
fovColorLabel.TextXAlignment = Enum.TextXAlignment.Left
fovColorLabel.Parent = fovColorContainer

local fovColorBtn = Instance.new("TextButton")
fovColorBtn.Size = UDim2.new(0, 50, 0, 20)
fovColorBtn.Position = UDim2.new(0.72, 0, 0.5, -10)
fovColorBtn.BackgroundColor3 = aimlockConfig.FOVColor
fovColorBtn.Text = "✓"
fovColorBtn.Font = Enum.Font.GothamBold
fovColorBtn.TextSize = 14
fovColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fovColorBtn.BorderSizePixel = 0
fovColorBtn.AutoButtonColor = false
fovColorBtn.Parent = fovColorContainer
corner(fovColorBtn, UDim.new(0, 3))

fovColorBtn.MouseButton1Click:Connect(function()
	colorIndex = colorIndex % #colorOptions + 1
	aimlockConfig.FOVColor = colorOptions[colorIndex]
	fovColorBtn.BackgroundColor3 = aimlockConfig.FOVColor
end)

-- FOV Filled Toggle
local toggleFOVFilled, getToggleFOVFilled = makeToggle(content, "Filled Circle", false, function(state)
	aimlockConfig.FOVFilled = state
end)

-- Target Part Selector
local targetPartContainer = Instance.new("Frame")
targetPartContainer.Size = UDim2.new(1, 0, 0, 28)
targetPartContainer.BackgroundTransparency = 1
targetPartContainer.Parent = content

local targetPartLabel = Instance.new("TextLabel")
targetPartLabel.BackgroundTransparency = 1
targetPartLabel.Size = UDim2.new(0.6, 0, 1, 0)
targetPartLabel.Text = "Target Part"
targetPartLabel.Font = Enum.Font.Gotham
targetPartLabel.TextSize = 12
targetPartLabel.TextColor3 = THEME.TextPrimary
targetPartLabel.TextXAlignment = Enum.TextXAlignment.Left
targetPartLabel.Parent = targetPartContainer

local targetPartButton = makeButton(targetPartContainer, { Text = aimlockConfig.TargetPartMode, Size = UDim2.new(0, 70, 1, 0) })
targetPartButton.Position = UDim2.new(1, -82, 0, 0)
targetPartButton.MouseButton1Click:Connect(function()
	if aimlockConfig.TargetPartMode == "Head" then
		aimlockConfig.TargetPartMode = "Torso"
		targetPartButton.Text = "Torso"
	else
		aimlockConfig.TargetPartMode = "Head"
		targetPartButton.Text = "Head"
	end
end)

-- Info Text
local keybindContainer = Instance.new("Frame")
keybindContainer.Size = UDim2.new(1, 0, 0, 28)
keybindContainer.BackgroundTransparency = 1
keybindContainer.Parent = content

local keybindLabel = Instance.new("TextLabel")
keybindLabel.BackgroundTransparency = 1
keybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
keybindLabel.Text = "Toggle Keybind"
keybindLabel.Font = Enum.Font.Gotham
keybindLabel.TextSize = 12
keybindLabel.TextColor3 = THEME.TextPrimary
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.Parent = keybindContainer

local keybindButton = makeButton(keybindContainer, { Text = aimlockConfig.ToggleKeybind.Name, Size = UDim2.new(0, 50, 1, 0) })
keybindButton.Position = UDim2.new(1, -60, 0, 0)

local awaitingKeybind = false
keybindButton.MouseButton1Click:Connect(function()
	if awaitingKeybind then return end
	awaitingKeybind = true
	keybindButton.Text = "..."
	
	local connection
	connection = UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			aimlockConfig.ToggleKeybind = input.KeyCode
			keybindButton.Text = input.KeyCode.Name
			connection:Disconnect()
			awaitingKeybind = false
		end
	end)
	
	task.wait(5)
	if awaitingKeybind then
		awaitingKeybind = false
		keybindButton.Text = aimlockConfig.ToggleKeybind.Name
		connection:Disconnect()
	end
end)

-- Info Text
local infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.Size = UDim2.new(1, 0, 0, 50)
infoText.BackgroundTransparency = 1
infoText.Text = "Press " .. aimlockConfig.ToggleKeybind.Name .. " to toggle aimlock.\nPress E to cycle targets.\nAim at enemies to lock on."
infoText.TextColor3 = THEME.TextMuted
infoText.TextSize = 11
infoText.Font = Enum.Font.Gotham
infoText.TextWrapped = true
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.Parent = content

--------------------------------------------------------------------------------
-- AIMLOCK CORE FUNCTIONS
--------------------------------------------------------------------------------
local function getTargetPart(player)
	if not player or not player.Character then return nil end
	local char = player.Character
	if aimlockConfig.TargetPartMode == "Torso" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	end
	return char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

local function isPlayerVisible(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return false end
	local targetChar = targetPlayer.Character
	local targetPart = getTargetPart(targetPlayer)
	if not targetPart then return false end

	local camera = workspace.CurrentCamera
	local rayOrigin = camera.CFrame.Position
	local rayDirection = (targetPart.Position - rayOrigin).Unit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

	local result = workspace:Raycast(rayOrigin, rayDirection * 500, raycastParams)
	if result then
		return result.Instance:IsDescendantOf(targetChar)
	end
	return true
end

local function isEnemy(player)
	if player == LocalPlayer then return false end
	local targetPart = getTargetPart(player)
	if not player.Character or not targetPart then return false end
	if not aimlockConfig.TargetTeam then
		if player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
			return false
		end
	end
	if aimlockConfig.VisibleOnly and not isPlayerVisible(player) then return false end
	return true
end

local function getClosestEnemy()
	local closest = nil
	local closestScore = math.huge
	local center = getAimCenter()

	for _, player in pairs(Players:GetPlayers()) do
		if isEnemy(player) then
			local targetPart = getTargetPart(player)
			if targetPart then
				local partPos = targetPart.Position
				local screenPos, onScreen = camera:WorldToScreenPoint(partPos)
				
				if onScreen then
					local screenVector = Vector2.new(screenPos.X, screenPos.Y)
					local distToCenter = (screenVector - center).Magnitude
					
					if distToCenter <= aimlockConfig.FOVRadius then
						local distance = (partPos - camera.CFrame.Position).Magnitude
						local score = distToCenter + (distance * 0.1)
						if score < closestScore then
							closestScore = score
							closest = player
						end
					end
				end
			end
		end
	end

	return closest
end

local function aimAtTarget(target)
	if not target or not target.Character then return end
	local targetPart = getTargetPart(target)
	if not targetPart then return end

	local currentCFrame = camera.CFrame
	local targetPosition = targetPart.Position + (targetPart.AssemblyLinearVelocity * 0.1)
	if aimlockConfig.TargetPartMode == "Torso" then
		targetPosition = targetPosition + Vector3.new(0, 0.25, 0)
	end
	local targetCFrame = CFrame.new(currentCFrame.Position, targetPosition)
	
	-- Smoothness ranges from 0 to 1, where higher = smoother/slower
	local alpha = aimlockConfig.Smoothness * 0.15
	alpha = math.clamp(alpha, 0.05, 0.15)
	camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
end

local function updateAutoTarget()
	local nearest = getClosestEnemy()
	if nearest then
		aimlockConfig.TargetPlayer = nearest
		StatusText.Text = "Status: Locked on " .. nearest.DisplayName
		tween(StatusText, { TextColor3 = Color3.fromRGB(66, 140, 235) })
		return
	end

	if aimlockConfig.TargetPlayer and aimlockConfig.TargetPlayer.Parent then
		local targetPart = getTargetPart(aimlockConfig.TargetPlayer)
		if targetPart then
			local partPos = targetPart.Position
			local screenPos, onScreen = camera:WorldToScreenPoint(partPos)
			if onScreen then
				local center = getAimCenter()
				local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
				if distToCenter <= aimlockConfig.FOVRadius then
					return
				end
			end
		end
	end

	aimlockConfig.TargetPlayer = nil
	StatusText.Text = "Status: Active (no target)"
	tween(StatusText, { TextColor3 = Color3.fromRGB(46, 204, 113) })
end

function startAimlock()
	if renderConnection then renderConnection:Disconnect() end
	createFOVCircle()
	renderConnection = RunService.RenderStepped:Connect(function()
		if not aimlockConfig.Enabled then return end
		
		updateFOVCircle()
		updateAutoTarget()

		if aimlockConfig.TargetPlayer and aimlockConfig.TargetPlayer.Parent then
			aimAtTarget(aimlockConfig.TargetPlayer)
		else
			aimlockConfig.TargetPlayer = nil
		end
	end)
end

function stopAimlock()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if fovCircle then
		pcall(function() fovCircle:Remove() end)
		fovCircle = nil
	end
end

-- Keybind to cycle targets
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Toggle aimlock on/off
	if input.KeyCode == aimlockConfig.ToggleKeybind then
		aimlockConfig.Enabled = not aimlockConfig.Enabled
		if aimlockConfig.Enabled then
			tween(StatusText, { TextColor3 = Color3.fromRGB(46, 204, 113) })
			StatusText.Text = "Status: Active (no target)"
			startAimlock()
		else
			StatusText.Text = "Status: Inactive"
			tween(StatusText, { TextColor3 = Color3.fromRGB(200, 50, 50) })
			stopAimlock()
		end
	end
	
	-- Cycle targets
	if input.KeyCode == aimlockConfig.Keybind and aimlockConfig.Enabled then
		local closest = getClosestEnemy()
		if closest then
			aimlockConfig.TargetPlayer = closest
			StatusText.Text = "Status: Locked on " .. closest.DisplayName
			tween(StatusText, { TextColor3 = Color3.fromRGB(66, 140, 235) })
		else
			aimlockConfig.TargetPlayer = nil
			StatusText.Text = "Status: Active (no target)"
			tween(StatusText, { TextColor3 = Color3.fromRGB(46, 204, 113) })
		end
	end
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	aimlockConfig.Enabled = false
	stopAimlock()
	if fovCircle then
		pcall(function() fovCircle:Remove() end)
		fovCircle = nil
	end
	local t = tween(frame, { Size = UDim2.new(0, 340, 0, 0), BackgroundTransparency = 1 })
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
		tween(frame, { Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			divider.Visible = true
		end)
		minBtn.Text = "–"
	end
end)

-- Dragging
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
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updateDrag(input)
	end
end)

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
frame.Size = UDim2.new(0, 340, 0, 0)
tween(frame, { Size = OPEN_SIZE })
