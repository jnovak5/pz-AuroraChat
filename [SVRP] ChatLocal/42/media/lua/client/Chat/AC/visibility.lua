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

--- Check if a screen coordinate / bounding box is occluded by open UI windows (e.g. Chatbox, Combat UI)
--- @param x number Screen center X
--- @param y number Screen top Y
--- @param w number? Optional width
--- @param h number? Optional height
--- @return boolean
function AC.Visibility.IsOccludedByUI(x, y, w, h)
    w = w or 0
    h = h or 14
    local x1 = x - (w / 2)
    local x2 = x + (w / 2)
    local y1 = y
    local y2 = y + h

    -- 1. Check ISChat window
    if ISChat and ISChat.instance and ISChat.instance:isVisible() then
        local chat = ISChat.instance
        local cx = chat:getAbsoluteX()
        local cy = chat:getAbsoluteY()
        local cw = chat:getWidth()
        local ch = (chat.isCollapsed and chat:isCollapsed()) and (chat:titleBarHeight() or 20) or chat:getHeight()

        if x1 < cx + cw and x2 > cx and y1 < cy + ch and y2 > cy then
            return true
        end
    end

    -- 2. Check Combat Match UI
    if AC_ISCombatMatchUI and AC_ISCombatMatchUI.instance and AC_ISCombatMatchUI.instance:isVisible() then
        local ui = AC_ISCombatMatchUI.instance
        local ux = ui:getAbsoluteX()
        local uy = ui:getAbsoluteY()
        local uw = ui:getWidth()
        local uh = ui:getHeight()

        if x1 < ux + uw and x2 > ux and y1 < uy + uh and y2 > uy then
            return true
        end
    end

    -- 3. Check Character Bio UI
    if AC_ISWriteBio and AC_ISWriteBio.instance and AC_ISWriteBio.instance:isVisible() then
        local bio = AC_ISWriteBio.instance
        local bx = bio:getAbsoluteX()
        local by = bio:getAbsoluteY()
        local bw = bio:getWidth()
        local bh = bio:getHeight()

        if x1 < bx + bw and x2 > bx and y1 < by + bh and y2 > by then
            return true
        end
    end

    return false
end

--- Draw text centered with a black outline and UI occlusion checks
function AC.Visibility.DrawTextCentre(font, x, y, text, r, g, b, a)
    if not text or text == "" or not a or a <= 0.01 then return end
    local tm = getTextManager()
    if not tm then return end

    -- Ensure integer pixel coordinates to prevent text rendering wobble/jitter
    x = math.floor(x)
    y = math.floor(y)

    local textW = tm:MeasureStringX(font or UIFont.Small, text)
    local textH = tm:getFontHeight(font or UIFont.Small)

    -- Do not draw if covered by the chatbox or open modal UI
    if AC.Visibility.IsOccludedByUI(x, y, textW, textH) then
        return
    end

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
