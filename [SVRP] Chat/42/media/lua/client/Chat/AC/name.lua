if isServer() and not isClient() then return end
AC = AC or {}
AC.Name = AC.Name or {}

local function DrawPlayerName(player)
    local me = getPlayer()
    if not me then return end
    local alpha = AC.Visibility.GetPlayerAlpha(player)
    if alpha > 0.01 then
        local username = player:getUsername()
        local name = AC.Meta.GetName(username) or username

        local playerNum = me:getPlayerNum() or 0
        local x = math.floor(isoToScreenX(playerNum, player:getX(), player:getY(), player:getZ()))
        local y = AC.Visibility.GetYOffsets(player).name or math.floor(isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ()) - 125)
        
        local color = AC.Meta.GetNameColorRGB(username) or {r=1.0, g=1.0, b=1.0}
        AC.Visibility.DrawTextCentre(UIFont.Small, x, y, name, color.r, color.g, color.b, alpha)
    end
end

function AC.Name.ShowNamesOnPlayers()
    local me = getPlayer()
    if not me then return end
    
    DrawPlayerName(me)

    local players = getOnlinePlayers()
    if not players then return end

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        
        if player ~= me and AC.CanSeePlayer(player, true, 20) and AC.GetDistanceSq(me, player) < 2500 then
            DrawPlayerName(player)
        end
    end
end
