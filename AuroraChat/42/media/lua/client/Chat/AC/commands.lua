if not isClient() then return end -- only in MP
AC = AC or {}
AC.Commands = AC.Commands or {}
AC.TabHandlers = AC.TabHandlers or {}

function AC.Commands.SetName(args)
    local name = args:gsub("^%s*(.-)%s*$", "%1")
    if name == nil or name == "" then
        AC_Utils.addErrorToChat("Invalid name. Use /name John")
        return
    end
    if name:len() > 32 then
        AC_Utils.addErrorToChat("Name too long. Use /name John")
        return
    end
    AC.Meta.SetName(name)
    AC_Utils.addInfoToChat("Name set to " .. name)
end

function AC.Commands.SetColor(args)
    if not args or args == "" then
        AC.Meta.SetNameColor(nil, nil, nil)
        AC_Utils.addInfoToChat("Color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    if ((color.r + color.g + color.b) / 3) < 0.3 and not AC.Override() then
        AC_Utils.addErrorToChat("Color too dark. Try a brighter color (higher numbers).")
        return
    end
    AC.Meta.SetNameColor(color.r, color.g, color.b)
    AC_Utils.addInfoToChat("<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">Color has been updated!")
end

function AC.Commands.SetSayColor(args)
    if not args or args == "" then
        AC.Meta.SetSayColor(nil)
        AC_Utils.addInfoToChat("Say color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetSayColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Say color has been updated!")
end

function AC.Commands.SetEmoteColor(args)
    if not args or args == "" then
        AC.Meta.SetEmoteColor(nil)
        AC_Utils.addInfoToChat("Emote color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetEmoteColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Emote color has been updated!")
end

function AC.Commands.SetOocColor(args)
    if not args or args == "" then
        AC.Meta.SetOocColor(nil)
        AC_Utils.addInfoToChat("OOC color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetOocColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "OOC color has been updated!")
end

function AC.Commands.SetWhisperVolumeColor(args)
    if not args or args == "" then
        AC.Meta.SetWhisperVolumeColor(AC.ChatColors["volumeprefixes"]["whisper"])
        AC_Utils.addInfoToChat(AC.Meta.GetWhisperVolumeColor() .. "Whisper color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetWhisperVolumeColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Whisper color has been updated!")
end

function AC.Commands.SetLowVolumeColor(args)
    if not args or args == "" then
        AC.Meta.SetLowVolumeColor(AC.ChatColors["volumeprefixes"]["low"])
        AC_Utils.addInfoToChat(AC.Meta.GetLowVolumeColor() .. "Low color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetLowVolumeColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Low color has been updated!")
end

function AC.Commands.SetSayVolumeColor(args)
    if not args or args == "" then
        AC.Meta.SetSayVolumeColor(AC.ChatColors["volumeprefixes"]["say"])
        AC_Utils.addInfoToChat(AC.Meta.GetSayVolumeColor() .. "Say volume color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetSayVolumeColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Say volume color has been updated!")
end

function AC.Commands.SetLoudVolumeColor(args)
    if not args or args == "" then
        AC.Meta.SetLoudVolumeColor(AC.ChatColors["volumeprefixes"]["loud"])
        AC_Utils.addInfoToChat(AC.Meta.GetLoudVolumeColor() .. "Loud color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetLoudVolumeColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Loud color has been updated!")
end

function AC.Commands.SetShoutVolumeColor(args)
    if not args or args == "" then
        AC.Meta.SetShoutColor(AC.ChatColors["volumeprefixes"]["shout"])
        AC_Utils.addInfoToChat(AC.Meta.GetShoutColor() .. "Shout color reset to default.")
        return
    end
    local color = AC.GetColor(args)
    if not color then return end
    local rgbString = "<RGB:" .. color.r .. "," .. color.g .. "," .. color.b .. ">"
    AC.Meta.SetShoutColor(rgbString)
    AC_Utils.addInfoToChat(rgbString .. "Shout color has been updated!")
end

function AC.Commands.SetLang(args)
    local lang = args:gsub("^%s*(.-)%s*$", "%1")
    if lang == nil or lang == "" then
        local currentLang = AC.Meta.GetCurrentLanguage(getPlayer():getUsername())
        local myLangs = AC.Meta.GetKnownLanguages()
        local msg = "Current language is " .. AC.Languages[currentLang].name .. " (" .. currentLang .. ")<LINE><LINE>Known languages:<INDENT:8>"
        for _, l in ipairs(myLangs) do
            msg = msg .. "<LINE>" .. AC.Languages[l].name .. " (" .. l .. ")" .. AC_Utils.MagicSpace
        end
        msg = msg .. "<LINE><LINE><INDENT:0>To Change language use /lang XX where XX is the language code. EX: /lang en"
        AC_Utils.addInfoToChat(msg)
        return
    end
    if lang == "all" then
        local langs = {}
        for l, data in pairs(AC.Languages) do
            table.insert(langs, data.name .. " (" .. l .. ")")
        end
        local msg = "All Languages:<LINE><INDENT:8>" .. table.concat(langs, ", ") .. "<LINE><INDENT:0>"
        AC_Utils.addInfoToChat(msg)
        return
    end
    if not AC.Languages[lang] then
        AC_Utils.addErrorToChat("Invalid language. Use /lang XX where XX is the language code. EX: /lang en")
        return
    end
    if not AC.Meta.CanSpeak(lang) then
        AC_Utils.addErrorToChat("You don't know that language. To see your languages use /lang all")
        return
    end
    AC.Meta.SetCurrentLanguage(lang)
    AC_Utils.addInfoToChat("Language set to " .. AC.Languages[lang].name .. " (" .. lang .. ")")
end

local addLangUsageStr = 'Use "/addlang username XX" where XX is the language code. EX: /addlang "John Smith" en'
local removeLangUsageStr = 'Use "/removelang username XX" where XX is the language code. EX: /removelang "John Smith" en'

function AC.Commands.AddLang(args)
    if not AC.Override() then
        AC_Utils.addErrorToChat("You are not permitted to add languages.")
        return
    end
    local params = AC.SplitString(args)
    if #params ~= 2 then
        AC_Utils.addErrorToChat("Invalid format. " .. addLangUsageStr)
        return
    end
    local username, lang = params[1], params[2]
    if username == "" or lang == "" then
        AC_Utils.addErrorToChat("Invalid format. " .. addLangUsageStr)
        return
    end
    local player = getPlayerFromUsername(username)
    if not player then
        AC_Utils.addErrorToChat("Player not found. " .. addLangUsageStr)
        return
    end
    if not AC.Languages[lang] then
        AC_Utils.addErrorToChat("Invalid language. " .. addLangUsageStr)
        return
    end
    if getPlayer() == player then
        AC.Meta.AddKnownLanguage(lang)
        AC_Utils.addInfoToChat("Language " .. AC.Languages[lang].name .. " (" .. lang .. ") added to yourself")
        return
    end
    AC.Meta.AddLanguageTo(username, lang)
    AC_Utils.addInfoToChat("Language " .. AC.Languages[lang].name .. " (" .. lang .. ") added to " .. player:getUsername())
end

function AC.Commands.RemoveLang(args)
    if not AC.Override() then
        AC_Utils.addErrorToChat("You are not permitted to remove languages.")
        return
    end
    local params = AC.SplitString(args)
    if #params ~= 2 then
        AC_Utils.addErrorToChat("Invalid format. " .. removeLangUsageStr)
        return
    end
    local username, lang = params[1], params[2]
    if username == "" or lang == "" then
        AC_Utils.addErrorToChat("Invalid format. " .. removeLangUsageStr)
        return
    end
    local player = getPlayerFromUsername(username)
    if not player then
        AC_Utils.addErrorToChat("Player not found. " .. removeLangUsageStr)
        return
    end
    if not AC.Languages[lang] then
        AC_Utils.addErrorToChat("Invalid language. " .. removeLangUsageStr)
        return
    end
    if getPlayer() == player then
        AC.Meta.RemoveKnownLanguage(lang)
        AC_Utils.addInfoToChat("Language " .. AC.Languages[lang].name .. " (" .. lang .. ") removed from yourself")
        return
    end
    AC.Meta.RemoveLanguageFrom(username, lang)
    AC_Utils.addInfoToChat("Language " .. AC.Languages[lang].name .. " (" .. lang .. ") removed from " .. player:getUsername())
end

function AC.Commands.Focus(args)
    local parts = AC.SplitString(args)
    if #parts ~= 1 then
        AC_Utils.addErrorToChat("Invalid format. Use /focus username")
        return
    end
    local username = parts[1]:gsub("^%s*(.-)%s*$", "%1")
    if username == nil or username == "" then
        local msg = "Focused on: <INDENT:8>"
        for i=1, #AC.Meta.FocusedPersons do
            msg = msg .. "<LINE>" .. AC.Meta.FocusedPersons[i]
        end
        msg = msg .. "<INDENT:0>"
        AC_Utils.addInfoToChat(msg)
        return
    end
    if getPlayerFromUsername(username) == nil then
        AC_Utils.addErrorToChat("Player not found. Use /focus username")
        return
    end
    AC.Meta.FocusOn(username)
    AC_Utils.addInfoToChat("You are now focused on " .. username)
end

function AC.Commands.Unfocus(args)
    local parts = AC.SplitString(args)
    if #parts ~= 1 then
        AC_Utils.addErrorToChat("Invalid format. Use /unfocus username")
        return
    end
    local username = parts[1]:gsub("^%s*(.-)%s*$", "%1")
    if username == nil or username == "" then
        AC_Utils.addErrorToChat("Invalid username. Use /unfocus username")
        return
    end
    if not AC.Meta.IsFocusedOn(username) then
        AC_Utils.addErrorToChat("You are not focused on " .. username)
        return
    end
    AC.Meta.UnfocusOn(username)
    AC_Utils.addInfoToChat("You are no longer focused on " .. username)
end

function AC.Commands.Hammer(args)
    if not AC.Override() and not AC.Meta.HasAdminHammer(getPlayer():getUsername()) then
        AC_Utils.addErrorToChat("You are not permitted to use the hammer.")
        return
    end
    local onOff = args:gsub("^%s*(.-)%s*$", "%1")
    if onOff == nil or onOff == "" then
        AC_Utils.addErrorToChat("Invalid format. Use /hammer on or /hammer off")
        return
    end
    if onOff == "on" then
        AC_Utils.addInfoToChat("Hammer enabled")
        AC.Meta.EnableAdminHammer()
    elseif onOff == "off" then
        AC_Utils.addInfoToChat("Hammer disabled")
        AC.Meta.DisableAdminHammer()
    else
        AC_Utils.addErrorToChat("Invalid format. Use /hammer on or /hammer off")
    end
end

function AC.Commands.Help()
    local msg = "Aurora Chat Commands:<LINE>"
    for _, data in pairs(AC.SpecialCommands) do
        if not data.adminOnly or AC.Override() then
            msg = msg .. "<LINE><INDENT:8>" .. data.usage .. "<LINE><INDENT:16>" .. data.help
        end
    end
    msg = msg .. "<LINE><INDENT:0>"
    AC_Utils.addInfoToChat(msg)
end

function AC.Commands.SendPM(args)
    if not SandboxVars.AuroraChat.EnablePM and not AC.Override(true) then
        AC_Utils.addErrorToChat("Private messages are disabled.")
        return
    end
    local params = AC.SplitString(args)
    if #params < 2 then
        AC_Utils.addErrorToChat("Invalid format. Use /pm username message")
        return
    end
    local username = params[1]
    table.remove(params, 1)
    local message = table.concat(params, " ")
    if message == nil or message == "" then
        AC_Utils.addErrorToChat("Invalid format. Use /pm username message")
        return
    end
    if username:find(" ") then
        username = '"' .. username .. '"'
    end
    proceedPM(username .. " " .. message)
end

function AC.Commands.GoAFK()
    if AC.Afk.IsSelfAfk() then
        AC.Afk.StopAfk()
    else
        AC.Afk.StartAfk()
    end
end

function AC.Commands.GrowBeard()
    local player = getPlayer()
    if player:isFemale() then
        AC_Utils.addErrorToChat("You can't grow a beard.")
        return
    end
    local action = ISTrimBeard:new(player, "Long", nil, 0)
    ISTimedActionQueue.add(action)
end

function AC.Commands.GrowHair()
    local player = getPlayer()
    if player:isFemale() then
        local action = ISCutHair:new(player, "Long2", nil, 0)
        ISTimedActionQueue.add(action)
    else
        local action = ISCutHair:new(player, "Fabian", nil, 0)
        ISTimedActionQueue.add(action)
    end
end

function AC.Commands.SetHairColor(args)
    local color = AC.GetColor(args)
    if not color then return end
    local player = getPlayer()
    player:getHumanVisual():setHairColor(ImmutableColor.new(color.r, color.g, color.b, 1))
    sendVisual(player)
    triggerEvent("OnClothingUpdated", player)
    player:resetModel()
end

function AC.Commands.SetBeardColor(args)
    local color = AC.GetColor(args)
    if not color then return end
    local player = getPlayer()
    player:getHumanVisual():setBeardColor(ImmutableColor.new(color.r, color.g, color.b, 1))
    sendVisual(player)
    triggerEvent("OnClothingUpdated", player)
    player:resetModel()
end

function AC.Commands.Override(args)
    local onOff = args:gsub("^%s*(.-)%s*$", "%1")
    if onOff == "on" then
        AC_Utils.addInfoToChat("Override enabled")
        AC.Meta.DisableOverride = false
    elseif onOff == "off" then
        AC_Utils.addInfoToChat("Override disabled")
        AC.Meta.DisableOverride = true
    else
        AC_Utils.addErrorToChat("Invalid format. Use /override on or /override off")
    end
end

local function getSortForMod(x)
    if x == nil then return "00" end
    if x == "me" then return "01" end
    if x == "env" then return "02" end
    if x == "ooc" then return "03" end
    return "04"
end
local function getRangeForType(type)
    local r = AC.ChatTypes[type].xyRange
    if r < 10 then r = "0" .. r end
    return r
end
local function sortCommands(a, b)
    local aCommand = AC.ChatCommands[a]
    local bCommand = AC.ChatCommands[b]
    local aMod = getSortForMod(aCommand.modifier)
    local bMod = getSortForMod(bCommand.modifier)
    local aXyRange = getRangeForType(aCommand.type)
    local bXyRange = getRangeForType(bCommand.type)
    return aXyRange .. aMod < bXyRange .. bMod
end
local commandPossibleColors = {
    "<RGB:0.5,0.5,1>",
    "<RGB:0.5,1,0.5>",
    "<RGB:1,0.5,0.5>",
    "<RGB:1,0.5,1>",
    "<RGB:1,1,0.5>",
    "<RGB:1,0.75,0.5>",
}
function AC.Commands.ListAllCommands()
    local commands = {}
    for command, data in pairs(AC.ChatCommands) do
        if not data.language then
            table.insert(commands, command)
        end
    end
    table.sort(commands, sortCommands)
    local lastType = AC.ChatCommands[commands[1]].type
    local lastModifier = AC.ChatCommands[commands[1]].modifier
    local lastColorIndex = 1
    local msg = "All possible Aurora Chat Commands<LINE><LINE><INDENT:8>" .. commandPossibleColors[lastColorIndex]
    for _,command in ipairs(commands) do
        local data = AC.ChatCommands[command]
        if data.type ~= "alert" or AC.Override(true) then
            if data.type ~= lastType or data.modifier ~= lastModifier then
                lastColorIndex = lastColorIndex + 1
                if lastColorIndex > #commandPossibleColors then lastColorIndex = 1 end
                msg = msg .. commandPossibleColors[lastColorIndex] .. AC_Utils.MagicSpace
                lastType = data.type
                lastModifier = data.modifier
            end
            msg = msg .. command .. " "
        end
    end
    msg = msg .. "<LINE><INDENT:0>"
    AC_Utils.addInfoToChat(msg)
end

function AC.Commands.KeepLast(args)
    local onOff = args:gsub("^%s*(.-)%s*$", "%1")
    if onOff == "on" then
        AC_Utils.addInfoToChat("Keep last enabled")
        AC.Meta.EnableSaveLastChat()
    elseif onOff == "off" then
        AC_Utils.addInfoToChat("Keep last disabled")
        AC.Meta.DisableSaveLastChat()
    else
        AC_Utils.addErrorToChat("Invalid format. Use /keeplast on or /keeplast off")
    end
end

local function parseRoll(rollString)
    local numDice, numSides, bonus = 0, 0, 0
    local _, _, dicePart, bonusPart = rollString:find("(%d+d%d+)(.*)")
    if dicePart then
        local _, _, numDiceStr, numSidesStr = dicePart:find("(%d+)d(%d+)")
        if numDiceStr and numSidesStr then
            numDice = tonumber(numDiceStr) or 0
            numSides = tonumber(numSidesStr) or 0
        end
    end
    if bonusPart then
        local _, _, bonusStr = bonusPart:find("(%d+)")
        if bonusStr then bonus = tonumber(bonusStr) or 0 end
    end
    if numDice == 0 or numSides == 0 then
        numDice = 1
        local numSidesStr = rollString:match("%d+")
        if numSidesStr then numSides = tonumber(numSidesStr) or 0 end
    end
    return numDice, numSides, bonus
end

function AC.Commands.Roll(args)
    local instance = ISChat.instance
    local currentTabID = instance.tabs[instance.currentTabID].tabID
    if currentTabID ~= 0 then
        AC_Utils.addErrorToChat("You must be in the General tab to roll.")
        return
    end
    local parts = AC.SplitString(args)
    local numDice, numSides, bonus, volume = 0, 0, 0, "say"
    if #parts == 1 then
        numDice, numSides, bonus = parseRoll(parts[1])
    elseif #parts == 2 then
        volume = parts[1]:gsub("^%s*(.-)%s*$", "%1")
        numDice, numSides, bonus = parseRoll(parts[2])
    else
        AC_Utils.addErrorToChat("Invalid format. <LINE> " .. AC.SpecialCommands["/roll"].usage)
        return
    end
    if not AC.ChatTypes[volume] then
        for t, v in pairs(AC.ChatTypes) do
            for _, a in ipairs(v.command) do
                if a == volume then volume = t break end
            end
        end
    end
    if numDice == 0 or numSides == 0 then
        AC_Utils.addErrorToChat("Invalid format. <LINE> " .. AC.SpecialCommands["/roll"].usage)
        return
    end
    local rolls = {}
    local total = bonus
    for i=1, numDice do
        local roll = ZombRand(numSides) + 1
        table.insert(rolls, roll)
        total = total + roll
    end
    local mutedRadios = {}
    local player = getPlayer()
    local radiosOn = ARU_Utils.getPlayerRadios(player, true)
    for _, radio in ipairs(radiosOn) do
        if ARU_Utils.isRadioBroadcasting(radio) then
            ARU_Utils.setRadioBroadcastingInstant(player, radio, false)
            table.insert(mutedRadios, radio)
        end
    end
    processSayMessage("[UN:" .. player:getUsername() .. "]/roll " .. volume .. " " .. numDice .. " " .. numSides .. " " .. bonus .. " " .. total .. " ".. table.concat(rolls, ","))
    for _, radio in ipairs(mutedRadios) do
        ARU_Utils.setRadioBroadcastingInstant(player, radio, true)
    end
end

function AC.Commands.Trade(args)
    local parts = AC.SplitString(args)
    if #parts ~= 1 then
        AC_Utils.addErrorToChat("Invalid format. Use /trade username")
        return
    end
    local username = parts[1]:gsub("^%s*(.-)%s*$", "%1")
    local player = getPlayer()
    local target = getPlayerFromUsername(username)
    if not target or not AC.CanSeePlayer(target) then
        AC_Utils.addErrorToChat("Player not found or too far. Use /trade username")
        return
    end
    ISWorldObjectContextMenu.onTrade(nil, player, target)
end

function AC.Commands.Injure(args)
    local parts = AC.SplitString(args)
    if #parts ~= 2 then
        AC_Utils.addErrorToChat("Invalid format. Use /injure bodypart injury")
        return
    end
    local bodyPartStr = parts[1]:gsub("^%s*(.-)%s*$", "%1")
    local injury = parts[2]:gsub("^%s*(.-)%s*$", "%1")
    local found = false
    for _,str in ipairs(AC.GetBodyParts()) do
        if str == bodyPartStr then found = true break end
    end
    if not found then
        AC_Utils.addErrorToChat("Invalid body part. Use /injure bodypart injury")
        return
    end
    local bodyPartType = BodyPartType.FromString(bodyPartStr)
    local bodyPart = getPlayer():getBodyDamage():getBodyPart(bodyPartType)
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
    else
        AC_Utils.addErrorToChat("Invalid injury. Use /injure bodypart injury")
        return
    end
    AC_Utils.addInfoToChat("<RGB:1.0,0.0,0.0>Injury applied!")
end

function AC.Commands.RadioSync(args)
    if args == nil or args == "" then
        AC.Meta.SetRadioSync(nil)
        AC_Utils.addInfoToChat("Radio sync disabled")
        return
    end
    local frequency = tonumber(args)
    if frequency == nil then
        AC_Utils.addErrorToChat("Invalid format. Use /radiosync [frequency]")
        return
    end
    AC.Meta.SetRadioSync(math.floor(frequency * 1000))
    AC_Utils.addInfoToChat("Radio sync set to " .. frequency .. "MHz")
end

function AC.Commands.SetStatus(args)
    local status = args:gsub("^%s*(.-)%s*$", "%1")
    if status == nil or status == "" then
        local currentStatus = AC.Meta.GetStatus(getPlayer():getUsername())
        local msg = "Current status is: " .. currentStatus .. "<LINE><LINE>To change your status use \"/status <status message>\" or \"/status clear\" to clear your status."
        AC_Utils.addInfoToChat(msg)
        return
    end
    if status == "clear" then
        AC.Meta.SetStatus(nil)
        AC_Utils.addInfoToChat("Status cleared")
        return
    end
    if status:len() < 8 then
        AC_Utils.addErrorToChat("Status too short. Use /status <status message>")
        return
    end
    if status:len() > 64 then
        AC_Utils.addErrorToChat("Status too long. Use /status <status message>")
        return
    end
    AC.Meta.SetStatus(status)
    AC_Utils.addInfoToChat("Status set to " .. status)
end

function AC.Commands.PrivateChat(args)
    if not SandboxVars.AuroraChat.EnablePrivate then
        AC_Utils.addErrorToChat("Private chat is disabled.")
        return
    end
    local parts = AC.SplitString(args)
    if #parts ~= 1 then
        AC_Utils.addErrorToChat("Invalid format. Use /private username")
        return
    end
    local username = parts[1]:gsub("^%s*(.-)%s*$", "%1")
    if AC.Meta.HasPrivate(true) then
        AC_Utils.addErrorToChat("You are already in a private chat. Use /stopprivate to stop it.")
        return
    end
    if not AC.Meta.InvitePrivate(username) then
        AC_Utils.addErrorToChat("Player not found or too far. Use /private <username>", {chatId = 1})
        return
    end
end

function AC.Commands.StopPrivateChat()
    if AC.Meta.HasPrivate(true) then
        AC.Meta.StopPrivate()
        AC.Meta.ClosePrivate()
    else
        AC_Utils.addErrorToChat("You are not in a private chat")
    end
end

function AC.Commands.Coords()
    if not SandboxVars.AuroraChat.AllowPlayerCoords and not AC.Override() then
        AC_Utils.addErrorToChat("Coordinates are disabled.")
        return
    end
    local player = getPlayer()
    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())
    AC_Utils.addInfoToChat(player:getUsername() .. " is at " .. x .. ", " .. y .. ", " .. z)
end

function AC.TabListHandler(list, text)
    if text == nil or text == "" then return list[1] end
    for i=1, #list do
        if list[i] == text then
            if isShiftKeyDown() then
                return list[(i - 2) % #list + 1]
            end
            return list[(i % #list) + 1]
        end
    end
    for i=1, #list do
        if list[i]:sub(1, #text) == text then
            return list[i]
        end
    end
    return nil
end

function AC.TabHandlers.MyLangs(text)
    local langs = AC.Meta.GetKnownLanguages()
    table.sort(langs)
    return AC.TabListHandler(langs, text)
end

function AC.TabHandlers.UsernameNotSelf(text)
    local playersArr = getOnlinePlayers()
    local players = {}
    for i=0, playersArr:size()-1 do
        local player = playersArr:get(i)
        if AC.CanSeePlayer(player) then
            table.insert(players, player:getUsername())
        end
    end
    table.sort(players)
    return AC.TabListHandler(players, text)
end

function AC.TabHandlers.Username(text)
    local playersArr = getOnlinePlayers()
    local players = {}
    for i=0, playersArr:size()-1 do
        local player = playersArr:get(i)
        if AC.CanSeePlayer(player, true) then
            table.insert(players, player:getUsername())
        end
    end
    table.sort(players)
    return AC.TabListHandler(players, text)
end

function AC.TabHandlers.AnyLang(text)
    local langs = {}
    for lang, _ in pairs(AC.Languages) do
        table.insert(langs, lang)
    end
    table.sort(langs)
    return AC.TabListHandler(langs, text)
end

function AC.TabHandlers.FocusedUsername(text)
    table.sort(AC.Meta.FocusedPersons)
    return AC.TabListHandler(AC.Meta.FocusedPersons, text)
end

function AC.TabHandlers.OnOff(text)
    return AC.TabListHandler({"on", "off"}, text)
end

function AC.TabHandlers.BodyPart(text)
    return AC.TabListHandler(AC.GetBodyParts(), text)
end

function AC.TabHandlers.Injury(text)
    return AC.TabListHandler(AC.GetInjuries(), text)
end

function AC.TabHandlers.RadioFrequencies(text)
    local radios = ARU_Utils.getPlayerRadios(getPlayer(), true)
    local frequencies = {}
    for _, radio in ipairs(radios) do
        table.insert(frequencies, tostring(ARU_Utils.getRadioFrequency(radio) / 1000))
    end
    return AC.TabListHandler(frequencies, text)
end
