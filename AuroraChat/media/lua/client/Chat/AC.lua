if not isClient() then return end -- only in MP
AC = AC or {}

require "Chat/AC/afk"
require "Chat/AC/buffs"
require "Chat/AC/commands"
require "Chat/AC/config"
require "Chat/AC/handlers"
require "Chat/AC/indicator"
require "Chat/AC/languages"
require "Chat/AC/meta"
require "Chat/AC/parsing"
require "Chat/AC/recorders"
require "Chat/AC/status"

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

function AC.Override(skipDisable)
    if AC.Meta.DisableOverride and not skipDisable then return false end
    
    local accessLevel = getAccessLevel()
    if type(accessLevel) == "string" then
        return string.lower(accessLevel) == "admin"
    end
    
    return false
end

function AC.CanSeePlayer(player, allowSelf, distance)
    if not distance then distance = 10 end
    if AC.Override() then return true end
    if not player then return false end
    local me = getPlayer()
    if not allowSelf and player == me then return false end
    if not me:CanSee(player) then return false end
    if player:isGhostMode() then return false end
    if me:getDistanceSq(player) > distance * distance then return false end
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

--- @param message string
--- @return number,number the xyRange and zRange
function AC.GetRangeFromMessage(message)
    if message:len() < 2 then
        return 0,0
    end
    if message:sub(1,1) ~= "/" then
        return AC.ChatTypes["say"].xyRange, AC.ChatTypes["say"].zRange
    end
    local firstSpace = message:find(" ")
    if not firstSpace then
        return 0,0
    end
    local command = message:sub(1, firstSpace - 1)
    if AC.ChatCommands[command] then
        return AC.ChatTypes[AC.ChatCommands[command].type].xyRange, AC.ChatTypes[AC.ChatCommands[command].type].zRange
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
        if player ~= me and me:getDistanceSq(player) <= range2 and zDist <= zRange and not player:isGhostMode() then
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
