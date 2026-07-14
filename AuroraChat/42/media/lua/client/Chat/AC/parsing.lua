if not isClient() then return end -- only in MP
AC = AC or {}
AC.Parsing = AC.Parsing or {}

--- @param message string
--- @return table|nil
function AC.Parsing.ParseMessage(message)
    local parsedMessage = {}
    local type = "say"
    local chatModifier = nil
    local language = nil
    local parts = {}
    local playerUsername = nil
    local pos = nil
    local fromRecorder = false
    local emote = false
    local onRadio = false
    local isNpc = false

    while true do
        local unMatch = message:match("^%[UN:([^%]]+)%]")
        local x,y,z = message:match("^%[POS:(%d+),(%d+),(%d+)%]")

        if unMatch then
            playerUsername = unMatch
            message = message:sub(unMatch:len() + 6, message:len())
        elseif x and y and z then
            pos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
            message = message:sub(x:len() + y:len() + z:len() + 9, message:len())
        elseif message:sub(1, 7) == "[radio]" then
            onRadio = true
            message = message:sub(8, message:len())
        elseif message:sub(1, 7) == "[emote]" then
            emote = true
            message = message:sub(8, message:len())
        elseif message:sub(1, 10) == "[Recorder]" then
            fromRecorder = true
            message = message:sub(11, message:len())
        elseif message:sub(1, 5) == "[npc]" then
            isNpc = true
            message = message:sub(6, message:len())
        else
            break
        end
    end

    if message:sub(1, 5) == "/roll" then
        local args = message:sub(7)
        local rollParts = AC.SplitString(args)
        if #rollParts ~= 6 then return nil end

        local volume = rollParts[1]
        local numDice = tonumber(rollParts[2])
        local numSides = tonumber(rollParts[3])
        local bonus = tonumber(rollParts[4])
        local total = tonumber(rollParts[5])
        local rolls = rollParts[6]

        local rollMsg = "threw " .. numDice .. "d" .. numSides
        if bonus ~= 0 then
            rollMsg = rollMsg .. "+" .. bonus
        end
        rollMsg = rollMsg .. " and got " .. rolls .. " for a total of " .. total

        return {
            playerUsername = playerUsername,
            showName = true,
            chatType = volume,
            chatModifier = "roll",
            parts = {
                { type = "roll", text = rollMsg }
            }
        }
    end

    if message:contains("<") then
        message = message:gsub("<", "&lt;")
    end
    if message:contains(">") then
        message = message:gsub(">", "&gt;")
    end

    if message:sub(1,1) == "/" then
        local space = message:find(" ")
        if not space then return nil end
        local command = message:sub(1, space - 1)
        if AC.ChatCommands[command] then
            type = AC.ChatCommands[command].type
            chatModifier = AC.ChatCommands[command].modifier
            language = AC.ChatCommands[command].language
        else
            return nil
        end
        message = message:sub(command:len() + 2, message:len())
    end

    message = message:gsub("^%s*(.-)%s*$", "%1")

    if message == "" then return nil end

    if chatModifier then
        if AC.ChatModifiers[chatModifier].singleLine then
            table.insert(parts, {type = AC.ChatModifiers[chatModifier].type, text = message})
        else
            local currentPart = {type = AC.ChatModifiers[chatModifier].type, text = ""}
            local inQuotes = false
            local i = 1
            while i <= message:len() do
                local char = message:sub(i, i)
                if char == "'" then
                    if i < message:len() and message:sub(i + 1, i + 1) == "'" then
                        char = "\""
                        i = i + 1
                    end
                end
                if char == "\"" then
                    inQuotes = not inQuotes
                    table.insert(parts, currentPart)
                    currentPart = {type = inQuotes and "text" or AC.ChatModifiers[chatModifier].type, text = ""}
                else
                    currentPart.text = currentPart.text .. char
                end
                i = i + 1
            end
            if currentPart.text ~= "" then
                table.insert(parts, currentPart)
            end
        end
    else
        if message:sub(1,1) == "\"" and message:sub(message:len(), message:len()) == "\"" then
            message = message:sub(2, message:len() - 1)
        end
        table.insert(parts, {type = "emote", text = AC.Parsing.DeterminePrefix(type, message) .. " "})
        table.insert(parts, {type = "text", text = message})
    end

    if #parts == 0 then return nil end

    parsedMessage.showName = not chatModifier or not AC.ChatModifiers[chatModifier].hideName
    parsedMessage.chatType = type
    parsedMessage.parts = parts
    parsedMessage.language = language
    parsedMessage.playerUsername = playerUsername
    parsedMessage.chatModifier = chatModifier
    parsedMessage.pos = pos
    parsedMessage.fromRecorder = fromRecorder
    parsedMessage.isEmote = emote
    parsedMessage.onRadio = onRadio
    parsedMessage.isNpc = isNpc
    return parsedMessage
end

function AC.Parsing.GetTextConvertedToOoc(parsedMessage)
    return "/ooc" .. AC.ChatTypes[parsedMessage.chatType].command[1] .. " " .. parsedMessage.parts[2].text
end

function AC.Parsing.PrependPlayerData(player, message)
    local x = tostring(math.floor(player:getX()))
    local y = tostring(math.floor(player:getY()))
    local z = tostring(math.floor(player:getZ()))
    return "[UN:" .. player:getUsername() .. "][POS:" .. x .. "," .. y .. "," .. z .. "]" .. message
end

function AC.Parsing.GetRandomWordsFromMessage(message, percentChancePerWord)
    local words = {}
    local word = ""
    message = message .. " "
    for i=1, message:len() do
        local char = message:sub(i, i)
        if char == " " then
            if ZombRand(100) < percentChancePerWord then
                table.insert(words, word)
            end
            word = ""
        else
            word = word .. char
        end
    end
    return words
end

function AC.Parsing.AdjustForDeaf(parsedMessage)
    if AC.Meta.CanSpeak("asl") and parsedMessage.language == "asl" then return end
    for _, part in ipairs(parsedMessage.parts) do
        if part.type == "text" then
            local newText = ""
            for c in part.text:gmatch(".") do
                if c == " " or c == "." or c == "," or c == "!" or c == "?" or c == ";" or c == ":" then
                    newText = newText .. c
                else
                    newText = newText .. "-"
                end
            end
            part.text = newText
        end
    end
end

AC.Parsing.HoH_BottomRange = 0.35
AC.Parsing.HoH_MaxFail = 0.8
function AC.Parsing.AdjustForHardOfHearing(parsedMessage, rangeRatio)
    if rangeRatio < AC.Parsing.HoH_BottomRange then return end
    if AC.Meta.CanSpeak("asl") and parsedMessage.language == "asl" then return end
    local failChance = (rangeRatio - AC.Parsing.HoH_BottomRange) / (1 - AC.Parsing.HoH_BottomRange) * AC.Parsing.HoH_MaxFail * 100
    for _, part in ipairs(parsedMessage.parts) do
        if part.type == "text" then
            local newText = ""
            for c in part.text:gmatch(".") do
                if ZombRand(100) > failChance or c == " " or c == "." or c == "," or c == "!" or c == "?" or c == ";" or c == ":" then
                    newText = newText .. c
                else
                    newText = newText .. "-"
                end
            end
            part.text = newText
        end
    end
end

function AC.Parsing.AdjustForUnknownLanguage(parsedMessage)
    local canPartiallyUnderstand = AC.Meta.CanPartiallyUnderstand(parsedMessage.language)
    for i=1, #parsedMessage.parts do
        if parsedMessage.parts[i].type == "text" then
            local len = parsedMessage.parts[i].text:len()
            if parsedMessage.language == "asl" then
                local aslText = len > 100 and "a lot of ASL" or (len > 50 and "some ASL" or "a little ASL")
                parsedMessage.parts[i] = { type = "emotemuted", text = aslText }
            else
                local understoodText
                if canPartiallyUnderstand then
                    local understoodWords = AC.Parsing.GetRandomWordsFromMessage(parsedMessage.parts[i].text, 10)
                    if #understoodWords > 0 then
                        understoodText = " but you picked up: " .. table.concat(understoodWords, ", ")
                    end
                end
                local langName = AC.Languages[parsedMessage.language].name
                local unknownText = len > 100 and ("a lot of " .. langName) or (len > 50 and ("some " .. langName) or ("a little " .. langName))
                parsedMessage.parts[i] = { type = "textmuted", text = unknownText }
                if understoodText then
                    parsedMessage.parts[i].text = parsedMessage.parts[i].text .. understoodText
                end
            end
        end
    end
end

function AC.Parsing.DeterminePrefix(chatType, line)
    local hasQuestion = line:find("?") ~= nil
    local hasExclamation = line:find("!") ~= nil
    if hasQuestion then
        return AC.ChatTypes[chatType].questionPrefix
    elseif hasExclamation then
        return AC.ChatTypes[chatType].exclamationPrefix
    else
        return AC.ChatTypes[chatType].defaultPrefix
    end
end

function AC.Parsing.GetSpecialStart(text)
    if text:sub(1, 3) == "'s " then return "'s " end
    if text:sub(1, 2) == ", " then return ", " end
    if text:sub(1, 2) == ": " then return ": " end
    return nil
end

function AC.Parsing.FormatPart(part, omitStart)
    local text = part.text
    if text and omitStart then
        text = text:sub(omitStart + 1, text:len())
    end
    if part.type == "text" then
        local sayColor = AC.Meta.GetSayColor()
        return AC.ChatColors[part.type] .. sayColor .. "\"" .. text .. "\"" .. AC_Utils.MagicSpace
    elseif part.type == "textmuted" then
        return AC.ChatColors[part.type] .. "\"" .. text .. "\"" .. AC_Utils.MagicSpace
    elseif part.type == "ooc" then
        local oocColor = AC.Meta.GetOocColor()
        return oocColor .. "(( " .. text .. " ))" .. AC_Utils.MagicSpace
    elseif part.type == "environment" then
        local doColor = AC.Meta.GetDoColor()
        return doColor .. "[[ " .. text .. " ]]" .. AC_Utils.MagicSpace
    elseif part.type == "emote" then
        local emoteColor = AC.Meta.GetEmoteColor()
        return emoteColor .. text .. AC_Utils.MagicSpace
    elseif part.type == "alert" then
        return AC.ChatColors["alert"] .. text .. AC_Utils.MagicSpace
    elseif part.type == "roll" then
        local fontHeight = getTextManager():MeasureStringY(UIFont.NewSmall, "XXX")
        local imageTag = " <IMAGE:Item_Dice,".. fontHeight .. "," .. fontHeight .. ">"
        return AC.ChatColors[part.type] .. imageTag .. text .. imageTag .. AC_Utils.MagicSpace
    else
        return AC.ChatColors[part.type] .. text .. AC_Utils.MagicSpace
    end
end

local fontHeight = getTextManager():MeasureStringY(UIFont.NewSmall, "XXX")

function AC.Parsing.FormatMessage(parsedMessage)
    local message = ""
    local hadText = false

    local specialStart
    if parsedMessage.playerUsername and parsedMessage.showName then
        specialStart = AC.Parsing.GetSpecialStart(parsedMessage.parts[1].text)
        if parsedMessage.parts[1].type == "emote" and specialStart then
            message = AC.Meta.GetNameColor(parsedMessage.playerUsername) .. AC.Meta.GetName(parsedMessage.playerUsername) .. specialStart .. AC_Utils.MagicSpace
        else
            message = AC.Meta.GetNameColor(parsedMessage.playerUsername) .. AC.Meta.GetName(parsedMessage.playerUsername) .. AC_Utils.MagicSpace
        end
    end

    -- Capitalize first letter of first text part
    for i=1, #parsedMessage.parts do
        if parsedMessage.parts[i].type == "text" then
            parsedMessage.parts[i].text = parsedMessage.parts[i].text:sub(1, 1):upper() .. parsedMessage.parts[i].text:sub(2)
            break
        end
    end

    -- Append punctuation if missing
    for i=#parsedMessage.parts, 1, -1 do
        if parsedMessage.parts[i].type == "text" then
            local lastChar = parsedMessage.parts[i].text:sub(-1)
            if lastChar ~= "." and lastChar ~= "!" and lastChar ~= "?" then
                parsedMessage.parts[i].text = parsedMessage.parts[i].text .. "."
            end
            break
        end
    end

    for n, part in ipairs(parsedMessage.parts) do
        if part.type == "text" or part.type == "textmuted" then hadText = true end
        if n == 1 and specialStart then
            message = message .. AC.Parsing.FormatPart(part, specialStart:len())
        else
            message = message .. AC.Parsing.FormatPart(part)
        end
    end

    if hadText then
        local language = parsedMessage.language or AC.Meta.GetCurrentLanguage(parsedMessage.playerUsername)
        if language ~= "en" or not AC.Meta.CanUnderstand(language) then
            message = AC.ChatColors["langprefix"] .. "[" .. AC.Languages[language].name .. "]" .. AC_Utils.MagicSpace .. message
        end
    end

    if parsedMessage.chatType == "whisper" then
        message = AC.Meta.GetWhisperVolumeColor() .. "[" .. AC.ChatTypes[parsedMessage.chatType].volumePrefix .. "]" .. AC_Utils.MagicSpace .. message
    elseif parsedMessage.chatType == "low" then
        message = AC.Meta.GetLowVolumeColor() .. "[" .. AC.ChatTypes[parsedMessage.chatType].volumePrefix .. "]" .. AC_Utils.MagicSpace .. message
    elseif parsedMessage.chatType == "say" then
        message = AC.Meta.GetSayVolumeColor() .. "[" .. AC.ChatTypes[parsedMessage.chatType].volumePrefix .. "]" .. AC_Utils.MagicSpace .. message
    elseif parsedMessage.chatType == "loud" then
        message = AC.Meta.GetLoudVolumeColor() .. "[" .. AC.ChatTypes[parsedMessage.chatType].volumePrefix .. "]" .. AC_Utils.MagicSpace .. message
    elseif parsedMessage.chatType == "shout" then
        message = AC.Meta.GetShoutVolumeColor() .. "[" .. AC.ChatTypes[parsedMessage.chatType].volumePrefix .. "]" .. AC_Utils.MagicSpace .. message
    end

    if parsedMessage.fromRecorder then
        message = AC.ChatColors["info"] .. "[Recorder]" .. AC_Utils.MagicSpace .. message
    end

    if AC.Meta.HasAdminHammer(parsedMessage.playerUsername) or parsedMessage.parts[1].type == "alert" then
        message = AC.ChatColors["admintag"] .. "(Admin) <IMAGE:Item_Hammer,".. fontHeight .. "," .. fontHeight .. ">" .. AC_Utils.MagicSpace .. message
    end

    if parsedMessage.radioFrequency and parsedMessage.radioFrequency > 0 then
        if parsedMessage.isOwnRadio then
            local freq = tostring(parsedMessage.radioFrequency/1000) .. " MHz"
            message = AC.ChatColors["radiochannel"] .. "[" .. freq .. "]" .. AC_Utils.MagicSpace .. message
        else
            message = AC.ChatColors["radiochannel"] .. "[Radio]" .. AC_Utils.MagicSpace .. message
        end
    end

    return message
end

function AC.Parsing.GetTextOnly(parsedMessage)
    local message = AC.Meta.GetName(parsedMessage.playerUsername)
    for n, part in ipairs(parsedMessage.parts) do
        if n == 1 and part.type == "emote" and AC.Parsing.GetSpecialStart(part.text) then
            message = message .. part.text
        elseif part.type == "textmuted" then
            message = message .. ' "Something you dont understand."'
        elseif part.type == "text" then
            message = message .. ' "' .. part.text .. '"'
        elseif part.type == "ooc" then
            message = message .. " (( " .. part.text .. " ))"
        elseif part.type == "environment" then
            message = message .. " [[ " .. part.text .. " ]]"
        else
            message = message .. " " .. part.text
        end
    end
    if message:contains("&lt;") then message = message:gsub("&lt;", "<") end
    if message:contains("&gt;") then message = message:gsub("&gt;", ">") end
    return message
end

function AC.Parsing.GetOverheadText(parsedMessage)
    local message = ""
    for n, part in ipairs(parsedMessage.parts) do
        if n == 1 and part.type == "emote" and AC.Parsing.GetSpecialStart(part.text) then
            message = message .. part.text
        elseif part.type == "textmuted" then
            message = message .. ' "Something you dont understand."'
        elseif part.type == "text" then
            message = message .. ' "' .. part.text .. '"'
        elseif part.type == "ooc" then
            message = message .. " (( " .. part.text .. " ))"
        elseif part.type == "environment" then
            message = message .. " [[ " .. part.text .. " ]]"
        else
            message = message .. " " .. part.text
        end
    end
    if message:contains("&lt;") then message = message:gsub("&lt;", "<") end
    if message:contains("&gt;") then message = message:gsub("&gt;", ">") end
    if message:sub(1,1) == " " then message = message:sub(2) end
    if message:sub(1,1) == '"' and message:sub(-1) == '"' then
        message = message:sub(2, -2)
    end
    return message
end

function AC.Parsing.GetLogText(parsedMessage)
    local message = ""
    if parsedMessage.radioFrequency and parsedMessage.radioFrequency > 0 then
        local freq = tostring(parsedMessage.radioFrequency/1000) .. " MHz"
        message = message .. "[" .. freq .. "] "
    end
    message = message .. "[" .. AC.ChatTypes[parsedMessage.chatType].volumePrefix .. "] "
    message = message .. AC.Meta.GetName(parsedMessage.playerUsername) .. " " .. AC.Parsing.GetTextOnly(parsedMessage)
    return message
end
