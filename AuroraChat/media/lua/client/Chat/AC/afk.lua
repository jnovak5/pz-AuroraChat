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
    for _,x in pairs(AC.Afk.OverheadUiElements) do x.seen = false end
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end
    local me = getPlayer()
    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        if AC.Meta.IsAfk(username) and AC.CanSeePlayer(player, true, 20) and me:getDistanceSq(player) < 2500 then
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ())
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ())
            y = y - (130 / zoom) - (3*zoom)
            if AC.Indicator.players[username] then y = y - AC.Indicator.IndicatorHeight - 2 end
            local ele = AC.Afk.OverheadUiElements[username]
            if ele then
                ele:setX(x - (ele.width / 2))
                ele:setY(y)
            else
                ele = ISUIElement:new(x - (AC.Afk.IndicatorWidth/2), y, AC.Afk.IndicatorWidth, AC.Afk.IndicatorHeight)
                ele.anchorTop = false
                ele.anchorBottom = true
                ele:initialise()
                ele:addToUIManager()
                ele:backMost()
                AC.Afk.OverheadUiElements[username] = ele
            end
            ele.seen = true
            ele:drawTextCentre("AFK", AC.Afk.IndicatorWidth/2, 0, 0.7, 0.7, 0.7, 1.0, UIFont.Small)
        end
    end
    for k,v in pairs(AC.Afk.OverheadUiElements) do
        if not v.seen then
            v:removeFromUIManager()
            AC.Afk.OverheadUiElements[k] = nil
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
