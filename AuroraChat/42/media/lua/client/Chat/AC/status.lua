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
    local zoom = getCore():getZoom(0)
    for _,x in pairs(AC.StatusIndicator.OverheadUiElements) do x.seen = false end

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
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ())
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ())
            y = y - (130 / zoom) - (3*zoom)
            if AC.Indicator.players[username] then y = y - AC.Indicator.IndicatorHeight - 2 end
            if AC.Meta.IsAfk(username) then y = y - AC.Afk.IndicatorHeight - 2 end
            local statusWidth = getTextManager():MeasureStringX(UIFont.Small, status)
            local statusHeight = getTextManager():MeasureStringY(UIFont.Small, status)
            local ele = AC.StatusIndicator.OverheadUiElements[username]
            if ele then
                ele:setX(x - (ele.width / 2))
                ele:setY(y)
            else
                ele = ISUIElement:new(x - (statusWidth/2), y, statusWidth, statusHeight)
                ele.anchorTop = false
                ele.anchorBottom = true
                ele:initialise()
                ele:addToUIManager()
                ele:backMost()
                AC.StatusIndicator.OverheadUiElements[username] = ele
            end
            ele.seen = true
            ele:drawTextCentre(status, statusWidth/2, 0, 1.0, 1.0, 1.0, 0.6, UIFont.Small)
        end
    end
    for k,v in pairs(AC.StatusIndicator.OverheadUiElements) do
        if not v.seen then
            v:removeFromUIManager()
            AC.StatusIndicator.OverheadUiElements[k] = nil
        end
    end
end
