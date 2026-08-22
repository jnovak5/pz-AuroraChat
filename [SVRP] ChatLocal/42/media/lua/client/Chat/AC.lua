if isServer() and not isClient() then return end
AC = AC or {}

require "Chat/AC/afk"
require "Chat/AC/alert"
require "Chat/AC/bio"
require "Chat/AC/buffs"
require "Chat/AC/commands"
require "Chat/AC/config"
require "Chat/AC/handlers"
require "Chat/AC/indicator"
require "Chat/AC/languages"
require "Chat/AC/meta"
require "Chat/AC/parsing"
require "Chat/AC/radio_map"
require "Chat/AC/events_system"
require "Chat/AC/recorders"
require "Chat/AC/status"
require "Chat/AC/voice"
require "Chat/AC/worldmap_hooks"
require "Chat/AC_ISCombatMatchUI"
require "Chat/AC_ISCreateEventUI"
require "Chat/AC_ISEventManageUI"

-- Must be last in require chain
require "Chat/AC/events"

AC.CustomChatCallbacks = {}

-- Dynamically create all possible chat type command, modifier, and language combinations
AC.ChatCommands = {}
for type, typeData in pairs(AC.ChatTypes) do
    for _, typeCommand in pairs(typeData.command) do
        if typeCommand ~= "" then
            AC.ChatCommands["/" .. typeCommand] = {}
            AC.ChatCommands["/" .. typeCommand].type = type
            AC.ChatCommands["/" .. typeCommand].modifier = nil
            AC.ChatCommands["/" .. typeCommand].language = nil
        end
    end
    for modifier, modifierData in pairs(AC.ChatModifiers) do
        for _, modifierCommand in pairs(modifierData.command) do
            for _, typeCommand in pairs(typeData.command) do
                AC.ChatCommands["/" .. modifierCommand .. typeCommand] = {}
                AC.ChatCommands["/" .. modifierCommand .. typeCommand].type = type
                AC.ChatCommands["/" .. modifierCommand .. typeCommand].modifier = modifier
                AC.ChatCommands["/" .. modifierCommand .. typeCommand].language = nil
            end
        end
    end
    for language, _ in pairs(AC.Languages) do
        for _, typeCommand in pairs(typeData.command) do
            if typeCommand ~= "" then
                AC.ChatCommands["/" .. typeCommand .. ":" .. language] = {}
                AC.ChatCommands["/" .. typeCommand .. ":" .. language].type = type
                AC.ChatCommands["/" .. typeCommand .. ":" .. language].modifier = nil
                AC.ChatCommands["/" .. typeCommand .. ":" .. language].language = language
            end
        end
        for modifier, modifierData in pairs(AC.ChatModifiers) do
            for _, modifierCommand in pairs(modifierData.command) do
                for _, typeCommand in pairs(typeData.command) do
                    AC.ChatCommands["/" .. modifierCommand .. typeCommand .. ":" .. language] = {}
                    AC.ChatCommands["/" .. modifierCommand .. typeCommand .. ":" .. language].type = type
                    AC.ChatCommands["/" .. modifierCommand .. typeCommand .. ":" .. language].modifier = modifier
                    AC.ChatCommands["/" .. modifierCommand .. typeCommand .. ":" .. language].language = language
                end
            end
        end
    end
end

function AC.isStaff(player)
    player = player or (getPlayer and getPlayer())
    if not player then return false end
    if not isClient() and not isServer() then
        return (getDebug and getDebug()) == true
    end
    local accessLevel = player.getAccessLevel and player:getAccessLevel()
    if type(accessLevel) == "string" and accessLevel ~= "" then
        local lower = string.lower(accessLevel)
        return lower == "admin" or lower == "moderator" or lower == "overseer" or lower == "gm" or lower == "observer"
    end
    return false
end

function AC.Override(skipDisable)
    if AC.Meta and AC.Meta.DisableOverride and not skipDisable then return false end
    return AC.isStaff()
end

function AC.CanHearAll(player)
    player = player or (getPlayer and getPlayer())
    if not player then return false end

    -- Regular non-staff players can NEVER hear-all
    if not AC.isStaff(player) then
        return false
    end

    if AC.Meta and AC.Meta.DisableOverride then
        return false
    end

    -- If verified staff, check if they have hear-all, ghost, or god modes active
    if player.isHearAll and player:isHearAll() == true then return true end
    if player.isHearAllChat and player:isHearAllChat() == true then return true end
    if player.isHearEveryone and player:isHearEveryone() == true then return true end
    if player.isSeeEveryone and player:isSeeEveryone() == true then return true end
    if player.isGhostMode and player:isGhostMode() == true then return true end
    if player.isGodMod and player:isGodMod() == true then return true end
    if player.isInvisible and player:isInvisible() == true then return true end

    if player.getModData then
        local md = player:getModData()
        if md and (md.isHearAll == true or md.HearAll == true or md.CanHearAll == true or md.bHearAll == true or md.HearEveryone == true or md.hearEveryone == true) then
            return true
        end
    end

    return true -- Staff with override enabled can hear all
end

function AC.GetDistanceSq(playerA, playerB)
    if not playerA or not playerB then return 999999999 end
    local dx = playerA:getX() - playerB:getX()
    local dy = playerA:getY() - playerB:getY()
    return (dx * dx) + (dy * dy)
end

function AC.CanSeePlayer(player, allowSelf, distance)
    if not distance then distance = 10 end
    if not player then return false end
    local me = getPlayer()
    if not allowSelf and player == me then return false end

    -- Verified staff with override enabled can see all
    if AC.isStaff(me) and not (AC.Meta and AC.Meta.DisableOverride) then
        return true
    end

    if not me:CanSee(player) then return false end
    if player:isGhostMode() then return false end
    if AC.GetDistanceSq(me, player) > distance * distance then return false end
    return true
end

function AC.GetBodyParts()
    local bodyParts = {}
    for i=0,16 do
        table.insert(bodyParts, BodyPartType.ToString(BodyPartType.FromIndex(i)))
    end
    return bodyParts
end

function AC.GetInjuries()
    return {
        "Bleeding",
        "Bullet",
        "Burned",
        "Deep Wound",
        "Fracture",
        "Glass Shards",
        "Infected",
        "Scratched",
        "Laceration",
        "Bite",
    }
end

function AC.GetAilments()
    return {
        "Cold",
        "Sickness",
    }
end

--- @param message string
--- @return number,number the xyRange and zRange
function AC.GetRangeFromMessage(message)
    if not message or message:len() == 0 then
        return 0,0
    end
    if message:sub(1,1) ~= "/" then
        local sayType = AC.ChatTypes and AC.ChatTypes["say"]
        return (sayType and sayType.xyRange) or 35, (sayType and sayType.zRange) or 2
    end
    local firstSpace = message:find(" ")
    if not firstSpace then
        return 0,0
    end
    local command = message:sub(1, firstSpace - 1)
    if AC.ChatCommands and AC.ChatCommands[command] then
        local chatType = AC.ChatTypes and AC.ChatTypes[AC.ChatCommands[command].type]
        return (chatType and chatType.xyRange) or 0, (chatType and chatType.zRange) or 0
    end
    return 0,0
end

function AC.GetAllPlayersInRange(range, zRange)
    local players = {}
    local me = getPlayer()
    local online = getOnlinePlayers()
    local range2 = range * range
    zRange = zRange or 0
    for i=0,online:size()-1 do
        local player = online:get(i)
        local zDist = math.abs(player:getZ() - me:getZ())
        if player ~= me and AC.GetDistanceSq(me, player) <= range2 and zDist <= zRange and not player:isGhostMode() then
            table.insert(players, player)
        end
    end
    return players
end

--- @param str string
--- @param sep string|nil
--- @return table
function AC.SplitString(str, sep)
    if not sep then sep = " " end
    local parts = {}
    local part = ""
    local quote = false
    for i=1,str:len() do
        local c = str:sub(i,i)
        if c == '"' then
            quote = not quote
        elseif c == ' ' and not quote then
            if part:len() > 0 then
                table.insert(parts, part)
                part = ""
            end
        else
            part = part .. c
        end
    end
    if part:len() > 0 then
        table.insert(parts, part)
    end
    return parts
end

function AC.GetColor(args)
    local color = args:gsub("^%s*(.-)%s*$", "%1") -- trim
    local rStr, gStr, bStr = color:match("(%d+),(%d+),(%d+)")
    if not rStr or not gStr or not bStr then
        AC_Utils.addErrorToChat("Invalid color format. EX: /color 0,128,255")
        return nil
    end
    local r, g, b = tonumber(rStr), tonumber(gStr), tonumber(bStr)
    if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then
        AC_Utils.addErrorToChat("Color numbers out of range of 0 to 255. EX: /color 0,128,255")
        return nil
    end
    r = math.floor(r/255 * 100)/100
    g = math.floor(g/255 * 100)/100
    b = math.floor(b/255 * 100)/100
    return {r = r, g = g, b = b}
end
