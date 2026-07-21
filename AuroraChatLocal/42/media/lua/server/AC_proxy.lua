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
    if onlinePlayers:size() == 0 then return end
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

local function onACCommand(module, command, sendingPlayer, args)
    if module ~= "AC" then return end

    if command == "doLog" then
        doLog(sendingPlayer, args)
    elseif command == "SetPlayerColor" then
        SetPlayerColor(sendingPlayer, args[1], args[2], args[3])
    elseif command == "SetPlayerLanguage" then
        SetPlayerLanguage(sendingPlayer, args[1])
    elseif command == "SetPlayerName" then
        SetPlayerName(sendingPlayer, args[1])
    elseif command == "SetPlayerStatus" then
        SetPlayerStatus(sendingPlayer, args and args[1] or nil)
    elseif command == "RemoveKnownLanguage" or command == "AddKnownLanguage" then
        local username, language = args[1], args[2]
        local allPlayers = getOnlinePlayers()
        if allPlayers:size() == 0 then return end
        for i=0, allPlayers:size()-1 do
            local player = allPlayers:get(i)
            if player:getUsername() == username then
                sendServerCommand(player, "AC", command, {language})
                break
            end
        end
    elseif command == "SetModifier" then
        local direction, modifier = args[1], args[2]
        SetModifier(sendingPlayer, direction, modifier)
    elseif command == "InvitePrivate"
    or     command == "PrivateUnavailable"
    or     command == "AcceptPrivateInvite"
    or     command == "DeclinePrivateInvite"
    or     command == "StopPrivate" then
        local otherPlayer = args[1]
        local allPlayers = getOnlinePlayers()
        if allPlayers:size() == 0 then return end
        for i=0, allPlayers:size()-1 do
            local player = allPlayers:get(i)
            if player:getUsername() == otherPlayer then
                sendServerCommand(player, "AC", command, {sendingPlayer:getUsername()})
                break
            end
        end
    elseif command == "PrivateChat" then
        local otherPlayer = args[1]
        local message = args[2]
        local lang = args[3]
        local allPlayers = getOnlinePlayers()
        if allPlayers:size() == 0 then return end
        for i=0, allPlayers:size()-1 do
            local player = allPlayers:get(i)
            if player:getUsername() == otherPlayer then
                sendServerCommand(player, "AC", command, {sendingPlayer:getUsername(), message})
                doPrivateLog(sendingPlayer, {player:getX(), player:getY(), player:getZ(), message, lang})
                break
            end
        end
    elseif command == "Injure" then
        local bodyPartStr = args[1]
        local injury = args[2]
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
            end
            
            bodyDamage:AddDamage(bodyPartType, 15.0)
        end
    elseif command == "StaffChat" then
        local color = staffColors[sendingPlayer:getAccessLevel()]
        if not color then color = "<RGB:0.8,0.8,0.8>" end
        local message = color .. "[" .. sendingPlayer:getUsername() .. "]" .. AC_Utils.MagicSpace .. "<RGB:1,1,1>" .. args[1]
        local allPlayers = getOnlinePlayers()
        if allPlayers:size() == 0 then return end
        for i=0, allPlayers:size()-1 do
            local player = allPlayers:get(i)
            if AC_Utils.isStaff(player) then
                sendServerCommand(player, "AC", command, {sendingPlayer:getUsername(), message})
            end
        end
    elseif command == "BioSave" then
        PlayerDB.CharacterBioStorage[sendingPlayer:getUsername()] = {description = args[1]}
        ModData.add("AC_CharacterBioStorage", PlayerDB.CharacterBioStorage)
    elseif command == "BioLoad" then
        sendServerCommand(sendingPlayer, module, command, PlayerDB.CharacterBioStorage[args[1]] or {})
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
