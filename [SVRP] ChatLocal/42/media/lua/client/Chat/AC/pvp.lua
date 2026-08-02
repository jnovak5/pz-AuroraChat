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
        
        -- Safely check if player has safety turned off (meaning PVP is ON)
        local isPvp = false
        local safety = player:getSafety()
        if safety and tostring(safety) ~= "null" then
            local success, isEnabled = pcall(function() return safety:isEnabled() end)
            if success and not isEnabled then
                isPvp = true
            end
        end

        if isPvp then
            if player == me or (AC.CanSeePlayer(player, true, 20) and me:getDistanceSq(player) < 2500) then
                local alpha = AC.Visibility.GetPlayerAlpha(player)
                if alpha > 0.01 then
                    local playerNum = getPlayer():getPlayerNum() or 0
                    local x = math.floor(isoToScreenX(playerNum, player:getX(), player:getY(), player:getZ()))
                    local y = AC.Visibility.GetYOffsets(player).pvp or math.floor(isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ()) - 155)
                    
                    if not AC.Pvp.SkullTexture then
                        AC.Pvp.SkullTexture = getTexture("media/ui/Skull.png")
                    end
                    if AC.Pvp.SkullTexture then
                        local w = AC.Pvp.SkullTexture:getWidth()
                        local h = AC.Pvp.SkullTexture:getHeight()
                        AC.Pvp.SkullTexture:render(x - w/2, y, w, h, 1.0, 1.0, 1.0, alpha, nil)
                    else
                        AC.Visibility.DrawTextCentre(UIFont.Small, x, y, "[PVP]", 1.0, 0.2, 0.2, alpha)
                    end
                end
            end
        end
    end
end
