require "ISUI/ISCollapsableWindowJoypad"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISButton"
require "ISUI/ISLabel"

AC_ISEventManageUI = ISCollapsableWindowJoypad:derive("AC_ISEventManageUI")

function AC_ISEventManageUI:initialise()
    ISCollapsableWindowJoypad.initialise(self)
end

function AC_ISEventManageUI:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)

    local th = self:titleBarHeight()
    local pad = 16
    local curY = th + 10
    local contentW = self.width - (pad * 2)

    local event = self.event
    if not event then return end

    local myUsername = getPlayer() and getPlayer():getUsername()
    local isHost = (event.host == myUsername) or (getPlayer() and (AC_Utils.isStaff(getPlayer()) or AC.Override(true)))
    local isAdmin = event.isAdminEvent == true

    -- Header Badge
    local headerText = isAdmin and "★ OFFICIAL SERVER EVENT ★" or "[ PLAYER EVENT ]"
    local headerColor = isAdmin and {r=1.0, g=0.85, b=0.2} or {r=0.2, g=0.85, b=0.95}
    local tagLbl = ISLabel:new(pad, curY, 18, headerText, headerColor.r, headerColor.g, headerColor.b, 1.0, UIFont.Small, true)
    self:addChild(tagLbl)
    curY = curY + 20

    -- Event Title
    local titleLbl = ISLabel:new(pad, curY, 22, event.title or "Event", 1.0, 1.0, 1.0, 1.0, UIFont.Medium, true)
    self:addChild(titleLbl)
    curY = curY + 24

    -- Host & Category
    local metaStr = string.format("Host: %s  |  Category: %s  |  Radius: %dm", event.hostCharName or event.host or "Unknown", event.category or "General", event.radius or 50)
    local metaLbl = ISLabel:new(pad, curY, 18, metaStr, 0.75, 0.85, 0.95, 1.0, UIFont.Small, true)
    self:addChild(metaLbl)
    curY = curY + 20

    -- Description Box
    local descStr = event.description or "No description provided."
    local descLbl = ISLabel:new(pad, curY, 36, descStr, 0.8, 0.8, 0.8, 1.0, UIFont.Small, true)
    self:addChild(descLbl)
    curY = curY + 38

    -- Headcount Breakdown Bar
    local going, maybe, declined = 0, 0, 0
    if AC.PlayerEvents and AC.PlayerEvents.GetAttendeeCounts then
        going, maybe, declined = AC.PlayerEvents.GetAttendeeCounts(event)
    elseif event and event.attendees then
        for _, att in pairs(event.attendees) do
            local st = type(att) == "table" and att.status or att
            if st == "accepted" then going = going + 1
            elseif st == "maybe" then maybe = maybe + 1
            elseif st == "declined" then declined = declined + 1
            end
        end
    end
    local countStr = string.format("Headcount: %d Going  |  %d Interested  |  %d Declined", going, maybe, declined)
    self.headcountLbl = ISLabel:new(pad, curY, 18, countStr, 0.25, 0.95, 0.45, 1.0, UIFont.Small, true)
    self:addChild(self.headcountLbl)
    curY = curY + 24

    -- RSVP Action Buttons (for all players)
    local rsvpW = (contentW - 16) / 3
    local rsvpH = 24

    self.btnGoing = ISButton:new(pad, curY, rsvpW, rsvpH, "Going (Accept)", self, function(self) self:onRSVP("accepted") end)
    self.btnGoing:initialise()
    self.btnGoing.backgroundColor = {r=0.1, g=0.4, b=0.15, a=0.9}
    self.btnGoing.borderColor = {r=0.2, g=0.8, b=0.3, a=0.9}
    self:addChild(self.btnGoing)

    self.btnMaybe = ISButton:new(pad + rsvpW + 8, curY, rsvpW, rsvpH, "Maybe", self, function(self) self:onRSVP("maybe") end)
    self.btnMaybe:initialise()
    self.btnMaybe.backgroundColor = {r=0.4, g=0.35, b=0.1, a=0.9}
    self.btnMaybe.borderColor = {r=0.85, g=0.75, b=0.2, a=0.9}
    self:addChild(self.btnMaybe)

    self.btnDecline = ISButton:new(pad + (rsvpW * 2) + 16, curY, rsvpW, rsvpH, "Decline", self, function(self) self:onRSVP("declined") end)
    self.btnDecline:initialise()
    self.btnDecline.backgroundColor = {r=0.4, g=0.1, b=0.1, a=0.9}
    self.btnDecline.borderColor = {r=0.8, g=0.2, b=0.2, a=0.9}
    self:addChild(self.btnDecline)
    curY = curY + 34

    -- If Host or Admin: Show Online Players List & Invitation Panel
    if isHost then
        local invHeader = ISLabel:new(pad, curY, 18, "Invite Players to Event:", 1.0, 0.85, 0.3, 1.0, UIFont.Small, true)
        self:addChild(invHeader)
        curY = curY + 20

        -- Player List
        local listH = 130
        self.playerList = ISScrollingListBox:new(pad, curY, contentW, listH)
        self.playerList:initialise()
        self.playerList:instantiate()
        self.playerList.itemheight = 24
        self.playerList.drawBorder = true
        self.playerList.doDrawItem = self.drawPlayerItem
        self.playerList.parentUI = self
        self:addChild(self.playerList)
        curY = curY + listH + 10

        self:populatePlayerList()

        -- Host Management Buttons: "Invite All Nearby" & "Cancel Event"
        local hostBtnW = (contentW - 12) / 2
        local hostBtnH = 26

        self.btnInviteNearby = ISButton:new(pad, curY, hostBtnW, hostBtnH, "Invite All Nearby", self, self.onInviteNearby)
        self.btnInviteNearby:initialise()
        self.btnInviteNearby.backgroundColor = {r=0.15, g=0.3, b=0.45, a=0.9}
        self.btnInviteNearby.borderColor = {r=0.3, g=0.6, b=0.9, a=0.9}
        self:addChild(self.btnInviteNearby)

        self.btnCancelEvent = ISButton:new(pad + hostBtnW + 12, curY, hostBtnW, hostBtnH, "Cancel Event", self, self.onCancelEvent)
        self.btnCancelEvent:initialise()
        self.btnCancelEvent.backgroundColor = {r=0.45, g=0.1, b=0.1, a=0.9}
        self.btnCancelEvent.borderColor = {r=0.9, g=0.2, b=0.2, a=0.9}
        self:addChild(self.btnCancelEvent)
        curY = curY + hostBtnH + 14
    else
        -- Close Button for regular attendees
        local closeW = 120
        local closeH = 24
        local closeBtn = ISButton:new(math.floor((self.width - closeW) / 2), curY, closeW, closeH, "Close", self, self.close)
        closeBtn:initialise()
        self:addChild(closeBtn)
        curY = curY + closeH + 14
    end

    self:setHeight(curY)
end

function AC_ISEventManageUI:populatePlayerList()
    if not self.playerList then return end
    self.playerList:clear()

    local myUsername = getPlayer() and getPlayer():getUsername()
    local onlinePlayers = getOnlinePlayers()

    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if p and p:getUsername() ~= myUsername then
                local uName = p:getUsername()
                local cName = p:getDescriptor() and (p:getDescriptor():getForename() .. " " .. p:getDescriptor():getSurname()) or uName
                local status = "Not Invited"
                if self.event.attendees and self.event.attendees[uName] then
                    status = self.event.attendees[uName].status or "Invited"
                end

                self.playerList:addItem(uName, {
                    username = uName,
                    charName = cName,
                    status = status,
                    playerObj = p,
                })
            end
        end
    end
end

function AC_ISEventManageUI:drawPlayerItem(y, item, alt)
    local isHover = self.mouseoverselected == item.index
    if isHover then
        self:drawRect(0, y, self:getWidth(), item.height, 0.25, 0.25, 0.5, 0.7)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), item.height, 0.15, 0.08, 0.1, 0.15)
    end

    local data = item.item
    local nameStr = string.format("%s (%s)", data.charName or data.username, data.username)
    local statusStr = "[" .. string.upper(data.status or "NOT INVITED") .. "]"
    local statusColor = {r=0.7, g=0.7, b=0.7}

    if data.status == "accepted" then
        statusStr = "[GOING]"
        statusColor = {r=0.2, g=0.95, b=0.4}
    elseif data.status == "maybe" then
        statusStr = "[INTERESTED]"
        statusColor = {r=0.95, g=0.85, b=0.2}
    elseif data.status == "declined" then
        statusStr = "[DECLINED]"
        statusColor = {r=0.9, g=0.3, b=0.3}
    elseif data.status == "invited" or data.status == "pending" then
        statusStr = "[INVITED]"
        statusColor = {r=0.3, g=0.75, b=0.95}
    end

    self:drawText(nameStr, 10, y + 4, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    self:drawTextRight(statusStr, self:getWidth() - 75, y + 4, statusColor.r, statusColor.g, statusColor.b, 1.0, UIFont.Small)

    -- Quick Invite Button area on right
    local btnW = 60
    local btnH = 18
    local btnX = self:getWidth() - btnW - 6
    local btnY = y + 3
    self:drawRect(btnX, btnY, btnW, btnH, 0.7, 0.15, 0.35, 0.55)
    self:drawRectBorder(btnX, btnY, btnW, btnH, 0.85, 0.3, 0.65, 0.95)
    self:drawTextCentre("Invite", btnX + (btnW / 2), btnY + 2, 1.0, 1.0, 1.0, 1.0, UIFont.Small)

    return y + item.height
end

function AC_ISEventManageUI:onMouseDown(x, y)
    ISCollapsableWindowJoypad.onMouseDown(self, x, y)
    if self.playerList and self.playerList:isMouseOver() then
        local row = self.playerList:rowAt(self.playerList:getMouseX(), self.playerList:getMouseY())
        if row and row > 0 and row <= #self.playerList.items then
            local item = self.playerList.items[row]
            if item and item.item then
                local uName = item.item.username
                AC.PlayerEvents.InvitePlayers(self.event.id, { uName })
                item.item.status = "invited"
                AC_Utils.addInfoToChat("Invited " .. uName .. " to '" .. self.event.title .. "'!")
            end
        end
    end
end

function AC_ISEventManageUI:onRSVP(status)
    AC.PlayerEvents.RSVP(self.event.id, status)
    local statusWord = (status == "accepted" and "Going") or (status == "maybe" and "Interested") or "Declined"
    AC_Utils.addInfoToChat(string.format("RSVP for '%s' updated: %s", self.event.title, statusWord))
    self:close()
end

function AC_ISEventManageUI:onInviteNearby()
    local player = getPlayer()
    if not player then return end
    local px, py = player:getX(), player:getY()
    local nearby = {}
    local onlinePlayers = getOnlinePlayers()

    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if p and p:getUsername() ~= player:getUsername() then
                local dist = math.sqrt((p:getX() - px)^2 + (p:getY() - py)^2)
                if dist <= 150 then
                    table.insert(nearby, p:getUsername())
                end
            end
        end
    end

    if #nearby > 0 then
        AC.PlayerEvents.InvitePlayers(self.event.id, nearby)
        AC_Utils.addInfoToChat(string.format("Invited %d nearby players to '%s'!", #nearby, self.event.title))
        self:populatePlayerList()
    else
        AC_Utils.addInfoToChat("No other players found nearby to invite.")
    end
end

function AC_ISEventManageUI:onCancelEvent()
    AC.PlayerEvents.CancelEvent(self.event.id)
    AC_Utils.addInfoToChat("Event '" .. self.event.title .. "' has been cancelled.")
    self:close()
end

function AC_ISEventManageUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if AC_ISEventManageUI.instance == self then
        AC_ISEventManageUI.instance = nil
    end
end

function AC_ISEventManageUI:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    self:drawRect(0, 0, self.width, self.height, 0.94, 0.04, 0.05, 0.08)
    self:drawRectBorder(0, 0, self.width, self.height, 0.85, 0.15, 0.55, 0.75)
end

--- Open Event Management window for a specific event
function AC_ISEventManageUI.Open(event)
    if not event then return end
    if AC_ISEventManageUI.instance then
        AC_ISEventManageUI.instance:close()
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local winW = 420
    local winH = 450
    local winX = math.floor((screenW - winW) / 2)
    local winY = math.floor((screenH - winH) / 2)

    local ui = AC_ISEventManageUI:new(winX, winY, winW, winH)
    ui.event = event
    ui.title = "Event: " .. (event.title or "Details")
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    ui:bringToTop()

    AC_ISEventManageUI.instance = ui
    return ui
end
