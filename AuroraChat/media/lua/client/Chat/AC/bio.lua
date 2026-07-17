AC.Bio = AC.Bio or {}

AC.Bio.OverheadUiElements = AC.Bio.OverheadUiElements or {}

function AC.Bio.ShowBioOnPlayers()
    if not SandboxVars.AuroraChat.EnableBioShortDescription then return end
    
    local zoom = getCore():getZoom(0)
    for _,x in pairs(AC.Bio.OverheadUiElements) do x.seen = false end
    
    local allPlayers = getOnlinePlayers()
    if not allPlayers then return end
    
    local me = getPlayer()
    if not me then return end
    
    for i=0,allPlayers:size()-1 do
        local player = allPlayers:get(i)
        local username = player:getUsername()
        
        local shortBio = player:getModData()['_CharacterBioShortDescription'] or ""
        
        if type(shortBio) == "string" and string.len(shortBio) > 1 and AC.CanSeePlayer(player, true, 20) and me:getDistanceSq(player) < 2500 then
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, shortBio)
            local textHeight = getTextManager():MeasureStringY(UIFont.Small, shortBio)
            
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ())
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ())
            local zoom = getCore():getZoom(0)
            if zoom > 0 then
                y = y - (130 / zoom) - (2 * zoom) + 4
            else
                y = y - 124
            end
            if AC.Indicator.players[username] then y = y + AC.Indicator.IndicatorHeight end
            if AC.Meta.IsAfk(username) then y = y + AC.Afk.IndicatorHeight end
            local status = AC.Meta.GetStatus(username)
            if status then y = y + getTextManager():MeasureStringY(UIFont.Small, status) end
            
            local ele = AC.Bio.OverheadUiElements[username]
            if ele then
                ele:setX(x - (textWidth / 2))
                ele:setY(y)
                ele:setWidth(textWidth)
                ele:setHeight(textHeight)
                ele.bioText = shortBio
            else
                ele = ISUIElement:new(x - (textWidth/2), y, textWidth, textHeight)
                ele.anchorTop = true
                ele.anchorBottom = false
                ele:initialise()
                ele:addToUIManager()
                ele:backMost()
                ele.bioText = shortBio
                
                ele.render = function(self)
                    self:drawTextCentre(self.bioText, self.width/2, 0, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
                end
                
                AC.Bio.OverheadUiElements[username] = ele
            end
            ele.seen = true
        end
    end
    
    for k,v in pairs(AC.Bio.OverheadUiElements) do
        if not v.seen then
            v:removeFromUIManager()
            AC.Bio.OverheadUiElements[k] = nil
        end
    end
end
