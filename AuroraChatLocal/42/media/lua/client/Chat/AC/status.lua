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
        local distSq = AC.StatusIndicator.GetDistanceSq(worldX, worldY, player)
        local status = AC.Meta.GetStatus(username)
        if worldZ == player:getZ() and distSq <= maxDistSq and AC.CanSeePlayer(player, true, 20) and status then
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ() + 0.65)
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ() + 0.65)
            y = y - 5
            
            local fontHeight = getTextManager():getFontHeight(UIFont.Small) - 2
            if AC.Meta.IsAfk(username) then y = y + fontHeight end
            
            getTextManager():DrawStringCentre(UIFont.Small, x, y, status, 1.0, 1.0, 1.0, 0.6)
        end
    end
end
