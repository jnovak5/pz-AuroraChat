-- Only MP
if not isServer() or isClient() then return end

local PlayerDB = {}

local function isStaffPlayer(player)
    if not player then return false end
    local accessLevel = player.getAccessLevel and player:getAccessLevel()
    if type(accessLevel) == "string" and accessLevel ~= "" then
        local lower = string.lower(accessLevel)
        if lower == "admin" or lower == "moderator" or lower == "overseer" or lower == "gm" or lower == "observer" then
            return true
        end
    end
    return false
end

local function enforceServerUserLimits(player)
    if not player then return end
    if not isStaffPlayer(player) then
        if player.setHearAll then
            pcall(function() player:setHearAll(false) end)
        end
        if player.setHearAllChat then
            pcall(function() player:setHearAllChat(false) end)
        end
        if player.setHearEveryone then
            pcall(function() player:setHearEveryone(false) end)
        end
        if player.setSeeEveryone then
            pcall(function() player:setSeeEveryone(false) end)
        end
        if player.getModData then
            local md = player:getModData()
            if md then
                md.isHearAll = nil
                md.HearAll = nil
                md.CanHearAll = nil
                md.bHearAll = nil
                md.HearEveryone = nil
                md.hearEveryone = nil
            end
        end
    end
end

local function canSee(player, otherPlayer, xyRange, zRange)
    if not player or not otherPlayer then return false end
    enforceServerUserLimits(player)
    
    -- Staff can see typing indicators if in staff mode
    if isStaffPlayer(player) then
        if player.isHearAll and player:isHearAll() == true then return true end
        if player.isHearAllChat and player:isHearAllChat() == true then return true end
        if player.isSeeEveryone and player:isSeeEveryone() == true then return true end
        if player.isGhostMode and player:isGhostMode() == true then return true end
        if player.isGodMod and player:isGodMod() == true then return true end
        return true
    end

    xyRange = (xyRange or 0) + .99
    zRange = zRange or 0
    local dx = player:getX() - otherPlayer:getX()
    local dy = player:getY() - otherPlayer:getY()
    if (dx * dx + dy * dy) > xyRange * xyRange then return false end
    if math.abs(player:getZ() - otherPlayer:getZ()) > zRange then return false end
    return true
end

local function getChatRangeAndType(text)
    local sandbox = SandboxVars.SVRPChat or SandboxVars.SVRPChat or {}
    if not text or text == "" then return "say", (sandbox.RangeXYSay or 20), (sandbox.RangeZSay or 2) end
    local clean = text:gsub("^%s+", "")
    if clean:sub(1,1) == "/" then
        local firstWord = clean:match("^/(%w+)")
        if firstWord then
            firstWord = string.lower(firstWord)
            if firstWord == "whisper" or firstWord == "w" then
                return "whisper", (sandbox.RangeXYWhisper or 2), (sandbox.RangeZWhisper or 0)
            elseif firstWord == "low" or firstWord == "l" or firstWord == "quiet" or firstWord == "q" then
                return "low", (sandbox.RangeXYLow or 6), (sandbox.RangeZLow or 0)
            elseif firstWord == "say" then
                return "say", (sandbox.RangeXYSay or 20), (sandbox.RangeZSay or 2)
            elseif firstWord == "loud" or firstWord == "yell" or firstWord == "y" then
                return "loud", (sandbox.RangeXYLoud or 45), (sandbox.RangeZLoud or 4)
            elseif firstWord == "shout" or firstWord == "s" then
                return "shout", (sandbox.RangeXYShout or 80), (sandbox.RangeZShout or 7)
            elseif firstWord == "ooc" or firstWord == "all" or firstWord == "roll" or firstWord == "card" or firstWord == "event" or firstWord == "status" or firstWord == "env" or firstWord == "me" or firstWord == "do" or firstWord == "it" or firstWord == "emote" then
                if firstWord == "me" or firstWord == "do" or firstWord == "it" or firstWord == "emote" then
                    if clean:find('"') or clean:find('“') then
                        return "say", (sandbox.RangeXYSay or 20), (sandbox.RangeZSay or 2)
                    end
                end
                return nil, 0, 0
            end
        end
    end
    return "say", (sandbox.RangeXYSay or 20), (sandbox.RangeZSay or 2)
end

local function dispatchVoiceChatter(sendingPlayer, text, x, y, z)
    local sandbox = SandboxVars.SVRPChat or SandboxVars.SVRPChat or {}
    if sandbox.EnableVoiceChatter == false then return end
    if not sendingPlayer or not text or text == "" then return end

    local chatTypeStr, xyRange, zRange = getChatRangeAndType(text)
    if not chatTypeStr or xyRange <= 0 then return end

    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers or onlinePlayers:size() == 0 then return end

    local speakerUsername = sendingPlayer:getUsername()
    local sx = x or sendingPlayer:getX()
    local sy = y or sendingPlayer:getY()
    local sz = z or sendingPlayer:getZ()
    local speakerSq = sendingPlayer:getCurrentSquare() or (getCell() and getCell():getGridSquare(sx, sy, sz))
    local speakerOutside = speakerSq and speakerSq:isOutside()

    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)
        local targetUsername = targetPlayer:getUsername()

        -- Check server-side voice preference for this target player
        local voicePref = PlayerDB.PlayerVoicePrefs and PlayerDB.PlayerVoicePrefs[targetUsername]
        local isVoiceEnabled = (voicePref ~= false)

        if isVoiceEnabled then
            local tx, ty, tz = targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ()
            local dx = sx - tx
            local dy = sy - ty
            local dist = math.sqrt(dx * dx + dy * dy)
            local zDist = math.abs(sz - tz)

            -- Acoustic wall dampening on server
            local wallPenalty = 0
            local targetSq = targetPlayer:getCurrentSquare() or (getCell() and getCell():getGridSquare(tx, ty, tz))
            if speakerSq and targetSq then
                local targetOutside = targetSq:isOutside()
                if speakerOutside ~= targetOutside then
                    if chatTypeStr == "whisper" or chatTypeStr == "low" then
                        wallPenalty = 9999
                    elseif chatTypeStr == "say" then
                        wallPenalty = 12.0
                    else
                        wallPenalty = 8.0
                    end
                elseif not speakerOutside and not targetOutside then
                    local sBuilding = speakerSq:getBuilding()
                    local tBuilding = targetSq:getBuilding()
                    if sBuilding and tBuilding and sBuilding ~= tBuilding then
                        if chatTypeStr == "whisper" or chatTypeStr == "low" then
                            wallPenalty = 9999
                        else
                            wallPenalty = 18.0
                        end
                    end
                end
            end

            local effectiveDist = dist + wallPenalty
            local rangeMult = (chatTypeStr == "whisper" or chatTypeStr == "low") and 1.2 or 1.4
            local maxRange = xyRange * rangeMult + 0.99

            enforceServerUserLimits(targetPlayer)
            local canHear = false
            if isStaffPlayer(targetPlayer) and (
                (targetPlayer.isHearAll and targetPlayer:isHearAll() == true) or
                (targetPlayer.isHearAllChat and targetPlayer:isHearAllChat() == true) or
                (targetPlayer.isHearEveryone and targetPlayer:isHearEveryone() == true) or
                (targetPlayer.isSeeEveryone and targetPlayer:isSeeEveryone() == true) or
                (targetPlayer.isGhostMode and targetPlayer:isGhostMode() == true) or
                (targetPlayer.isGodMod and targetPlayer:isGodMod() == true)
            ) then
                canHear = true
            elseif effectiveDist <= maxRange and zDist <= zRange then
                canHear = true
            end

            if canHear then
                local isDifferentZ = (zDist > 0)
                sendServerCommand(targetPlayer, "AC", "PlayVoiceChatter", {
                    speakerUsername,
                    chatTypeStr,
                    text,
                    isDifferentZ,
                    { x = sx, y = sy, z = sz }
                })
            end
        end
    end
end

local function doLog(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    local forname = sendingPlayer:getDescriptor():getForename()
    local x, y, z, text, lang = args[1], args[2], args[3], args[4], args[5]
    local logMessage = string.format("%s (%s) @ %s,%s,%s: [%s] %s", username, forname, x, y, z, lang, text)
    writeLog("ReadableChat", logMessage)
    dispatchVoiceChatter(sendingPlayer, text, x, y, z)
end

local function doPrivateLog(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    local forname = sendingPlayer:getDescriptor():getForename()
    local x, y, z, text, lang = args[1], args[2], args[3], args[4], args[5]
    local logMessage = string.format("%s (%s) @ %s,%s,%s: [%s] %s", username, forname, x, y, z, lang, text)
    writeLog("PrivateChat", logMessage)
end

local function SetVoiceChatterPref(player, enabled)
    if not player then return end
    PlayerDB.PlayerVoicePrefs = PlayerDB.PlayerVoicePrefs or {}
    PlayerDB.PlayerVoicePrefs[player:getUsername()] = (enabled == true)
    ModData.add("AC_PlayerVoicePrefs", PlayerDB.PlayerVoicePrefs)
    sendServerCommand("AC", "SetVoiceChatterPref", {player:getUsername(), (enabled == true)})
end

local function SetPlayerColor(player, r, g, b)
    if not player then return end
    if not r or not g or not b then
        PlayerDB.PlayerColors[player:getUsername()] = nil
        ModData.add("AC_PlayerColors", PlayerDB.PlayerColors)
        sendServerCommand("AC", "SetPlayerColor", {player:getUsername(), nil, nil, nil})
        return
    end
    PlayerDB.PlayerColors[player:getUsername()] = {r = r, g = g, b = b}
    ModData.add("AC_PlayerColors", PlayerDB.PlayerColors)
    sendServerCommand("AC", "SetPlayerColor", {player:getUsername(), r, g, b})
end

local function SetPlayerLanguage(player, language)
    if not player or not language then return end
    PlayerDB.PlayerLanguages[player:getUsername()] = language
    ModData.add("AC_PlayerLanguages", PlayerDB.PlayerLanguages)
    sendServerCommand("AC", "SetPlayerLanguage", {player:getUsername(), language})
end

local function NotifyTyping(sendingPlayer, command, args)
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers or onlinePlayers:size() == 0 then return end
    local username = sendingPlayer:getUsername()
    if command == "onCleared" then
        for i = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(i)
            sendServerCommand(player, "AC", "onCleared", {username})
        end
        return
    end
    if command ~= "onTyping" then return end
    local xyRange = args and args[1] or 0
    local zRange = args and args[2] or 0
    if xyRange <= 0 then return end
    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i)
        if player:getUsername() ~= username and canSee(player, sendingPlayer, xyRange, zRange) then
            sendServerCommand(player, "AC", command, {username})
        end
    end
end

local function SetModifier(player, direction, modifier)
    local username = player:getUsername()
    PlayerDB.PlayerModifiers[username] = PlayerDB.PlayerModifiers[username] or {}
    if direction == "enable" then
        PlayerDB.PlayerModifiers[username][modifier] = true
    elseif direction == "disable" then
        PlayerDB.PlayerModifiers[username][modifier] = nil
    end
    ModData.add("AC_PlayerModifiers", PlayerDB.PlayerModifiers)
    sendServerCommand("AC", "SetModifier", {username, direction, modifier})
end

local function SetPlayerName(player, name)
    if not player or not name then return end
    PlayerDB.PlayerNames[player:getUsername()] = name
    ModData.add("AC_PlayerNames", PlayerDB.PlayerNames)
    sendServerCommand("AC", "SetPlayerName", {player:getUsername(), name})
end

local function SetPlayerStatus(player, status)
    if not player then return end
    PlayerDB.PlayerStatus[player:getUsername()] = status
    ModData.add("AC_PlayerStatus", PlayerDB.PlayerStatus)
    sendServerCommand("AC", "SetPlayerStatus", {player:getUsername(), status})
end

local staffColors = {
    ["Admin"]    = "<RGB:0.2,0.8,0.2>",
    ["Moderator"]= "<RGB:0.2,0.2,0.8>",
    ["Overseer"] = "<RGB:0.8,0.2,0.2>",
    ["GM"]       = "<RGB:0.8,0.8,0.2>",
    ["Observer"] = "<RGB:0.8,0.2,0.8>"
}

local function broadcastCombatMatch(match, commandName, cmdArgs)
    if not match then return end
    commandName = commandName or "CombatSync"
    cmdArgs = cmdArgs or {match}
    local allPlayers = getOnlinePlayers()
    if not allPlayers or allPlayers:size() == 0 then return end

    local userMap = {}
    for _, u in ipairs(match.participants or {}) do userMap[u] = true end
    for _, u in ipairs(match.viewers or {}) do userMap[u] = true end

    for i = 0, allPlayers:size() - 1 do
        local player = allPlayers:get(i)
        if userMap[player:getUsername()] then
            sendServerCommand(player, "AC", commandName, cmdArgs)
        end
    end
end

-- Command dispatch table
local CommandHandlers = {}

CommandHandlers.doLog = function(sendingPlayer, args)
    doLog(sendingPlayer, args)
end

CommandHandlers.SetVoiceChatterPref = function(sendingPlayer, args)
    SetVoiceChatterPref(sendingPlayer, args and args[1])
end

CommandHandlers.SetPlayerColor = function(sendingPlayer, args)
    SetPlayerColor(sendingPlayer, args[1], args[2], args[3])
end

CommandHandlers.SetPlayerLanguage = function(sendingPlayer, args)
    SetPlayerLanguage(sendingPlayer, args[1])
end

CommandHandlers.SetPlayerName = function(sendingPlayer, args)
    SetPlayerName(sendingPlayer, args[1])
end

CommandHandlers.SetPlayerStatus = function(sendingPlayer, args)
    SetPlayerStatus(sendingPlayer, args and args[1] or nil)
end

CommandHandlers.RemoveKnownLanguage = function(sendingPlayer, args)
    local username, language = args[1], args[2]
    local allPlayers = getOnlinePlayers()
    if not allPlayers or allPlayers:size() == 0 then return end
    for i=0, allPlayers:size()-1 do
        local player = allPlayers:get(i)
        if player:getUsername() == username then
            sendServerCommand(player, "AC", "RemoveKnownLanguage", {language})
            break
        end
    end
end

CommandHandlers.AddKnownLanguage = function(sendingPlayer, args)
    local username, language = args[1], args[2]
    local allPlayers = getOnlinePlayers()
    if not allPlayers or allPlayers:size() == 0 then return end
    for i=0, allPlayers:size()-1 do
        local player = allPlayers:get(i)
        if player:getUsername() == username then
            sendServerCommand(player, "AC", "AddKnownLanguage", {language})
            break
        end
    end
end

CommandHandlers.SetModifier = function(sendingPlayer, args)
    SetModifier(sendingPlayer, args[1], args[2])
end

local function forwardToUser(targetUsername, sendingPlayer, commandName, cmdArgs)
    local allPlayers = getOnlinePlayers()
    if not allPlayers or allPlayers:size() == 0 then return end
    for i=0, allPlayers:size()-1 do
        local player = allPlayers:get(i)
        if player:getUsername() == targetUsername then
            sendServerCommand(player, "AC", commandName, cmdArgs)
            break
        end
    end
end

CommandHandlers.InvitePrivate = function(sendingPlayer, args)
    forwardToUser(args[1], sendingPlayer, "InvitePrivate", {sendingPlayer:getUsername()})
end

CommandHandlers.PrivateUnavailable = function(sendingPlayer, args)
    forwardToUser(args[1], sendingPlayer, "PrivateUnavailable", {sendingPlayer:getUsername()})
end

CommandHandlers.AcceptPrivateInvite = function(sendingPlayer, args)
    forwardToUser(args[1], sendingPlayer, "AcceptPrivateInvite", {sendingPlayer:getUsername()})
end

CommandHandlers.DeclinePrivateInvite = function(sendingPlayer, args)
    forwardToUser(args[1], sendingPlayer, "DeclinePrivateInvite", {sendingPlayer:getUsername()})
end

CommandHandlers.StopPrivate = function(sendingPlayer, args)
    forwardToUser(args[1], sendingPlayer, "StopPrivate", {sendingPlayer:getUsername()})
end

CommandHandlers.PrivateChat = function(sendingPlayer, args)
    local otherPlayer, message, lang = args[1], args[2], args[3]
    local allPlayers = getOnlinePlayers()
    if not allPlayers or allPlayers:size() == 0 then return end
    for i=0, allPlayers:size()-1 do
        local player = allPlayers:get(i)
        if player:getUsername() == otherPlayer then
            sendServerCommand(player, "AC", "PrivateChat", {sendingPlayer:getUsername(), message})
            doPrivateLog(sendingPlayer, {player:getX(), player:getY(), player:getZ(), message, lang})
            break
        end
    end
end

CommandHandlers.Injure = function(sendingPlayer, args)
    local sandbox = SandboxVars.SVRPChat or SandboxVars.SVRPChat
    if sandbox and sandbox.EnableSelfInjury == false then
        return
    end
    local bodyPartStr, injury = args[1], args[2]
    local bodyPartType = BodyPartType.FromString(bodyPartStr)
    if bodyPartType then
        sendServerCommand(sendingPlayer, "AC", "ApplyInjury", {bodyPartStr, injury})
    end
end

CommandHandlers.Ailment = function(sendingPlayer, args)
    local sandbox = SandboxVars.SVRPChat or SandboxVars.SVRPChat
    if sandbox and sandbox.EnableSelfInjury == false then
        return
    end
    local ailment = args[1]
    if ailment == "Cold" or ailment == "Sickness" then
        sendServerCommand(sendingPlayer, "AC", "ApplyAilment", {ailment})
    end
end

local function broadcastStaffMessage(sendingPlayer, text, command)
    local color = staffColors[sendingPlayer:getAccessLevel()] or "<RGB:0.8,0.8,0.8>"
    local message = color .. "[" .. sendingPlayer:getUsername() .. "]" .. AC_Utils.MagicSpace .. "<RGB:1,1,1>" .. (text or "")
    local allPlayers = getOnlinePlayers()
    if not allPlayers or allPlayers:size() == 0 then return end
    for i=0, allPlayers:size()-1 do
        local player = allPlayers:get(i)
        if AC_Utils.isStaff(player) then
            sendServerCommand(player, "AC", command, {sendingPlayer:getUsername(), message})
        end
    end
end

CommandHandlers.Override = function(sendingPlayer, args)
    broadcastStaffMessage(sendingPlayer, args[1], "Override")
end

CommandHandlers.StaffChat = function(sendingPlayer, args)
    broadcastStaffMessage(sendingPlayer, args[1], "StaffChat")
end

CommandHandlers.BioSave = function(sendingPlayer, args)
    PlayerDB.CharacterBioStorage[sendingPlayer:getUsername()] = {description = args[1]}
    ModData.add("AC_CharacterBioStorage", PlayerDB.CharacterBioStorage)
end

CommandHandlers.BioLoad = function(sendingPlayer, args)
    sendServerCommand(sendingPlayer, "AC", "BioLoad", PlayerDB.CharacterBioStorage[args[1]] or {})
end

CommandHandlers.ApplyRpBuffs = function(sendingPlayer, args)
    local stats = sendingPlayer:getStats()
    if args.boredom and stats:get(CharacterStat.BOREDOM) > args.boredom then stats:remove(CharacterStat.BOREDOM, args.boredom) end
    if args.hunger and stats:get(CharacterStat.HUNGER) > args.hunger then stats:remove(CharacterStat.HUNGER, args.hunger) end
    if args.thirst and stats:get(CharacterStat.THIRST) > args.thirst then stats:remove(CharacterStat.THIRST, args.thirst) end
    if args.stressSmokes and stats:get(CharacterStat.STRESS) > args.stressSmokes then stats:remove(CharacterStat.STRESS, args.stressSmokes) end
    if args.unhappyness and stats:get(CharacterStat.UNHAPPINESS) > args.unhappyness then stats:remove(CharacterStat.UNHAPPINESS, args.unhappyness) end
end

-- Combat Handlers
CommandHandlers.CombatCreate = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    PlayerDB.PlayerToCombatMatch = PlayerDB.PlayerToCombatMatch or {}
    PlayerDB.CombatMatches[hostName] = {
        host = hostName,
        isActive = false,
        round = 1,
        currentTurn = 1,
        participants = { hostName },
        viewers = {},
        history = {}
    }
    PlayerDB.PlayerToCombatMatch[hostName] = hostName
    sendServerCommand(sendingPlayer, "AC", "CombatSync", {PlayerDB.CombatMatches[hostName]})
end

CommandHandlers.CombatInvite = function(sendingPlayer, args)
    local targetUsername, isViewer = args[1], args[2] or false
    local hostName = sendingPlayer:getUsername()
    forwardToUser(targetUsername, sendingPlayer, "CombatInvite", {hostName, isViewer})
end

CommandHandlers.CombatAccept = function(sendingPlayer, args)
    local hostName, isViewer = args[1], args[2] or false
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    PlayerDB.PlayerToCombatMatch = PlayerDB.PlayerToCombatMatch or {}
    local match = PlayerDB.CombatMatches[hostName]
    local username = sendingPlayer:getUsername()
    if match then
        if isViewer then
            match.viewers = match.viewers or {}
            local found = false
            for _, u in ipairs(match.viewers) do if u == username then found = true break end end
            if not found then table.insert(match.viewers, username) end
        else
            match.participants = match.participants or {}
            local found = false
            for _, u in ipairs(match.participants) do if u == username then found = true break end end
            if not found then table.insert(match.participants, username) end
        end
        PlayerDB.PlayerToCombatMatch[username] = hostName
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatToggleRole = function(sendingPlayer, args)
    local targetUsername = args[1]
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match then
        local isParticipant = false
        for i, u in ipairs(match.participants or {}) do
            if u == targetUsername then
                table.remove(match.participants, i)
                isParticipant = true
                break
            end
        end
        if isParticipant then
            match.viewers = match.viewers or {}
            table.insert(match.viewers, targetUsername)
        else
            for i, u in ipairs(match.viewers or {}) do
                if u == targetUsername then
                    table.remove(match.viewers, i)
                    break
                end
            end
            match.participants = match.participants or {}
            table.insert(match.participants, targetUsername)
        end
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatLeave = function(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    PlayerDB.PlayerToCombatMatch = PlayerDB.PlayerToCombatMatch or {}
    local hostName = PlayerDB.PlayerToCombatMatch[username]
    if hostName and PlayerDB.CombatMatches[hostName] then
        local match = PlayerDB.CombatMatches[hostName]
        if hostName == username then
            broadcastCombatMatch(match, "CombatEnd", {})
            for _, u in ipairs(match.participants or {}) do PlayerDB.PlayerToCombatMatch[u] = nil end
            for _, u in ipairs(match.viewers or {}) do PlayerDB.PlayerToCombatMatch[u] = nil end
            PlayerDB.CombatMatches[hostName] = nil
        else
            for i = #(match.participants or {}), 1, -1 do
                if match.participants[i] == username then table.remove(match.participants, i) end
            end
            for i = #(match.viewers or {}), 1, -1 do
                if match.viewers[i] == username then table.remove(match.viewers, i) end
            end
            PlayerDB.PlayerToCombatMatch[username] = nil
            broadcastCombatMatch(match, "CombatSync", {match})
        end
    end
end

CommandHandlers.CombatKick = function(sendingPlayer, args)
    local targetUsername = args[1]
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    PlayerDB.PlayerToCombatMatch = PlayerDB.PlayerToCombatMatch or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match then
        for i = #(match.participants or {}), 1, -1 do
            if match.participants[i] == targetUsername then table.remove(match.participants, i) end
        end
        for i = #(match.viewers or {}), 1, -1 do
            if match.viewers[i] == targetUsername then table.remove(match.viewers, i) end
        end
        PlayerDB.PlayerToCombatMatch[targetUsername] = nil
        forwardToUser(targetUsername, sendingPlayer, "CombatKicked", {})
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatReorder = function(sendingPlayer, args)
    local newOrder = args[1]
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match and type(newOrder) == "table" then
        match.participants = newOrder
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatStart = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match then
        match.isActive = true
        match.round = 1
        match.currentTurn = 1
        table.insert(match.history, { text = "--- Combat Started (Round 1) ---", r = 0.3, g = 1.0, b = 0.3 })
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatEnd = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match then
        match.isActive = false
        table.insert(match.history, { text = "--- Combat Ended ---", r = 1.0, g = 0.3, b = 0.3 })
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatNextTurn = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match and match.isActive and #match.participants > 0 then
        match.currentTurn = match.currentTurn + 1
        if match.currentTurn > #match.participants then
            match.currentTurn = 1
            match.round = (match.round or 1) + 1
            table.insert(match.history, { text = string.format("--- Round %d ---", match.round), r = 0.4, g = 0.8, b = 1.0 })
        end
        local currentActor = match.participants[match.currentTurn]
        local actorName = PlayerDB.PlayerNames and PlayerDB.PlayerNames[currentActor] or currentActor
        table.insert(match.history, { text = string.format("Turn: %s", actorName), r = 0.8, g = 0.9, b = 0.5 })
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatPrevTurn = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local match = PlayerDB.CombatMatches[hostName]
    if match and match.isActive and #match.participants > 0 then
        match.currentTurn = match.currentTurn - 1
        if match.currentTurn < 1 then
            match.currentTurn = #match.participants
            match.round = math.max(1, (match.round or 1) - 1)
        end
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.CombatRoll = function(sendingPlayer, args)
    local rollText = args[5] or args[1]
    local username = sendingPlayer:getUsername()
    PlayerDB.PlayerToCombatMatch = PlayerDB.PlayerToCombatMatch or {}
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local hostName = PlayerDB.PlayerToCombatMatch[username]
    if hostName and PlayerDB.CombatMatches[hostName] then
        local match = PlayerDB.CombatMatches[hostName]
        table.insert(match.history, { text = rollText, r = 1.0, g = 0.85, b = 0.3 })
        if #match.history > 100 then table.remove(match.history, 1) end
        broadcastCombatMatch(match, "CombatRoll", {rollText})
    end
end

CommandHandlers.CombatHealth = function(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    local currentHP = tonumber(args[1]) or 100
    local maxHP = tonumber(args[2]) or 100
    local logText = args[3] or ""

    PlayerDB.PlayerToCombatMatch = PlayerDB.PlayerToCombatMatch or {}
    PlayerDB.CombatMatches = PlayerDB.CombatMatches or {}
    local hostName = PlayerDB.PlayerToCombatMatch[username]
    if hostName and PlayerDB.CombatMatches[hostName] then
        local match = PlayerDB.CombatMatches[hostName]
        match.health = match.health or {}
        match.health[username] = { current = currentHP, max = maxHP }
        if logText ~= "" then
            table.insert(match.history, { text = logText, r = 0.95, g = 0.4, b = 0.4 })
            if #match.history > 100 then table.remove(match.history, 1) end
        end
        broadcastCombatMatch(match, "CombatSync", {match})
    end
end

CommandHandlers.EventCreate = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    PlayerDB.PlayerEvents = PlayerDB.PlayerEvents or {}

    local eventId = hostName .. "_" .. getTimestampMs()
    local newEvent = {
        id = eventId,
        host = hostName,
        hostCharName = args.hostCharName or hostName,
        title = args.title or "Player Event",
        description = args.description or "",
        category = args.category or "Roleplay",
        radius = tonumber(args.radius) or 50,
        isPublic = (args.isPublic ~= false),
        isAdminEvent = (args.isAdminEvent == true),
        x = tonumber(args.x) or math.floor(sendingPlayer:getX()),
        y = tonumber(args.y) or math.floor(sendingPlayer:getY()),
        z = tonumber(args.z) or math.floor(sendingPlayer:getZ()),
        attendees = {
            [hostName] = { status = "accepted", charName = args.hostCharName or hostName }
        },
        timestamp = getTimestamp(),
    }

    PlayerDB.PlayerEvents[eventId] = newEvent
    ModData.add("AC_PlayerEvents", PlayerDB.PlayerEvents)
    sendServerCommand("AC", "EventSync", { PlayerDB.PlayerEvents })

    if newEvent.isPublic then
        local tag = newEvent.isAdminEvent and "[OFFICIAL EVENT]" or "[EVENT]"
        local notifyMsg = string.format("%s '%s' started at (%d, %d)! Check your map to view or RSVP.", tag, newEvent.title, newEvent.x, newEvent.y)
        sendServerCommand("AC", "EventBroadcast", { notifyMsg, newEvent.isAdminEvent })
    end
end

CommandHandlers.EventCancel = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    local eventId = args[1]
    PlayerDB.PlayerEvents = PlayerDB.PlayerEvents or {}

    local event = PlayerDB.PlayerEvents[eventId]
    if event and (event.host == hostName or sendingPlayer:isAccessLevel("admin")) then
        local title = event.title
        PlayerDB.PlayerEvents[eventId] = nil
        ModData.add("AC_PlayerEvents", PlayerDB.PlayerEvents)
        sendServerCommand("AC", "EventSync", { PlayerDB.PlayerEvents })
        sendServerCommand("AC", "EventBroadcast", { string.format("Event '%s' has concluded/ended.", title), false })
    end
end

CommandHandlers.EventInvite = function(sendingPlayer, args)
    local hostName = sendingPlayer:getUsername()
    local eventId = args[1]
    local targetList = args[2] or {}
    PlayerDB.PlayerEvents = PlayerDB.PlayerEvents or {}

    local event = PlayerDB.PlayerEvents[eventId]
    if not event then return end

    local onlinePlayers = getOnlinePlayers()
    for _, targetUsername in ipairs(targetList) do
        event.attendees[targetUsername] = event.attendees[targetUsername] or { status = "invited", charName = targetUsername }
        if onlinePlayers then
            for i = 0, onlinePlayers:size() - 1 do
                local targetP = onlinePlayers:get(i)
                if targetP and targetP:getUsername() == targetUsername then
                    sendServerCommand(targetP, "AC", "EventInvite", { eventId, event.title, event.hostCharName or hostName, event.isAdminEvent })
                    break
                end
            end
        end
    end

    ModData.add("AC_PlayerEvents", PlayerDB.PlayerEvents)
    sendServerCommand("AC", "EventSync", { PlayerDB.PlayerEvents })
end

CommandHandlers.EventRSVP = function(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    local eventId = args[1]
    local status = args[2] or "accepted"
    local charName = args[3] or username
    PlayerDB.PlayerEvents = PlayerDB.PlayerEvents or {}

    local event = PlayerDB.PlayerEvents[eventId]
    if event then
        event.attendees = event.attendees or {}
        event.attendees[username] = { status = status, charName = charName }
        ModData.add("AC_PlayerEvents", PlayerDB.PlayerEvents)
        sendServerCommand("AC", "EventSync", { PlayerDB.PlayerEvents })
    end
end

CommandHandlers.CellMsg = function(sendingPlayer, args)
    if not sendingPlayer then return end
    if not AC_Utils.isStaff(sendingPlayer) and not AC.Override(true) then return end

    local text = args.text or args[1]
    if not text or text == "" then return end

    local x = args.x or sendingPlayer:getX()
    local y = args.y or sendingPlayer:getY()
    local author = args.author or sendingPlayer:getUsername()
    local radius = args.radius or 25 -- 50x50 tiles = radius 25

    sendServerCommand("AC", "CellMsg", { text = text, author = author, x = x, y = y, radius = radius })
end

local function onACCommand(module, command, sendingPlayer, args)
    if module ~= "AC" then return end
    args = args or {}
    local handler = CommandHandlers[command]
    if handler then
        handler(sendingPlayer, args)
    else
        NotifyTyping(sendingPlayer, command, args)
    end
end

local function ProcessLastSeenTimes()
    local allUsernames = {}
    local function collectUsernames(dbTable)
        if type(dbTable) == "table" then
            for k, _ in pairs(dbTable) do
                allUsernames[k] = true
            end
        end
    end
    
    collectUsernames(PlayerDB.LastSeenTimes)
    collectUsernames(PlayerDB.PlayerColors)
    collectUsernames(PlayerDB.PlayerLanguages)
    collectUsernames(PlayerDB.PlayerModifiers)
    collectUsernames(PlayerDB.PlayerNames)
    collectUsernames(PlayerDB.PlayerAfk)
    collectUsernames(PlayerDB.PlayerStatus)
    collectUsernames(PlayerDB.PlayerVoicePrefs)
    collectUsernames(PlayerDB.CharacterBioStorage)
    collectUsernames(PlayerDB.CharacterPortraitStorage)

    local now = getTimestamp()

    local allPlayers = getOnlinePlayers()
    if allPlayers and allPlayers:size() > 0 then
        for i=0, allPlayers:size()-1 do
            local player = allPlayers:get(i)
            local username = player:getUsername()
            PlayerDB.LastSeenTimes[username] = now
            allUsernames[username] = true
        end
    end

    for username, _ in pairs(allUsernames) do
        local lastSeenTime = PlayerDB.LastSeenTimes[username]
        if not lastSeenTime then
            PlayerDB.LastSeenTimes[username] = now
            lastSeenTime = now
        end
        -- 30 days
        if lastSeenTime < now - 30*24*60*60 then
            PlayerDB.LastSeenTimes[username] = nil
            if PlayerDB.PlayerColors then PlayerDB.PlayerColors[username] = nil end
            if PlayerDB.PlayerLanguages then PlayerDB.PlayerLanguages[username] = nil end
            if PlayerDB.PlayerModifiers then PlayerDB.PlayerModifiers[username] = nil end
            if PlayerDB.PlayerNames then PlayerDB.PlayerNames[username] = nil end
            if PlayerDB.PlayerAfk then PlayerDB.PlayerAfk[username] = nil end
            if PlayerDB.PlayerStatus then PlayerDB.PlayerStatus[username] = nil end
            if PlayerDB.PlayerVoicePrefs then PlayerDB.PlayerVoicePrefs[username] = nil end
            if PlayerDB.CharacterBioStorage then PlayerDB.CharacterBioStorage[username] = nil end
            if PlayerDB.CharacterPortraitStorage then PlayerDB.CharacterPortraitStorage[username] = nil end
        end
    end
    ModData.add("AC_LastSeenTimes", PlayerDB.LastSeenTimes)
    ModData.add("AC_PlayerColors", PlayerDB.PlayerColors)
    ModData.add("AC_PlayerLanguages", PlayerDB.PlayerLanguages)
    ModData.add("AC_PlayerModifiers", PlayerDB.PlayerModifiers)
    ModData.add("AC_PlayerNames", PlayerDB.PlayerNames)
    ModData.add("AC_PlayerAfk", PlayerDB.PlayerAfk)
    ModData.add("AC_PlayerStatus", PlayerDB.PlayerStatus)
    ModData.add("AC_PlayerVoicePrefs", PlayerDB.PlayerVoicePrefs)
    ModData.add("AC_CharacterBioStorage", PlayerDB.CharacterBioStorage)
    ModData.add("AC_CharacterPortraitStorage", PlayerDB.CharacterPortraitStorage)
    ModData.add("AC_PlayerEvents", PlayerDB.PlayerEvents)
end

local function OnInitGlobalModData(isNewGame)
    PlayerDB.LastSeenTimes  = ModData.getOrCreate("AC_LastSeenTimes")
    PlayerDB.PlayerColors   = ModData.getOrCreate("AC_PlayerColors")
    PlayerDB.PlayerLanguages= ModData.getOrCreate("AC_PlayerLanguages")
    PlayerDB.PlayerModifiers= ModData.getOrCreate("AC_PlayerModifiers")
    PlayerDB.PlayerNames    = ModData.getOrCreate("AC_PlayerNames")
    PlayerDB.PlayerAfk      = ModData.getOrCreate("AC_PlayerAfk")
    PlayerDB.PlayerStatus   = ModData.getOrCreate("AC_PlayerStatus")
    PlayerDB.PlayerVoicePrefs = ModData.getOrCreate("AC_PlayerVoicePrefs")
    PlayerDB.CharacterBioStorage = ModData.getOrCreate("AC_CharacterBioStorage")
    PlayerDB.CharacterPortraitStorage = ModData.getOrCreate("AC_CharacterPortraitStorage")
    PlayerDB.PlayerEvents   = ModData.getOrCreate("AC_PlayerEvents")
end

Events.EveryDays.Add(ProcessLastSeenTimes)
Events.OnClientCommand.Add(onACCommand)
Events.OnInitGlobalModData.Add(OnInitGlobalModData)
