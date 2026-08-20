-- Only MP
if not isServer() or isClient() then return end

local PlayerDB = {}

local function canSee(player, otherPlayer, xyRange, zRange)
    if not player or not otherPlayer then return false end
    xyRange = xyRange + .99
    if player:getDistanceSq(otherPlayer) > xyRange*xyRange then return false end
    if math.abs(player:getZ() - otherPlayer:getZ()) > zRange then return false end
    if player:isGhostMode() and not otherPlayer:isGodMod() then return false end
    return true
end

local function doLog(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    local forname = sendingPlayer:getDescriptor():getForename()
    local x, y, z, text, lang = args[1], args[2], args[3], args[4], args[5]
    local logMessage = string.format("%s (%s) @ %s,%s,%s: [%s] %s", username, forname, x, y, z, lang, text)
    writeLog("ReadableChat", logMessage)
end

local function doPrivateLog(sendingPlayer, args)
    local username = sendingPlayer:getUsername()
    local forname = sendingPlayer:getDescriptor():getForename()
    local x, y, z, text, lang = args[1], args[2], args[3], args[4], args[5]
    local logMessage = string.format("%s (%s) @ %s,%s,%s: [%s] %s", username, forname, x, y, z, lang, text)
    writeLog("PrivateChat", logMessage)
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
    local xyRange, zRange
    if command == "onCleared" then
        xyRange = 50
        zRange = 7
    else
        xyRange = args and args[1] or 0
        zRange = args and args[2] or 0
    end
    local username = sendingPlayer:getUsername()
    for i=0, onlinePlayers:size()-1 do
        local player = onlinePlayers:get(i)
        if canSee(player, sendingPlayer, xyRange, zRange) then
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
    local bodyPartStr, injury = args[1], args[2]
    local bodyPartType = BodyPartType.FromString(bodyPartStr)
    if bodyPartType then
        local bodyDamage = sendingPlayer:getBodyDamage()
        local bodyPart = bodyDamage:getBodyPart(bodyPartType)
        if injury == "Bleeding" then bodyPart:setBleedingTime(10)
        elseif injury == "Bullet" then bodyPart:setHaveBullet(true, 0)
        elseif injury == "Burned" then bodyPart:setBurnTime(50)
        elseif injury == "Deep Wound" then bodyPart:generateDeepWound()
        elseif injury == "Fracture" then bodyPart:setFractureTime(21)
        elseif injury == "Glass Shards" then bodyPart:generateDeepShardWound()
        elseif injury == "Infected" then bodyPart:setWoundInfectionLevel(10)
        elseif injury == "Scratched" then bodyPart:setScratched(true, true)
        elseif injury == "Laceration" then bodyPart:setCut(true)
        elseif injury == "Bite" then
            bodyPart:SetBitten(true)
            bodyPart:SetInfected(false)
            bodyPart:SetFakeInfected(false)
        elseif injury == "Cold" then bodyDamage:setColdStrength(100.0)
        elseif injury == "Sickness" then bodyDamage:setFoodSicknessLevel(100.0)
        end
        bodyDamage:AddDamage(bodyPartType, 15.0)
    end
end

CommandHandlers.Ailment = function(sendingPlayer, args)
    local ailment = args[1]
    local bodyDamage = sendingPlayer:getBodyDamage()
    if ailment == "Cold" then
        bodyDamage:setColdStrength(100.0)
        bodyDamage:setHasACold(true)
    elseif ailment == "Sickness" then
        sendingPlayer:getStats():set(CharacterStat.FOOD_SICKNESS, 40.0)
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
    ModData.add("AC_CharacterBioStorage", PlayerDB.CharacterBioStorage)
    ModData.add("AC_CharacterPortraitStorage", PlayerDB.CharacterPortraitStorage)
end

local function OnInitGlobalModData(isNewGame)
    PlayerDB.LastSeenTimes  = ModData.getOrCreate("AC_LastSeenTimes")
    PlayerDB.PlayerColors   = ModData.getOrCreate("AC_PlayerColors")
    PlayerDB.PlayerLanguages= ModData.getOrCreate("AC_PlayerLanguages")
    PlayerDB.PlayerModifiers= ModData.getOrCreate("AC_PlayerModifiers")
    PlayerDB.PlayerNames    = ModData.getOrCreate("AC_PlayerNames")
    PlayerDB.PlayerAfk      = ModData.getOrCreate("AC_PlayerAfk")
    PlayerDB.PlayerStatus   = ModData.getOrCreate("AC_PlayerStatus")
    PlayerDB.CharacterBioStorage = ModData.getOrCreate("AC_CharacterBioStorage")
    PlayerDB.CharacterPortraitStorage = ModData.getOrCreate("AC_CharacterPortraitStorage")
end

Events.EveryDays.Add(ProcessLastSeenTimes)
Events.OnClientCommand.Add(onACCommand)
Events.OnInitGlobalModData.Add(OnInitGlobalModData)
