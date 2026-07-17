if not isClient() then return end -- only in MP

AC = AC or {}
AC.Meta = AC.Meta or {}

AC.Meta.DisableOverride = false
AC.Meta.LastChat = nil
AC.Meta.ChatPreferences = AC.Meta.ChatPreferences or {
    SayColor = AC.ChatColors["text"],
    EmoteColor = AC.ChatColors["emote"],
    DoColor = AC.ChatColors["environment"],
    OocColor = AC.ChatColors["ooc"],
    WhisperVolumeColor = AC.ChatColors["volumeprefixes"]["whisper"],
    LowVolumeColor = AC.ChatColors["volumeprefixes"]["low"],
    SayVolumeColor = AC.ChatColors["volumeprefixes"]["say"],
    LoudVolumeColor = AC.ChatColors["volumeprefixes"]["loud"],
    ShoutVolumeColor = AC.ChatColors["volumeprefixes"]["shout"],
    UnreadTabTextColor = {r = 0, g = 0, b = 0},
    UnreadTabBackgroundColor = {r = 1, g = 0, b = 0},
    UnreadTabBlinking = true,
    OverheadTypingIndicator = true,
    SaveLastChat = false,
}

local function changeModifier(modifier, enable)
    local args = {}
    args[1] = enable and "enable" or "disable"
    args[2] = modifier
    sendClientCommand(getPlayer(), "AC", "SetModifier", args)
end

local function getModifier(username, modifier)
    if not AC.PlayerModifiers[username] then return false end
    if not AC.PlayerModifiers[username][modifier] then return false end
    return true
end

local function writeChatPrefs()
    local file = getFileWriter("AC_ChatPreferences.txt", true, false)
    if not file then return end
    for k, v in pairs(AC.Meta.ChatPreferences) do
        if type(v) == "boolean" then
            v = tostring(v)
        elseif type(v) == "table" and v.r ~= nil and v.g ~= nil and v.b ~= nil then
            v = v.r .. "," .. v.g .. "," .. v.b
        elseif type(v) == "number" then
            v = tostring(v)
        elseif type(v) == "string" then
            -- do nothing
        else
            print("AC: Unknown type for chat preference " .. k .. ": " .. type(v))
            v = ""
        end
        file:write(k .. "=" .. v .. "\n")
    end
    file:close()
end

local function writeChatPref(preference, value)
    AC.Meta.ChatPreferences[preference] = value
    writeChatPrefs()
end

local function getChatPref(preference)
    return AC.Meta.ChatPreferences[preference]
end

local function readChatPrefs()
    local file = getFileReader("AC_ChatPreferences.txt", false)
    if not file then return end
    local line = file:readLine()
    while line do
        local split = string.split(line, "=")
        if #split == 2 then
            local val = split[2]
            if val == "true" then
                val = true
            elseif val == "false" then
                val = false
            else
                local r, g, b = val:match("^(%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*)$")
                if r and g and b then
                    local rgb = string.split(val, ",")
                    val = {r = tonumber(rgb[1]), g = tonumber(rgb[2]), b = tonumber(rgb[3])}
                elseif val:match("^%d+$") then
                    val = tonumber(val)
                end
            end
            AC.Meta.ChatPreferences[split[1]] = val
        end
        line = file:readLine()
    end
    file:close()
end

function AC.Meta.GetKnownLanguages()
    local md = getPlayer():getModData()
    local numKnown = md["AC_NumKnownLanguages"] or 0
    if numKnown == 0 then
        md["AC_NumKnownLanguages"] = 1
        md["AC_KnownLanguage1"] = "en"
        return {"en"}
    end
    local languages = {}
    for i=1, numKnown do
        table.insert(languages, md["AC_KnownLanguage" .. i])
    end
    return languages
end

function AC.Meta.AddLanguageTo(username, language)
    sendClientCommand(getPlayer(), "AC", "AddKnownLanguage", {username, language})
end

function AC.Meta.RemoveLanguageFrom(username, language)
    sendClientCommand(getPlayer(), "AC", "RemoveKnownLanguage", {username, language})
end

local function writeLanguages(languages)
    local md = getPlayer():getModData()
    local numKnown = #languages
    if numKnown == 0 then
        md["AC_NumKnownLanguages"] = 1
        md["AC_KnownLanguage1"] = "en"
        return
    end
    md["AC_NumKnownLanguages"] = numKnown
    for i=1, numKnown do
        md["AC_KnownLanguage" .. i] = languages[i]
    end
end

function AC.Meta.AddKnownLanguage(language)
    local languages = AC.Meta.GetKnownLanguages()
    for i=1, #languages do
        if languages[i] == language then return end
    end
    table.insert(languages, language)
    writeLanguages(languages)
end

function AC.Meta.RemoveKnownLanguage(language)
    local known = AC.Meta.GetKnownLanguages()
    local toKeep = {}
    for i=1, #known do
        if known[i] ~= language then
            table.insert(toKeep, known[i])
        end
    end
    writeLanguages(toKeep)
end

function AC.Meta.CanSpeak(language)
    if AC.Override() then return true end
    local known = AC.Meta.GetKnownLanguages()
    for i=1, #known do
        if known[i] == language then return true end
    end
    return false
end

function AC.Meta.CanUnderstand(language)
    if AC.Override() then return true end
    local known = AC.Meta.GetKnownLanguages()
    for i=1, #known do
        if known[i] == language then return true end
    end
    return false
end

function AC.Meta.CanPartiallyUnderstand(language)
    if AC.Override() then return true end
    local known = AC.Meta.GetKnownLanguages()
    for _, l in ipairs(known) do
        for _, partialLanguage in ipairs(AC.Languages[l].canPartiallyUnderstand) do
            if partialLanguage == language then return true end
        end
    end
    return false
end

function AC.Meta.GetCurrentLanguage(username)
    if AC.PlayerLanguages and AC.PlayerLanguages[username] then
        return AC.PlayerLanguages[username]
    end
    return "en"
end

function AC.Meta.SetCurrentLanguage(language)
    sendClientCommand(getPlayer(), "AC", "SetPlayerLanguage", {language})
end

function AC.Meta.IsInRange(myPlayer, chattingPlayer, xyRange, zRange)
    if AC.Override() then return true end
    xyRange = xyRange + 0.99
    if myPlayer:getDistanceSq(chattingPlayer) > xyRange * xyRange or math.abs(myPlayer:getZ() - chattingPlayer:getZ()) > zRange then
        return false
    end
    return true
end

function AC.Meta.IsInPosRange(myPlayer, pos, xyRange, zRange)
    if AC.Override() then return true end
    xyRange = xyRange + 0.99
    local xDist = myPlayer:getX() - pos.x
    local yDist = myPlayer:getY() - pos.y
    local zDist = math.abs(myPlayer:getZ() - pos.z)
    local xyDistSq = xDist * xDist + yDist * yDist
    if xyDistSq > xyRange * xyRange or zDist > zRange then return false end
    return true
end

function AC.Meta.GetStatus(username)
    if AC.PlayerStatus and AC.PlayerStatus[username] then
        return AC.PlayerStatus[username]
    end
    return nil
end

function AC.Meta.SetStatus(status)
    sendClientCommand(getPlayer(), "AC", "SetPlayerStatus", {status})
end

function AC.Meta.GetName(username)
    local name = username
    if AC.PlayerNames and AC.PlayerNames[username] then
        name = AC.PlayerNames[username]
    end
    return name
end

function AC.Meta.SetName(newName)
    local player = getPlayer()
    player:getDescriptor():setForename(newName)
    player:getDescriptor():setSurname("")
    sendPlayerStatsChange(player)
    sendClientCommand(player, "AC", "SetPlayerName", {newName})
end

function AC.Meta.GetNameColor(username)
    local c = AC.ChatColors["playerDefault"]
    if AC.PlayerColors and AC.PlayerColors[username] then
        c = AC.PlayerColors[username]
    end
    return "<RGB:" .. c.r .. "," .. c.g .. "," .. c.b .. ">"
end

function AC.Meta.GetNameColorRGB(username)
    local c = AC.ChatColors["playerDefault"]
    if AC.PlayerColors and AC.PlayerColors[username] then
        c = AC.PlayerColors[username]
    end
    return c
end

function AC.Meta.GetSpeechColorRGB()
    local sayColorStr = AC.Meta.GetSayColor()
    if sayColorStr and sayColorStr ~= "" then
        local rStr, gStr, bStr = sayColorStr:match("<RGB:(%d*%.?%d*),(%d*%.?%d*),(%d*%.?%d*)>")
        if rStr and gStr and bStr then
            return { r = tonumber(rStr), g = tonumber(gStr), b = tonumber(bStr) }
        end
    end
    return { r = 1, g = 1, b = 1 }
end

function AC.Meta.GetColor()
    return AC.Meta.GetNameColor(getPlayer():getUsername())
end

function AC.Meta.SetNameColor(r, g, b)
    sendClientCommand(getPlayer(), "AC", "SetPlayerColor", {r, g, b})
end

function AC.Meta.GetSayColor() return getChatPref("SayColor") or "" end
function AC.Meta.SetSayColor(c) writeChatPref("SayColor", c) end
function AC.Meta.GetEmoteColor() return getChatPref("EmoteColor") or "" end
function AC.Meta.SetEmoteColor(c) writeChatPref("EmoteColor", c) end
function AC.Meta.GetDoColor() return getChatPref("DoColor") or "" end
function AC.Meta.SetDoColor(c) writeChatPref("DoColor", c) end
function AC.Meta.GetOocColor() return getChatPref("OocColor") or "" end
function AC.Meta.SetOocColor(c) writeChatPref("OocColor", c) end
function AC.Meta.GetWhisperVolumeColor() return getChatPref("WhisperVolumeColor") end
function AC.Meta.SetWhisperVolumeColor(c) writeChatPref("WhisperVolumeColor", c) end
function AC.Meta.GetLowVolumeColor() return getChatPref("LowVolumeColor") end
function AC.Meta.SetLowVolumeColor(c) writeChatPref("LowVolumeColor", c) end
function AC.Meta.GetSayVolumeColor() return getChatPref("SayVolumeColor") end
function AC.Meta.SetSayVolumeColor(c) writeChatPref("SayVolumeColor", c) end
function AC.Meta.GetLoudVolumeColor() return getChatPref("LoudVolumeColor") end
function AC.Meta.SetLoudVolumeColor(c) writeChatPref("LoudVolumeColor", c) end
function AC.Meta.GetShoutVolumeColor() return getChatPref("ShoutVolumeColor") end
function AC.Meta.SetShoutColor(c) writeChatPref("ShoutVolumeColor", c) end
function AC.Meta.GetShoutColor() return getChatPref("ShoutVolumeColor") end
function AC.Meta.EnableSaveLastChat() writeChatPref("SaveLastChat", true) end
function AC.Meta.DisableSaveLastChat() writeChatPref("SaveLastChat", false) end
function AC.Meta.IsSaveLastChatEnabled() return getChatPref("SaveLastChat") end

AC.Meta.FocusedPersons = AC.Meta.FocusedPersons or {}

function AC.Meta.FocusOn(username)
    if not AC.Meta.FocusedPersons then AC.Meta.FocusedPersons = {} end
    if AC.Meta.IsFocusedOn(username) then return end
    table.insert(AC.Meta.FocusedPersons, username)
end

function AC.Meta.UnfocusOn(username)
    if not AC.Meta.FocusedPersons then AC.Meta.FocusedPersons = {} end
    local newFocused = {}
    for i=1, #AC.Meta.FocusedPersons do
        if AC.Meta.FocusedPersons[i] ~= username then
            table.insert(newFocused, AC.Meta.FocusedPersons[i])
        end
    end
    AC.Meta.FocusedPersons = newFocused
end

function AC.Meta.HasFocus()
    if not AC.Meta.FocusedPersons then AC.Meta.FocusedPersons = {} end
    return #AC.Meta.FocusedPersons > 0
end

function AC.Meta.IsFocusedOn(username)
    if not AC.Meta.FocusedPersons then AC.Meta.FocusedPersons = {} end
    for i=1, #AC.Meta.FocusedPersons do
        if AC.Meta.FocusedPersons[i] == username then return true end
    end
    return false
end

function AC.Meta.InvitePrivate(username)
    if not username then return false end
    local target = getPlayerFromUsername(username)
    if not target or target == getPlayer() then return false end
    if getPlayer():getDistanceSq(target) > 100 then return false end
    if AC.Meta.PrivateWith then return false end
    sendClientCommand(getPlayer(), "AC", "InvitePrivate", {username})
    AC_Utils.addInfoToChat("You have invited " .. AC.Meta.GetName(username) .. " to a private chat.")
    return true
end

function AC.Meta.OnPrivateInvite(otherUser)
    local w = 300
    local h = 200
    local x = getCore():getScreenWidth() / 2 - w / 2
    local y = getCore():getScreenHeight() / 2 - h / 2
    local othersName = AC.Meta.GetName(otherUser)
    local dialog = ISModalDialog:new(x, y, w, h, "Start private chat with " .. othersName .. "?", true, otherUser, AC.Meta.OnPrivateInviteResponse)
    dialog:initialise()
    dialog:addToUIManager()
end

function AC.Meta.OnPrivateInviteResponse(otherUser, button)
    if button.internal == "YES" then
        AC.Meta.StartPrivate(otherUser)
        ISChat.instance.panel:activateView("Private")
        AC_Utils.addInfoToChat("Private chat started with " .. AC.Meta.GetName(otherUser) .. ".")
        sendClientCommand(getPlayer(), "AC", "AcceptPrivateInvite", {otherUser})
    else
        sendClientCommand(getPlayer(), "AC", "DeclinePrivateInvite", {otherUser})
    end
end

function AC.Meta.StartPrivate(username)
    AC.Meta.PrivatePartner = username
    AC.Meta.ShowPrivateChat = true
end

function AC.Meta.StopPrivate(skipSend)
    if not skipSend and AC.Meta.PrivatePartner then
        sendClientCommand(getPlayer(), "AC", "StopPrivate", {AC.Meta.PrivatePartner})
    end
    AC.Meta.PrivatePartner = nil
end

function AC.Meta.ClosePrivate()
    ISChat.instance.panel:activateView("Private")
    ISChat.instance:onContextClear()
    AC.Meta.ShowPrivateChat = false
    ISChat.instance.panel:activateView("General")
end

function AC.Meta.HasPrivate(simple)
    if simple and AC.Meta.ShowPrivateChat then return true end
    if not AC.Meta.PrivatePartner then return false end
    local others = AC.GetAllPlayersInRange(10, 0)
    if #others ~= 1 or others[1]:getUsername() ~= AC.Meta.PrivatePartner then return false end
    return true
end

function AC.Meta.EnableAdminHammer()
    if not AC_Utils.canModerate(getPlayer()) then return end
    changeModifier("adminHammer", true)
end

function AC.Meta.DisableAdminHammer()
    changeModifier("adminHammer", false)
end

function AC.Meta.HasAdminHammer(username)
    return getModifier(username, "adminHammer")
end

function AC.Meta.EnableAfk()
    changeModifier("afk", true)
end

function AC.Meta.DisableAfk()
    changeModifier("afk", false)
end

function AC.Meta.IsAfk(username)
    return getModifier(username, "afk")
end

function AC.Meta.GetUnreadTabOptions()
    local textColor = getChatPref("UnreadTabTextColor")
    local backgroundColor = getChatPref("UnreadTabBackgroundColor")
    local blinking = getChatPref("UnreadTabBlinking")
    return textColor, backgroundColor, blinking
end

function AC.Meta.SetUnreadTabTextColor(color)
    if not color or color == "" then
        writeChatPref("UnreadTabTextColor", nil)
        AC_Utils.addInfoToChat("Unread tab text color reset to default.")
        return
    end
    local colorVals = AC.GetColor(color)
    if not colorVals then return end
    writeChatPref("UnreadTabTextColor", colorVals)
    AC_Utils.addInfoToChat("<RGB:" .. colorVals.r .. "," .. colorVals.g .. "," .. colorVals.b .. ">Unread tab text color updated.")
end

function AC.Meta.SetUnreadTabBackgroundColor(color)
    if not color or color == "" then
        writeChatPref("UnreadTabBackgroundColor", nil)
        AC_Utils.addInfoToChat("Unread tab background color reset to default.")
        return
    end
    local colorVals = AC.GetColor(color)
    if not colorVals then return end
    writeChatPref("UnreadTabBackgroundColor", colorVals)
    AC_Utils.addInfoToChat("<RGB:" .. colorVals.r .. "," .. colorVals.g .. "," .. colorVals.b .. ">Unread tab background color updated.")
end

function AC.Meta.SetUnreadTabBlinking(blinking)
    writeChatPref("UnreadTabBlinking", blinking)
end

function AC.Meta.GetOverheadTypingIndicator()
    return getChatPref("OverheadTypingIndicator")
end

function AC.Meta.SetOverheadTypingIndicator(enabled)
    writeChatPref("OverheadTypingIndicator", enabled)
end

local radioSyncOption = nil
function AC.Meta.GetRadioSync()
    return radioSyncOption
end

function AC.Meta.SetRadioSync(channel)
    radioSyncOption = channel
end

function AC.Meta.CreateActionsContext(context, myPlayer, players)
    local actionsOption = context:addOptionOnTop("Actions", nil, nil)
    local actionsContext = context:getNew(context)
    context:addSubMenu(actionsOption, actionsContext)

    actionsContext:addOption("Go AFK", nil, AC.Commands.GoAFK)

    local languageOption = actionsContext:addOption("Choose Language", nil, nil)
    local languageContext = actionsContext:getNew(actionsContext)
    actionsContext:addSubMenu(languageOption, languageContext)

    for _, language in ipairs(AC.Meta.GetKnownLanguages()) do
        languageContext:addOption(AC.Languages[language].name .. " (" .. language .. ")", language, AC.Commands.SetLang)
    end

    local focusablePlayers = {}
    local unfocusablePlayers = {}
    local tradablePlayers = {}
    for i=0,players:size()-1 do
        local player = players:get(i)
        local username = player:getUsername()
        if AC.Meta.IsFocusedOn(username) then
            table.insert(unfocusablePlayers, username)
        else
            if AC.CanSeePlayer(player) then
                table.insert(focusablePlayers, username)
            end
        end
        if AC.CanSeePlayer(player) then
            table.insert(tradablePlayers, player)
        end
    end
    table.sort(focusablePlayers)
    table.sort(unfocusablePlayers)
    table.sort(tradablePlayers, function (a,b) return myPlayer:getDistanceSq(a) < myPlayer:getDistanceSq(b) end)

    local focusOption = actionsContext:addOption("Focus On", nil, nil)
    if #focusablePlayers > 0 then
        local focusContext = actionsContext:getNew(actionsContext)
        actionsContext:addSubMenu(focusOption, focusContext)
        for _, username in ipairs(focusablePlayers) do
            focusContext:addOption(AC.Meta.GetName(username) .. " (" .. username .. ")", '"' .. username .. '"', AC.Commands.Focus)
        end
        focusOption.notAvailable = false
    else
        focusOption.notAvailable = true
    end

    local unfocusOption = actionsContext:addOption("Unfocus From", nil, nil)
    if #unfocusablePlayers > 0 then
        local unfocusContext = actionsContext:getNew(actionsContext)
        actionsContext:addSubMenu(unfocusOption, unfocusContext)
        for _, username in ipairs(unfocusablePlayers) do
            unfocusContext:addOption(AC.Meta.GetName(username) .. " (" .. username .. ")", '"' .. username .. '"', AC.Commands.Unfocus)
        end
        unfocusOption.notAvailable = false
    else
        unfocusOption.notAvailable = true
    end

    local tradingOption = actionsContext:addOption("Trade With", nil, nil)
    if #tradablePlayers > 0 then
        local tradingContext = context:getNew(context)
        context:addSubMenu(tradingOption, tradingContext)
        for _, player in ipairs(tradablePlayers) do
            local username = player:getUsername()
            tradingContext:addOption(AC.Meta.GetName(username) .. " (" .. username .. ")", '"' .. username .. '"', AC.Commands.Trade)
        end
        tradingOption.notAvailable = false
    else
        tradingOption.notAvailable = true
    end

    if SandboxVars.AuroraChat.EnablePrivate then
        if AC.Meta.HasPrivate(true) then
            actionsContext:addOption("Close Private Chat", nil, AC.Commands.StopPrivateChat)
        else
            local privateablePlayers = AC.GetAllPlayersInRange(5, 0)
            if #privateablePlayers == 1 then
                local name = AC.Meta.GetName(privateablePlayers[1]:getUsername()) .. " (" .. privateablePlayers[1]:getUsername() .. ")"
                actionsContext:addOption("Invite Private: " .. name, privateablePlayers[1]:getUsername(), AC.Meta.InvitePrivate)
            end
        end
    end

    actionsContext:addOption("Show Help", nil, AC.Commands.Help)
    actionsContext:addOption("List RP Chat Commands", nil, AC.Commands.ListAllCommands)
end

function AC.Meta.CreateCharacterContext(context, myPlayer)
    local characterOption = context:insertOptionAfter("Actions", "Character", nil, nil)
    local characterContext = context:getNew(context)
    context:addSubMenu(characterOption, characterContext)

    local function openEditBio()
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local core = getCore()
        local width = 400 * FONT_SCALE
        local height = 600 * FONT_SCALE
        
        local ISWriteBio = require "Chat/AC_ISWriteBio"
        local ui = ISWriteBio:new((core:getScreenWidth() - width)/2, (core:getScreenHeight() - height)/2, width, height, myPlayer, true)
        ui:initialise()
        ui:addToUIManager()
    end
    characterContext:addOption("Edit Bio", nil, openEditBio)

    if SandboxVars.AuroraChat.EnableModCharacter then
        characterContext:addOption("Set Name", nil, AC.MakeShowDialogPrompt("Input your new name", AC.Commands.SetName))
        characterContext:addOption("Grow Hair", nil, AC.Commands.GrowHair)
        characterContext:addOption("Set Hair Color", nil, AC.MakeColorDialogPrompt("Set Hair Color", AC.Commands.SetHairColor))
        if not myPlayer:isFemale() then
            characterContext:addOption("Grow Beard", nil, AC.Commands.GrowBeard)
            characterContext:addOption("Set Beard Color", nil, AC.MakeColorDialogPrompt("Set Beard Color", AC.Commands.SetBeardColor))
        end
    end

    if SandboxVars.AuroraChat.EnableSelfInjury then
        local injureSelfOption = characterContext:addOption("Add Injury", nil, nil)
        local injureSelfContext = characterContext:getNew(characterContext)
        characterContext:addSubMenu(injureSelfOption, injureSelfContext)

        for _, bodyPartStr in ipairs(AC.GetBodyParts()) do
            local bodyPart = BodyPartType.FromString(bodyPartStr)
            local bodyPartOption = injureSelfContext:addOption(BodyPartType.getDisplayName(bodyPart), nil, nil)
            local bodyPartContext = injureSelfContext:getNew(injureSelfContext)
            injureSelfContext:addSubMenu(bodyPartOption, bodyPartContext)

            for _, injury in ipairs(AC.GetInjuries()) do
                bodyPartContext:addOption(injury, '"' .. bodyPartStr .. '" "' .. injury .. '"', AC.Commands.Injure)
            end
        end
    end
end

function AC.Meta.CreateChatSettingsContext(context)
    local chatSettingsOption = context:insertOptionAfter("Character", "Aurora Chat Settings", nil, nil)
    local chatSettingsContext = context:getNew(context)
    context:addSubMenu(chatSettingsOption, chatSettingsContext)

    local saveLast = AC.Meta.IsSaveLastChatEnabled()
    chatSettingsContext:addOption((saveLast and "Disable" or "Enable") .. " Keep Last", not saveLast and "on" or "off", AC.Commands.KeepLast)

    local chatColorsOption = chatSettingsContext:addOption("Chat Colors", nil, nil)
    local chatColorsContext = chatSettingsContext:getNew(chatSettingsContext)
    chatSettingsContext:addSubMenu(chatColorsOption, chatColorsContext)

    chatColorsContext:addOption("Set Name Color", nil, AC.MakeColorDialogPrompt("New Name Color (blank for default)", AC.Commands.SetColor))
    chatColorsContext:addOption("Set Speech Color", nil, AC.MakeColorDialogPrompt("New Speech Color (blank for default)", AC.Commands.SetSayColor))
    local function resetColors()
        if AC.Commands.SetColor then AC.Commands.SetColor("") end
        if AC.Commands.SetSayColor then AC.Commands.SetSayColor("") end
        if AC.Commands.SetEmoteColor then AC.Commands.SetEmoteColor("") end
        if AC.Commands.SetOocColor then AC.Commands.SetOocColor("") end
        if AC.Meta.SetDoColor then AC.Meta.SetDoColor(nil) end
        if AC.Commands.SetWhisperVolumeColor then AC.Commands.SetWhisperVolumeColor("") end
        if AC.Commands.SetLowVolumeColor then AC.Commands.SetLowVolumeColor("") end
        if AC.Commands.SetSayVolumeColor then AC.Commands.SetSayVolumeColor("") end
        if AC.Commands.SetLoudVolumeColor then AC.Commands.SetLoudVolumeColor("") end
        if AC.Commands.SetShoutVolumeColor then AC.Commands.SetShoutVolumeColor("") end
    end
    chatColorsContext:addOption("Reset Colors", nil, resetColors)
    -- chatColorsContext:addOption("Set Emote Color", nil, AC.MakeColorDialogPrompt("New Emote Color (blank for default)", AC.Commands.SetEmoteColor))
    -- chatColorsContext:addOption("Set Do Color", nil, AC.MakeColorDialogPrompt("New Do Color (blank for default)", AC.Commands.SetDoColor))
    -- chatColorsContext:addOption("Set OOC Color", nil, AC.MakeColorDialogPrompt("New OOC Color (blank for default)", AC.Commands.SetOocColor))

    -- local volumeColorsOption = chatColorsContext:addOption("Volume Prefix Colors", nil, nil)
    -- local volumeColorsContext = chatColorsContext:getNew(chatColorsContext)
    -- chatSettingsContext:addSubMenu(volumeColorsOption, volumeColorsContext)

    -- volumeColorsContext:addOption("Set Whisper Color", nil, AC.MakeColorDialogPrompt("New Whisper Volume Color (blank for default)", AC.Commands.SetWhisperVolumeColor))
    -- volumeColorsContext:addOption("Set Low Color", nil, AC.MakeColorDialogPrompt("New Low Volume Color (blank for default)", AC.Commands.SetLowVolumeColor))
    -- volumeColorsContext:addOption("Set Say Color", nil, AC.MakeColorDialogPrompt("New Say Volume Color (blank for default)", AC.Commands.SetSayVolumeColor))
    -- volumeColorsContext:addOption("Set Loud Color", nil, AC.MakeColorDialogPrompt("New Loud Volume Color (blank for default)", AC.Commands.SetLoudVolumeColor))
    -- volumeColorsContext:addOption("Set Shout Color", nil, AC.MakeColorDialogPrompt("New Shout Volume Color (blank for default)", AC.Commands.SetShoutVolumeColor))

    local unreadTabOption = chatSettingsContext:addOption("Unread Tab Options", nil, nil)
    local unreadTabContext = chatSettingsContext:getNew(chatSettingsContext)
    chatSettingsContext:addSubMenu(unreadTabOption, unreadTabContext)

    local _, _, blinking = AC.Meta.GetUnreadTabOptions()
    unreadTabContext:addOption("Set Title Color", nil, AC.MakeColorDialogPrompt("New Title Color (blank for default)", AC.Meta.SetUnreadTabTextColor))
    unreadTabContext:addOption("Set Background Color", nil, AC.MakeColorDialogPrompt("New Background Color (blank for default)", AC.Meta.SetUnreadTabBackgroundColor))
    unreadTabContext:addOption((blinking and "Disable" or "Enable") .. " Blinking", not blinking, AC.Meta.SetUnreadTabBlinking)

    local overheadTypingIndicator = AC.Meta.GetOverheadTypingIndicator()
    chatSettingsContext:addOption((overheadTypingIndicator and "Disable" or "Enable") .. " Overhead Typing Indicator", not overheadTypingIndicator, AC.Meta.SetOverheadTypingIndicator)
end

function AC.Meta.CreateAdminContext(context, myPlayer, players)
    local adminOption = context:insertOptionAfter("Aurora Chat Settings", "Aurora Chat Admin", nil, nil)
    local adminContext = context:getNew(context)
    context:addSubMenu(adminOption, adminContext)

    if AC.Meta.HasAdminHammer(myPlayer:getUsername()) then
        adminContext:addOption("Disable Admin Hammer", "off", AC.Commands.Hammer)
    else
        adminContext:addOption("Enable Admin Hammer", "on", AC.Commands.Hammer)
    end

    if AC.Meta.DisableOverride then
        adminContext:addOption("Enable Admin Chat Override", "on", AC.Commands.Override)
    else
        adminContext:addOption("Disable Admin Chat Override", "off", AC.Commands.Override)
    end

    local usernames = {}
    for i=0,players:size()-1 do
        local username = players:get(i):getUsername()
        table.insert(usernames, {AC.Meta.GetName(username) .. " (" .. username .. ")", username})
    end
    local languages = {}
    for code, language in pairs(AC.Languages) do
        table.insert(languages, {language.name .. " (" .. code .. ")", code})
    end
    table.sort(usernames, function (a,b) return a[1] < b[1] end)
    table.sort(languages, function (a,b) return a[1] < b[1] end)

    local addLangOption = adminContext:addOption("Add Language", nil, nil)
    local addLangContext = adminContext:getNew(adminContext)
    adminContext:addSubMenu(addLangOption, addLangContext)
    for _,p in ipairs(usernames) do
        local userDisplayName = p[1]
        local username = p[2]
        local playerOption = addLangContext:addOption(userDisplayName, nil, nil)
        local playerContext = addLangContext:getNew(addLangContext)
        addLangContext:addSubMenu(playerOption, playerContext)
        for _, l in ipairs(languages) do
            playerContext:addOption(l[1], '"' .. username .. '" ' .. l[2], AC.Commands.AddLang)
        end
    end

    local removeLangOption = adminContext:addOption("Remove Language", nil, nil)
    local removeLangContext = adminContext:getNew(adminContext)
    adminContext:addSubMenu(removeLangOption, removeLangContext)
    for _,p in ipairs(usernames) do
        local userDisplayName = p[1]
        local username = p[2]
        local playerOption = removeLangContext:addOption(userDisplayName, nil, nil)
        local playerContext = removeLangContext:getNew(removeLangContext)
        removeLangContext:addSubMenu(playerOption, playerContext)
        for _, l in ipairs(languages) do
            playerContext:addOption(l[1], '"' .. username .. '" ' .. l[2], AC.Commands.RemoveLang)
        end
    end
end

Events.OnLoad.Add(function()
    readChatPrefs()
end)
