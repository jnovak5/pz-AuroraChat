if not isClient() then return end -- only in MP
AC = AC or {}
AC.Events = AC.Events or {}
AC.Events.IsFirstSync = true

function AC.Events.OnReceiveGlobalModData(key, modData)
    if key == "AC_PlayerColors" then
        AC.PlayerColors = modData
    elseif key == "AC_PlayerLanguages" then
        AC.PlayerLanguages = modData
    elseif key == "AC_PlayerModifiers" then
        AC.PlayerModifiers = modData
        AC.Afk.CheckLocalPlayersForAfk()
        if AC.Events.IsFirstSync then
            AC.Events.IsFirstSync = false
            if AC.Afk.IsSelfAfk() then
                AC.Afk.StartAfk()
            end
        end
    elseif key == "AC_PlayerNames" then
        AC.PlayerNames = modData
        if not AC.PlayerNames[getPlayer():getUsername()] then
            AC.Meta.SetName(getPlayer():getDescriptor():getForename())
        end
    elseif key == "AC_PlayerStatus" then
        AC.PlayerStatus = modData
    end
end

function AC.Events.OnConnected()
    ModData.request("AC_PlayerColors")
    ModData.request("AC_PlayerLanguages")
    ModData.request("AC_PlayerModifiers")
    ModData.request("AC_PlayerNames")
    ModData.request("AC_PlayerStatus")
end

function AC.Events.onServerCommand(module, command, args)
    if module ~= "AC" then return end

    if command == "onTyping" then
        AC.Indicator.players[args[1]] = getTimestampMs()
    elseif command == "onCleared" then
        AC.Indicator.players[args[1]] = nil
    elseif command == "SetPlayerColor" then
        local player = args[1]
        local r = args[2]
        local g = args[3]
        local b = args[4]
        if r and g and b then
            AC.PlayerColors[player] = {r = r, g = g, b = b}
        else
            AC.PlayerColors[player] = nil
        end
    elseif command == "SetPlayerLanguage" then
        local player = args[1]
        local language = args[2]
        AC.PlayerLanguages[player] = language
    elseif command == "SetModifier" then
        local player = args[1]
        local direction = args[2]
        local modifier = args[3]
        AC.PlayerModifiers[player] = AC.PlayerModifiers[player] or {}
        if direction == "enable" then
            AC.PlayerModifiers[player][modifier] = true
        elseif direction == "disable" then
            AC.PlayerModifiers[player][modifier] = nil
        end
    elseif command == "SetPlayerName" then
        local player = args[1]
        local name = args[2]
        AC.PlayerNames[player] = name
    elseif command == "SetPlayerStatus" then
        local player = args[1]
        local status = args[2]
        AC.PlayerStatus[player] = status
    elseif command == "AddKnownLanguage" then
        local languageData = AC.Languages[args[1]]
        if languageData then
            AC.Meta.AddKnownLanguage(args[1])
            AC_Utils.addInfoToChat("You have learned " .. languageData.name)
        end
    elseif command == "RemoveKnownLanguage" then
        local languageData = AC.Languages[args[1]]
        if languageData then
            AC.Meta.RemoveKnownLanguage(args[1])
            AC_Utils.addInfoToChat("You have forgotten " .. languageData.name)
        end
    elseif command == "InvitePrivate" then
        local otherPlayer = args[1]
        if AC.Meta.HasPrivate(true) then
            sendClientCommand(getPlayer(), "AC", "PrivateUnavailable", {otherPlayer})
        else
            AC.Meta.OnPrivateInvite(otherPlayer)
        end
    elseif command == "PrivateUnavailable" then
        local otherPlayer = args[1]
        AC_Utils.addErrorToChat(otherPlayer .. " is unable to private chat.")
    elseif command == "AcceptPrivateInvite" then
        local otherPlayer = args[1]
        AC.Meta.StartPrivate(otherPlayer)
        ISChat.instance.panel:activateView("Private")
        AC_Utils.addInfoToChat("Private chat started with " .. AC.Meta.GetName(otherPlayer) .. ".")
    elseif command == "DeclinePrivateInvite" then
        local otherPlayer = args[1]
        AC_Utils.addInfoToChat(otherPlayer .. " declined your private chat invite.")
    elseif command == "PrivateChat" then
        local otherPlayerUsername = args[1]
        local message = args[2]
        AC.Handlers.AddPrivateMessage(otherPlayerUsername, message)
    elseif command == "StopPrivate" then
        ISChat.instance.panel:activateView("Private")
        local name = AC.Meta.PrivatePartner and AC.Meta.GetName(AC.Meta.PrivatePartner) or "Unknown"
        AC_Utils.addInfoToChat("Private with " .. name .. " ended.")
        AC.Meta.StopPrivate(true)
    elseif command == "StaffChat" then
        local sourceUsername = args[1]
        local message = args[2]
        AC.Handlers.AddStaffMessage(sourceUsername, message)
    end
end

Events.OnReceiveGlobalModData.Add(AC.Events.OnReceiveGlobalModData)
Events.OnConnected.Add(AC.Events.OnConnected)
Events.OnServerCommand.Add(AC.Events.onServerCommand)
Events.OnTick.Add(AC.Indicator.update)
Events.EveryOneMinute.Add(AC.Afk.CheckLocalPlayersForAfk)
