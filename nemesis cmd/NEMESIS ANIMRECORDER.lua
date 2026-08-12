-- NEMESIS TEMPLATE UI + ANIMATION RECORDER INTEGRATION (WITH LOGO)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate UI instances
local existing = CoreGui:FindFirstChild("TemplateAnimRecorderGui") or PlayerGui:FindFirstChild("TemplateAnimRecorderGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- UI THEME & CONFIGURATION
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
	StatusRecord = Color3.fromRGB(231, 76, 60),
	StatusPlay   = Color3.fromRGB(46, 204, 113),
}

local OPEN_SIZE        = UDim2.new(0, 360, 0, 480)
local COLLAPSED_HEIGHT = 60
local MIN_SIZE         = Vector2.new(300, 320)
local MAX_SIZE         = Vector2.new(580, 680)
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
		tween(btn, { BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle, BackgroundTransparency = props.BackgroundTransparency or 0.25 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)

	return btn
end

--------------------------------------------------------------------------------
-- MAIN UI CONSTRUCTION
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TemplateAnimRecorderGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -180, 0.5, -240)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 22))
local frameStroke = stroke(frame, THEME.Stroke, 1.3)

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

-- Restored Logo Image Component
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.BackgroundTransparency = 1
logo.Size = UDim2.new(0, 32, 0, 32)
logo.Position = UDim2.new(0, 14, 0.5, -16)
logo.Image = "rbxassetid://107541043103322"
logo.Parent = titleBar
corner(logo, UDim.new(0, 10))

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 180, 0, 24)
title.Position = UDim2.new(0, 56, 0.5, -12)
title.Text = "NEMESIS ANIM RECORDER"
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
-- SEARCH & RECORDING UI ELEMENTS
--------------------------------------------------------------------------------
local searchContainer = Instance.new("Frame")
searchContainer.Size = UDim2.new(1, 0, 0, 50)
searchContainer.BackgroundTransparency = 1
searchContainer.Parent = content

local searchLabel = Instance.new("TextLabel")
searchLabel.Size = UDim2.new(1, 0, 0, 16)
searchLabel.BackgroundTransparency = 1
searchLabel.Font = Enum.Font.GothamBold
searchLabel.Text = "Target Player:"
searchLabel.TextColor3 = THEME.TextPrimary
searchLabel.TextSize = 12
searchLabel.TextXAlignment = Enum.TextXAlignment.Left
searchLabel.Parent = searchContainer

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 0, 30)
searchBox.Position = UDim2.new(0, 0, 0, 18)
searchBox.BackgroundColor3 = THEME.Panel
searchBox.TextColor3 = THEME.TextPrimary
searchBox.PlaceholderText = "Search display/username..."
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.Text = ""
searchBox.Parent = searchContainer
corner(searchBox, UDim.new(0, 8))
stroke(searchBox, THEME.Stroke, 1)

local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size = UDim2.new(1, 0, 0, 0)
dropdownFrame.Position = UDim2.new(0, 0, 0, 50)
dropdownFrame.BackgroundColor3 = THEME.Panel
dropdownFrame.Visible = false
dropdownFrame.ZIndex = 10
dropdownFrame.Parent = searchContainer
corner(dropdownFrame, UDim.new(0, 8))
stroke(dropdownFrame, THEME.Stroke, 1)

local dropdownLayout = Instance.new("UIListLayout")
dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownLayout.Parent = dropdownFrame

local recordBtn = makeButton(content, { Text = "START RECORDING", Size = UDim2.new(1, 0, 0, 36), TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = THEME.StatusRecord, BackgroundTransparency = 0 })

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = THEME.TextMuted
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = content

local clipsHeader = Instance.new("TextLabel")
clipsHeader.Size = UDim2.new(1, 0, 0, 18)
clipsHeader.BackgroundTransparency = 1
clipsHeader.Font = Enum.Font.GothamBold
clipsHeader.Text = "Saved Clips"
clipsHeader.TextColor3 = THEME.TextPrimary
clipsHeader.TextSize = 13
clipsHeader.TextXAlignment = Enum.TextXAlignment.Left
clipsHeader.Parent = content

local clipsContainer = Instance.new("Frame")
clipsContainer.Size = UDim2.new(1, 0, 0, 0)
clipsContainer.AutomaticSize = Enum.AutomaticSize.Y
clipsContainer.BackgroundTransparency = 1
clipsContainer.Parent = content

local clipsLayout = Instance.new("UIListLayout")
clipsLayout.Padding = UDim.new(0, 8)
clipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
clipsLayout.Parent = clipsContainer

--------------------------------------------------------------------------------
-- DRAGGING & RESIZING LOGIC
--------------------------------------------------------------------------------
local resizeHandle = Instance.new("Frame")
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -4, 1, -4)
resizeHandle.Size = UDim2.new(0, 20, 0, 20)
resizeHandle.BackgroundTransparency = 1
resizeHandle.ZIndex = 5
resizeHandle.Parent = frame

local resizeCursor = Instance.new("TextButton")
resizeCursor.BackgroundTransparency = 1
resizeCursor.Text = ""
resizeCursor.Size = UDim2.new(1, 0, 1, 0)
resizeCursor.Parent = resizeHandle

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

local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--------------------------------------------------------------------------------
-- ANIMATION RECORDER CORE SYSTEM
--------------------------------------------------------------------------------
local RecordingClip = false
local CurrentClip = {}
local SavedClips = {}
local LoopingClips = {}
local KeyBinds = {}
local SelectedPlayer = nil
local CurrentlyPlayingClip = nil
local CurrentStopFunc = nil
local TrackingAnimations = false
local AnimationTracks = {}

local SaveFileName = "AnimationClips_" .. LocalPlayer.UserId .. ".json"

local function SaveClipsToFile()
	if writefile then
		pcall(function()
			writefile(SaveFileName, HttpService:JSONEncode(SavedClips))
		end)
	end
end

local function SaveKeybinds()
	if writefile then
		pcall(function()
			local kbData = {}
			for id, key in pairs(KeyBinds) do
				kbData[id] = key.Name
			end
			writefile("AnimationKeybinds_" .. LocalPlayer.UserId .. ".json", HttpService:JSONEncode(kbData))
		end)
	end
end

local function LoadSavedClips()
	if readfile and isfile and isfile(SaveFileName) then
		pcall(function()
			SavedClips = HttpService:JSONDecode(readfile(SaveFileName))
		end)
	end
end

local function FindPlayer(searchText)
	if searchText == "" then return {} end
	local results = {}
	for _, p in pairs(Players:GetPlayers()) do
		if string.lower(p.Name):find(string.lower(searchText)) or string.lower(p.DisplayName):find(string.lower(searchText)) then
			table.insert(results, p)
		end
		if #results >= 5 then break end
	end
	return results
end

local function GenerateClipName(playerName)
	local baseName = playerName .. "'s clip"
	local highestNumber = 0
	for _, clip in ipairs(SavedClips) do
		if clip.PlayerName == playerName then
			local clipNumber = clip.Name:match(baseName .. " (%d+)")
			if clipNumber then
				clipNumber = tonumber(clipNumber)
				if clipNumber and clipNumber > highestNumber then
					highestNumber = clipNumber
				end
			end
		end
	end
	return highestNumber == 0 and (baseName .. " 1") or (baseName .. " " .. (highestNumber + 1))
end

local function StartTrackingAnimations(target)
	if not target then return end
	local character = target.Character or target.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	TrackingAnimations = true
	AnimationTracks = {}

	CurrentClip = {
		Name = GenerateClipName(target.Name),
		PlayerName = target.Name,
		Events = {},
		StartTime = tick(),
	}

	local equippedTool = nil
	for _, item in pairs(character:GetChildren()) do
		if item:IsA("Tool") then equippedTool = item break end
	end

	local toolConnection = character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then equippedTool = child end
	end)
	local toolRemovedConnection = character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == equippedTool then equippedTool = nil end
	end)

	local function UpdateAnimationTracks()
		local tracks = animator:GetPlayingAnimationTracks()
		local currentTime = tick() - CurrentClip.StartTime

		for _, track in pairs(tracks) do
			local trackId = track.Animation.AnimationId
			local skipTrack = false
			if equippedTool then
				if trackId:match("tool") or trackId:match("equip") or trackId:match("weapon") then
					skipTrack = true
				end
			end

			if not skipTrack then
				if not AnimationTracks[trackId] or AnimationTracks[trackId].Stopped then
					AnimationTracks[trackId] = {
						Track = track,
						Stopped = false,
						StartTime = currentTime,
						LastTimePosition = track.TimePosition,
						LastUpdateTime = currentTime,
						LastSpeed = track.Speed,
						IsFrozen = false
					}
					table.insert(CurrentClip.Events, {
						Type = "Start",
						AnimationId = trackId,
						Time = currentTime,
						Speed = track.Speed,
						Weight = track.WeightCurrent,
						TimePosition = track.TimePosition
					})
				else
					local trackData = AnimationTracks[trackId]
					local isFrozen = math.abs(track.TimePosition - trackData.LastTimePosition) < 0.01 and track.Speed ~= 0
					if isFrozen ~= trackData.IsFrozen then
						table.insert(CurrentClip.Events, { Type = "Freeze", AnimationId = trackId, Time = currentTime, IsFrozen = isFrozen })
						trackData.IsFrozen = isFrozen
					end
					if math.abs(track.Speed - trackData.LastSpeed) > 0.01 then
						table.insert(CurrentClip.Events, { Type = "Speed", AnimationId = trackId, Time = currentTime, Speed = track.Speed })
						trackData.LastSpeed = track.Speed
					end
					trackData.Track = track
					trackData.LastTimePosition = track.TimePosition
					trackData.LastUpdateTime = currentTime
				end
			end
		end

		for id, data in pairs(AnimationTracks) do
			if not data.Stopped then
				local stillPlaying = false
				for _, track in pairs(tracks) do
					if track.Animation.AnimationId == id then stillPlaying = true break end
				end
				if not stillPlaying then
					data.Stopped = true
					table.insert(CurrentClip.Events, { Type = "Stop", AnimationId = id, Time = currentTime, FinalPosition = data.LastTimePosition })
				end
			end
		end
	end

	task.spawn(function()
		while TrackingAnimations do
			UpdateAnimationTracks()
			task.wait(0.03)
		end
		toolConnection:Disconnect()
		toolRemovedConnection:Disconnect()
	end)
end

local function StopTrackingAnimations()
	TrackingAnimations = false
	if CurrentClip and #CurrentClip.Events > 0 then
		CurrentClip.Duration = tick() - CurrentClip.StartTime
		CurrentClip.Id = HttpService:GenerateGUID(false)
		table.insert(SavedClips, CurrentClip)
		SaveClipsToFile()
		return true
	end
	return false
end

local PlayClip

local function RefreshClipsList()
	for _, child in pairs(clipsContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for index, clip in ipairs(SavedClips) do
		local clipFrame = Instance.new("Frame")
		clipFrame.Size = UDim2.new(1, 0, 0, 60)
		clipFrame.BackgroundColor3 = THEME.Panel
		clipFrame.Parent = clipsContainer
		corner(clipFrame, UDim.new(0, 8))
		stroke(clipFrame, THEME.Stroke, 1)

		local nameBox = Instance.new("TextBox")
		nameBox.Size = UDim2.new(0.65, 0, 0, 24)
		nameBox.Position = UDim2.new(0, 8, 0, 4)
		nameBox.BackgroundTransparency = 1
		nameBox.Font = Enum.Font.GothamBold
		nameBox.TextColor3 = THEME.TextPrimary
		nameBox.TextSize = 12
		nameBox.Text = clip.Name
		nameBox.TextXAlignment = Enum.TextXAlignment.Left
		nameBox.Parent = clipFrame

		nameBox.FocusLost:Connect(function()
			clip.Name = nameBox.Text
			SaveClipsToFile()
		end)

		local durLabel = Instance.new("TextLabel")
		durLabel.Size = UDim2.new(0.3, 0, 0, 24)
		durLabel.Position = UDim2.new(0.68, 0, 0, 4)
		durLabel.BackgroundTransparency = 1
		durLabel.Font = Enum.Font.Gotham
		durLabel.TextColor3 = THEME.TextMuted
		durLabel.TextSize = 10
		durLabel.Text = string.format("%.1fs", clip.Duration or 0)
		durLabel.Parent = clipFrame

		local actions = Instance.new("Frame")
		actions.Size = UDim2.new(1, -16, 0, 24)
		actions.Position = UDim2.new(0, 8, 0, 30)
		actions.BackgroundTransparency = 1
		actions.Parent = clipFrame

		local playBtn = makeButton(actions, { Text = "PLAY", Size = UDim2.new(0.23, 0, 1, 0) })
		playBtn.Position = UDim2.new(0, 0, 0, 0)

		local loopBtn = makeButton(actions, { Text = "LOOP", Size = UDim2.new(0.23, 0, 1, 0) })
		loopBtn.Position = UDim2.new(0.25, 0, 0, 0)

		local keybindBtn = makeButton(actions, { Text = KeyBinds[clip.Id] and KeyBinds[clip.Id].Name or "KEYBIND", Size = UDim2.new(0.25, 0, 1, 0) })
		keybindBtn.Position = UDim2.new(0.50, 0, 0, 0)

		local delBtn = makeButton(actions, { Text = "DEL", Size = UDim2.new(0.20, 0, 1, 0), TextColor3 = Color3.fromRGB(230, 80, 80) })
		delBtn.Position = UDim2.new(0.78, 0, 0, 0)

		local stopFunc = nil
		playBtn.MouseButton1Click:Connect(function()
			if stopFunc then
				stopFunc()
				stopFunc = nil
				playBtn.Text = "PLAY"
				return
			end
			stopFunc = PlayClip(clip, LoopingClips[clip.Id] or false)
			CurrentStopFunc = stopFunc
			playBtn.Text = "STOP"
		end)

		loopBtn.MouseButton1Click:Connect(function()
			LoopingClips[clip.Id] = not LoopingClips[clip.Id]
			loopBtn.BackgroundColor3 = LoopingClips[clip.Id] and THEME.Accent or THEME.ButtonIdle
		end)

		keybindBtn.MouseButton1Click:Connect(function()
			keybindBtn.Text = "PRESS..."
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gpe)
				if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
					KeyBinds[clip.Id] = input.KeyCode
					keybindBtn.Text = input.KeyCode.Name
					SaveKeybinds()
					conn:Disconnect()
				end
			end)
		end)

		delBtn.MouseButton1Click:Connect(function()
			if CurrentlyPlayingClip == clip.Id and CurrentStopFunc then CurrentStopFunc() end
			table.remove(SavedClips, index)
			KeyBinds[clip.Id] = nil
			SaveClipsToFile()
			RefreshClipsList()
		end)
	end
end

PlayClip = function(clip, loop)
	if CurrentStopFunc then CurrentStopFunc() CurrentStopFunc = nil end

	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop() end

	local clipTracks = {}
	CurrentlyPlayingClip = clip.Id

	local startTime = tick()
	local eventsProcessed = {}

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > clip.Duration and not loop then
			connection:Disconnect()
			for _, t in pairs(clipTracks) do if t.Track then t.Track:Stop() end end
			CurrentlyPlayingClip = nil
			RefreshClipsList()
			return
		end
		if loop and elapsed > clip.Duration then
			startTime = tick()
			table.clear(eventsProcessed)
			elapsed = 0
		end

		for i, event in ipairs(clip.Events) do
			if not eventsProcessed[i] and elapsed >= event.Time then
				eventsProcessed[i] = true
				if event.Type == "Start" then
					local anim = Instance.new("Animation")
					anim.AnimationId = event.AnimationId
					local track = animator:LoadAnimation(anim)
					track:AdjustSpeed(event.Speed or 1)
					if event.TimePosition then track.TimePosition = event.TimePosition end
					track:Play()
					clipTracks[event.AnimationId] = { Track = track }
				elseif event.Type == "Stop" and clipTracks[event.AnimationId] then
					clipTracks[event.AnimationId].Track:Stop()
				elseif event.Type == "Speed" and clipTracks[event.AnimationId] then
					clipTracks[event.AnimationId].Track:AdjustSpeed(event.Speed)
				end
			end
		end
	end)

	return function()
		connection:Disconnect()
		CurrentlyPlayingClip = nil
		for _, t in pairs(clipTracks) do if t.Track then t.Track:Stop() end end
		RefreshClipsList()
	end
end

--------------------------------------------------------------------------------
-- SEARCH & EVENT BINDINGS
--------------------------------------------------------------------------------
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = searchBox.Text
	for _, child in pairs(dropdownFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local results = FindPlayer(text)
	if #results == 0 then
		dropdownFrame.Visible = false
		return
	end

	for i, player in ipairs(results) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 24)
		btn.BackgroundTransparency = 1
		btn.Font = Enum.Font.Gotham
		btn.TextColor3 = THEME.TextPrimary
		btn.TextSize = 11
		btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
		btn.Parent = dropdownFrame

		btn.MouseButton1Click:Connect(function()
			SelectedPlayer = player
			searchBox.Text = player.DisplayName
			dropdownFrame.Visible = false
			statusLabel.Text = "Target: " .. player.DisplayName
		end)
	end
	dropdownFrame.Size = UDim2.new(1, 0, 0, 24 * #results)
	dropdownFrame.Visible = true
end)

recordBtn.MouseButton1Click:Connect(function()
	if not RecordingClip then
		local target = SelectedPlayer or LocalPlayer
		RecordingClip = true
		recordBtn.Text = "STOP RECORDING"
		statusLabel.Text = "Recording " .. target.DisplayName .. "..."
		StartTrackingAnimations(target)
	else
		RecordingClip = false
		recordBtn.Text = "START RECORDING"
		statusLabel.Text = "Status: Idle"
		if StopTrackingAnimations() then
			RefreshClipsList()
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		for id, key in pairs(KeyBinds) do
			if key == input.KeyCode then
				for _, clip in ipairs(SavedClips) do
					if clip.Id == id then
						PlayClip(clip, LoopingClips[clip.Id] or false)
						break
					end
				end
			end
		end
	end
end)

-- Initialization
LoadSavedClips()
RefreshClipsList()