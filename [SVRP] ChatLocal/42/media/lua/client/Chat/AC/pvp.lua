if not isClient() then return end -- only in MP
AC = AC or {}
AC.Pvp = AC.Pvp or {}

function AC.Pvp.ShowPvpOnPlayers()
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end

    local me = getPlayer()
    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        if username == me:getUsername() then player = me end
        
        -- Check if player has safety turned off (meaning PVP is ON)
        if player:getSafety() ~= nil and not player:getSafety():isCurrent() then
            if player == me or (AC.CanSeePlayer(player, true, 20) and me:getDistanceSq(player) < 2500) then
                local alpha = AC.Visibility.GetPlayerAlpha(player)
                if alpha > 0.01 then
                    local playerNum = getPlayer():getPlayerNum() or 0
                    local x = math.floor(isoToScreenX(playerNum, player:getX(), player:getY(), player:getZ()))
                    local y = AC.Visibility.GetYOffsets(player).pvp or math.floor(isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ()) - 155)
                    
                    AC.Visibility.DrawTextCentre(UIFont.Small, x, y, "[PVP]", 1.0, 0.2, 0.2, alpha)
                end
            end
        end
    end
end
