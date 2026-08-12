-- Combined NEMESIS Template UI + SHMOST Server Finder Script (Manual Join)
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local pg = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate UI instances
local existing = pg:FindFirstChild("TemplateGui")
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
}

local OPEN_SIZE        = UDim2.new(0, 340, 0, 300)
local COLLAPSED_HEIGHT = 60
local MIN_SIZE         = Vector2.new(280, 200)
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

--------------------------------------------------------------------------------
-- UI CONSTRUCTION (TEMPLATE)
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TemplateGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -170, 0.5, -150)
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
title.Text = "NEMESIS SERVER-HOP MOST"
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
-- INTEGRATED DYNAMIC SHMOST UI ELEMENTS
--------------------------------------------------------------------------------
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, 0, 0, 36)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Ready. Press the button below to search for a server."
StatusText.TextColor3 = THEME.TextPrimary
StatusText.TextSize = 13
StatusText.Font = Enum.Font.Gotham
StatusText.TextWrapped = true
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = content

local StatsText = Instance.new("TextLabel")
StatsText.Name = "StatsText"
StatsText.Size = UDim2.new(1, 0, 0, 18)
StatsText.BackgroundTransparency = 1
StatsText.Text = "Servers analyzed: 0 | Highest found: 0 players"
StatsText.TextColor3 = THEME.TextMuted
StatsText.TextSize = 11
StatsText.Font = Enum.Font.Gotham
StatsText.TextXAlignment = Enum.TextXAlignment.Left
StatsText.Parent = content

-- Progress Bar Elements
local ProgressContainer = Instance.new("Frame")
ProgressContainer.Name = "ProgressContainer"
ProgressContainer.Size = UDim2.new(1, 0, 0, 8)
ProgressContainer.BackgroundColor3 = THEME.Stroke
ProgressContainer.BackgroundTransparency = 0.5
ProgressContainer.BorderSizePixel = 0
ProgressContainer.Parent = content
corner(ProgressContainer, UDim.new(1, 0))

local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = THEME.Accent
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressContainer
corner(ProgressBar, UDim.new(1, 0))

local ProgressGlow = Instance.new("Frame")
ProgressGlow.Name = "ProgressGlow"
ProgressGlow.Size = UDim2.new(1, 4, 1, 4)
ProgressGlow.Position = UDim2.new(0, -2, 0, -2)
ProgressGlow.BackgroundColor3 = THEME.Accent
ProgressGlow.BackgroundTransparency = 0.7
ProgressGlow.BorderSizePixel = 0
ProgressGlow.Parent = ProgressBar
corner(ProgressGlow, UDim.new(1, 0))

-- Action Button
local ActionButton = makeButton(content, { Text = "Find Highest Server", Size = UDim2.new(1, 0, 0, 32) })

--------------------------------------------------------------------------------
-- RESIZE HANDLE & WINDOW CONTROLS
--------------------------------------------------------------------------------
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

closeBtn.MouseButton1Click:Connect(function()
	local t = tween(frame, { Size = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1 })
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

-- Window Dragging Functionality
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

-- Window Resizing Functionality
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
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
			end
		end)
	end
end)

resizeCursor.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		resizeInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and input == resizeInput then
		updateResize(input)
	end
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

--------------------------------------------------------------------------------
-- EXACT SHMOST CONFIGURATION & LOGIC (MANUAL TRIGGER)
--------------------------------------------------------------------------------
local visitedServersFileName = "VisitedServers_" .. game.PlaceId .. ".json"
local minimumAcceptablePlayerCount = 8 
local maximumPreferredPlayerCount = math.floor(Players.MaxPlayers * 0.95) 
local minimumSpaceRequired = 1 
local maxRetries = 15 
local maxServerPages = 8 
local serverBlacklist = {} 

local ANIMATION_SPEED = 0.6
local EASE_STYLE = Enum.EasingStyle.Quart
local EASE_DIRECTION = Enum.EasingDirection.Out

local failedTeleports = {}
local targetServerFound = nil
local retryCount = 0
local isSearching = false

-- Animated Update Functions
local function AnimateStatus(message, progress)
	local textFade = TweenService:Create(StatusText, TweenInfo.new(0.2, EASE_STYLE, EASE_DIRECTION), {TextTransparency = 0.8})
	textFade:Play()
	
	textFade.Completed:Connect(function()
		StatusText.Text = message
		TweenService:Create(StatusText, TweenInfo.new(0.2, EASE_STYLE, EASE_DIRECTION), {TextTransparency = 0}):Play()
	end)
	
	local progressTween = TweenService:Create(ProgressBar, TweenInfo.new(ANIMATION_SPEED, EASE_STYLE, EASE_DIRECTION), {
		Size = UDim2.new(math.max(0.02, progress), 0, 1, 0)
	})
	progressTween:Play()
	
	local glowIntensity = 0.9 - (progress * 0.2)
	TweenService:Create(ProgressGlow, TweenInfo.new(ANIMATION_SPEED, EASE_STYLE, EASE_DIRECTION), {
		BackgroundTransparency = glowIntensity
	}):Play()
end

local function AnimateStats(serversChecked, highestPlayerCount)
	local statsFade = TweenService:Create(StatsText, TweenInfo.new(0.15, EASE_STYLE, EASE_DIRECTION), {TextTransparency = 0.6})
	statsFade:Play()
	
	statsFade.Completed:Connect(function()
		StatsText.Text = "Servers analyzed: " .. serversChecked .. " | Highest found: " .. highestPlayerCount .. " players"
		TweenService:Create(StatsText, TweenInfo.new(0.15, EASE_STYLE, EASE_DIRECTION), {TextTransparency = 0}):Play()
	end)
end

-- Visited Servers Data Persistence
local function LoadVisitedServers()
	local success, result = pcall(function()
		if not isfolder("ServerHistory") then
			makefolder("ServerHistory")
		end
		
		local filePath = "ServerHistory/" .. visitedServersFileName
		if isfile(filePath) then
			return HttpService:JSONDecode(readfile(filePath))
		else
			return {}
		end
	end)
	
	return success and result or {}
end

local function SaveVisitedServers(visitedServers)
	pcall(function()
		if not isfolder("ServerHistory") then
			makefolder("ServerHistory")
		end
		
		local filePath = "ServerHistory/" .. visitedServersFileName
		writefile(filePath, HttpService:JSONEncode(visitedServers))
	end)
end

local function AddCurrentServerToVisited(visitedServers)
	local currentServerGuid = game.JobId
	if currentServerGuid ~= "" then
		visitedServers[currentServerGuid] = {
			timestamp = os.time(),
			playerCount = #Players:GetPlayers()
		}
		SaveVisitedServers(visitedServers)
	end
end

-- Exact Http Fetching
local function GetAllServers()
	local allServers = {}
	local cursor = ""
	local pageCount = 0
	local maxRetryAttempts = 3
	
	repeat
		local success, result = false, nil
		local retryAttempt = 0
		
		repeat
			retryAttempt = retryAttempt + 1
			success, result = pcall(function()
				local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
				if cursor ~= "" then
					url = url .. "&cursor=" .. cursor
				end
				return HttpService:JSONDecode(game:HttpGet(url))
			end)
			
			if not success then
				task.wait(retryAttempt * 0.5)
			end
		until success or retryAttempt >= maxRetryAttempts
		
		if success and result and result.data then
			for _, server in ipairs(result.data) do
				if server.id and server.playing and server.maxPlayers then
					table.insert(allServers, server)
				end
			end
			
			cursor = result.nextPageCursor or ""
			pageCount = pageCount + 1
			
			AnimateStatus("Fetching server data... Page " .. pageCount .. "/" .. maxServerPages, 
						 0.1 + (pageCount / maxServerPages) * 0.3)
			task.wait(0.1)
		else
			cursor = ""
		end
	until cursor == "" or pageCount >= maxServerPages
	
	return allServers
end

-- Server Prioritization Engine
local function FindHighestPopulationServer(serverList, visitedServers, excludeServerIds)
	excludeServerIds = excludeServerIds or {}
	local bestServer = nil
	local highestPlayerCount = 0
	local serversChecked = 0
	local candidates = {}
	
	for _, server in pairs(serverList) do
		serversChecked = serversChecked + 1
		
		if excludeServerIds[server.id] or serverBlacklist[server.id] or server.id == game.JobId then
			continue
		end
		
		local playerCount = server.playing or 0
		local maxPlayers = server.maxPlayers or Players.MaxPlayers
		local spaceAvailable = maxPlayers - playerCount
		
		if playerCount < minimumAcceptablePlayerCount or spaceAvailable < minimumSpaceRequired then
			continue
		end
		
		if playerCount > maximumPreferredPlayerCount then
			continue
		end
		
		if playerCount > highestPlayerCount then
			highestPlayerCount = playerCount
		end
		
		local priority = playerCount * 100
		
		if visitedServers[server.id] then
			local timeAgo = os.time() - visitedServers[server.id].timestamp
			if timeAgo < 1800 then 
				priority = priority - 500
			elseif timeAgo < 3600 then 
				priority = priority - 200
			end
		else
			priority = priority + 100
		end
		
		local idealOccupancy = maxPlayers * 0.7
		if math.abs(playerCount - idealOccupancy) < maxPlayers * 0.2 then
			priority = priority + 50
		end
		
		table.insert(candidates, {
			server = server,
			priority = priority,
			playerCount = playerCount
		})
		
		if serversChecked % 20 == 0 then
			AnimateStats(serversChecked, highestPlayerCount)
		end
	end
	
	table.sort(candidates, function(a, b)
		return a.priority > b.priority
	end)
	
	if #candidates > 0 then
		bestServer = candidates[1].server
		AnimateStats(serversChecked, highestPlayerCount)
		return bestServer, candidates[1].priority, highestPlayerCount
	end
	
	AnimateStats(serversChecked, highestPlayerCount)
	return nil, 0, highestPlayerCount
end

-- Search Function (No Auto Teleport)
local function SearchForHighestPopulationServer()
	if isSearching then return end
	isSearching = true
	targetServerFound = nil
	ActionButton.Text = "Searching..."
	
	AnimateStatus("Initializing server search...", 0.05)
	
	local visitedServers = LoadVisitedServers()
	AddCurrentServerToVisited(visitedServers)
	
	AnimateStatus("Fetching server list...", 0.1)
	
	local allServers = GetAllServers()
	if #allServers == 0 then
		AnimateStatus("No servers available. Please try again later.", 1)
		ActionButton.Text = "Find Highest Server"
		isSearching = false
		return
	end
	
	AnimateStatus("Analyzing " .. #allServers .. " servers for highest population...", 0.4)
	
	local targetServer, serverPriority, highestFound = FindHighestPopulationServer(allServers, visitedServers, failedTeleports)
	
	local attempts = 0
	while not targetServer and attempts < 3 do
		attempts = attempts + 1
		AnimateStatus("Expanding search criteria... (Attempt " .. attempts .. "/3)", 0.6)
		
		if attempts >= 2 then
			visitedServers = {}
		end
		
		local originalMin = minimumAcceptablePlayerCount
		minimumAcceptablePlayerCount = math.max(1, minimumAcceptablePlayerCount - (attempts * 3))
		
		targetServer, serverPriority, highestFound = FindHighestPopulationServer(allServers, visitedServers, failedTeleports)
		
		minimumAcceptablePlayerCount = originalMin
	end
	
	if targetServer then
		local playerCount = targetServer.playing
		local spaceAvailable = (targetServer.maxPlayers or Players.MaxPlayers) - playerCount
		
		targetServerFound = targetServer
		AnimateStatus("Found optimal server: " .. playerCount .. " players (" .. spaceAvailable .. " slots free). Press 'Join Server'!", 1)
		ActionButton.Text = "Join Server"
	else
		AnimateStatus("No suitable high-population servers found at this time.", 1)
		ActionButton.Text = "Find Highest Server"
	end
	isSearching = false
end

-- Manual Join Trigger Function
local function JoinFoundServer()
	if not targetServerFound then return end
	
	AnimateStatus("Joining high population server...", 1)
	ActionButton.Text = "Teleporting..."
	
	local teleportSuccess, teleportError = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServerFound.id, LocalPlayer)
	end)
	
	if not teleportSuccess and retryCount < maxRetries then
		retryCount = retryCount + 1
		failedTeleports[targetServerFound.id] = true
		targetServerFound = nil
		AnimateStatus("Connection failed. Finding new server...", 0.5)
		
		task.spawn(function()
			task.wait(1)
			SearchForHighestPopulationServer()
		end)
	end
end

-- Teleport Error Event Hook
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	if player == LocalPlayer then
		local failReason = teleportResult.Name
		
		if failReason == "GameEnded" or failReason == "GameFull" or failReason == "Unauthorized" then
			if retryCount < maxRetries then
				retryCount = retryCount + 1
				AnimateStatus("Server unavailable. Finding alternative... (Attempt " .. retryCount .. "/" .. maxRetries .. ")", 0.4)
				
				if targetServerFound and targetServerFound.id then
					failedTeleports[targetServerFound.id] = true
				end
				targetServerFound = nil
				
				task.spawn(function()
					task.wait(1)
					SearchForHighestPopulationServer()
				end)
			else
				AnimateStatus("Unable to find available server after " .. maxRetries .. " attempts.", 1)
				ActionButton.Text = "Find Highest Server"
			end
		else
			AnimateStatus("Teleport failed: " .. failReason, 1)
			ActionButton.Text = "Find Highest Server"
		end
	end
end)

-- Combined Button Action Handler
ActionButton.MouseButton1Click:Connect(function()
	if isSearching then return end
	
	if targetServerFound then
		JoinFoundServer()
	else
		retryCount = 0
		failedTeleports = {}
		task.spawn(SearchForHighestPopulationServer)
	end
end)

--------------------------------------------------------------------------------
-- INITIALIZATION & ANIMATION OPENING
--------------------------------------------------------------------------------
frame.Size = UDim2.new(0, 340, 0, 0)
tween(frame, { Size = OPEN_SIZE })