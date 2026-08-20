require "ISUI/ISCollapsableWindowJoypad"
require "ISUI/ISComboBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISTickBox"
require "ISUI/ISButton"
require "ISUI/ISLabel"

AC_ISCreateEventUI = ISCollapsableWindowJoypad:derive("AC_ISCreateEventUI")

function AC_ISCreateEventUI:initialise()
    ISCollapsableWindowJoypad.initialise(self)
end

function AC_ISCreateEventUI:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)

    local player = getPlayer()
    local isAdmin = player and (AC_Utils.isStaff(player) or AC.Override(true))

    local th = self:titleBarHeight()
    local pad = 16
    local curY = th + 12
    local contentW = self.width - (pad * 2)

    -- Header subtitle
    local subHeader = isAdmin and "Create an Official Server Event (Gold Map Marker)" or "Create a Player Gathering (Cyan Map Marker)"
    local subHeaderColor = isAdmin and {r=1.0, g=0.85, b=0.2} or {r=0.2, g=0.85, b=0.95}
    local subLabel = ISLabel:new(pad, curY, 18, subHeader, subHeaderColor.r, subHeaderColor.g, subHeaderColor.b, 1.0, UIFont.Small, true)
    self:addChild(subLabel)
    curY = curY + 22

    -- Event Title Label & Entry
    local titleLbl = ISLabel:new(pad, curY, 18, "Event Title:", 1.0, 1.0, 1.0, 1.0, UIFont.Small, true)
    self:addChild(titleLbl)
    curY = curY + 18

    self.titleEntry = ISTextEntryBox:new("Community Gathering", pad, curY, contentW, 24)
    self.titleEntry:initialise()
    self.titleEntry:instantiate()
    self:addChild(self.titleEntry)
    curY = curY + 30

    -- Category Dropdown
    local catLbl = ISLabel:new(pad, curY, 18, "Event Category:", 1.0, 1.0, 1.0, 1.0, UIFont.Small, true)
    self:addChild(catLbl)
    curY = curY + 18

    self.categoryCombo = ISComboBox:new(pad, curY, contentW, 24, self, nil)
    self.categoryCombo:initialise()
    self.categoryCombo:addOption("Social Gathering")
    self.categoryCombo:addOption("Barter / Trade")
    self.categoryCombo:addOption("Expedition / Scouting")
    self.categoryCombo:addOption("Combat / Tournament")
    self.categoryCombo:addOption("Training / Workshop")
    self.categoryCombo:addOption("Faction / Meeting")
    self.categoryCombo:addOption("Other / Special")
    self:addChild(self.categoryCombo)
    curY = curY + 30

    -- Area Radius Dropdown
    local radLbl = ISLabel:new(pad, curY, 18, "Event Area Radius:", 1.0, 1.0, 1.0, 1.0, UIFont.Small, true)
    self:addChild(radLbl)
    curY = curY + 18

    self.radiusCombo = ISComboBox:new(pad, curY, contentW, 24, self, nil)
    self.radiusCombo:initialise()
    self.radiusCombo:addOptionWithData("Small Area (30 meters)", 30)
    self.radiusCombo:addOptionWithData("Medium Area (50 meters)", 50)
    self.radiusCombo:addOptionWithData("Large Settlement (100 meters)", 100)
    self.radiusCombo:addOptionWithData("Regional Zone (200 meters)", 200)
    self.radiusCombo.selected = 2 -- Default 50m
    self:addChild(self.radiusCombo)
    curY = curY + 30

    -- Visibility TickBox
    self.publicTick = ISTickBox:new(pad, curY, contentW, 22, "", self, nil)
    self.publicTick:initialise()
    self.publicTick:addOption("Public Event (Visible to all players on the map)", true)
    self.publicTick:setSelected(1, true)
    self:addChild(self.publicTick)
    curY = curY + 28

    -- Description Label & Entry
    local descLbl = ISLabel:new(pad, curY, 18, "Event Details / Description:", 1.0, 1.0, 1.0, 1.0, UIFont.Small, true)
    self:addChild(descLbl)
    curY = curY + 18

    self.descEntry = ISTextEntryBox:new("Bring your trade goods, supplies, or come meet up!", pad, curY, contentW, 48)
    self.descEntry:initialise()
    self.descEntry:instantiate()
    self.descEntry:setMultipleLine(true)
    self.descEntry:setMaxLines(3)
    self:addChild(self.descEntry)
    curY = curY + 56

    -- Coordinates Info
    local coordStr = string.format("Map Location: X: %d, Y: %d", math.floor(self.worldX or 0), math.floor(self.worldY or 0))
    local coordLbl = ISLabel:new(pad, curY, 18, coordStr, 0.6, 0.75, 0.9, 0.9, UIFont.Small, true)
    self:addChild(coordLbl)
    curY = curY + 24

    -- Buttons (Create & Cancel)
    local btnW = (contentW - 12) / 2
    local btnH = 26

    self.createBtn = ISButton:new(pad, curY, btnW, btnH, "Create Event", self, self.onCreateClick)
    self.createBtn:initialise()
    self.createBtn:instantiate()
    self.createBtn.backgroundColor = {r=0.1, g=0.35, b=0.2, a=0.9}
    self.createBtn.borderColor = {r=0.2, g=0.8, b=0.4, a=0.9}
    self:addChild(self.createBtn)

    self.cancelBtn = ISButton:new(pad + btnW + 12, curY, btnW, btnH, "Cancel", self, self.onCancelClick)
    self.cancelBtn:initialise()
    self.cancelBtn:instantiate()
    self:addChild(self.cancelBtn)

    self:setHeight(curY + btnH + 16)
end

function AC_ISCreateEventUI:onCreateClick()
    local title = self.titleEntry:getText()
    if not title or title:gsub("%s+", "") == "" then
        title = "Player Event"
    end

    local desc = self.descEntry:getText() or ""
    local category = self.categoryCombo:getOptionText(self.categoryCombo.selected) or "Roleplay"
    local radius = self.radiusCombo:getOptionData(self.radiusCombo.selected) or 50
    local isPublic = self.publicTick:isSelected(1)

    AC.PlayerEvents.CreateEvent(title, desc, category, radius, isPublic, self.worldX, self.worldY, self.worldZ)

    self:close()
    AC_Utils.addInfoToChat(string.format("Event '%s' created! Right-click on map to manage or invite players.", title))
end

function AC_ISCreateEventUI:onCancelClick()
    self:close()
end

function AC_ISCreateEventUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if AC_ISCreateEventUI.instance == self then
        AC_ISCreateEventUI.instance = nil
    end
end

function AC_ISCreateEventUI:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    -- Background styling
    self:drawRect(0, 0, self.width, self.height, 0.94, 0.04, 0.05, 0.08)
    self:drawRectBorder(0, 0, self.width, self.height, 0.85, 0.15, 0.55, 0.75)
end

--- Open Event Creation modal at world coordinates
function AC_ISCreateEventUI.Open(worldX, worldY, worldZ)
    if AC_ISCreateEventUI.instance then
        AC_ISCreateEventUI.instance:close()
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local winW = 380
    local winH = 360
    local winX = math.floor((screenW - winW) / 2)
    local winY = math.floor((screenH - winH) / 2)

    local player = getPlayer()
    local isAdmin = player and (AC_Utils.isStaff(player) or AC.Override(true))
    local title = isAdmin and "Create Official Server Event" or "Create Player Event"

    local ui = AC_ISCreateEventUI:new(winX, winY, winW, winH)
    ui.title = title
    ui.worldX = worldX or (player and player:getX() or 0)
    ui.worldY = worldY or (player and player:getY() or 0)
    ui.worldZ = worldZ or (player and player:getZ() or 0)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    ui:bringToTop()

    AC_ISCreateEventUI.instance = ui
    return ui
end
