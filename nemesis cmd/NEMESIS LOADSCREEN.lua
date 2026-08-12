-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Background Configuration
local bgConfig = {
    UseAnimatedBg = true,
    SpriteFile    = "mainuibg.png",     -- Animated sprite background (OPEN)
    OpenImage     = "nemesislogov2.png",   -- Static PNG background (CLOSED)
    FrameColumns  = 5,
    FrameRows     = 10,
    TotalFrames   = 15,
    FramesPerSec  = 5,
    LogoImageFile = "nemesislogov2.png",  -- Top-centered logo asset path or rbxassetid
}

-- Custom Asset Loader Helper
local function loadLocalAsset(filePath)
    if typeof(getcustomasset) == "function" then
        return getcustomasset(filePath)
    elseif typeof(getsynasset) == "function" then
        return getsynasset(filePath)
    elseif not filePath:find("rbxassetid://") and tonumber(filePath) then
        return "rbxassetid://" .. tostring(filePath)
    else
        return filePath
    end
end

-- ScreenGui Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NemesisLoadingScreen"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Background Container
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
background.BorderSizePixel = 0
background.Parent = screenGui

-- Animated / Static Background Image
local bgImage = Instance.new("ImageLabel")
bgImage.Name = "BgImage"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.BackgroundTransparency = 1
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.Parent = background

local isAnimating = false

-- Apply Background Setup
if bgConfig.UseAnimatedBg then
    bgImage.Image = loadLocalAsset(bgConfig.SpriteFile)
    isAnimating = true
    
    task.spawn(function()
        local currentFrame = 0
        local delayTime = 1 / bgConfig.FramesPerSec
        
        repeat task.wait() until bgImage.ContentImageSize.X > 0
        
        local imageWidth = bgImage.ContentImageSize.X
        local imageHeight = bgImage.ContentImageSize.Y
        
        local frameWidth = imageWidth / bgConfig.FrameColumns
        local frameHeight = imageHeight / bgConfig.FrameRows
        
        bgImage.ImageRectSize = Vector2.new(frameWidth, frameHeight)
        
        while isAnimating do
            local col = currentFrame % bgConfig.FrameColumns
            local row = math.floor(currentFrame / bgConfig.FrameColumns)
            
            bgImage.ImageRectOffset = Vector2.new(col * frameWidth, row * frameHeight)
            
            currentFrame = (currentFrame + 1) % bgConfig.TotalFrames
            task.wait(delayTime)
        end
    end)
else
    bgImage.Image = loadLocalAsset(bgConfig.OpenImage)
end

--------------------------------------------------------------------------------
-- CENTERED UI CONTAINER & LAYOUT
--------------------------------------------------------------------------------

-- Invisible container centered exactly on screen
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(0, 400, 0, 300)
contentContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
contentContainer.AnchorPoint = Vector2.new(0.5, 0.5)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = background

-- Larger Centered Logo Image (160x160)
local logoImage = Instance.new("ImageLabel")
logoImage.Name = "LogoImage"
logoImage.Size = UDim2.new(0, 160, 0, 160)
logoImage.Position = UDim2.new(0.5, 0, 0, 0)
logoImage.AnchorPoint = Vector2.new(0.5, 0)
logoImage.BackgroundTransparency = 1
logoImage.Image = loadLocalAsset(bgConfig.LogoImageFile)
logoImage.ScaleType = Enum.ScaleType.Fit
logoImage.Parent = contentContainer

-- Title Text Below Logo
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0.5, 0, 0, 175)
title.AnchorPoint = Vector2.new(0.5, 0)
title.BackgroundTransparency = 1
title.Text = "NEMESIS (BETA)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 30
title.Font = Enum.Font.GothamBold
title.Parent = contentContainer

-- Status Text Below Title
local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0.5, 0, 0, 215)
status.AnchorPoint = Vector2.new(0.5, 0)
status.BackgroundTransparency = 1
status.Text = "Initializing..."
status.TextColor3 = Color3.fromRGB(170, 170, 190)
status.TextSize = 15
status.Font = Enum.Font.Gotham
status.Parent = contentContainer

-- Progress Bar Background
local barBackground = Instance.new("Frame")
barBackground.Name = "BarBackground"
barBackground.Size = UDim2.new(0, 340, 0, 8)
barBackground.Position = UDim2.new(0.5, 0, 0, 250)
barBackground.AnchorPoint = Vector2.new(0.5, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
barBackground.BorderSizePixel = 0
barBackground.Parent = contentContainer

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBackground

-- Progress Bar Fill
local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(90, 120, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBackground

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

--------------------------------------------------------------------------------
-- LOADING ANIMATION (5 SECONDS TOTAL)
--------------------------------------------------------------------------------

local function startLoading()
    -- Step durations sum up to exactly 5.0 seconds
    local steps = {
        {text = "Loading assets...", progress = 0.30, duration = 1.5},
        {text = "Initializing modules...", progress = 0.70, duration = 2.0},
        {text = "Finalizing startup...", progress = 0.95, duration = 1.0},
        {text = "Ready!", progress = 1.00, duration = 0.5}
    }
    
    for _, step in ipairs(steps) do
        status.Text = step.text
        
        local barTween = TweenService:Create(
            barFill,
            TweenInfo.new(step.duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(step.progress, 0, 1, 0)}
        )
        barTween:Play()
        barTween.Completed:Wait()
    end
    
    task.wait(0.2)
    
    -- Stop background animation loop
    isAnimating = false
    
    -- Fade Out Transition (0.5s fade out after loading)
    local fadeOut = TweenService:Create(
        background,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    
    TweenService:Create(bgImage, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
    TweenService:Create(logoImage, TweenInfo.new(0.4), {ImageTransparency = 1}):Play()
    TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(status, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(barBackground, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFill, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    
    fadeOut:Play()
    fadeOut.Completed:Wait()
    
    screenGui:Destroy()
end

task.spawn(startLoading)