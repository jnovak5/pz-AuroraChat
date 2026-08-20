if isServer() and not isClient() then return end

AC = AC or {}
AC.PlayerEvents = AC.PlayerEvents or {}
AC.PlayerEvents.ActiveEvents = {}
AC.PlayerEvents.HoveredEventId = nil

--- Create a new player or admin event
function AC.PlayerEvents.CreateEvent(title, desc, category, radius, isPublic, worldX, worldY, worldZ)
    local player = getPlayer()
    if not player then return end

    local charName = player:getDescriptor() and (player:getDescriptor():getForename() .. " " .. player:getDescriptor():getSurname()) or player:getUsername()
    local isAdmin = AC_Utils.isStaff(player) or AC.Override(true)

    local payload = {
        id = "ev_" .. tostring(getPlayer():getUsername()) .. "_" .. tostring(getTimestampMs()),
        title = title or "Player Gathering",
        description = desc or "",
        category = category or "Social Gathering",
        radius = tonumber(radius) or 50,
        isPublic = (isPublic ~= false),
        worldX = math.floor(worldX or player:getX()),
        worldY = math.floor(worldY or player:getY()),
        worldZ = math.floor(worldZ or player:getZ()),
        isAdminEvent = isAdmin,
        host = player:getUsername(),
        hostCharName = charName,
        createdAt = getTimestampMs(),
        attendees = {
            [player:getUsername()] = { status = "accepted", charName = charName }
        }
    }

    if isClient() then
        sendClientCommand(player, "AC", "EventCreate", payload)
    else
        AC.PlayerEvents.ActiveEvents[payload.id] = payload
        AC_Utils.addInfoToChat(string.format("Created event '%s' successfully!", payload.title))
    end
end

--- Cancel / end an event
function AC.PlayerEvents.CancelEvent(eventId)
    local player = getPlayer()
    if not player or not eventId then return end
    if isClient() then
        sendClientCommand(player, "AC", "EventCancel", { eventId })
    else
        AC.PlayerEvents.ActiveEvents[eventId] = nil
        AC_Utils.addInfoToChat("Event cancelled.")
    end
end

--- Invite a list of players to an event
function AC.PlayerEvents.InvitePlayers(eventId, playerUsernames)
    local player = getPlayer()
    if not player or not eventId or not playerUsernames then return end
    if isClient() then
        sendClientCommand(player, "AC", "EventInvite", { eventId = eventId, players = playerUsernames })
    else
        local event = AC.PlayerEvents.ActiveEvents[eventId]
        if event then
            for _, u in ipairs(playerUsernames) do
                event.attendees[u] = { status = "invited", charName = u }
            end
        end
    end
end

--- RSVP to an event
function AC.PlayerEvents.RSVP(eventId, status)
    local player = getPlayer()
    if not player or not eventId then return end
    local charName = player:getDescriptor() and (player:getDescriptor():getForename() .. " " .. player:getDescriptor():getSurname()) or player:getUsername()
    if isClient() then
        sendClientCommand(player, "AC", "EventRSVP", { eventId, status, charName })
    else
        local event = AC.PlayerEvents.ActiveEvents[eventId]
        if event then
            event.attendees[player:getUsername()] = { status = status, charName = charName }
        end
    end
end

--- Get attendee counts breakdown (going, maybe, declined)
function AC.PlayerEvents.GetAttendeeCounts(event)
    if not event or not event.attendees then return 0, 0, 0 end
    local going, maybe, declined = 0, 0, 0
    for _, att in pairs(event.attendees) do
        if type(att) == "table" then
            if att.status == "accepted" then
                going = going + 1
            elseif att.status == "maybe" then
                maybe = maybe + 1
            elseif att.status == "declined" then
                declined = declined + 1
            end
        elseif att == "accepted" then
            going = going + 1
        elseif att == "maybe" then
            maybe = maybe + 1
        elseif att == "declined" then
            declined = declined + 1
        end
    end
    return going, maybe, declined
end

--- Get event hosted by current player
function AC.PlayerEvents.GetMyHostedEvent()
    local player = getPlayer()
    if not player then return nil end
    local myUsername = player:getUsername()
    for _, event in pairs(AC.PlayerEvents.ActiveEvents) do
        if event.host == myUsername then
            return event
        end
    end
    return nil
end

--- Find event near world coordinates
function AC.PlayerEvents.GetEventAtWorldPos(worldX, worldY, tolerance)
    tolerance = tolerance or 30
    for _, event in pairs(AC.PlayerEvents.ActiveEvents) do
        local ex = event.worldX or event.x or 0
        local ey = event.worldY or event.y or 0
        local dist = math.sqrt((worldX - ex) * (worldX - ex) + (worldY - ey) * (worldY - ey))
        local rad = event.radius or 50
        if dist <= (rad + tolerance) then
            return event
        end
    end
    return nil
end

--- Render player & admin event markers on ISWorldMap
function AC.PlayerEvents.RenderMapMarkers(mapUI)
    if not mapUI or not mapUI.mapAPI then return end
    if not AC.PlayerEvents.ActiveEvents then return end

    local mouseX = mapUI:getMouseX()
    local mouseY = mapUI:getMouseY()
    local hoveredEvent = nil
    local now = getTimestampMs()
    local whiteTex = Texture:getWhite()

    for eventId, event in pairs(AC.PlayerEvents.ActiveEvents) do
        local wx = event.worldX or event.x
        local wy = event.worldY or event.y
        if wx and wy then
            local centerUIX = mapUI.mapAPI:worldToUIX(wx, wy)
            local centerUIY = mapUI.mapAPI:worldToUIY(wx, wy)
            local radiusWorld = event.radius or 50

            local isAdmin = event.isAdminEvent == true
            local r, g, b = 0.15, 0.85, 0.95
            local fillA = 0.08
            local borderA = 0.85

            if isAdmin then
                local pulse = 0.7 + (math.sin(now / 300) * 0.3)
                r, g, b = 1.0, 0.85 * pulse, 0.2
                fillA = 0.14
                borderA = 0.95 * pulse
            end

            -- 1. Draw Event Area Boundary Circle in World Coordinates
            local numSegments = 64
            local angleStep = (math.pi * 2) / numSegments
            local p0x = wx + math.cos(0) * radiusWorld
            local p0y = wy + math.sin(0) * radiusWorld
            local prevX = mapUI.mapAPI:worldToUIX(p0x, p0y)
            local prevY = mapUI.mapAPI:worldToUIY(p0x, p0y)

            for i = 1, numSegments do
                local angle = i * angleStep
                local curWx = wx + math.cos(angle) * radiusWorld
                local curWy = wy + math.sin(angle) * radiusWorld
                local nextX = mapUI.mapAPI:worldToUIX(curWx, curWy)
                local nextY = mapUI.mapAPI:worldToUIY(curWx, curWy)

                if mapUI.javaObject and mapUI.javaObject.DrawLine then
                    mapUI.javaObject:DrawLine(whiteTex, prevX, prevY, nextX, nextY, 3, r, g, b, borderA)
                    if isAdmin then
                        mapUI.javaObject:DrawLine(whiteTex, prevX + 1, prevY + 1, nextX + 1, nextY + 1, 2, 1.0, 0.85, 0.2, borderA * 0.7)
                    end
                elseif mapUI.drawLine then
                    mapUI:drawLine(whiteTex, prevX, prevY, nextX, nextY, 3, borderA, r, g, b)
                end

                prevX = nextX
                prevY = nextY
            end

            -- 2. Draw Center Marker Badge
            local badgeW = isAdmin and 180 or 150
            local badgeH = 26
            local badgeX = centerUIX - (badgeW / 2)
            local badgeY = centerUIY - 13

            local distToCenter = math.sqrt((mouseX - centerUIX) * (mouseX - centerUIX) + (mouseY - centerUIY) * (mouseY - centerUIY))
            local isMouseOver = (distToCenter <= 30) or (mouseX >= badgeX and mouseX <= badgeX + badgeW and mouseY >= badgeY and mouseY <= badgeY + badgeH)

            if isMouseOver and not hoveredEvent then
                hoveredEvent = event
            end

            local bgAlpha = isMouseOver and 0.95 or 0.85
            mapUI:drawRect(badgeX, badgeY, badgeW, badgeH, bgAlpha, 0.04, 0.05, 0.08)

            if isAdmin then
                mapUI:drawRectBorder(badgeX, badgeY, badgeW, badgeH, 0.95, 1.0, 0.80, 0.20)
                mapUI:drawRectBorder(badgeX + 1, badgeY + 1, badgeW - 2, badgeH - 2, 0.60, 0.95, 0.30, 0.20)
                mapUI:drawTextCentre("★ OFFICIAL EVENT ★", centerUIX, badgeY + 3, 1.0, 0.85, 0.20, 1.0, UIFont.Small)
                mapUI:drawTextCentre(event.title or "Server Event", centerUIX, badgeY + 13, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
            else
                mapUI:drawRectBorder(badgeX, badgeY, badgeW, badgeH, 0.90, 0.20, 0.80, 0.95)
                mapUI:drawTextCentre("[ PLAYER EVENT ]", centerUIX, badgeY + 3, 0.30, 0.85, 0.95, 1.0, UIFont.Small)
                mapUI:drawTextCentre(event.title or "Gathering", centerUIX, badgeY + 13, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
            end
        end
    end

    -- 3. Draw Hover Tooltip Card
    if hoveredEvent then
        local hw = 260
        local hh = 110
        local hx = math.min(mapUI.width - hw - 10, math.max(10, mouseX + 15))
        local hy = math.min(mapUI.height - hh - 10, math.max(10, mouseY + 15))

        mapUI:drawRect(hx - 2, hy - 2, hw + 4, hh + 4, 0.50, 0.0, 0.0, 0.0)
        mapUI:drawRect(hx, hy, hw, hh, 0.94, 0.05, 0.07, 0.12)

        local isAdmin = hoveredEvent.isAdminEvent == true
        if isAdmin then
            mapUI:drawRectBorder(hx, hy, hw, hh, 0.95, 1.0, 0.80, 0.20)
            mapUI:drawText("★ OFFICIAL SERVER EVENT", hx + 10, hy + 8, 1.0, 0.85, 0.20, 1.0, UIFont.Medium)
        else
            mapUI:drawRectBorder(hx, hy, hw, hh, 0.90, 0.20, 0.80, 0.95)
            mapUI:drawText("[ " .. (hoveredEvent.category or "Gathering") .. " ]", hx + 10, hy + 8, 0.30, 0.85, 0.95, 1.0, UIFont.Medium)
        end

        mapUI:drawText(hoveredEvent.title or "Untitled", hx + 10, hy + 28, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
        mapUI:drawText("Host: " .. (hoveredEvent.hostCharName or hoveredEvent.host or "Unknown"), hx + 10, hy + 46, 0.80, 0.80, 0.80, 1.0, UIFont.Small)

        local goingCount, maybeCount = 0, 0
        if hoveredEvent.attendees then
            for _, att in pairs(hoveredEvent.attendees) do
                if att.status == "accepted" then goingCount = goingCount + 1 end
                if att.status == "maybe" then maybeCount = maybeCount + 1 end
            end
        end
        mapUI:drawText(string.format("RSVP: %d Going | %d Interested", goingCount, maybeCount), hx + 10, hy + 64, 0.30, 0.95, 0.50, 1.0, UIFont.Small)
        mapUI:drawText("Right-Click map to RSVP or View Details", hx + 10, hy + 86, 0.65, 0.75, 0.85, 1.0, UIFont.Small)
    end
end
