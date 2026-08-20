if isServer() and not isClient() then return end

AC = AC or {}
AC.RadioMap = AC.RadioMap or {}

AC.RadioMap.ShowRange = false

--- Check if an inventory item is a two-way radio
--- @param item InventoryItem
--- @return boolean, number, number
local function getRadioData(item)
    if not item then return false, 0, 0 end
    local data = nil
    if item.getDeviceData then
        local success, result = pcall(function() return item:getDeviceData() end)
        if success then data = result end
    end
    if data and data.getIsTwoWay and data:getIsTwoWay() then
        local range = data:getTransmitRange() or 0
        if range <= 0 then
            local fullType = item:getFullType() or ""
            if string.find(fullType, "ManPack") or string.find(fullType, "Ham") then
                range = 20000
            elseif string.find(fullType, "Military") or string.find(fullType, "WalkieTalkie5") then
                range = 16000
            elseif string.find(fullType, "WalkieTalkie4") then
                range = 7500
            elseif string.find(fullType, "WalkieTalkie3") then
                range = 5000
            elseif string.find(fullType, "WalkieTalkie2") then
                range = 3000
            else
                range = 1000
            end
        end
        local freq = (data:getChannel() or 0) / 1000.0
        return true, range, freq
    end
    return false, 0, 0
end

--- Find an active, equipped or attached handheld two-way radio on the player
--- @param player IsoPlayer
--- @return InventoryItem|nil, number, number
function AC.RadioMap.GetEquippedHandheldRadio(player)
    if not player then return nil, 0, 0 end
    local inv = player:getInventory()
    if not inv then return nil, 0, 0 end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    local attachedItems = player:getAttachedItems()

    local candidates = {}
    if primary then table.insert(candidates, primary) end
    if secondary and secondary ~= primary then table.insert(candidates, secondary) end

    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local item = attachedItems:getItemByIndex(i)
            if item then
                table.insert(candidates, item)
            end
        end
    end

    -- Check equipped/worn items on player (backpacks, walkies on belt/chest/holster)
    local items = inv:getItems()
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local isEquipped = false
                if player.isEquipped and player:isEquipped(item) then
                    isEquipped = true
                elseif player.isAttachedItem and player:isAttachedItem(item) then
                    isEquipped = true
                elseif item.isEquipped and item:isEquipped() then
                    isEquipped = true
                end
                if isEquipped then
                    table.insert(candidates, item)
                end
            end
        end
    end

    -- If no equipped/attached radio, check any two-way radio in main inventory that is turned on
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item.getDeviceData then
                local data = item:getDeviceData()
                if data and data.getIsTurnedOn and data:getIsTurnedOn() then
                    table.insert(candidates, item)
                end
            end
        end
    end

    -- If still none, check any two-way radio in inventory
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                table.insert(candidates, item)
            end
        end
    end

    for _, item in ipairs(candidates) do
        local isRadio, range, freq = getRadioData(item)
        if isRadio and range > 0 then
            return item, range, freq
        end
    end

    return nil, 0, 0
end

--- Toggle radio range display on world map
function AC.RadioMap.ToggleRange()
    AC.RadioMap.ShowRange = not AC.RadioMap.ShowRange
    local player = getPlayer()
    local radio, range, freq = AC.RadioMap.GetEquippedHandheldRadio(player)

    if AC.RadioMap.ShowRange then
        if radio then
            local data = radio:getDeviceData()
            local isOn = data and data:getIsTurnedOn()
            local statusStr = isOn and "Active" or "Turned Off"
            AC_Utils.addInfoToChat(string.format("Radio Range Display: ON (%dm reach | %.1f MHz | %s)", range, freq, statusStr))
        else
            AC_Utils.addInfoToChat("Radio Range Display: ON (Equip or carry a two-way radio to project range)")
        end
    else
        AC_Utils.addInfoToChat("Radio Range Display: OFF")
    end
    return AC.RadioMap.ShowRange
end

--- Draw a single projected circle ring at a specific world radius
local function drawWorldCircleRing(mapUI, px, py, radius, numSegments, r, g, b, alpha, thickness)
    local whiteTex = Texture:getWhite()
    local angleStep = (math.pi * 2) / numSegments
    local p0x = px + math.cos(0) * radius
    local p0y = py + math.sin(0) * radius
    local prevX = mapUI.mapAPI:worldToUIX(p0x, p0y)
    local prevY = mapUI.mapAPI:worldToUIY(p0x, p0y)

    for i = 1, numSegments do
        local angle = i * angleStep
        local wx = px + math.cos(angle) * radius
        local wy = py + math.sin(angle) * radius
        local nextX = mapUI.mapAPI:worldToUIX(wx, wy)
        local nextY = mapUI.mapAPI:worldToUIY(wx, wy)

        if mapUI.javaObject and mapUI.javaObject.DrawLine then
            mapUI.javaObject:DrawLine(whiteTex, prevX, prevY, nextX, nextY, thickness, r, g, b, alpha)
        elseif mapUI.drawLine then
            mapUI:drawLine(whiteTex, prevX, prevY, nextX, nextY, thickness, alpha, r, g, b)
        end

        prevX = nextX
        prevY = nextY
    end
end

--- Render giant radio range overlay circle on ISWorldMap with edge blur / signal falloff
--- @param mapUI ISWorldMap
function AC.RadioMap.Render(mapUI)
    if not AC.RadioMap.ShowRange then return end
    if not mapUI or not mapUI.mapAPI then return end

    local player = mapUI.character or getPlayer()
    if not player then return end

    local radio, range, freq = AC.RadioMap.GetEquippedHandheldRadio(player)
    if not radio or range <= 0 then return end

    local px = player:getX()
    local py = player:getY()

    local data = radio:getDeviceData()
    local isTurnedOn = data and data:getIsTurnedOn()
    local r, g, b = 0.15, 0.85, 0.95 -- Vivid Cyan / Azure
    if not isTurnedOn then
        r, g, b = 0.85, 0.65, 0.25 -- Amber if turned off
    end

    local whiteTex = Texture:getWhite()
    local numSegments = 96

    -- 1. Intermediate Signal Distance Rings (Visible at Close Zoom)
    local refDistances = {}
    if range >= 12000 then
        refDistances = { 500, 1500, 5000, 10000 }
    elseif range >= 4000 then
        refDistances = { 500, 1500, 3000 }
    elseif range >= 1500 then
        refDistances = { 250, 500, 1000 }
    end

    for _, refDist in ipairs(refDistances) do
        if refDist < (range * 0.82) then
            drawWorldCircleRing(mapUI, px, py, refDist, 64, r, g, b, 0.25, 1)
            local rx = mapUI.mapAPI:worldToUIX(px, py - refDist)
            local ry = mapUI.mapAPI:worldToUIY(px, py - refDist)
            local lbl = refDist >= 1000 and string.format("%.1fkm", refDist / 1000) or string.format("%dm", refDist)
            mapUI:drawTextCentre(lbl, rx, ry - 14, r, g, b, 0.75, UIFont.Small)
        end
    end

    -- 2. Multi-Layer Radial Fringe Gradient (Simulates Signal Dispersion & Edge Blur at Max Range)
    local fringeLayers = {
        { scale = 0.88, alpha = 0.08, thick = 1 },
        { scale = 0.91, alpha = 0.15, thick = 1 },
        { scale = 0.94, alpha = 0.25, thick = 1.5 },
        { scale = 0.97, alpha = 0.45, thick = 2 },
        { scale = 1.00, alpha = 0.90, thick = 2.5 }, -- Nominal limit
        { scale = 1.03, alpha = 0.45, thick = 2 },
        { scale = 1.06, alpha = 0.25, thick = 1.5 },
        { scale = 1.09, alpha = 0.12, thick = 1 },
        { scale = 1.12, alpha = 0.06, thick = 1 }
    }

    for _, layer in ipairs(fringeLayers) do
        drawWorldCircleRing(mapUI, px, py, range * layer.scale, numSegments, r, g, b, layer.alpha, layer.thick)
    end

    -- 3. Subtle Radial Static Rays across the Edge Fringe (±10% Zone)
    local numSpokes = 48
    local spokeStep = (math.pi * 2) / numSpokes
    for i = 1, numSpokes do
        local angle = i * spokeStep
        local inX = px + math.cos(angle) * (range * 0.92)
        local inY = py + math.sin(angle) * (range * 0.92)
        local outX = px + math.cos(angle) * (range * 1.08)
        local outY = py + math.sin(angle) * (range * 1.08)

        local uinX = mapUI.mapAPI:worldToUIX(inX, inY)
        local uinY = mapUI.mapAPI:worldToUIY(inX, inY)
        local uoutX = mapUI.mapAPI:worldToUIX(outX, outY)
        local uoutY = mapUI.mapAPI:worldToUIY(outX, outY)

        if mapUI.javaObject and mapUI.javaObject.DrawLine then
            mapUI.javaObject:DrawLine(whiteTex, uinX, uinY, uoutX, uoutY, 1, r, g, b, 0.18)
        end
    end

    -- 4. Center Crosshair
    local centerUIX = mapUI.mapAPI:worldToUIX(px, py)
    local centerUIY = mapUI.mapAPI:worldToUIY(px, py)

    if mapUI.javaObject and mapUI.javaObject.DrawLine then
        mapUI.javaObject:DrawLine(whiteTex, centerUIX - 10, centerUIY, centerUIX + 10, centerUIY, 2, r, g, b, 0.95)
        mapUI.javaObject:DrawLine(whiteTex, centerUIX, centerUIY - 10, centerUIX, centerUIY + 10, 2, r, g, b, 0.95)
    elseif mapUI.drawLine then
        mapUI:drawLine(whiteTex, centerUIX - 10, centerUIY, centerUIX + 10, centerUIY, 2, 0.95, r, g, b)
        mapUI:drawLine(whiteTex, centerUIX, centerUIY - 10, centerUIX, centerUIY + 10, 2, 0.95, r, g, b)
    end

    -- 5. Info Badge above player (Clean text without emoji characters)
    local badgeText = string.format("[ Radio Range: %dm (±10%% Fringe) | %.1f MHz ]", range, freq)
    if not isTurnedOn then
        badgeText = string.format("[ Radio Range: %dm (OFF) ]", range)
    end

    local tm = getTextManager()
    local font = UIFont.Small
    local textW = tm:MeasureStringX(font, badgeText)
    local textH = tm:getFontHeight(font)
    local badgeX = centerUIX - (textW / 2)
    local badgeY = centerUIY - 32

    mapUI:drawRect(badgeX - 4, badgeY - 2, textW + 8, textH + 4, 0.88, 0.04, 0.06, 0.1)
    mapUI:drawRectBorder(badgeX - 4, badgeY - 2, textW + 8, textH + 4, 0.95, r, g, b)
    mapUI:drawText(badgeText, badgeX, badgeY, 1.0, 1.0, 1.0, 1.0, font)
end
