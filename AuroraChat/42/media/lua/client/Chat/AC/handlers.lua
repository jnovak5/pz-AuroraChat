if not isClient() then return end -- only in MP
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

            if command == "/all" and not SandboxVars.AuroraChat.EnableAll and not AC.Override(true) then
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

    message = AC.Parsing.PrependPlayerData(player, message)
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

    if parsedMessage.chatModifier == "ooc" and not SandboxVars.AuroraChat.EnableOOC and not AC.Override(true) then
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

    message = AC.Parsing.PrependPlayerData(player, message)

    if parsedMessage.chatType == "shout" then
        processShoutMessage(message)
    else
        processSayMessage(message)
    end

    for _, radio in ipairs(radiosMuted) do
        ARU_Utils.setRadioBroadcastingInstant(player, radio, true)
    end

    if parsedMessage.chatModifier == nil or parsedMessage.chatModifier == "me" then
        if AC.Meta.IsSaveLastChatEnabled() then
            AC.Meta.LastChat = "/" .. (parsedMessage.chatModifier or "") .. parsedMessage.chatType .. " "
        end
    elseif parsedMessage.chatModifier == "ooc" and AC.Meta.IsSaveLastChatEnabled() then
        AC.Meta.LastChat = "/ooc" .. parsedMessage.chatType .. " "
    end

    for _, callback in ipairs(AC.CustomChatCallbacks) do
        callback(parsedMessage)
    end

    return true
end

local lastRadioAuthor = nil
local lastRadioChannel = nil
local lastRadioMessage = nil

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
        return false
    end

    local hasText, rawText = pcall(function() return chatMessage:getText() end)
    if not hasText or not rawText then
        hasText, rawText = pcall(function() return chatMessage:getTextWithPrefix() end)
    end
    if not hasText or not rawText then return false end
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

    local chattingPlayer = getPlayerFromUsername(parsedMessage.playerUsername)
    local myPlayer = getPlayer()
    local isMe = myPlayer:getUsername() == parsedMessage.playerUsername

    local hasRadio, radioChannel = pcall(function() return chatMessage:getRadioChannel() end)
    if hasRadio and radioChannel > 0 then
        parsedMessage.radioFrequency = radioChannel

        if   lastRadioAuthor == parsedMessage.playerUsername
        and  lastRadioChannel == parsedMessage.radioFrequency
        and  lastRadioMessage == rawText
        then parsedMessage.isOwnRadio = false
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
            local colorRGB = AC.ChatTypes[parsedMessage.chatType].colorRGB
            pcall(function() myPlayer:addLineChatElement(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes[parsedMessage.chatType].xyRange, "radio") end)
            
            if parsedMessage.activeRadio then
                if instanceof(parsedMessage.activeRadio, "IsoRadio") then
                    local success = pcall(function() parsedMessage.activeRadio:addLineChatElement(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes[parsedMessage.chatType].xyRange, "radio") end)
                    if not success then success = pcall(function() parsedMessage.activeRadio:getChatElement():addChatLine(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes[parsedMessage.chatType].xyRange, "radio", true, true, true, true, true, true) end) end
                    if not success then success = pcall(function() parsedMessage.activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1") end) end
                    if not success then success = pcall(function() parsedMessage.activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1) end) end
                    if not success then success = pcall(function() parsedMessage.activeRadio:AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1") end) end
                    if not success then success = pcall(function() parsedMessage.activeRadio:AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1) end) end
                    if not success then pcall(function() myPlayer:addLineChatElement(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes[parsedMessage.chatType].xyRange, "radio") end) end
                elseif instanceof(parsedMessage.activeRadio, "VehiclePart") then
                    local success = pcall(function() parsedMessage.activeRadio:getVehicle():getChatElement():addChatLine(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes[parsedMessage.chatType].xyRange, "radio", true, true, true, true, true, true) end)
                    if not success then success = pcall(function() parsedMessage.activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", "-1") end) end
                    if not success then success = pcall(function() parsedMessage.activeRadio:getDeviceData():AddDeviceText(textToDisplay, colorRGB.r, colorRGB.g, colorRGB.b, "radio", -1) end) end
                end
            end
        end
    else
        local chatType = AC.ChatTypes[parsedMessage.chatType]
        local pos

        if parsedMessage.fromRecorder then
            chatType = AC.ChatTypes["low"]
            local recPlayer = getPlayerFromUsername(chatMessage:getAuthor())
            if not recPlayer then
                pcall(function() chatMessage:setText("") end)
                return true
            end
            if not AC.Meta.IsInRange(myPlayer, recPlayer, chatType.xyRange, chatType.zRange) then
                pcall(function() chatMessage:setText("") end)
                return true
            end
            pos = {x = recPlayer:getX(), y = recPlayer:getY()}
        elseif parsedMessage.isNpc then
            pos = {x = myPlayer:getX(), y = myPlayer:getY(), z = myPlayer:getZ()}
        elseif chattingPlayer then
            if not AC.Meta.IsInRange(myPlayer, chattingPlayer, chatType.xyRange, chatType.zRange) then
                if myPlayer:getZ() == chattingPlayer:getZ() then
                    if parsedMessage.chatType == "whisper" and AC.CanSeePlayer(chattingPlayer, false, AC.ChatTypes["say"].xyRange) then
                        local colorRGB = AC.Meta.GetNameColorRGB(parsedMessage.playerUsername)
                        if parsedMessage.onRadio then
                            pcall(function() chattingPlayer:addLineChatElement("Whispered into a walkie", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "") end)
                        else
                            pcall(function() chattingPlayer:addLineChatElement("Whispered", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "") end)
                        end
                    elseif parsedMessage.chatType == "low" and AC.CanSeePlayer(chattingPlayer, false, AC.ChatTypes["say"].xyRange) then
                        local colorRGB = AC.Meta.GetNameColorRGB(parsedMessage.playerUsername)
                        if parsedMessage.onRadio then
                            pcall(function() chattingPlayer:addLineChatElement("Spoke Quietly into a walkie", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "") end)
                        else
                            pcall(function() chattingPlayer:addLineChatElement("Spoke Quietly", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["say"].xyRange, "") end)
                        end
                    elseif parsedMessage.chatType == "say" and AC.CanSeePlayer(chattingPlayer, false, AC.ChatTypes["loud"].xyRange) then
                        local colorRGB = AC.Meta.GetNameColorRGB(parsedMessage.playerUsername)
                        if parsedMessage.onRadio then
                            pcall(function() chattingPlayer:addLineChatElement("Spoke into a walkie", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["loud"].xyRange, "") end)
                        else
                            pcall(function() chattingPlayer:addLineChatElement("Spoke", colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, AC.ChatTypes["loud"].xyRange, "") end)
                        end
                    end
                end
                pcall(function() chatMessage:setText("") end)
                return true
            end
            pos = {x = chattingPlayer:getX(), y = chattingPlayer:getY()}
        elseif parsedMessage.pos then
            if not AC.Meta.IsInPosRange(myPlayer, parsedMessage.pos, chatType.xyRange, chatType.zRange) then
                pcall(function() chatMessage:setText("") end)
                return true
            end
            pos = parsedMessage.pos
        else
            pcall(function() chatMessage:setText("") end)
            return true
        end

        if AC.Meta.CanUnderstand(parsedMessage.language) and safeHasTrait(myPlayer, "HardOfHearing") and SandboxVars.AuroraChat.EnableHardOfHearing and not isMe then
            local xyRange = chatType.xyRange + 0.99
            local xDist = myPlayer:getX() - pos.x
            local yDist = myPlayer:getY() - pos.y
            local xyDistSq = xDist * xDist + yDist * yDist
            local rangeRatio = xyDistSq / (xyRange * xyRange)
            AC.Parsing.AdjustForHardOfHearing(parsedMessage, rangeRatio)
        end
    end

    if parsedMessage.radioFrequency and parsedMessage.chatModifier == "ooc" then
        return true
    end

    if safeHasTrait(myPlayer, "Deaf") and SandboxVars.AuroraChat.EnableDeaf and (not isMe or parsedMessage.fromRecorder) then
        AC.Parsing.AdjustForDeaf(parsedMessage)
    elseif not AC.Meta.CanUnderstand(parsedMessage.language) then
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

    if chattingPlayer and not parsedMessage.radioFrequency and not parsedMessage.fromRecorder then
        local textOnlyMessage = AC.Parsing.GetTextOnly(parsedMessage)
        textOnlyMessage = textOnlyMessage:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")
        textOnlyMessage = textOnlyMessage:sub(1,1):upper() .. textOnlyMessage:sub(2)
        local colorRGB = AC.Meta.GetSpeechColorRGB()
        if parsedMessage.chatModifier == "ooc" then
            colorRGB = {r = 0.4, g = 0.4, b = 0.4}
        elseif parsedMessage.chatModifier == "alert" then
            colorRGB = {r = 1.0, g = 0.4, b = 0.4}
        end
        pcall(function() chattingPlayer:addLineChatElement(textOnlyMessage, colorRGB.r, colorRGB.g, colorRGB.b, UIFont.Dialogue, 30.0, "") end)
    end

    if parsedMessage.chatModifier == "alert" then
        for _, tab in ipairs(ISChat.instance.tabs) do
            AC.ISChatOriginal.addLineInChat(fakeMessage, tab.tabID)
        end
        ISChat.instance.servermsg = parsedMessage.parts[1].text
        ISChat.instance.servermsgTimer = 5000
        ISChat.instance.panel.blinkTabs = blinkingTabsCurrently
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
        if parsedMessage.isOwnRadio then
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
        pcall(function() chattingPlayer:addLineChatElement(textOnly, 0.4, 0.9, 0.4, UIFont.Dialogue, 30.0, "") end)
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
    if AC.Meta.CanUnderstand(parsedMessage.language) and safeHasTrait(myPlayer, "HardOfHearing") and SandboxVars.AuroraChat.EnableHardOfHearing then
        local chatType = AC.ChatTypes[parsedMessage.chatType]
        local xyRange = chatType.xyRange + 0.99
        local xDist = myPlayer:getX() - chattingPlayer:getX()
        local yDist = myPlayer:getY() - chattingPlayer:getY()
        local xyDistSq = xDist * xDist + yDist * yDist
        local rangeRatio = xyDistSq / (xyRange * xyRange)
        AC.Parsing.AdjustForHardOfHearing(parsedMessage, rangeRatio)
    elseif safeHasTrait(myPlayer, "Deaf") and SandboxVars.AuroraChat.EnableDeaf then
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
                            object:AddDeviceText("", 0, 0, 0, "", "", 30)
                            object:AddDeviceText("", 0, 0, 0, "", "", 30)
                            object:AddDeviceText("", 0, 0, 0, "", "", 30)
                            object:AddDeviceText("", 0, 0, 0, "", "", 30)
                            object:AddDeviceText("", 0, 0, 0, "", "", 30)
                            object:AddDeviceText(AC.Meta.GetName(parsedMessage.playerUsername) .. " " .. AC.Parsing.GetTextOnly(parsedMessage), 0.7, 0.7, 0.7, "", "", 30)
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
                            part:AddDeviceText("", 0, 0, 0, "", "", 30)
                            part:AddDeviceText("", 0, 0, 0, "", "", 30)
                            part:AddDeviceText("", 0, 0, 0, "", "", 30)
                            part:AddDeviceText("", 0, 0, 0, "", "", 30)
                            part:AddDeviceText("", 0, 0, 0, "", "", 30)
                            part:AddDeviceText(AC.Meta.GetName(parsedMessage.playerUsername) .. " " .. AC.Parsing.GetTextOnly(parsedMessage), 0.7, 0.7, 0.7, "", "", 30)
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
