if not isClient() then return end

AC = AC or {}
AC.Visibility = AC.Visibility or {}

--- Get the visibility alpha of a player based on their tile's light level
--- @param player IsoPlayer
--- @return number alpha (0.0 to 1.0)
function AC.Visibility.GetPlayerAlpha(player)
    if AC.Meta.GetAdminHideOverheads() then return 0.0 end
    if not player then return 1.0 end

    local square = player:getCurrentSquare()
    if not square then return 1.0 end

    local playerNum = getPlayer():getPlayerNum() or 0
    -- getLightLevel typically returns a value where 1.0 is bright. In some PZ versions it can be slightly different.
    local lightLevel = square:getLightLevel(playerNum)

    -- Define our thresholds
    local minLight = 0.25
    local maxLight = 0.65

    if lightLevel <= minLight then
        return 0.0
    elseif lightLevel >= maxLight then
        return 1.0
    else
        -- Linear interpolation between min and max
        local alpha = (lightLevel - minLight) / (maxLight - minLight)
        -- Clamp to 0.0 - 1.0 just in case
        return math.max(0.0, math.min(1.0, alpha))
    end
end

--- Draw text centered with a black outline
function AC.Visibility.DrawTextCentre(font, x, y, text, r, g, b, a)
    local tm = getTextManager()
    
    -- Ensure integer pixel coordinates to prevent text rendering wobble/jitter
    x = math.floor(x)
    y = math.floor(y)

    -- Draw 4-way black outline
    tm:DrawStringCentre(font, x - 1, y - 1, text, 0, 0, 0, a)
    tm:DrawStringCentre(font, x + 1, y - 1, text, 0, 0, 0, a)
    tm:DrawStringCentre(font, x - 1, y + 1, text, 0, 0, 0, a)
    tm:DrawStringCentre(font, x + 1, y + 1, text, 0, 0, 0, a)
    
    -- Draw main text
    tm:DrawStringCentre(font, x, y, text, r, g, b, a)
end

--- Get dynamic Y offsets for the entire text stack to prevent gaps and overlap
function AC.Visibility.GetYOffsets(player)
    local offsets = {}
    local username = player:getUsername()
    local playerNum = getPlayer():getPlayerNum() or 0
    local y = isoToScreenY(playerNum, player:getX(), player:getY(), player:getZ())
    local zoom = getCore():getZoom(playerNum)
    local baseY = y
    
    if not AC.PlayerChatTimes then AC.PlayerChatTimes = {} end
    local lastChatTime = AC.PlayerChatTimes[username] or 0
    local hasChat = (getTimeInMillis() - lastChatTime < 5000) -- chat bubbles typically last ~5s
    if hasChat or player:getVehicle() ~= nil then 
        offsets.bio = -9999
        offsets.status = -9999
        offsets.afk = -9999
        offsets.name = -9999
        offsets.indicator = -9999
        return offsets 
    end
    
    if zoom > 0 then
        baseY = baseY - (125 / zoom)
    else
        baseY = baseY - 125
        
    end
    
    local currentStack = 0
    
    -- 1. Bio (Lowest on screen)
    local shortBio = player:getModData()['_CharacterBioShortDescription']
    if shortBio and type(shortBio) == "string" and string.len(shortBio) > 1 then
        offsets.bio = math.floor(baseY - currentStack)
        currentStack = currentStack + 15
    end
    
    -- 2. Status
    local status = AC.Meta.GetStatus(username)
    local isHovered = false
    local ownPlayer = getPlayer()
    if ownPlayer then
        local worldX = screenToIsoX(0, getMouseX(), getMouseY(), ownPlayer:getZ())
        local worldY = screenToIsoY(0, getMouseX(), getMouseY(), ownPlayer:getZ())
        local dx = worldX - player:getX()
        local dy = worldY - player:getY()
        local distSq = dx*dx + dy*dy
        if ownPlayer:getZ() == player:getZ() and distSq <= 2.25 and AC.CanSeePlayer(player, true, 20) then
            isHovered = true
        end
    end
    if isHovered and type(status) == "string" and status:match("%S") then
        offsets.status = math.floor(baseY - currentStack)
        currentStack = currentStack + 15
    end
    
    -- 3. AFK
    if AC.Meta.IsAfk(username) then
        offsets.afk = math.floor(baseY - currentStack)
        currentStack = currentStack + 15
    end
    
    -- 3.5 PVP
    local isPvp = false
    local safety = player:getSafety()
    if safety and tostring(safety) ~= "null" then
        local success, isCurrent = pcall(function() return safety:isCurrent() end)
        if success and not isCurrent then
            isPvp = true
        end
    end
    if isPvp then
        offsets.pvp = math.floor(baseY - currentStack)
        currentStack = currentStack + 15
    end
    
    -- 4. Nameplate
    if AC.Name.ShowNamesOnPlayers then
        offsets.name = math.floor(baseY - currentStack)
        currentStack = currentStack + 15
    end
    
    -- 5. Indicator (Typing, Highest on screen)
    if AC.Indicator and AC.Indicator.players[username] then
        offsets.indicator = math.floor(baseY - currentStack)
        currentStack = currentStack + 15
    end
    
    return offsets
end
