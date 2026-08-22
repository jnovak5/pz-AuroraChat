if isServer() and not isClient() then return end
AC = AC or {}
AC.Bio = AC.Bio or {}

AC.Bio.OverheadUiElements = AC.Bio.OverheadUiElements or {}

function AC.Bio.ShowBioOnPlayers()
    local sandbox = SandboxVars.SVRPChat or {}
    if not sandbox.EnableBioShortDescription then return end
    
    local zoom = getCore():getZoom(0)
    
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end
    
    local me = getPlayer()
    if not me then return end
    
    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        if username == me:getUsername() then player = me end
        
        local shortBio = player:getModData()['_CharacterBioShortDescription'] or ""
        
        local sandbox = (SandboxVars and (SandboxVars.SVRPChat or SandboxVars.SVRPChat)) or {}
        local sayRange = sandbox.RangeXYSay or 35
        if type(shortBio) == "string" and string.len(shortBio) > 1 and (player == me or (AC.CanSeePlayer(player, true, sayRange) and me:getDistanceSq(player) < (sayRange * sayRange))) then
            local alpha = AC.Visibility.GetPlayerAlpha(player)
            if alpha > 0.01 then
                local textWidth = getTextManager():MeasureStringX(UIFont.Small, shortBio)
                local textHeight = getTextManager():MeasureStringY(UIFont.Small, shortBio)
                
                local playerNum = getPlayer():getPlayerNum() or 0
                local x = math.floor(isoToScreenX(playerNum, player:getX(), player:getY(), player:getZ()))
                local y = AC.Visibility.GetYOffsets(player).bio or math.floor(isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ()) - 155)
                
                AC.Visibility.DrawTextCentre(UIFont.Small, x, y, shortBio, 1.0, 1.0, 1.0, alpha)
            end
        end
    end
end
