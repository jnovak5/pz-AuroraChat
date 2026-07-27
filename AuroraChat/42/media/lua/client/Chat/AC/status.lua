if not isClient() then return end -- only in MP
AC = AC or {}
AC.StatusIndicator = AC.StatusIndicator or {}
AC.PlayerStatus = AC.PlayerStatus or {}

function AC.StatusIndicator.GetDistanceSq(mouseWorldX, mouseWorldY, player)
    local playerWorldX = player:getX()
    local playerWorldY = player:getY()
    local dx = mouseWorldX - playerWorldX
    local dy = mouseWorldY - playerWorldY
    return dx*dx + dy*dy
end

local maxDistSq = 2.25 -- 1.5 tiles
AC.StatusIndicator.OverheadUiElements = AC.StatusIndicator.OverheadUiElements or {}
function AC.StatusIndicator.ShowStatusIndicatorOnHovered()
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end

    local ownPlayer = getPlayer()
    local worldX = screenToIsoX(0, getMouseX(), getMouseY(), ownPlayer:getZ())
    local worldY = screenToIsoY(0, getMouseX(), getMouseY(), ownPlayer:getZ())
    local worldZ = ownPlayer:getZ()

    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        if username == ownPlayer:getUsername() then player = ownPlayer end
        
        local distSq = AC.StatusIndicator.GetDistanceSq(worldX, worldY, player)
        local status = AC.Meta.GetStatus(username)
        if (worldZ == player:getZ() and distSq <= maxDistSq and AC.CanSeePlayer(player, true, 20)) and type(status) == "string" and status:match("%S") then
            local alpha = AC.Visibility.GetPlayerAlpha(player)
            if alpha > 0.01 then
                local playerNum = getPlayer():getPlayerNum() or 0
                local x = math.floor(isoToScreenX(playerNum, player:getX(), player:getY(), player:getZ()))
                local y = AC.Visibility.GetYOffsets(player).status or math.floor(isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ()) - 140)
                
                AC.Visibility.DrawTextCentre(UIFont.Small, x, y, status, 0.8, 0.8, 0.8, alpha)
            end
        end
    end
end
