if not isClient() then return end

local FONT_HGT_SMALL = (getTextManager() and getTextManager():getFontHeight(UIFont.Small)) or 14
local FONT_HGT_MEDIUM = (getTextManager() and getTextManager():getFontHeight(UIFont.Medium)) or 18
local FONT_SCALE = (FONT_HGT_SMALL > 0 and (FONT_HGT_SMALL / 14)) or 1.0

AC_ISCombatMatchUI = ISPanel:derive("AC_ISCombatMatchUI")
AC_ISCombatMatchUI.instance = nil

AC_Combat = AC_Combat or {}
AC_Combat.CurrentMatch = nil -- { host = "", isHost = false, isActive = false, round = 1, currentTurn = 1, participants = {}, viewers = {}, history = {} }

function AC_ISCombatMatchUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor = {r=0.9, g=0.55, b=0.1, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.5, a=0.8}
    o.backgroundColor = {r=0.08, g=0.08, b=0.12, a=0.95}
    o.buttonBorderColor = {r=0.6, g=0.6, b=0.7, a=0.6}
    o.moveWithMouse = true
    AC_ISCombatMatchUI.instance = o
    return o
end

function AC.OpenCombatMatchUI()
    if AC_ISCombatMatchUI.instance then
        AC_ISCombatMatchUI.instance:setVisible(true)
        AC_ISCombatMatchUI.instance:bringToTop()
        return
    end

    local width = math.max(520 * FONT_SCALE, 480)
    local height = math.max(580 * FONT_SCALE, 540)
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local ui = AC_ISCombatMatchUI:new(x, y, width, height)
    ui:initialise()
    ui:addToUIManager()
end

function AC_ISCombatMatchUI:initialise()
    ISPanel.initialise(self)
end

function AC_ISCombatMatchUI:createChildren()
    ISPanel.createChildren(self)

    local pad = 10 * FONT_SCALE
    local btnHgt = FONT_HGT_SMALL + 8 * FONT_SCALE
    local topY = 32 * FONT_SCALE

    -- Close Button
    self.closeButton = ISButton:new(self.width - 28 * FONT_SCALE - pad, 6 * FONT_SCALE, 28 * FONT_SCALE, 20 * FONT_SCALE, "X", self, AC_ISCombatMatchUI.onClose)
    self.closeButton:initialise()
    self.closeButton.backgroundColor = {r=0.6, g=0.1, b=0.1, a=0.7}
    self:addChild(self.closeButton)

    -- Host Controls Bar
    local hostBtnWid = (self.width - pad * 5) / 4

    self.inviteCombatantButton = ISButton:new(pad, topY, hostBtnWid, btnHgt, "+ Combatant", self, function() self:onInviteClick(false) end)
    self.inviteCombatantButton:initialise()
    self:addChild(self.inviteCombatantButton)

    self.inviteViewerButton = ISButton:new(pad * 2 + hostBtnWid, topY, hostBtnWid, btnHgt, "+ Viewer", self, function() self:onInviteClick(true) end)
    self.inviteViewerButton:initialise()
    self.inviteViewerButton.backgroundColor = {r=0.2, g=0.35, b=0.5, a=0.8}
    self:addChild(self.inviteViewerButton)

    self.startMatchButton = ISButton:new(pad * 3 + hostBtnWid * 2, topY, hostBtnWid, btnHgt, "Start Match", self, AC_ISCombatMatchUI.onStartMatchClick)
    self.startMatchButton:initialise()
    self.startMatchButton.backgroundColor = {r=0.1, g=0.5, b=0.2, a=0.8}
    self:addChild(self.startMatchButton)

    self.leaveButton = ISButton:new(pad * 4 + hostBtnWid * 3, topY, hostBtnWid, btnHgt, "Leave Match", self, AC_ISCombatMatchUI.onLeaveClick)
    self.leaveButton:initialise()
    self.leaveButton.backgroundColor = {r=0.5, g=0.2, b=0.1, a=0.8}
    self:addChild(self.leaveButton)

    -- Turn Order & Viewers List
    local listY = topY + btnHgt + 8 * FONT_SCALE
    local listHgt = 160 * FONT_SCALE
    self.turnList = ISScrollingListBox:new(pad, listY, self.width - pad * 2, listHgt)
    self.turnList:initialise()
    self.turnList:instantiate()
    self.turnList.itemheight = FONT_HGT_SMALL + 8 * FONT_SCALE
    self.turnList.selected = 0
    self.turnList.joypadParent = self
    self.turnList.doDrawItem = AC_ISCombatMatchUI.drawTurnListItem
    self.turnList.drawBorder = true
    self:addChild(self.turnList)

    -- Turn & Role Management Buttons
    local turnNavY = listY + listHgt + 8 * FONT_SCALE
    local navBtnWid = (self.width - pad * 6) / 5

    self.prevTurnButton = ISButton:new(pad, turnNavY, navBtnWid, btnHgt, "< Prev Turn", self, AC_ISCombatMatchUI.onPrevTurn)
    self.prevTurnButton:initialise()
    self:addChild(self.prevTurnButton)

    self.nextTurnButton = ISButton:new(pad * 2 + navBtnWid, turnNavY, navBtnWid, btnHgt, "Next Turn >", self, AC_ISCombatMatchUI.onNextTurn)
    self.nextTurnButton:initialise()
    self.nextTurnButton.backgroundColor = {r=0.2, g=0.4, b=0.7, a=0.8}
    self:addChild(self.nextTurnButton)

    self.moveUpButton = ISButton:new(pad * 3 + navBtnWid * 2, turnNavY, navBtnWid, btnHgt, "Move Up", self, AC_ISCombatMatchUI.onMoveUp)
    self.moveUpButton:initialise()
    self:addChild(self.moveUpButton)

    self.toggleRoleButton = ISButton:new(pad * 4 + navBtnWid * 3, turnNavY, navBtnWid, btnHgt, "Swap Role", self, AC_ISCombatMatchUI.onToggleRole)
    self.toggleRoleButton:initialise()
    self.toggleRoleButton.backgroundColor = {r=0.4, g=0.3, b=0.6, a=0.8}
    self:addChild(self.toggleRoleButton)

    self.removePlayerButton = ISButton:new(pad * 5 + navBtnWid * 4, turnNavY, navBtnWid, btnHgt, "Remove", self, AC_ISCombatMatchUI.onRemovePlayer)
    self.removePlayerButton:initialise()
    self.removePlayerButton.backgroundColor = {r=0.6, g=0.1, b=0.1, a=0.7}
    self:addChild(self.removePlayerButton)

    -- Dice Roller Section
    local diceSectionY = turnNavY + btnHgt + 10 * FONT_SCALE
    local diceTypes = {"d4", "d6", "d8", "d10", "d12", "d20", "d100"}
    local diceBtnWid = (self.width - pad * 2 - (pad / 2) * (#diceTypes - 1)) / #diceTypes
    self.diceButtons = {}
    for i, dName in ipairs(diceTypes) do
        local dx = pad + (i - 1) * (diceBtnWid + pad / 2)
        local btn = ISButton:new(dx, diceSectionY, diceBtnWid, btnHgt, dName, self, function() AC_ISCombatMatchUI.doRollDice(dName) end)
        btn:initialise()
        btn.backgroundColor = {r=0.2, g=0.25, b=0.35, a=0.8}
        self:addChild(btn)
        table.insert(self.diceButtons, btn)
    end

    -- Custom roll entry (e.g. 2d6+4)
    local customY = diceSectionY + btnHgt + 6 * FONT_SCALE
    local rollBtnWid = 90 * FONT_SCALE
    self.customEntry = ISTextEntryBox:new("1d20+0", pad, customY, self.width - pad * 3 - rollBtnWid, btnHgt)
    self.customEntry:initialise()
    self.customEntry:instantiate()
    self:addChild(self.customEntry)

    self.customRollButton = ISButton:new(self.width - pad - rollBtnWid, customY, rollBtnWid, btnHgt, "Roll Dice", self, AC_ISCombatMatchUI.onCustomRoll)
    self.customRollButton:initialise()
    self.customRollButton.backgroundColor = {r=0.8, g=0.5, b=0.1, a=0.8}
    self:addChild(self.customRollButton)

    -- Combat Roll History Feed
    local histY = customY + btnHgt + 10 * FONT_SCALE
    local histHgt = self.height - histY - pad
    self.historyList = ISScrollingListBox:new(pad, histY, self.width - pad * 2, histHgt)
    self.historyList:initialise()
    self.historyList:instantiate()
    self.historyList.itemheight = FONT_HGT_SMALL + 4 * FONT_SCALE
    self.historyList.selected = 0
    self.historyList.drawBorder = true
    self.historyList.doDrawItem = AC_ISCombatMatchUI.drawHistoryItem
    self:addChild(self.historyList)

    self:updateMatchView()
end

function AC_ISCombatMatchUI:prerender()
    ISPanel.prerender(self)
    local title = "Combat & Turn Manager"
    if AC_Combat.CurrentMatch then
        if AC_Combat.CurrentMatch.isActive then
            title = "Combat: Round " .. (AC_Combat.CurrentMatch.round or 1)
        else
            title = "Combat Lobby (Setting up)"
        end
    end
    self:drawTextCentre(title, self.width / 2, 8 * FONT_SCALE, 1, 1, 1, 1, UIFont.Medium)
end

function AC_ISCombatMatchUI:updateMatchView()
    local match = AC_Combat.CurrentMatch
    local me = getPlayer()
    local myUsername = me and me:getUsername() or ""
    local isHost = match and match.host == myUsername

    if not match then
        self.inviteCombatantButton:setTitle("Host New Match")
        self.inviteCombatantButton:setEnable(true)
        self.inviteViewerButton:setVisible(false)
        self.startMatchButton:setVisible(false)
        self.leaveButton:setVisible(false)
        self.prevTurnButton:setVisible(false)
        self.nextTurnButton:setVisible(false)
        self.moveUpButton:setVisible(false)
        self.toggleRoleButton:setVisible(false)
        self.removePlayerButton:setVisible(false)
    else
        self.inviteCombatantButton:setTitle("+ Combatant")
        self.inviteCombatantButton:setEnable(isHost)
        self.inviteViewerButton:setVisible(isHost)
        self.inviteViewerButton:setEnable(isHost)
        self.startMatchButton:setVisible(isHost)
        self.startMatchButton:setTitle(match.isActive and "End Match" or "Start Match")
        self.leaveButton:setVisible(true)
        self.leaveButton:setTitle(isHost and "Disband" or "Leave")
        self.prevTurnButton:setVisible(isHost and match.isActive)
        self.nextTurnButton:setVisible(isHost and match.isActive)
        self.moveUpButton:setVisible(isHost and not match.isActive)
        self.toggleRoleButton:setVisible(isHost)
        self.removePlayerButton:setVisible(isHost)
    end

    -- Refresh Turn & Viewer List
    self.turnList:clear()
    if match then
        -- Add Combatants
        if match.participants and #match.participants > 0 then
            for i, username in ipairs(match.participants) do
                local displayName = AC.Meta.GetName(username) or username
                local item = {
                    index = i,
                    username = username,
                    displayName = displayName,
                    isViewer = false,
                    isCurrent = match.isActive and (match.currentTurn == i),
                    isHost = (username == match.host)
                }
                self.turnList:addItem(displayName, item)
            end
        end

        -- Add Viewers
        if match.viewers and #match.viewers > 0 then
            for i, username in ipairs(match.viewers) do
                local displayName = AC.Meta.GetName(username) or username
                local item = {
                    index = i,
                    username = username,
                    displayName = displayName,
                    isViewer = true,
                    isCurrent = false,
                    isHost = (username == match.host)
                }
                self.turnList:addItem(displayName, item)
            end
        end
    end

    -- Refresh History
    self.historyList:clear()
    if match and match.history then
        for _, logItem in ipairs(match.history) do
            self.historyList:addItem(logItem.text, logItem)
        end
        self.historyList:setYScroll(-10000)
    end
end

function AC_ISCombatMatchUI:drawTurnListItem(y, item, alt)
    if not item then return y + (self.itemheight or 20) end
    local isSelected = (self.selected == item.itemindex)
    local data = item.item or item
    local hgt = item.height or self.itemheight or 20
    if not data or type(data) ~= "table" then return y + hgt end

    if data.isCurrent then
        self:drawRect(0, y, self.width, hgt, 0.35, 0.1, 0.6, 0.3)
        self:drawRectBorder(0, y, self.width, hgt, 0.9, 0.3, 1.0, 0.4)
    elseif isSelected then
        self:drawRect(0, y, self.width, hgt, 0.25, 0.3, 0.4, 0.6)
    elseif alt then
        self:drawRect(0, y, self.width, hgt, 0.15, 0.15, 0.15, 0.2)
    end

    local nameText = ""
    if data.isViewer then
        nameText = "[Viewer] " .. (data.displayName or "Unknown")
    else
        nameText = string.format("#%d %s", data.index or item.itemindex or 1, data.displayName or "Unknown")
    end

    if data.isHost then
        nameText = nameText .. " (Host)"
    end
    if data.isCurrent then
        nameText = nameText .. "  >>> [ACTING] <<<"
    end

    local r, g, b = 0.9, 0.9, 0.9
    if data.isCurrent then
        r, g, b = 0.4, 1.0, 0.4
    elseif data.isViewer then
        r, g, b = 0.6, 0.75, 0.9
    elseif data.isHost then
        r, g, b = 1.0, 0.85, 0.3
    end

    local fontHgt = (getTextManager() and getTextManager():getFontHeight(UIFont.Small)) or 14
    local textY = y + (hgt - fontHgt) / 2
    self:drawText(nameText, 10, textY, r, g, b, 1.0, UIFont.Small)
    return y + hgt
end

function AC_ISCombatMatchUI:drawHistoryItem(y, item, alt)
    if not item then return y + (self.itemheight or 18) end
    local data = item.item or item
    local text = ""
    local r, g, b = 0.85, 0.85, 0.85
    if type(data) == "table" then
        text = data.text or item.text or ""
        r = data.r or 0.85
        g = data.g or 0.85
        b = data.b or 0.85
    else
        text = tostring(item.text or item)
    end

    local hgt = item.height or self.itemheight or 18

    if alt then
        self:drawRect(0, y, self.width, hgt, 0.1, 0.1, 0.1, 0.15)
    end

    local fontHgt = (getTextManager() and getTextManager():getFontHeight(UIFont.Small)) or 14
    local textY = y + (hgt - fontHgt) / 2
    self:drawText(text, 6, textY, r, g, b, 1.0, UIFont.Small)
    return y + hgt
end

function AC_ISCombatMatchUI:onInviteClick(isViewer)
    local match = AC_Combat.CurrentMatch
    local me = getPlayer()
    if not match then
        -- Host new match
        sendClientCommand(me, "AC", "CombatCreate", {})
        return
    end

    local anchorBtn = isViewer and self.inviteViewerButton or self.inviteCombatantButton
    local context = ISContextMenu.get(0, self:getAbsoluteX() + anchorBtn:getX(), self:getAbsoluteY() + anchorBtn:getY() + anchorBtn:getHeight())
    if not context then return end

    local players = getOnlinePlayers()
    local added = 0
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        local username = p:getUsername()
        if username ~= me:getUsername() then
            local alreadyIn = false
            for _, u in ipairs(match.participants or {}) do
                if u == username then alreadyIn = true break end
            end
            for _, u in ipairs(match.viewers or {}) do
                if u == username then alreadyIn = true break end
            end
            if not alreadyIn then
                local name = AC.Meta.GetName(username) .. " (" .. username .. ")"
                context:addOption(name, username, function(target)
                    sendClientCommand(getPlayer(), "AC", "CombatInvite", {target, isViewer})
                    local roleName = isViewer and "Viewer" or "Combatant"
                    AC_Utils.addInfoToChat("Invited " .. AC.Meta.GetName(target) .. " as a " .. roleName .. " to the combat match.")
                end)
                added = added + 1
            end
        end
    end

    if added == 0 then
        local opt = context:addOption("No other players available", nil, nil)
        opt.notAvailable = true
    end
end

function AC_ISCombatMatchUI:onStartMatchClick()
    local match = AC_Combat.CurrentMatch
    if not match then return end
    if match.isActive then
        sendClientCommand(getPlayer(), "AC", "CombatEnd", {})
    else
        sendClientCommand(getPlayer(), "AC", "CombatStart", {})
    end
end

function AC_ISCombatMatchUI:onLeaveClick()
    local match = AC_Combat.CurrentMatch
    if not match then return end
    sendClientCommand(getPlayer(), "AC", "CombatLeave", {})
    AC_Combat.CurrentMatch = nil
    self:updateMatchView()
end

function AC_ISCombatMatchUI:onNextTurn()
    sendClientCommand(getPlayer(), "AC", "CombatNextTurn", {})
end

function AC_ISCombatMatchUI:onPrevTurn()
    sendClientCommand(getPlayer(), "AC", "CombatPrevTurn", {})
end

function AC_ISCombatMatchUI:onMoveUp()
    local sel = self.turnList.selected
    if sel and sel > 1 and AC_Combat.CurrentMatch then
        local item = self.turnList.items[sel]
        if item and item.item and not item.item.isViewer then
            local parts = AC_Combat.CurrentMatch.participants
            local idx = item.item.index
            if idx and idx > 1 then
                local tmp = parts[idx - 1]
                parts[idx - 1] = parts[idx]
                parts[idx] = tmp
                sendClientCommand(getPlayer(), "AC", "CombatReorder", {parts})
                self.turnList.selected = sel - 1
                self:updateMatchView()
            end
        end
    end
end

function AC_ISCombatMatchUI:onToggleRole()
    local sel = self.turnList.selected
    if sel and sel > 0 and AC_Combat.CurrentMatch then
        local item = self.turnList.items[sel]
        if item and item.item then
            local target = item.item.username
            if target and target ~= AC_Combat.CurrentMatch.host then
                sendClientCommand(getPlayer(), "AC", "CombatToggleRole", {target})
            end
        end
    end
end

function AC_ISCombatMatchUI:onRemovePlayer()
    local sel = self.turnList.selected
    if sel and sel > 0 and AC_Combat.CurrentMatch then
        local item = self.turnList.items[sel]
        if item and item.item then
            local target = item.item.username
            if target then
                sendClientCommand(getPlayer(), "AC", "CombatKick", {target})
            end
        end
    end
end

function AC_ISCombatMatchUI.doRollDice(diceName)
    local sides = tonumber(diceName:sub(2)) or 20
    local roll = ZombRand(sides) + 1
    local me = getPlayer()
    local name = AC.Meta.GetName(me:getUsername())
    local rollText = string.format("[%s] rolled 1%s: [%d] = %d", name, diceName, roll, roll)

    if AC_Combat.CurrentMatch then
        sendClientCommand(me, "AC", "CombatRoll", {"1" .. diceName, roll, tostring(roll), 0, rollText})
    else
        AC.Commands.Roll(diceName)
    end
end

function AC_ISCombatMatchUI:onCustomRoll()
    local text = self.customEntry:getText()
    if not text or text == "" then return end

    local numDice, numSides, bonus = 1, 20, 0
    local dPos = text:find("d")
    if dPos then
        numDice = tonumber(text:sub(1, dPos - 1)) or 1
        local rest = text:sub(dPos + 1)
        local plusPos = rest:find("%+") or rest:find("%-")
        if plusPos then
            numSides = tonumber(rest:sub(1, plusPos - 1)) or 20
            bonus = tonumber(rest:sub(plusPos)) or 0
        else
            numSides = tonumber(rest) or 20
        end
    else
        numSides = tonumber(text) or 20
    end

    if numDice < 1 or numDice > 50 or numSides < 2 or numSides > 1000 then
        AC_Utils.addErrorToChat("Invalid dice format. Example: 2d6+3")
        return
    end

    local rolls = {}
    local sum = 0
    for i = 1, numDice do
        local r = ZombRand(numSides) + 1
        table.insert(rolls, r)
        sum = sum + r
    end
    local total = sum + bonus

    local me = getPlayer()
    local name = AC.Meta.GetName(me:getUsername())
    local bonusStr = (bonus > 0 and ("+" .. bonus)) or (bonus < 0 and tostring(bonus)) or ""
    local rollText = string.format("[%s] rolled %dd%d%s: [%s]%s = %d", name, numDice, numSides, bonusStr, table.concat(rolls, ","), (bonusStr ~= "" and (" " .. bonusStr) or ""), total)

    if AC_Combat.CurrentMatch then
        sendClientCommand(me, "AC", "CombatRoll", {numDice .. "d" .. numSides .. bonusStr, total, table.concat(rolls, ","), bonus, rollText})
    else
        AC.Commands.Roll(text)
    end
end

function AC_ISCombatMatchUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    AC_ISCombatMatchUI.instance = nil
end

return AC_ISCombatMatchUI
