if isServer() and not isClient() then return end
AC = AC or {}
AC.Handlers = AC.Handlers or {}
AC.RadioTabId = 202

local function safeHasTrait(player, traitStr)
    if player.HasTrait then
        return player:HasTrait(traitStr)
    elseif player.hasTrait and CharacterTrait then
        if traitStr == "HardOfHearing" and CharacterTrait.HARD_OF_HEARING then
            return player:hasTrait(CharacterTrait.HARD_OF_HEARING)
        elseif traitStr == "Deaf" and CharacterTrait.DEAF then
            return player:hasTrait(CharacterTrait.DEAF)
        elseif CharacterTrait[traitStr:upper()] then
            return player:hasTrait(CharacterTrait[traitStr:upper()])
        end
    end
    return false
end

function AC.Handlers.SpecialCommand(message)
    if message:sub(1,1) == "/" then
        local firstSpace = message:find(" ")
        if not firstSpace then
            firstSpace = message:len()
        else
            firstSpace = firstSpace - 1
        end
        if firstSpace then
            local command = message:sub(1, firstSpace)

            -- special case for roll volume
            if command:sub(1, 5) == "/roll" then
                local extra = command:sub(6, command:len())
                local args = message:sub(firstSpace + 1, message:len())
                if extra and extra ~= "" then
                    args = extra .. " " .. args
                end
                AC.Commands.Roll(args)
                return true
            end

            if AC.SpecialCommands[command] then
                local handler = AC.SpecialCommands[command].handler
                local args = message:sub(firstSpace + 1, message:len())
                if AC.Commands[handler] then
                    AC.Commands[handler](args)
                    return true
                end
            end

            local sandbox = SandboxVars.SVRPChat or {}
            if command == "/all" and not sandbox.EnableAll and not AC.Override(true) then
                AC_Utils.addErrorToChat("All chat is disabled")
                return true
            end
        end
    end
    return false
end

function AC.Handlers.HandleStaffTabCommand(message)
    if not AC_Utils.isStaff(getPlayer()) then
        AC_Utils.addErrorToChat("You are not staff")
        return true
    end
    sendClientCommand(getPlayer(), 'AC', 'StaffChat', {message})
    return true
end

function AC.Handlers.HandlePrivateTabCommand(message)
    if not AC.Meta.HasPrivate() then
        AC_Utils.addErrorToChat("Private chat partner is no longer close or your two are no longer alone.")
        return true
    end
    local parsedMessage = AC.Parsing.ParseMessage(message)
    if not parsedMessage then
        AC_Utils.addErrorToChat("Invalid Message")
        return true
    end

    local player = getPlayer()
    parsedMessage.playerUsername = player:getUsername()
    if not parsedMessage.language then
        parsedMessage.language = AC.Meta.GetCurrentLanguage(parsedMessage.playerUsername)
    end
    local formatted = AC.Parsing.FormatMessage(parsedMessage)
    local fakeMessage = AC_FakeMessage:new(formatted, {
        author = message.playerUsername,
        radioChannel = nil,
    })
    AC.ISChatOriginal.addLineInChat(fakeMessage, AC.PrivateTabId)

    message = AC.Parsing.PrependPlayerData(player, message, parsedMessage.language)
    sendClientCommand(getPlayer(), 'AC', 'PrivateChat', {AC.Meta.PrivatePartner, message, parsedMessage.language})
    return true
end

function AC.Handlers.CommandEntered(message)
    local currentTabId = ISChat.instance.tabs[ISChat.instance.currentTabID].tabID

    if currentTabId == AC.StaffTabId then
        return AC.Handlers.HandleStaffTabCommand(message)
    end

    if currentTabId == AC.PrivateTabId then
        return AC.Handlers.HandlePrivateTabCommand(message)
    end

    local parsedMessage = AC.Parsing.ParseMessage(message)
    if not parsedMessage then
        return false
    end

    local sandbox = SandboxVars.SVRPChat or {}
    if parsedMessage.chatModifier == "ooc" and not sandbox.EnableOOC and not AC.Override(true) then
        AC_Utils.addErrorToChat("OOC chat is disabled")
        return true
    end

    if parsedMessage.chatModifier == "alert" and not AC.Override(true) then
        AC_Utils.addErrorToChat("Alert chat is disabled for non-staff")
        return true
    end

    if currentTabId == AC.OocTabId then
        if parsedMessage.chatModifier == nil then
            message = AC.Parsing.GetTextConvertedToOoc(parsedMessage)
            parsedMessage = AC.Parsing.ParseMessage(message)
            if not parsedMessage then
                print("AC: ooc conversion failed " .. message)
                AC_Utils.addErrorToChat("Failed to convert to OOC")
                return true
            end
        elseif parsedMessage.chatModifier ~= "ooc" then
            AC_Utils.addErrorToChat("This tab is for OOC chat only")
            return true
        end
    elseif parsedMessage.chatModifier == "ooc" then
        ISChat.instance.panel:activateView("OOC")
    end

    if parsedMessage.language and not AC.Meta.CanSpeak(parsedMessage.language) then
        if not AC.Languages[parsedMessage.language] then
            AC_Utils.addErrorToChat("Unknown language " .. parsedMessage.language)
        else
            AC_Utils.addErrorToChat("You don't know the language " .. AC.Languages[parsedMessage.language].name)
        end
        return true
    end

    local player = getPlayer()
    parsedMessage.playerUsername = player:getUsername()

    if not parsedMessage.language then
        parsedMessage.language = AC.Meta.GetCurrentLanguage(parsedMessage.playerUsername)
    end

    local isGeneralTab = ISChat.instance.tabs[ISChat.instance.currentTabID].tabID == 0
    local isIntoRadioTab = ISChat.instance.tabs[ISChat.instance.currentTabID].tabID == AC.RadioTabId
    local shouldDisableRadio = not isIntoRadioTab or parsedMessage.language == "asl" or parsedMessage.chatModifier == "alert"
    local radiosOn = ARU_Utils.getPlayerRadios(player, true, true, true)
    local radiosMuted = {}
    local intoRadioSynced = false

    if shouldDisableRadio then
        local radioSync = AC.Meta.GetRadioSync()
        for _, radio in ipairs(radiosOn) do
            local isRadioSync = isGeneralTab and ARU_Utils.getRadioFrequency(radio) == radioSync
            if isRadioSync then
                intoRadioSynced = true
            end
            local shouldMuteThisRadio = parsedMessage.language == "asl" or parsedMessage.chatModifier == "alert" or (not isIntoRadioTab and not isGeneralTab)
            if shouldMuteThisRadio then
                ARU_Utils.setRadioBroadcastingInstant(player, radio, false)
                table.insert(radiosMuted, radio)
            end
        end
    end

    if (isIntoRadioTab or isGeneralTab) and #radiosOn > 0 then
        message = "[radio]" .. message
    end

    message = AC.Parsing.PrependPlayerData(player, message, parsedMessage.language)

    if parsedMessage.chatType == "shout" then
        processShoutMessage(message)
    else
        processSayMessage(message)
    end

    for _, radio in ipairs(radiosMuted) do
        ARU_Utils.setRadioBroadcastingInstant(player, radio, true)
    end

    if parsedMessage.chatModifier == nil then
        if AC.Meta.IsSaveLastChatEnabled() then
            if parsedMessage.chatType == "say" then
                AC.Meta.LastChat = ""
            else
                AC.Meta.LastChat = "/" .. parsedMessage.chatType .. " "
            end
        end
    elseif parsedMessage.chatModifier == "me" then
        if AC.Meta.IsSaveLastChatEnabled() then
            AC.Meta.LastChat = "/me "
        end
    elseif parsedMessage.chatModifier == "ooc" and AC.Meta.IsSaveLastChatEnabled() then
        AC.Meta.LastOoc = "/ooc "
    end

    for _, callback in ipairs(AC.CustomChatCallbacks) do
        callback(parsedMessage)
    end

    return true
end

local lastRadioAuthor = nil
local lastRadioChannel = nil
local lastRadioMessage = nil
local lastRadioTime = 0

--- @return boolean
function AC.Handlers.AddLineInChat(chatMessage, tabID)
    pcall(function() chatMessage:setOverHeadSpeech(false) end)
    pcall(function() chatMessage:setShouldAttractZombies(false) end)

    local hasChatId, chatId = pcall(function() return chatMessage:getChatID() end)
    if not hasChatId then chatId = 1 end
    if chatId ~= 1 and chatId ~= 2 and chatId ~= 3 then -- General, Shout, Radio
        return false
    end

    local isAlert = false
    pcall(function() isAlert = chatMessage:isServerAlert() end)
    if isAlert then
        local alertText = (chatMessage.getText and chatMessage:getText()) or ""
        local alertAuthor = (chatMessage.isShowAuthor and chatMessage:isShowAuthor() and chatMessage.getAuthor and chatMessage:getAuthor()) or nil
        if AC.Alert and AC.Alert.ShowServerMessage and alertText ~= "" then
            AC.Alert.ShowServerMessage(alertText, alertAuthor)
        end
        return false
    end

    local hasText, rawText = pcall(function() return chatMessage:getText() end)
    if not hasText or not rawText then
        hasText, rawText = pcall(function() return chatMessage:getTextWithPrefix() end)
    end
    if not hasText or not rawText then return false end

    local isFromDiscord = false
    pcall(function() isFromDiscord = chatMessage:isFromDiscord() end)
    if isFromDiscord then
        local myPlayer = getPlayer()
        local isHearAll = AC.CanHearAll(myPlayer)
        local radios = ARU_Utils.getPlayerRadios(myPlayer, true, false, true)
        if #radios == 0 and not AC.Override() and not isHearAll then
            pcall(function() chatMessage:setText("") end)
            return true
        end
        
        local textOnly = rawText
        local colonPos = textOnly:find(":")
        if colonPos and colonPos < 30 then
            textOnly = textOnly:sub(colonPos + 1):gsub("^%s+", "")
        end
        
        local formattedMessage = "<RGB:0.6,0.6,0.8>[Discord Radio] " .. textOnly
        local fakeMessage = AC_FakeMessage:new(formattedMessage, {
            author = "Radio",
            radioChannel = -1,
            datetimeStr = (pcall(function() return chatMessage:getDatetimeStr() end) and chatMessage:getDatetimeStr()) or "",
        })
        
        local textToDisplay = "[Discord Radio] " .. textOnly
        local colorRGB = {r = 0.6, g = 0.6, b = 0.8}
        local activeRadio = radios[1]
        
        if activeRadio then
            if instanceof(activeRadio, "IsoRadio") then
                local success = pcall(function() activeRadio:addLineChatElement(textToDisplay .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "radio") end)
                if not success then success = pcall(function() activeRadio:getChatElement():addChatLine(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "radio", true, true, true, true, true, true) end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1", 30) end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1, 30) end) end
                if not success then success = pcall(function() activeRadio:AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1", 30) end) end
                if not success then success = pcall(function() activeRadio:AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1, 30) end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1") end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1) end) end
                if not success then success = pcall(function() activeRadio:AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1") end) end
                if not success then success = pcall(function() activeRadio:AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1) end) end
                if not success then pcall(function() myPlayer:addLineChatElement(textToDisplay .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "radio") end) end
            elseif instanceof(activeRadio, "VehiclePart") then
                local success = pcall(function() activeRadio:getVehicle():getChatElement():addChatLine(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "radio", true, true, true, true, true, true) end)
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1", 30) end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1, 30) end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1") end) end
                if not success then success = pcall(function() activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1) end) end
            else
                pcall(function() myPlayer:addLineChatElement(textToDisplay .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "radio") end)
            end
        else
            pcall(function() myPlayer:addLineChatElement(textToDisplay .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "radio") end)
        end

        AC.ISChatOriginal.addLineInChat(fakeMessage, 0)
        AC.ISChatOriginal.addLineInChat(fakeMessage, AC.RadioTabId)
        pcall(function() chatMessage:setText("") end)
        return true
    end

    print("AC DEBUG: rawText = " .. tostring(rawText)); local parsedMessage = AC.Parsing.ParseMessage(rawText)
    if not parsedMessage then
        return false
    end

    if not parsedMessage.playerUsername and
    (
        rawText == getText("IGUI_PlayerText_Sneeze")
        or rawText == getText("IGUI_PlayerText_Cough")
        or rawText == getText("IGUI_PlayerText_SneezeMuffled")
        or rawText == getText("IGUI_PlayerText_CoughMuffled")
    ) then
        pcall(function() chatMessage:setText("") end)
        return true
    end

    local wasZombieYell = false
    if chatId == 2 and parsedMessage.chatType ~= "shout" and not parsedMessage.playerUsername then
        wasZombieYell = true
        parsedMessage.chatType = "shout"
        parsedMessage.playerUsername = chatMessage:getAuthor()
    end

    if not parsedMessage.playerUsername
        or parsedMessage.playerUsername == "Error"
        or parsedMessage.playerUsername == "Server"
    then
        return false
    end

    if not parsedMessage.language then
        parsedMessage.language = AC.Meta.GetCurrentLanguage(parsedMessage.playerUsername)
    end

    local myPlayer = getPlayer()
    local isHearAll = AC.CanHearAll(myPlayer)
    local isMe = myPlayer and (myPlayer:getUsername() == parsedMessage.playerUsername)
    local chattingPlayer = nil

    if isMe or (parsedMessage.playerUsername and myPlayer and parsedMessage.playerUsername == AC.Meta.GetName(myPlayer:getUsername())) then
        chattingPlayer = myPlayer
    end

    if not chattingPlayer and parsedMessage.playerUsername then
        chattingPlayer = getPlayerFromUsername(parsedMessage.playerUsername)
    end

    local author = (chatMessage and chatMessage.getAuthor and chatMessage:getAuthor()) or nil
    if not chattingPlayer and author and author ~= "" then
        chattingPlayer = getPlayerFromUsername(author)
    end

    if not chattingPlayer then
        local online = getOnlinePlayers()
        if online then
            for i = 0, online:size() - 1 do
                local op = online:get(i)
                if op then
                    local opUsername = op.getUsername and op:getUsername()
                    local opCharName = opUsername and AC.Meta.GetName(opUsername)
                    local desc = op.getDescriptor and op:getDescriptor()
                    local descName = desc and (desc:getForename() .. " " .. desc:getSurname())

                    if (opUsername and (opUsername == parsedMessage.playerUsername or opUsername == author))
                    or (opCharName and (opCharName == parsedMessage.playerUsername))
                    or (descName and (descName == parsedMessage.playerUsername)) then
                        chattingPlayer = op
                        break
                    end
                end
            end
        end
    end

    if not chattingPlayer and parsedMessage.pos and parsedMessage.pos.x and parsedMessage.pos.y then
        local targetX = parsedMessage.pos.x
        local targetY = parsedMessage.pos.y
        local targetZ = parsedMessage.pos.z or 0
        local online = getOnlinePlayers()
        if online then
            local closestPlayer = nil
            local closestDistSq = 36
            for i = 0, online:size() - 1 do
                local op = online:get(i)
                if op then
                    local dx = op:getX() - targetX
                    local dy = op:getY() - targetY
                    local dz = math.abs(op:getZ() - targetZ)
                    local distSq = dx * dx + dy * dy + dz * dz * 10
                    if distSq < closestDistSq then
                        closestDistSq = distSq
                        closestPlayer = op
                    end
                end
            end
            if closestPlayer then
                chattingPlayer = closestPlayer
            end
        end
    end

    if isMe and not chattingPlayer then
        chattingPlayer = myPlayer
    end

    print(string.format("[SVRP Chat Debug] AddLineInChat: author=%s, user=%s, isMe=%s, resolvedPlayer=%s, chatType=%s, modifier=%s, radio=%s",
        tostring(chatMessage:getAuthor()),
        tostring(parsedMessage.playerUsername),
        tostring(isMe),
        tostring(chattingPlayer and chattingPlayer:getUsername()),
        tostring(parsedMessage.chatType),
        tostring(parsedMessage.chatModifier),
        tostring(parsedMessage.radioFrequency)))

    local hasRadio, radioChannel = pcall(function() return chatMessage:getRadioChannel() end)
    if hasRadio and radioChannel > 0 then
        parsedMessage.radioFrequency = radioChannel

        if   lastRadioAuthor == parsedMessage.playerUsername
        and  lastRadioChannel == parsedMessage.radioFrequency
        and  lastRadioMessage == rawText
        and  (getTimestampMs() - lastRadioTime < 1000)
        then 
            pcall(function() chatMessage:setText("") end)
            return true
        else
            local activeRadio = nil
            local radios = ARU_Utils.getPlayerRadios(myPlayer, true, false, true)
            for _, radio in ipairs(radios) do
                local channel = ARU_Utils.getRadioFrequency(radio)
                if channel == parsedMessage.radioFrequency then
                    parsedMessage.isOwnRadio = true
                    activeRadio = radio
                    break
                end
            end
            parsedMessage.activeRadio = activeRadio
            if parsedMessage.isOwnRadio then
                lastRadioAuthor = parsedMessage.playerUsername
                lastRadioChannel = parsedMessage.radioFrequency
                lastRadioMessage = rawText
                lastRadioTime = getTimestampMs()
            end
        end

        if parsedMessage.isOwnRadio then
            local textToDisplay = ""
            if parsedMessage.parts then
                for _, part in ipairs(parsedMessage.parts) do
                    if part.text then
                        textToDisplay = textToDisplay .. part.text
                    end
                end
            else
                textToDisplay = rawText
            end
            textToDisplay = AC.Parsing.CleanOverheadText(textToDisplay)
            local colorRGB = AC.ChatTypes[parsedMessage.chatType].colorRGB
            pcall(function() myPlayer:addLineChatElement(textToDisplay .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes[parsedMessage.chatType].xyRange, "radio") end)
            
            if parsedMessage.activeRadio then
                local xyRange = AC.ChatTypes[parsedMessage.chatType].xyRange
                if instanceof(parsedMessage.activeRadio, "IsoRadio") then
                    local success = pcall(function() parsedMessage.activeRadio:addLineChatElement(textToDisplay .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, xyRange, "radio") end)
                    if not success then success = pcall(function() parsedMessage.activeRadio:getChatElement():addChatLine(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, xyRange, "radio", true, true, true, true, true, true) end) end
                    if not success then pcall(function() parsedMessage.activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1", 30) end) end
                elseif instanceof(parsedMessage.activeRadio, "VehiclePart") then
                    local success = pcall(function() parsedMessage.activeRadio:getVehicle():getChatElement():addChatLine(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, xyRange, "radio", true, true, true, true, true, true) end)
                    if not success then pcall(function() parsedMessage.activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1", 30) end) end
                end
            end
        end
    end

    if not parsedMessage.isOwnRadio then
        local chatType = AC.ChatTypes[parsedMessage.chatType]
        local pos
        local effectiveDist = 0
        local horizontalDist = 0
        local zDist = 0
        local isDifferentZ = false

        if parsedMessage.fromRecorder then
            chatType = AC.ChatTypes["low"]
            local recPlayer = getPlayerFromUsername(chatMessage:getAuthor())
            if not recPlayer then
                if not isHearAll then
                    pcall(function() chatMessage:setText("") end)
                    return true
                end
            end
            if not isHearAll and not AC.Meta.IsInRange(myPlayer, recPlayer, chatType.xyRange * 1.5, chatType.zRange) then
                pcall(function() chatMessage:setText("") end)
                return true
            end
            if recPlayer then
                pos = {x = recPlayer:getX(), y = recPlayer:getY(), z = recPlayer:getZ()}
                local dx = myPlayer:getX() - pos.x
                local dy = myPlayer:getY() - pos.y
                zDist = math.abs(myPlayer:getZ() - pos.z)
                horizontalDist = math.sqrt(dx * dx + dy * dy)
                effectiveDist = horizontalDist + zDist * 8.0
            else
                pos = parsedMessage.pos or {x = myPlayer:getX(), y = myPlayer:getY(), z = myPlayer:getZ()}
                zDist = 0
                horizontalDist = 0
                effectiveDist = 0
            end
        elseif parsedMessage.isNpc then
            pos = {x = myPlayer:getX(), y = myPlayer:getY(), z = myPlayer:getZ()}
        elseif chattingPlayer then
            local dx = myPlayer:getX() - chattingPlayer:getX()
            local dy = myPlayer:getY() - chattingPlayer:getY()
            zDist = math.abs(myPlayer:getZ() - chattingPlayer:getZ())
            horizontalDist = math.sqrt(dx * dx + dy * dy)
            isDifferentZ = (zDist > 0)

            -- Check if voice can be heard across floors
            local canHearVoiceAcrossZ = false
            if isDifferentZ then
                if parsedMessage.chatType == "say" and zDist <= 1 and horizontalDist <= (chatType.xyRange * 1.5) then
                    canHearVoiceAcrossZ = true
                elseif parsedMessage.chatType == "loud" and zDist <= 2 and horizontalDist <= (chatType.xyRange * 1.5) then
                    canHearVoiceAcrossZ = true
                elseif parsedMessage.chatType == "shout" and zDist <= 4 and horizontalDist <= (chatType.xyRange * 1.5) then
                    canHearVoiceAcrossZ = true
                end
            end

            -- Trigger player voice chatter for all in-character General chat messages (say, mesay, loud, meloud, etc.)
            local isGeneralDialogue = (not parsedMessage.radioFrequency)
                and (not parsedMessage.isOwnRadio)
                and (not parsedMessage.fromRecorder)
                and (parsedMessage.chatModifier ~= "ooc")
                and (parsedMessage.chatModifier ~= "alert")
                and (parsedMessage.chatModifier ~= "staff")
                and (not parsedMessage.isPrivate)

            if isGeneralDialogue then
                local voicePos = pos or (chattingPlayer and {x = chattingPlayer:getX(), y = chattingPlayer:getY(), z = chattingPlayer:getZ()})
                local voiceType = parsedMessage.chatType or "say"
                if not isDifferentZ then
                    AC.Voice.PlayChatVoice(chattingPlayer, voiceType, rawText, false, voicePos)
                elseif canHearVoiceAcrossZ then
                    AC.Voice.PlayChatVoice(chattingPlayer, voiceType, rawText, true, voicePos)
                end
            end

            -- Floor attenuation penalty (+8m per Z-level difference)
            local floorPenalty = zDist * 8.0
            if (parsedMessage.chatType == "whisper" or parsedMessage.chatType == "low") and zDist > 0 then
                floorPenalty = 9999
            end
            effectiveDist = horizontalDist + floorPenalty
            local maxRange = chatType.maxRange or (chatType.xyRange * 1.5 + 0.99)

            -- If player is on different Z level or out of range, do not show text in chat window or overhead (unless admin hear-all)
            if not isHearAll and (isDifferentZ or effectiveDist > maxRange or zDist > chatType.zRange) then
                pcall(function() chatMessage:setText("") end)
                return true
            end
            pos = {x = chattingPlayer:getX(), y = chattingPlayer:getY(), z = chattingPlayer:getZ()}
        elseif parsedMessage.pos then
            pos = parsedMessage.pos
            local dx = myPlayer:getX() - pos.x
            local dy = myPlayer:getY() - pos.y
            zDist = math.abs(myPlayer:getZ() - (pos.z or myPlayer:getZ()))
            horizontalDist = math.sqrt(dx * dx + dy * dy)
            effectiveDist = horizontalDist + zDist * 8.0
            if not isHearAll and not AC.Meta.IsInPosRange(myPlayer, parsedMessage.pos, chatType.xyRange * 1.5, chatType.zRange) then
                pcall(function() chatMessage:setText("") end)
                return true
            end

            -- Also trigger voice chatter for pos-based messages
            local isGeneralDialogue = (not parsedMessage.radioFrequency)
                and (not parsedMessage.isOwnRadio)
                and (not parsedMessage.fromRecorder)
                and (parsedMessage.chatModifier ~= "ooc")
                and (parsedMessage.chatModifier ~= "alert")
                and (parsedMessage.chatModifier ~= "staff")
                and (not parsedMessage.isPrivate)

            if isGeneralDialogue then
                local isDifferentZ = (zDist > 0)
                AC.Voice.PlayChatVoice(nil, parsedMessage.chatType or "say", rawText, isDifferentZ, pos)
            end
        else
            if not isHearAll then
                pcall(function() chatMessage:setText("") end)
                return true
            end
        end

        if not isMe and parsedMessage.chatModifier ~= "ooc" and not isHearAll then
            local clearRange = chatType.clearRange or chatType.xyRange
            local maxRange = chatType.maxRange or (chatType.xyRange * 1.5)
            if zDist > 0 then
                local zMuffle = math.min(0.6, 0.25 * zDist)
                for _, part in ipairs(parsedMessage.parts) do
                    if part.text then
                        part.text = AC.Parsing.ScrambleTextByDistance(part.text, effectiveDist, clearRange * (1 - zMuffle), maxRange)
                    end
                end
            else
                for _, part in ipairs(parsedMessage.parts) do
                    if part.text then
                        part.text = AC.Parsing.ScrambleTextByDistance(part.text, horizontalDist, clearRange, maxRange)
                    end
                end
            end
        end

        local sandbox = SandboxVars.SVRPChat or {}
        if parsedMessage.chatModifier ~= "ooc" and AC.Meta.CanUnderstand(parsedMessage.language) and safeHasTrait(myPlayer, "HardOfHearing") and sandbox.EnableHardOfHearing and not isMe and not isHearAll then
            local xyRange = chatType.xyRange + 0.99
            local xDist = myPlayer:getX() - (pos and pos.x or myPlayer:getX())
            local yDist = myPlayer:getY() - (pos and pos.y or myPlayer:getY())
            local xyDistSq = xDist * xDist + yDist * yDist
            local rangeRatio = xyDistSq / (xyRange * xyRange)
            AC.Parsing.AdjustForHardOfHearing(parsedMessage, rangeRatio)
        end
    end

    if parsedMessage.radioFrequency and parsedMessage.chatModifier == "ooc" then
        return true
    end

    local sandbox = SandboxVars.SVRPChat or {}
    if parsedMessage.chatModifier ~= "ooc" and safeHasTrait(myPlayer, "Deaf") and sandbox.EnableDeaf and (not isMe or parsedMessage.fromRecorder) and not isHearAll then
        AC.Parsing.AdjustForDeaf(parsedMessage)
    elseif parsedMessage.chatModifier ~= "ooc" and not AC.Meta.CanUnderstand(parsedMessage.language) and not isHearAll then
        AC.Parsing.AdjustForUnknownLanguage(parsedMessage)
    end

    local formattedMessage = AC.Parsing.FormatMessage(parsedMessage)

    local fakeMessage = AC_FakeMessage:new(formattedMessage, {
        author = chatMessage:getAuthor(),
        radioChannel = hasRadio and radioChannel or -1,
        datetimeStr = (pcall(function() return chatMessage:getDatetimeStr() end) and chatMessage:getDatetimeStr()) or "",
    })

    local blinkingTabsCurrently = {}
    if isMe or parsedMessage.chatModifier == "alert" then
        for _, tabTitle in ipairs(ISChat.instance.panel.blinkTabs) do
            table.insert(blinkingTabsCurrently, tabTitle)
        end
    end

    if chattingPlayer and not parsedMessage.radioFrequency and not parsedMessage.fromRecorder and (not isDifferentZ or isHearAll) then
        local textOnlyMessage = AC.Parsing.GetTextOnly(parsedMessage)
        textOnlyMessage = textOnlyMessage:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")
        textOnlyMessage = textOnlyMessage:sub(1,1):upper() .. textOnlyMessage:sub(2)
        textOnlyMessage = AC.Parsing.CleanOverheadText(textOnlyMessage)
        local colorRGB = AC.Meta.GetSpeechColorRGB()
        if parsedMessage.chatModifier == "ooc" then
            colorRGB = {r = 0.4, g = 0.4, b = 0.4}
        elseif parsedMessage.chatModifier == "alert" then
            colorRGB = {r = 1.0, g = 0.4, b = 0.4}
        end
        local overheadRadius = isHearAll and 9999.0 or 30.0
        if not AC.PlayerChatTimes then AC.PlayerChatTimes = {} end; AC.PlayerChatTimes[chattingPlayer:getUsername()] = getTimeInMillis(); pcall(function() chattingPlayer:addLineChatElement(textOnlyMessage .. "", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, overheadRadius, "") end)
    end

    if parsedMessage.chatModifier == "alert" then
        for _, tab in ipairs(ISChat.instance.tabs) do
            AC.ISChatOriginal.addLineInChat(fakeMessage, tab.tabID)
        end
        ISChat.instance.servermsg = parsedMessage.parts[1].text
        ISChat.instance.servermsgTimer = 10000
        ISChat.instance.panel.blinkTabs = blinkingTabsCurrently
        if AC.Alert and AC.Alert.ShowServerMessage then
            AC.Alert.ShowServerMessage(parsedMessage.parts[1].text, parsedMessage.author)
        end
        return true
    end

    local currentTabId = ISChat.instance.tabs[ISChat.instance.currentTabID].tabID
    local doInGeneral = false
    local doInFocus = false
    local doInRadio = false
    local doInOOC = false

    local radioSync = AC.Meta.GetRadioSync()
    if parsedMessage.chatModifier == "ooc" then
        doInOOC = true
    else
        doInGeneral = true
        if parsedMessage.isOwnRadio or (parsedMessage.radioFrequency and (AC.Override() or isHearAll)) then
            doInRadio = true
        end

        if AC.Meta.IsFocusedOn(parsedMessage.playerUsername) or (currentTabId == AC.FocusTabId and isMe) then
            doInFocus = true
        end
    end

    if parsedMessage.chatModifier == nil or parsedMessage.chatModifier == "me" then
        AC.Buffs.ApplyRpBuffs()
    end

    if not parsedMessage.isEmote then
        if doInGeneral then
            AC.ISChatOriginal.addLineInChat(fakeMessage, 0)
        end
        if doInFocus then
            AC.ISChatOriginal.addLineInChat(fakeMessage, AC.FocusTabId)
        end
        if doInRadio then
            AC.ISChatOriginal.addLineInChat(fakeMessage, AC.RadioTabId)
        end
        if doInOOC then
            AC.ISChatOriginal.addLineInChat(fakeMessage, AC.OocTabId)
        end
        writeLog("ReadableChat", AC.Parsing.GetLogText(parsedMessage))
    end

    if parsedMessage.radioFrequency then
        AC.Handlers.FixWorldRadios(myPlayer, parsedMessage)
    end

    if (currentTabId == AC.RadioTabId or currentTabId == 0) and not wasZombieYell and isMe then
        local radios = ARU_Utils.getPlayerRadios(getPlayer(), true, true, true)
        for _, radio in ipairs(radios) do
            local channel = ARU_Utils.getRadioFrequency(radio)
            parsedMessage.radioFrequency = channel
            local radioFormatted = AC.Parsing.FormatMessage(parsedMessage)
            local radioMessage = AC_FakeMessage:new(radioFormatted, {
                author = chatMessage:getAuthor(),
                radioChannel = hasRadio and radioChannel or -1,
                datetimeStr = (pcall(function() return chatMessage:getDatetimeStr() end) and chatMessage:getDatetimeStr()) or "",
            })
            AC.ISChatOriginal.addLineInChat(radioMessage, currentTabId)
        end
    end

    if isMe then
        ISChat.instance.panel.blinkTabs = blinkingTabsCurrently
    end

    if parsedMessage.chatModifier ~= "ooc" then
        local primaryHand = myPlayer:getPrimaryHandItem()
        local secondaryHand = myPlayer:getSecondaryHandItem()
        if primaryHand and primaryHand:getType() == "ACRecorder" then
            if AC.Recorders.IsRecording(primaryHand) then
                AC.Recorders.SaveToRecorder(myPlayer, primaryHand, rawText)
            end
        end
        if secondaryHand and secondaryHand:getType() == "ACRecorder" then
            if AC.Recorders.IsRecording(secondaryHand) then
                AC.Recorders.SaveToRecorder(myPlayer, secondaryHand, rawText)
            end
        end
    end

    return true
end

function AC.Handlers.AddStaffMessage(otherPlayerUsername, message)
    if not AC_Utils.isStaff(getPlayer()) then
        return
    end

    local fakeMessage = AC_FakeMessage:new(message, {
        author = otherPlayerUsername,
        radioChannel = nil,
    })
    AC.ISChatOriginal.addLineInChat(fakeMessage, AC.StaffTabId)
    
    local chattingPlayer = getPlayerFromUsername(otherPlayerUsername)
    if chattingPlayer then
        local textOnly = message:gsub("<[^>]+>", "")
        textOnly = AC.Parsing.CleanOverheadText(textOnly)
        if not AC.PlayerChatTimes then AC.PlayerChatTimes = {} end; AC.PlayerChatTimes[chattingPlayer:getUsername()] = getTimeInMillis(); pcall(function() chattingPlayer:addLineChatElement(textOnly .. "", 0.4, 0.9, 0.4, UIFont.Dialogue, 30.0, "") end)
    end
end

function AC.Handlers.AddPrivateMessage(otherPlayerUsername, message)
    if not AC.Meta.HasPrivate() then
        return
    end
    local chattingPlayer
    for i=0, getOnlinePlayers():size()-1 do
        local player = getOnlinePlayers():get(i)
        if player:getUsername() == otherPlayerUsername then
            chattingPlayer = player
            break
        end
    end
    if not chattingPlayer then return end
    local myPlayer = getPlayer()
    local parsedMessage = AC.Parsing.ParseMessage(message)
    parsedMessage.playerUsername = otherPlayerUsername
    if not parsedMessage.language then
        parsedMessage.language = AC.Meta.GetCurrentLanguage(parsedMessage.playerUsername)
    end
    local sandbox = SandboxVars.SVRPChat or {}
    local isHearAll = AC.CanHearAll(myPlayer)
    if isHearAll then
        -- Skip all hard of hearing, deaf, and language checks
    elseif AC.Meta.CanUnderstand(parsedMessage.language) and safeHasTrait(myPlayer, "HardOfHearing") and sandbox.EnableHardOfHearing then
        local chatType = AC.ChatTypes[parsedMessage.chatType]
        local xyRange = chatType.xyRange + 0.99
        local xDist = myPlayer:getX() - chattingPlayer:getX()
        local yDist = myPlayer:getY() - chattingPlayer:getY()
        local xyDistSq = xDist * xDist + yDist * yDist
        local rangeRatio = xyDistSq / (xyRange * xyRange)
        AC.Parsing.AdjustForHardOfHearing(parsedMessage, rangeRatio)
    elseif safeHasTrait(myPlayer, "Deaf") and sandbox.EnableDeaf then
        AC.Parsing.AdjustForDeaf(parsedMessage)
    elseif not AC.Meta.CanUnderstand(parsedMessage.language) then
        AC.Parsing.AdjustForUnknownLanguage(parsedMessage)
    end
    local formatted = AC.Parsing.FormatMessage(parsedMessage)

    local fakeMessage = AC_FakeMessage:new(formatted, {
        author = otherPlayerUsername,
        radioChannel = nil,
    })
    AC.ISChatOriginal.addLineInChat(fakeMessage, AC.PrivateTabId)
    AC.Buffs.ApplyRpBuffs()
end

function AC.Handlers.FixWorldRadios(myPlayer, parsedMessage)
    local playerX = myPlayer:getX()
    local playerY = myPlayer:getY()
    for x=playerX-15,playerX+15,1 do
    for y=playerY-15,playerY+15,1 do
    for z=0,7,1 do
        local square = getCell():getGridSquare(x, y, z)
        if square then
            local objects = square:getObjects()
            for i=0,objects:size()-1,1 do
                local object = objects:get(i)
                if instanceof(object, "IsoRadio") then
                    if ARU_Utils.isRadioOn(object) then
                        local channel = ARU_Utils.getRadioFrequency(object)
                        if channel == parsedMessage.radioFrequency then
                            local txt = AC.Meta.GetName(parsedMessage.playerUsername) .. " " .. AC.Parsing.GetTextOnly(parsedMessage)
                            local function addTextSafe(t)
                                local s = pcall(function() object:AddDeviceText(t, 0.7, 0.7, 0.7, "", "", 30) end)
                                if not s then s = pcall(function() object:getDeviceData():AddDeviceText(t, 0.7, 0.7, 0.7, "radio", "-1", 30) end) end
                                if not s then s = pcall(function() object:getDeviceData():AddDeviceText(t, 0.7, 0.7, 0.7, "radio", -1, 30) end) end
                                if not s then s = pcall(function() object:getDeviceData():AddDeviceText(t, 0.7, 0.7, 0.7, "radio", "-1") end) end
                                if not s then pcall(function() object:getDeviceData():AddDeviceText(t, 0.7, 0.7, 0.7, "radio", -1) end) end
                            end
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe(txt)
                        end
                    end
                end
            end
            local movingObjects = square:getMovingObjects()
            for i=0,movingObjects:size()-1,1 do
                local movingObject = movingObjects:get(i)
                if instanceof(movingObject, "BaseVehicle") then
                    local parts = movingObject:getPartCount()
                    for j=0,parts-1 do
                        local part = movingObject:getPartByIndex(j)
                        local data = part:getDeviceData()
                        if data and data:getIsTurnedOn() and data:getChannel() == parsedMessage.radioFrequency then
                            local txt = AC.Meta.GetName(parsedMessage.playerUsername) .. " " .. AC.Parsing.GetTextOnly(parsedMessage)
                            local function addTextSafe(t)
                                local s = pcall(function() part:getVehicle():getChatElement():addChatLine(t, 0.7, 0.7, 0.7, UIFont.Dialogue, 30, "radio", true, true, true, true, true, true) end)
                                if not s then s = pcall(function() data:AddDeviceText(t, 0.7, 0.7, 0.7, "radio", "-1", 30) end) end
                                if not s then s = pcall(function() data:AddDeviceText(t, 0.7, 0.7, 0.7, "radio", -1, 30) end) end
                                if not s then s = pcall(function() data:AddDeviceText(t, 0.7, 0.7, 0.7, "radio", "-1") end) end
                                if not s then pcall(function() data:AddDeviceText(t, 0.7, 0.7, 0.7, "radio", -1) end) end
                            end
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe("")
                            addTextSafe(txt)
                        end
                    end
                end
            end
        end
    end end end
end

function AC.Handlers.DrawRadioPlaceholder(chatInstance)
    local message = ""
    local currentLang = AC.Meta.GetCurrentLanguage(getPlayer():getUsername())
    if currentLang and currentLang ~= "en" then
        message = "Speaking " .. AC.Languages[currentLang].name
    end
    local me = getPlayer()
    local textEntry = chatInstance.textEntry
    if not ARU_Utils.AreAnyRadiosTransmitting(me) then
        if message ~= "" then message = message .. ", " end
        message = message .. "No radio is transmitting"
    else
        local frequencies = {}
        local radios = ARU_Utils.getPlayerRadios(me, true, true, true)
        for _, radio in ipairs(radios) do
            table.insert(frequencies, tostring(ARU_Utils.getRadioFrequency(radio)/1000) .. " MHz")
        end
        local transmitMessage = "TX on: " .. table.concat(frequencies, ", ")
        local width = getTextManager():MeasureStringX(UIFont.Medium, message .. ", " .. transmitMessage)
        if width > textEntry:getWidth() then
            transmitMessage = "TX on " .. #frequencies .. " frequencies"
        end
        if message ~= "" then message = message .. ", " end
        message = message .. transmitMessage
    end
    chatInstance:drawText(message, textEntry:getX() + 5, textEntry:getY() + 4, 1, 0.2, 0.2, 0.2, UIFont.Medium)
end

function AC.Handlers.DrawFocusPlaceholder(chatInstance)
    local message = ""
    local currentLang = AC.Meta.GetCurrentLanguage(getPlayer():getUsername())
    if currentLang and currentLang ~= "en" then
        message = "Speaking " .. AC.Languages[currentLang].name
    end
    local textEntry = chatInstance.textEntry
    local focusedNames = {}
    for _, username in ipairs(AC.Meta.FocusedPersons) do
        table.insert(focusedNames, AC.Meta.GetName(username))
    end
    local focusedOnMessage = "Focused on: " .. table.concat(focusedNames, ", ")
    local width = getTextManager():MeasureStringX(UIFont.Medium, message .. ", " .. focusedOnMessage)
    if width > textEntry:getWidth() then
        focusedOnMessage = "Focused on " .. #focusedNames .. " players"
    end
    if message ~= "" then message = message .. ", " end
    message = message .. focusedOnMessage
    chatInstance:drawText(message, textEntry:getX() + 5, textEntry:getY() + 4, 0.2, 0.2, 1, 0.7, UIFont.Medium)
end

function AC.Handlers.DrawGeneralPlaceholder(chatInstance)
    local message = ""
    local currentLang = AC.Meta.GetCurrentLanguage(getPlayer():getUsername())
    if currentLang and currentLang ~= "en" then
        message = "Speaking " .. AC.Languages[currentLang].name
    end

    local me = getPlayer()
    local textEntry = chatInstance.textEntry
    if ARU_Utils.AreAnyRadiosTransmitting(me) then
        local frequencies = {}
        local radios = ARU_Utils.getPlayerRadios(me, true, true, true)
        for _, radio in ipairs(radios) do
            table.insert(frequencies, tostring(ARU_Utils.getRadioFrequency(radio)/1000) .. " MHz")
        end
        local transmitMessage = "TX on: " .. table.concat(frequencies, ", ")
        local width = getTextManager():MeasureStringX(UIFont.Medium, message .. ", " .. transmitMessage)
        if width > textEntry:getWidth() then
            transmitMessage = "TX on " .. #frequencies .. " frequencies"
        end
        if message ~= "" then message = message .. ", " end
        message = message .. transmitMessage
    else
        local radioSync = AC.Meta.GetRadioSync()
        if radioSync then
            if message ~= "" then message = message .. ", " end
            message = message .. "Synced with " .. tostring(radioSync/1000) .. " MHz"
        end
    end

    if message ~= "" then
        chatInstance:drawText(message, textEntry:getX() + 5, textEntry:getY() + 4, 0.4, 0.4, 1, 0.4, UIFont.Medium)
    end
end

function AC.Handlers.IsOutdated(text)
    if text:sub(1, 3) == "/do" then
        AC_Utils.addErrorToChat("The /do command is no longer supported. Use /me for emotes, and /env for environmental.")
        return true
    end
    return false
end
