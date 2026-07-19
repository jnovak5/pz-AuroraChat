AC.Bio = AC.Bio or {}

AC.Bio.OverheadUiElements = AC.Bio.OverheadUiElements or {}

function AC.Bio.ShowBioOnPlayers()
    local sandbox = SandboxVars.AuroraChatLocal or {}
    if not sandbox.EnableBioShortDescription then return end
    
    local zoom = getCore():getZoom(0)
    
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end
    
    local me = getPlayer()
    if not me then return end
    
    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        
        local shortBio = player:getModData()['_CharacterBioShortDescription'] or ""
        
        local sandbox = SandboxVars.AuroraChatLocal or {}
        local sayRange = sandbox.RangeXYSay or 20
        if type(shortBio) == "string" and string.len(shortBio) > 1 and AC.CanSeePlayer(player, true, sayRange) and me:getDistanceSq(player) < (sayRange * sayRange) then
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, shortBio)
            local textHeight = getTextManager():MeasureStringY(UIFont.Small, shortBio)
            
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ() + 0.65)
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ() + 0.65)
            y = y - 5
            
            local fontHeight = getTextManager():getFontHeight(UIFont.Small) - 2
            if AC.Meta.IsAfk(username) then y = y + fontHeight end
            local status = AC.Meta.GetStatus(username)
            if status then y = y + fontHeight end
            
            getTextManager():DrawStringCentre(UIFont.Small, x, y, shortBio, 1.0, 1.0, 1.0, 1.0)
        end
    end
end
