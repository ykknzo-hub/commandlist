-- NEMESIS-STYLE UI - BASEPLATE EXPANDER (Xeno Max Compatibility)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safely determine where to parent the UI
local TargetGuiService = (typeof(gethui) == "function" and gethui()) or PlayerGui

-- Prevent duplicate UI
local existing = TargetGuiService:FindFirstChild("NemesisBaseplateGui")
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
}

local OPEN_SIZE        = UDim2.new(0, 320, 0, 420)
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
-- BASEPLATE LOGIC (unchanged)
--------------------------------------------------------------------------------
local bpSize = 2048
local bpHeight = 15.9
local bpColor = Color3.fromRGB(115, 231, 117)
local bpMaterial = Enum.Material.Plastic
local bpEnabled = false
local bpInfinite = false
local customBaseplate = nil

local loadedChunks = {}
local baseplateFolder = nil
local lastBpSize = bpSize

local function clearInfiniteChunks()
	if baseplateFolder then
		baseplateFolder:Destroy()
		baseplateFolder = nil
	end
	table.clear(loadedChunks)
end

local function updateBaseplate()
	if bpEnabled and not bpInfinite then
		if not customBaseplate then
			customBaseplate = Instance.new("Part")
			customBaseplate.Name = "NemesisBaseplate"
			customBaseplate.Anchored = true
			customBaseplate.TopSurface = Enum.SurfaceType.Smooth
			customBaseplate.BottomSurface = Enum.SurfaceType.Smooth
			customBaseplate.Parent = workspace
		end
		customBaseplate.Size = Vector3.new(bpSize, bpHeight, bpSize)
		customBaseplate.CFrame = CFrame.new(8, -8, -482.000031)
		customBaseplate.Color = bpColor
		customBaseplate.Material = bpMaterial
	else
		if customBaseplate then
			customBaseplate:Destroy()
			customBaseplate = nil
		end
	end

	if bpEnabled and bpInfinite then
		for _, chunk in pairs(loadedChunks) do
			chunk.Size = Vector3.new(chunk.Size.X, bpHeight, chunk.Size.Z)
			chunk.Color = bpColor
			chunk.Material = bpMaterial
			chunk.CFrame = CFrame.new(chunk.Position.X, -8, chunk.Position.Z)
		end
	else
		clearInfiniteChunks()
	end
end

local function getChunkPos(x, z, size)
	return math.floor(x / size), math.floor(z / size)
end

local function createChunk(chunkX, chunkZ, size, height)
	local key = chunkX .. "_" .. chunkZ
	if loadedChunks[key] then return end

	if not baseplateFolder then
		baseplateFolder = Instance.new("Folder")
		baseplateFolder.Name = "NemesisInfiniteBaseplate"
		baseplateFolder.Parent = workspace
	end

	local chunk = Instance.new("Part")
	chunk.Name = "Chunk_" .. key
	chunk.Size = Vector3.new(size, height, size)
	chunk.CFrame = CFrame.new(chunkX * size + size / 2, -8, chunkZ * size + size / 2)
	chunk.Anchored = true
	chunk.CanCollide = true
	chunk.TopSurface = Enum.SurfaceType.Smooth
	chunk.BottomSurface = Enum.SurfaceType.Smooth
	chunk.Color = bpColor
	chunk.Material = bpMaterial
	chunk.Parent = baseplateFolder

	loadedChunks[key] = chunk
end

local function removeDistantChunks(playerX, playerZ, size)
	local renderDistance = 3
	local px, pz = getChunkPos(playerX, playerZ, size)

	for key, chunk in pairs(loadedChunks) do
		local cx, cz = key:match("([^_]+)_([^_]+)")
		if cx and cz then
			cx, cz = tonumber(cx), tonumber(cz)
			local distX = math.abs(cx - px)
			local distZ = math.abs(cz - pz)

			if distX > renderDistance + 1 or distZ > renderDistance + 1 then
				chunk:Destroy()
				loadedChunks[key] = nil
			end
		end
	end
end

local function updateChunks()
	if not (bpEnabled and bpInfinite) then return end

	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	if lastBpSize ~= bpSize then
		lastBpSize = bpSize
		clearInfiniteChunks()
		return
	end

	local pos = char.HumanoidRootPart.Position
	local size = math.max(bpSize, 128)
	local px, pz = getChunkPos(pos.X, pos.Z, size)
	local renderDistance = 3

	for x = -renderDistance, renderDistance do
		for z = -renderDistance, renderDistance do
			createChunk(px + x, pz + z, size, bpHeight)
		end
	end

	removeDistantChunks(pos.X, pos.Z, size)
end

task.spawn(function()
	while true do
		updateChunks()
		task.wait(0.3)
	end
end)

--------------------------------------------------------------------------------
-- MAIN UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisBaseplateGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGuiService

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -160, 0.5, -210)
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
title.Size = UDim2.new(0, 200, 0, 24)
title.Position = UDim2.new(0, 56, 0.5, -12)
title.Text = "NEMESIS BASEPLATE"
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

-- Tabs
local tabContainer = Instance.new("Frame")
tabContainer.BackgroundTransparency = 1
tabContainer.Size = UDim2.new(1, -28, 0, 32)
tabContainer.Position = UDim2.new(0, 14, 0, 70)
tabContainer.Parent = frame

local tab1Btn = makeButton(tabContainer, {
	Text = "Size",
	Size = UDim2.new(0.5, -6, 1, 0),
	BackgroundColor3 = THEME.Accent,
	BackgroundTransparency = 0,
	TextColor3 = Color3.fromRGB(255, 255, 255),
})
tab1Btn.Position = UDim2.new(0, 0, 0, 0)

local tab2Btn = makeButton(tabContainer, {
	Text = "Style",
	Size = UDim2.new(0.5, -6, 1, 0),
	BackgroundTransparency = 0.25,
})
tab2Btn.Position = UDim2.new(0.5, 6, 0, 0)

-- Content
local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 14, 0, 112)
content.Size = UDim2.new(1, -28, 1, -126)
content.Parent = frame

local page1 = Instance.new("Frame")
page1.Size = UDim2.new(1, 0, 1, 0)
page1.BackgroundTransparency = 1
page1.Parent = content
page1.Visible = true

local page2 = Instance.new("Frame")
page2.Size = UDim2.new(1, 0, 1, 0)
page2.BackgroundTransparency = 1
page2.Parent = content
page2.Visible = false

local p1Layout = Instance.new("UIListLayout")
p1Layout.Padding = UDim.new(0, 10)
p1Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
p1Layout.Parent = page1

--------------------------------------------------------------------------------
-- SLIDER BUILDER
--------------------------------------------------------------------------------
local function createSlider(parent, labelText, minV, maxV, defV, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = parent
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.5, 0, 0, 18)
	label.Position = UDim2.new(0, 12, 0, 6)
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.new(0.3, 0, 0, 18)
	valLbl.Position = UDim2.new(0.45, 0, 0, 6)
	valLbl.Text = tostring(defV)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 12
	valLbl.TextColor3 = THEME.Accent
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	local resetBtn = makeButton(row, {
		Text = "reset",
		Size = UDim2.new(0, 42, 0, 18),
		TextSize = 10,
		BackgroundTransparency = 0.15,
	})
	resetBtn.Position = UDim2.new(1, -54, 0, 6)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 6)
	track.Position = UDim2.new(0, 12, 0, 34)
	track.BackgroundColor3 = THEME.Stroke
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, UDim.new(1, 0))

	local pct = (defV - minV) / (maxV - minV)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct, 0, 1, 0)
	fill.BackgroundColor3 = THEME.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, UDim.new(1, 0))

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 16, 0, 16)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(pct, 0, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 4
	thumb.Parent = track
	corner(thumb, UDim.new(1, 0))
	stroke(thumb, THEME.Accent, 2)

	local sliding = false

	local function setValue(v)
		local r = math.clamp((v - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(r, 0, 1, 0)
		thumb.Position = UDim2.new(r, 0, 0.5, 0)
		valLbl.Text = tostring(v)
		callback(v)
	end

	local function update(ix)
		local tp = track.AbsolutePosition.X
		local ts = track.AbsoluteSize.X
		local r = math.clamp((ix - tp) / ts, 0, 1)
		local v = math.floor((minV + (maxV - minV) * r) * 10 + 0.5) / 10
		setValue(v)
	end

	resetBtn.MouseButton1Click:Connect(function()
		setValue(defV)
	end)

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			update(i.Position.X)
		end
	end)
	track.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	thumb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
		end
	end)
	thumb.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end)
end

--------------------------------------------------------------------------------
-- TOGGLE BUILDER
--------------------------------------------------------------------------------
local function createToggleRow(parent, labelText, initialState, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = parent
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

	btn.MouseButton1Click:Connect(function()
		on = not on
		if on then
			tween(bg, { BackgroundColor3 = THEME.Accent })
			circle:TweenPosition(UDim2.new(1, -19, 0.5, -8), "Out", "Quad", 0.15, true)
		else
			tween(bg, { BackgroundColor3 = THEME.Stroke })
			circle:TweenPosition(UDim2.new(0, 3, 0.5, -8), "Out", "Quad", 0.15, true)
		end
		callback(on)
	end)
end

--------------------------------------------------------------------------------
-- PAGE 1 - SIZE
--------------------------------------------------------------------------------
createSlider(page1, "Length & Width", 10, 2000, 2048, function(v)
	bpSize = v
	updateBaseplate()
end)

createSlider(page1, "Height (Thickness)", 1, 100, 15.9, function(v)
	bpHeight = v
	updateBaseplate()
end)

createToggleRow(page1, "Enable Custom Baseplate", false, function(v)
	bpEnabled = v
	updateBaseplate()
end)

createToggleRow(page1, "Infinite Baseplate", false, function(v)
	bpInfinite = v
	updateBaseplate()
end)

--------------------------------------------------------------------------------
-- PAGE 2 - STYLE
--------------------------------------------------------------------------------
local styleScroll = Instance.new("ScrollingFrame")
styleScroll.Size = UDim2.new(1, 0, 1, 0)
styleScroll.BackgroundTransparency = 1
styleScroll.BorderSizePixel = 0
styleScroll.ScrollBarThickness = 4
styleScroll.ScrollBarImageColor3 = THEME.Accent
styleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
styleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
styleScroll.Parent = page2

local styleLayout = Instance.new("UIListLayout")
styleLayout.Padding = UDim.new(0, 12)
styleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
styleLayout.Parent = styleScroll

local function createHeader(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = THEME.TextPrimary
	lbl.TextSize = 13
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = styleScroll
end

createHeader("Materials")

local matGrid = Instance.new("Frame")
matGrid.Size = UDim2.new(1, 0, 0, 0)
matGrid.AutomaticSize = Enum.AutomaticSize.Y
matGrid.BackgroundTransparency = 1
matGrid.Parent = styleScroll

local matUIGrid = Instance.new("UIGridLayout")
matUIGrid.CellSize = UDim2.new(0, 110, 0, 28)
matUIGrid.CellPadding = UDim2.new(0, 8, 0, 8)
matUIGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
matUIGrid.Parent = matGrid

local MATERIALS = {
	{name = "Plastic", mat = Enum.Material.Plastic},
	{name = "ForceField", mat = Enum.Material.ForceField},
	{name = "Wood Planks", mat = Enum.Material.WoodPlanks},
	{name = "Neon", mat = Enum.Material.Neon},
	{name = "Ice", mat = Enum.Material.Ice},
	{name = "Glass", mat = Enum.Material.Glass},
	{name = "Grass", mat = Enum.Material.Grass},
	{name = "Cobblestone", mat = Enum.Material.Cobblestone},
}

for _, m in pairs(MATERIALS) do
	local btn = makeButton(matGrid, {
		Text = m.name,
		Size = UDim2.new(0, 110, 0, 28),
		TextSize = 11,
		BackgroundTransparency = 0.15,
	})
	btn.MouseButton1Click:Connect(function()
		bpMaterial = m.mat
		updateBaseplate()
	end)
end

createHeader("Colors")

local colGrid = Instance.new("Frame")
colGrid.Size = UDim2.new(1, 0, 0, 0)
colGrid.AutomaticSize = Enum.AutomaticSize.Y
colGrid.BackgroundTransparency = 1
colGrid.Parent = styleScroll

local colUIGrid = Instance.new("UIGridLayout")
colUIGrid.CellSize = UDim2.new(0, 36, 0, 36)
colUIGrid.CellPadding = UDim2.new(0, 8, 0, 8)
colUIGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
colUIGrid.Parent = colGrid

local COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(200, 50, 50),
	Color3.fromRGB(50, 200, 50),
	Color3.fromRGB(50, 100, 255),
	Color3.fromRGB(255, 200, 50),
	Color3.fromRGB(200, 50, 200),
	Color3.fromRGB(50, 200, 200),
	Color3.fromRGB(115, 231, 117),
	Color3.fromRGB(80, 80, 80),
}

for _, c in pairs(COLORS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 36, 0, 36)
	btn.BackgroundColor3 = c
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.Parent = colGrid
	corner(btn, UDim.new(0, 8))
	local s = stroke(btn, Color3.fromRGB(255, 255, 255), 1)
	s.Transparency = 0.4

	btn.MouseButton1Click:Connect(function()
		bpColor = c
		updateBaseplate()
	end)
end

--------------------------------------------------------------------------------
-- TAB SWITCHING
--------------------------------------------------------------------------------
local function setActiveTab(isSize)
	if isSize then
		page1.Visible = true
		page2.Visible = false
		tab1Btn.BackgroundColor3 = THEME.Accent
		tab1Btn.BackgroundTransparency = 0
		tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tab2Btn.BackgroundColor3 = THEME.ButtonIdle
		tab2Btn.BackgroundTransparency = 0.25
		tab2Btn.TextColor3 = THEME.TextPrimary
	else
		page1.Visible = false
		page2.Visible = true
		tab2Btn.BackgroundColor3 = THEME.Accent
		tab2Btn.BackgroundTransparency = 0
		tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tab1Btn.BackgroundColor3 = THEME.ButtonIdle
		tab1Btn.BackgroundTransparency = 0.25
		tab1Btn.TextColor3 = THEME.TextPrimary
	end
end

tab1Btn.MouseButton1Click:Connect(function()
	setActiveTab(true)
end)

tab2Btn.MouseButton1Click:Connect(function()
	setActiveTab(false)
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local minimized = false
local expandedSize = OPEN_SIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size
		content.Visible = false
		tabContainer.Visible = false
		divider.Visible = false
		tween(frame, { Size = UDim2.new(0, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			tabContainer.Visible = true
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
