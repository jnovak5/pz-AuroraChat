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
        local fullType = item:getFullType() or ""
        if not (string.find(fullType, "Military") or string.find(fullType, "WalkieTalkie5")) then
            return false, 0, 0
        end
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
    local thick = math.max(1, math.floor(thickness or 1))

    for i = 1, numSegments do
        local angle = i * angleStep
        local wx = px + math.cos(angle) * radius
        local wy = py + math.sin(angle) * radius
        local nextX = mapUI.mapAPI:worldToUIX(wx, wy)
        local nextY = mapUI.mapAPI:worldToUIY(wx, wy)

        if prevX and prevY and nextX and nextY then
            if mapUI.javaObject and mapUI.javaObject.DrawLine then
                mapUI.javaObject:DrawLine(whiteTex, prevX, prevY, nextX, nextY, thick, r, g, b, alpha)
            elseif mapUI.drawLine then
                mapUI:drawLine(whiteTex, prevX, prevY, nextX, nextY, thick, alpha, r, g, b)
            end
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

    -- High-Contrast Color Palette
    -- Active / ON: Electric Aqua / Cyan (High visibility on map & dark mode)
    -- Turned OFF: Vibrant Bright Crimson / Coral (Sharp, non-blending contrast)
    local r, g, b = 0.05, 0.88, 1.0
    if not isTurnedOn then
        r, g, b = 1.0, 0.28, 0.35
    end

    local whiteTex = Texture:getWhite()
    local numSegments = 96
    local tm = getTextManager()
    -- 1. Close, Medium, and Long Distance Signal Radar Propagation Rings (Visible at Any Zoom Level!)
    local allDistanceRings = { 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 15000 }
    for _, refDist in ipairs(allDistanceRings) do
        if refDist < (range * 0.85) then
            drawWorldCircleRing(mapUI, px, py, refDist, 64, r, g, b, 0.40, 1)
        end
    end

    -- 2. Multi-Layer Radial Fringe Gradient (Simulates Signal Dispersion & Edge Blur at Max Range)
    local fringeLayers = {
        { scale = 0.88, alpha = 0.12, thick = 1 },
        { scale = 0.91, alpha = 0.22, thick = 1 },
        { scale = 0.94, alpha = 0.38, thick = 2 },
        { scale = 0.97, alpha = 0.65, thick = 2 },
        { scale = 1.00, alpha = 0.98, thick = 3 }, -- Nominal maximum limit
        { scale = 1.03, alpha = 0.65, thick = 2 },
        { scale = 1.06, alpha = 0.38, thick = 2 },
        { scale = 1.09, alpha = 0.22, thick = 1 },
        { scale = 1.12, alpha = 0.10, thick = 1 }
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

        if uinX and uinY and uoutX and uoutY then
            if mapUI.javaObject and mapUI.javaObject.DrawLine then
                mapUI.javaObject:DrawLine(whiteTex, uinX, uinY, uoutX, uoutY, 1, r, g, b, 0.25)
            end
        end
    end

    -- 4. Center Crosshair (with high-contrast dark drop shadow)
    local centerUIX = mapUI.mapAPI:worldToUIX(px, py)
    local centerUIY = mapUI.mapAPI:worldToUIY(px, py)

    if centerUIX and centerUIY then
        if mapUI.javaObject and mapUI.javaObject.DrawLine then
            -- Dark shadow underlay
            mapUI.javaObject:DrawLine(whiteTex, centerUIX - 13, centerUIY + 1, centerUIX + 13, centerUIY + 1, 3, 0.0, 0.0, 0.0, 0.8)
            mapUI.javaObject:DrawLine(whiteTex, centerUIX + 1, centerUIY - 13, centerUIX + 1, centerUIY + 13, 3, 0.0, 0.0, 0.0, 0.8)
            -- Foreground crosshair
            mapUI.javaObject:DrawLine(whiteTex, centerUIX - 12, centerUIY, centerUIX + 12, centerUIY, 2, r, g, b, 1.0)
            mapUI.javaObject:DrawLine(whiteTex, centerUIX, centerUIY - 12, centerUIX, centerUIY + 12, 2, r, g, b, 1.0)
        elseif mapUI.drawLine then
            mapUI:drawLine(whiteTex, centerUIX - 12, centerUIY, centerUIX + 12, centerUIY, 2, 1.0, r, g, b)
            mapUI:drawLine(whiteTex, centerUIX, centerUIY - 12, centerUIX, centerUIY + 12, 2, 1.0, r, g, b)
        end

        -- 5. Info Badge above player (Clean high-contrast obsidian card)
        local badgeText = string.format("[ Radio Range: %dm (±10%% Fringe) | %.1f MHz ]", range, freq)
        if not isTurnedOn then
            badgeText = string.format("[ Radio Range: %dm (OFF) ]", range)
        end

        local font = UIFont.Small
        local textW = tm and tm:MeasureStringX(font, badgeText) or 180
        local textH = tm and tm:getFontHeight(font) or 16
        local badgeX = centerUIX - (textW / 2)
        local badgeY = centerUIY - 34

        mapUI:drawRect(badgeX - 4, badgeY - 2, textW + 8, textH + 4, 0.92, 0.05, 0.07, 0.12)
        mapUI:drawRectBorder(badgeX - 4, badgeY - 2, textW + 8, textH + 4, 0.98, r, g, b)
        mapUI:drawText(badgeText, badgeX, badgeY, 1.0, 1.0, 1.0, 1.0, font)
    end
end
