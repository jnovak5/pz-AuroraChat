if not isClient() then return end -- only in MP
AC = AC or {}
AC.Afk = AC.Afk or {}

AC.Afk.ALERT_AFK_DIST_SQ = 20*20 -- 20 squares
AC.Afk.ALERT_BACK_DIST_SQ = 50*50 -- 50 squares
AC.Afk.FORGET_AFK_DIST_SQ = 100*100 -- 100 squares
AC.Afk.UsersAlertedAbout = {}

function AC.Afk.IsSelfAfk()
    return AC.Meta.IsAfk(getPlayer():getUsername())
end

function AC.Afk.StartAfk()
    AC.Meta.EnableAfk()
    AC_Utils.addInfoToChat("You are now AFK. Type /afk again to cancel.")
end

function AC.Afk.StopAfk()
    AC.Meta.DisableAfk()
    AC_Utils.addInfoToChat("You are no longer AFK")
end

AC.Afk.IndicatorWidth = getTextManager():MeasureStringX(UIFont.Small, "AFK")
AC.Afk.IndicatorHeight = getTextManager():MeasureStringY(UIFont.Small, "AFK")
AC.Afk.OverheadUiElements = AC.Afk.OverheadUiElements or {}
function AC.Afk.ShowAfkOnPlayers()
    local zoom = getCore():getZoom(0)
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end
    local me = getPlayer()
    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        if AC.Meta.IsAfk(username) and AC.CanSeePlayer(player, true, 20) and me:getDistanceSq(player) < 2500 then
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ() + 0.65)
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ() + 0.65)
            y = y - 5
            
            getTextManager():DrawStringCentre(UIFont.Small, x, y, "AFK", 1.0, 0.2, 0.2, 1.0)
        end
    end
end

function AC.Afk.CheckLocalPlayersForAfk()
    local players = getOnlinePlayers()
    local me = getPlayer()
    if not me then return end
    local seen = {}
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player ~= me and me:CanSee(player) then
            local username = player:getUsername()
            seen[username] = true
            local dist = player:getDistanceSq(getPlayer())
            if AC.Meta.IsAfk(username) and not AC.Afk.UsersAlertedAbout[username] and dist < AC.Afk.ALERT_AFK_DIST_SQ then
                AC.Afk.AlertPlayerHasGoneAfk(player)
                AC.Afk.UsersAlertedAbout[username] = true
            elseif not AC.Meta.IsAfk(username) and AC.Afk.UsersAlertedAbout[username] and dist < AC.Afk.ALERT_BACK_DIST_SQ then
                AC.Afk.AlertPlayerHasReturned(player)
                AC.Afk.UsersAlertedAbout[username] = nil
            elseif AC.Afk.UsersAlertedAbout[username] and dist > AC.Afk.FORGET_AFK_DIST_SQ then
                AC.Afk.UsersAlertedAbout[username] = nil
            end
        end
    end
    for username, _ in pairs(AC.Afk.UsersAlertedAbout) do
        if not seen[username] then
            AC.Afk.UsersAlertedAbout[username] = nil
        end
    end
end

function AC.Afk.AlertPlayerHasGoneAfk(player)
    pcall(function() player:addLineChatElement("Is AFK", 1, 1, 1) end)
    local username = player:getUsername()
    local message = AC.Meta.GetNameColor(username) .. AC.Meta.GetName(username) .. " " .. AC.ChatColors["info"] .. AC_Utils.MagicSpace .. "is AFK"
    AC_Utils.addInfoToChat(message)
end

function AC.Afk.AlertPlayerHasReturned(player)
    pcall(function() player:addLineChatElement("Is no longer AFK", 1, 1, 1) end)
    local username = player:getUsername()
    local message = AC.Meta.GetNameColor(username) .. AC.Meta.GetName(username) .. " " .. AC.ChatColors["info"] .. AC_Utils.MagicSpace .. "is no longer AFK"
    AC_Utils.addInfoToChat(message)
end
