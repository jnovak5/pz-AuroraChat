if isServer() and not isClient() then return end

require "ISUI/Maps/ISWorldMap"

AC = AC or {}
AC.WorldMap = AC.WorldMap or {}

-- Wrap ISWorldMap:createChildren to add our custom Radio Range and Event buttons
local original_ISWorldMap_createChildren = ISWorldMap.createChildren
function ISWorldMap:createChildren()
    original_ISWorldMap_createChildren(self)

    local btnSize = 36
    if self.closeBtn then
        btnSize = self.closeBtn:getWidth()
    end

    -- 2. Player / Server Event Button
    local noteTex = getTexture("media/ui/inventoryPanes/Button_Note.png") or getTexture("media/textures/worldMap/Map_On.png")
    self.acEventBtn = ISButton:new(0, 0, btnSize, btnSize, "EV", self, function(mapObj)
        local myHosted = AC.PlayerEvents and AC.PlayerEvents.GetMyHostedEvent()
        if myHosted then
            AC_ISEventManageUI.Open(myHosted)
        else
            local player = (mapObj and mapObj.character) or getPlayer()
            local cx = player and player:getX() or (mapObj and mapObj.mapAPI and mapObj.mapAPI:getCenterWorldX() or 0)
            local cy = player and player:getY() or (mapObj and mapObj.mapAPI and mapObj.mapAPI:getCenterWorldY() or 0)
            AC_ISCreateEventUI.Open(math.floor(cx), math.floor(cy), 0)
        end
    end)
    self.acEventBtn:initialise()
    self.acEventBtn:instantiate()
    if noteTex then
        self.acEventBtn:setImage(noteTex)
    end
    self.acEventBtn.tooltip = "Player & Server Events (Create / Manage)"
    self.acEventBtn.backgroundColor = {r=0.15, g=0.25, b=0.45, a=0.85}
    self.acEventBtn.borderColor = {r=0.3, g=0.7, b=0.95, a=0.8}

    if self.buttonPanel then
        local rightBtn = self.closeBtn or self.optionBtn
        local nextX = rightBtn and (rightBtn:getRight() + 10) or 0

        self.acEventBtn:setX(nextX)
        self.buttonPanel:addChild(self.acEventBtn)

        self.buttonPanel:shrinkWrap(0, 0, nil)
        self.buttonPanel:setX(self.width - 10 - self.buttonPanel.width)
    else
        self.acEventBtn:setX(self.width - 145)
        self.acEventBtn:setY(10)
        self:addChild(self.acEventBtn)
    end
end

-- Hook ISWorldMap:onRightMouseDown to ensure onRightMouseUp is delivered to ISWorldMap
function ISWorldMap:onRightMouseDown(x, y)
    if self.symbolsUI and self.symbolsUI:onRightMouseDownMap(x, y) then
        return true
    end
    return true -- Return true so ISUIElement registers mouse down and fires onRightMouseUp
end

-- Wrap ISWorldMap:onRightMouseUp to support right-click Player Events and context menus
local original_ISWorldMap_onRightMouseUp = ISWorldMap.onRightMouseUp
function ISWorldMap:onRightMouseUp(x, y)
    if self.symbolsUI and self.symbolsUI:onRightMouseUpMap(x, y) then
        return true
    end

    local player = self.character or getSpecificPlayer(self.playerNum or 0) or getPlayer()
    if not player then return false end

    local worldX = math.floor(self.mapAPI:uiToWorldX(x, y))
    local worldY = math.floor(self.mapAPI:uiToWorldY(x, y))

    local screenX = math.floor(x + self:getAbsoluteX())
    local screenY = math.floor(y + self:getAbsoluteY())

    local playerNum = player:getPlayerNum() or 0
    local context = ISContextMenu.get(playerNum, screenX, screenY)
    if not context then return false end

    -- Check if right-clicking near an existing active event
    local nearbyEvent = AC.PlayerEvents and AC.PlayerEvents.GetEventAtWorldPos(worldX, worldY, 40)
    if nearbyEvent then
        local isAdmin = nearbyEvent.isAdminEvent == true
        local tag = isAdmin and "[OFFICIAL EVENT] " or "[EVENT] "
        local evOpt = context:addOption(tag .. (nearbyEvent.title or "Details"), nearbyEvent, function(ev)
            AC_ISEventManageUI.Open(ev)
        end)

        -- RSVP quick actions
        local myUsername = player:getUsername()
        if nearbyEvent.host ~= myUsername then
            local rsvpMenu = ISContextMenu:getNew(context)
            context:addSubMenu(evOpt, rsvpMenu)
            rsvpMenu:addOption("RSVP: Going (Accept)", nearbyEvent.id, function(id) AC.PlayerEvents.RSVP(id, "accepted") end)
            rsvpMenu:addOption("RSVP: Interested (Maybe)", nearbyEvent.id, function(id) AC.PlayerEvents.RSVP(id, "maybe") end)
            rsvpMenu:addOption("RSVP: Can't Go (Decline)", nearbyEvent.id, function(id) AC.PlayerEvents.RSVP(id, "declined") end)
            rsvpMenu:addOption("View Full Event Details & Attendees", nearbyEvent, function(ev) AC_ISEventManageUI.Open(ev) end)
        end
    end

    -- My Hosted Event option
    local myHostedEvent = AC.PlayerEvents and AC.PlayerEvents.GetMyHostedEvent()
    if myHostedEvent then
        context:addOption("Manage My Event (" .. myHostedEvent.title .. ")", myHostedEvent, function(ev)
            AC_ISEventManageUI.Open(ev)
        end)
    else
        -- Start New Event option
        local isAdmin = AC_Utils.isStaff(player) or AC.Override(true)
        local createText = isAdmin and "Start Official Server Event Here..." or "Start Player Event Here..."
        context:addOption(createText, nil, function()
            AC_ISCreateEventUI.Open(worldX, worldY, 0)
        end)
    end

    -- If admin/debug, also allow vanilla admin menu items
    if getDebug() or (isClient() and (getAccessLevel() == "admin")) or (not isClient()) then
        if original_ISWorldMap_onRightMouseUp then
            pcall(function() original_ISWorldMap_onRightMouseUp(self, x, y) end)
        end
    end

    context:bringToTop()
    return true
end

-- Wrap ISWorldMap:prerender to draw radio range and event markers
local original_ISWorldMap_prerender = ISWorldMap.prerender
function ISWorldMap:prerender()
    original_ISWorldMap_prerender(self)

    -- 2. Render Player & Admin Event Markers
    if AC.PlayerEvents then
        pcall(function()
            AC.PlayerEvents.RenderMapMarkers(self)
        end)
    end
end
