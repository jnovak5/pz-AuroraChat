if isServer() and not isClient() then return end
AC = AC or {}
AC.Pvp = AC.Pvp or {}

function AC.Pvp.IsPvpEnabled(player)
    if not player then return false end

    local serverOptions = getServerOptions()
    if serverOptions then
        if serverOptions:getBoolean("PVP") == false then
            return false
        end
        if serverOptions:getBoolean("SafetySystem") == false then
            return true
        end
    end

    local safety = player:getSafety()
    if safety and tostring(safety) ~= "null" then
        if safety.isEnabled then
            local success, isSafe = pcall(function() return safety:isEnabled() end)
            if success then
                return not isSafe
            end
        end
    end
    
    return false
end

function AC.Pvp.ShowPvpOnPlayers()
    local me = getPlayer()
    if not me then return end
    
    local playersToProcess = {me}
    
    local allPlayers = getOnlinePlayers()
    if allPlayers then
        for i=0,allPlayers:size()-1 do
            local player = allPlayers:get(i)
            if player:getUsername() ~= me:getUsername() then
                table.insert(playersToProcess, player)
            end
        end
    end

    for _, player in ipairs(playersToProcess) do
        if AC.Pvp.IsPvpEnabled(player) then
            if player == me or (AC.CanSeePlayer(player, true, 20) and me:getDistanceSq(player) < 2500) then
                local alpha = AC.Visibility.GetPlayerAlpha(player)
                if alpha > 0.01 then
                    local playerNum = me:getPlayerNum() or 0
                    local x = math.floor(isoToScreenX(playerNum, player:getX(), player:getY(), player:getZ()))
                    -- Use the name's Y offset to place it next to the name
                    local y = AC.Visibility.GetYOffsets(player).name or math.floor(isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ()) - 125)
                    
                    -- Calculate name width so we can place it on the right
                    local username = player:getUsername()
                    local name = AC.Meta.GetName(username) or username
                    local nameWidth = getTextManager():MeasureStringX(UIFont.Small, name)
                    
                    local iconX = x + (nameWidth / 2) + 5
                    
                    -- getTexture returns a dummy object if missing, skipping the text fallback.
                    -- Only use texture if it has explicitly been marked as available, otherwise fallback to text.
                    local useTexture = true 
                    if useTexture then
                        if not AC.Pvp.SkullTexture then
                            AC.Pvp.SkullTexture = getTexture("media/ui/Skull.png")
                        end
                    end
                    
                    if useTexture and AC.Pvp.SkullTexture then
                        local w = AC.Pvp.SkullTexture:getWidth()
                        local h = AC.Pvp.SkullTexture:getHeight()
                        -- Center texture vertically relative to text
                        local fontHeight = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
                        local iconY = y + (fontHeight / 2) - (h / 2)
                        if not AC.Visibility.IsOccludedByUI(iconX + (w/2), iconY, w, h) then
                            AC.Pvp.SkullTexture:render(iconX, iconY, w, h, 1.0, 1.0, 1.0, alpha, nil)
                        end
                    else
                        AC.Visibility.DrawTextCentre(UIFont.Small, iconX + 15, y, "[PVP]", 1.0, 0.2, 0.2, alpha)
                    end
                end
            end
        end
    end
end
