-- NEMESIS-STYLE UI - HIDE PLAYERS (Xeno Max Compatibility)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safely determine where to parent the UI
local TargetGuiService = (typeof(gethui) == "function" and gethui()) or PlayerGui

-- Prevent duplicate UI
local existing = TargetGuiService:FindFirstChild("NemesisHidePlayersGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- THEME
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
	Danger       = Color3.fromRGB(220, 90, 90),
	Success      = Color3.fromRGB(60, 180, 110),
}

local OPEN_SIZE        = UDim2.new(0, 320, 0, 460)
local COLLAPSED_HEIGHT = 60
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local CUSTOM_LOGO_ID = "rbxassetid://107541043103322"

--------------------------------------------------------------------------------
-- HELPERS
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
	btn.Size = props.Size or UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle
	btn.BackgroundTransparency = props.BackgroundTransparency or 0.25
	btn.AutoButtonColor = false
	btn.Text = props.Text or ""
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = props.TextSize or 12
	btn.TextColor3 = props.TextColor3 or THEME.TextPrimary
	btn.Parent = parent
	corner(btn, UDim.new(0, 10))
	local btnStroke = stroke(btn, THEME.Stroke, 1)
	btnStroke.Transparency = 0.3

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = THEME.ButtonHover, BackgroundTransparency = 0.1 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Accent, Transparency = 0 }, HOVER_TWEEN_INFO)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {
			BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle,
			BackgroundTransparency = props.BackgroundTransparency or 0.25
		}, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)

	return btn
end

--------------------------------------------------------------------------------
-- LOGIC
--------------------------------------------------------------------------------
local ScriptActive = false
local HideAllMode = false
local HiddenPlayers = {}
local HideFolder = Instance.new("Folder")
HideFolder.Name = "HiddenPlayersBin"

local function RestoreAllM()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character.Parent == HideFolder then
			plr.Character.Parent = workspace
		end
	end
end

RunService.RenderStepped:Connect(function()
	if not ScriptActive then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local shouldHide = HideAllMode or HiddenPlayers[plr]

			if shouldHide then
				if plr.Character and plr.Character:IsDescendantOf(workspace) then
					-- Teleport the character far out of the map to break spatial audio/voice chat range
					plr.Character:PivotTo(CFrame.new(999999, 999999, 999999))
					
					-- Then move them into the HideFolder
					plr.Character.Parent = HideFolder
				end
			else
				if plr.Character and plr.Character.Parent == HideFolder then
					-- Put them back in the map
					plr.Character.Parent = workspace
					-- (The server will automatically snap their position back to where they actually are)
				end
			end
		end
	end
end)

--------------------------------------------------------------------------------
-- MAIN UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisHidePlayersGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGuiService

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -160, 0.5, -230)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 22))
stroke(frame, THEME.Stroke, 1.3)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, THEME.Background),
})
gradient.Rotation = 90
gradient.Parent = frame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundTransparency = 1
titleBar.Size = UDim2.new(1, 0, 0, 60)
titleBar.Parent = frame

local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.BackgroundTransparency = 1
logo.Size = UDim2.new(0, 32, 0, 32)
logo.Position = UDim2.new(0, 14, 0.5, -16)
logo.Image = CUSTOM_LOGO_ID
logo.Parent = titleBar
corner(logo, UDim.new(0, 10))

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 180, 0, 24)
title.Position = UDim2.new(0, 56, 0.5, -12)
title.Text = "NEMESIS HIDE PLAYERS"
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = THEME.TextPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = makeButton(titleBar, { Text = "–", Size = UDim2.new(0, 26, 0, 26) })
minBtn.Position = UDim2.new(1, -66, 0, 16)

local closeBtn = makeButton(titleBar, {
	Text = "×",
	Size = UDim2.new(0, 26, 0, 26),
	TextColor3 = THEME.Danger
})
closeBtn.Position = UDim2.new(1, -34, 0, 16)
closeBtn.TextSize = 18

local divider = Instance.new("Frame")
divider.BackgroundColor3 = THEME.Stroke
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, 60)
divider.Parent = frame

-- Content
local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 14, 0, 70)
content.Size = UDim2.new(1, -28, 1, -84)
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = content

--------------------------------------------------------------------------------
-- TOGGLE BUILDER
--------------------------------------------------------------------------------
local function createToggleRow(labelText, initialState, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = content
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 40, 0, 22)
	bg.Position = UDim2.new(1, -52, 0.5, -11)
	bg.BackgroundColor3 = initialState and THEME.Accent or THEME.Stroke
	bg.BorderSizePixel = 0
	bg.Parent = row
	corner(bg, UDim.new(1, 0))

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 16, 0, 16)
	circle.Position = initialState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = bg
	corner(circle, UDim.new(1, 0))

	local on = initialState
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = row

	local api = {
		setOn = function(val)
			on = val
			if on then
				tween(bg, { BackgroundColor3 = THEME.Accent })
				circle:TweenPosition(UDim2.new(1, -19, 0.5, -8), "Out", "Quad", 0.15, true)
			else
				tween(bg, { BackgroundColor3 = THEME.Stroke })
				circle:TweenPosition(UDim2.new(0, 3, 0.5, -8), "Out", "Quad", 0.15, true)
			end
		end
	}

	btn.MouseButton1Click:Connect(function()
		on = not on
		api.setOn(on)
		callback(on)
	end)

	return api
end

--------------------------------------------------------------------------------
-- TOGGLES
--------------------------------------------------------------------------------
local activeToggle = createToggleRow("Active", false, function(on)
	ScriptActive = on
	if not on then
		RestoreAllM()
	end
end)

local hideAllToggle = createToggleRow("Hide All", false, function(on)
	HideAllMode = on
end)

--------------------------------------------------------------------------------
-- PLAYER LIST
--------------------------------------------------------------------------------
local listCard = Instance.new("Frame")
listCard.Size = UDim2.new(1, 0, 0, 280)
listCard.BackgroundColor3 = THEME.ButtonIdle
listCard.BackgroundTransparency = 0.25
listCard.Parent = content
corner(listCard, UDim.new(0, 10))
stroke(listCard, THEME.Stroke, 1).Transparency = 0.3

local listHeader = Instance.new("Frame")
listHeader.Size = UDim2.new(1, -16, 0, 28)
listHeader.Position = UDim2.new(0, 8, 0, 8)
listHeader.BackgroundTransparency = 1
listHeader.Parent = listCard

local listLabel = Instance.new("TextLabel")
listLabel.Size = UDim2.new(0.55, 0, 1, 0)
listLabel.BackgroundTransparency = 1
listLabel.Text = "Player List (Click to Hide)"
listLabel.Font = Enum.Font.GothamBold
listLabel.TextSize = 12
listLabel.TextColor3 = THEME.TextMuted
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = listHeader

local resetAllBtn = makeButton(listHeader, {
	Text = "Reset All",
	Size = UDim2.new(0, 80, 0, 24),
	BackgroundColor3 = THEME.Danger,
	BackgroundTransparency = 0,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
})
resetAllBtn.Position = UDim2.new(1, -80, 0.5, -12)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -16, 1, -44)
playerScroll.Position = UDim2.new(0, 8, 0, 40)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 4
playerScroll.ScrollBarImageColor3 = THEME.Accent
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.Parent = listCard

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6)
playerLayout.SortOrder = Enum.SortOrder.Name
playerLayout.Parent = playerScroll

local playerButtons = {}

local function updateButtonVis(btn, player)
	if HiddenPlayers[player] then
		btn.BackgroundColor3 = THEME.Danger
		btn.BackgroundTransparency = 0
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = player.DisplayName .. " [HIDDEN]"
	else
		btn.BackgroundColor3 = THEME.ButtonIdle
		btn.BackgroundTransparency = 0.15
		btn.TextColor3 = THEME.TextPrimary
		btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	end
end

local function createPlayerButton(player)
	local btn = makeButton(playerScroll, {
		Text = player.DisplayName .. " (@" .. player.Name .. ")",
		Size = UDim2.new(1, 0, 0, 32),
		TextSize = 12,
		BackgroundTransparency = 0.15,
	})

	updateButtonVis(btn, player)

	btn.MouseButton1Click:Connect(function()
		if not HiddenPlayers[player] then
			HiddenPlayers[player] = true
		else
			HiddenPlayers[player] = nil
		end
		updateButtonVis(btn, player)
	end)

	playerButtons[player] = btn
	return btn
end

local function refreshPlayerList()
	for _, btn in pairs(playerButtons) do
		btn:Destroy()
	end
	playerButtons = {}

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			createPlayerButton(plr)
		end
	end

	playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 8)
end

refreshPlayerList()

Players.PlayerAdded:Connect(function(plr)
	if plr ~= LocalPlayer then
		createPlayerButton(plr)
		playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 8)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	HiddenPlayers[plr] = nil
	if playerButtons[plr] then
		playerButtons[plr]:Destroy()
		playerButtons[plr] = nil
		playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 8)
	end
end)

resetAllBtn.MouseButton1Click:Connect(function()
	HiddenPlayers = {}
	hideAllToggle.setOn(false)
	HideAllMode = false
	for player, btn in pairs(playerButtons) do
		if player.Parent then
			updateButtonVis(btn, player)
		end
	end
	RestoreAllM()
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	RestoreAllM()
	gui:Destroy()
end)

gui.Destroying:Connect(function()
	RestoreAllM()
end)

local minimized = false
local expandedSize = OPEN_SIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size
		content.Visible = false
		divider.Visible = false
		tween(frame, { Size = UDim2.new(0, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
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
local draggingWindow, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = false
	end
end)
