---@diagnostic disable: duplicate-set-field
if isServer() and not isClient() then return end

require "Chat/ISChat"
require "Chat/AC"
-- GroundHightlighter is stubbed in !SVRPLibStubs.lua

AC = AC or {}
AC.ISChatOriginal = AC.ISChatOriginal or {}

local fntSize = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()

AC.ISChatOriginal.initialise = AC.ISChatOriginal.initialise or ISChat.initialise
function ISChat:initialise()
    AC.ISChatOriginal.initialise(self)

    self.panel.prerender = AC.ISTabPanel.prerender
    self.panel.render = AC.ISTabPanel.render
    self.panel.getTabIndexAtX = AC.ISTabPanel.getTabIndexAtX
    self.panel.getWidthOfAllTabs = AC.ISTabPanel.getWidthOfAllTabs

    local nextStreamId = #ISChat.allChatStreams+1
    AC.FocusTabId = 90
    AC.FocusStreamId = nextStreamId
    ISChat.allChatStreams[nextStreamId] = {name = "Focused", command = "/focusedchat", tabID = 91}

    nextStreamId = nextStreamId+1
    AC.PrivateTabId = 91
    AC.PrivateStreamId = nextStreamId
    ISChat.allChatStreams[nextStreamId] = {name = "Private", command = "/privatechat", tabID = 92}

    nextStreamId = nextStreamId+1
    AC.RadioTabId = 92
    AC.RadioStreamId = nextStreamId
    ISChat.allChatStreams[nextStreamId] = {name = "Radio", command = "/radiochat", tabID = 93}

    nextStreamId = nextStreamId+1
    AC.OocTabId = 93
    AC.OocStreamId = nextStreamId
    ISChat.allChatStreams[nextStreamId] = {name = "OOC", command = "/oocchat", tabID = 94}

    nextStreamId = nextStreamId+1
    AC.StaffTabId = 94
    AC.StaffStreamId = nextStreamId
    ISChat.allChatStreams[nextStreamId] = {name = "Staff", command = "/staff", tabID = 95}

    ISChat.allChatStreams[7].tabID = 7
    ISChat.defaultTabStream[7] = ISChat.allChatStreams[7]
    
    -- Remove the /all command from the chat UI, and admin stream if not staff
    for i = #ISChat.allChatStreams, 1, -1 do
        if ISChat.allChatStreams[i].command == "/all" then
            table.remove(ISChat.allChatStreams, i)
        elseif ISChat.allChatStreams[i].command == "/admin" and not AC.Override(true) then
            table.remove(ISChat.allChatStreams, i)
        end
    end
end

AC.ISChatOriginal.onTextChange = AC.ISChatOriginal.onTextChange or ISChat.onTextChange
ISChat.onTextChange = function()
    if ISChat.instance.currentTabID > 6 then
        if AC.ISChatOriginal.onTextChange then AC.ISChatOriginal.onTextChange() end
        AC.Indicator.onCleared()
        return
    end

    local text = ISChat.instance.textEntry:getInternalText()
    local textLen = text:len()

    local firstLetter = text:sub(1, 1)
    local firstSpace = text:find(" ")
    if firstLetter == "/" and textLen > 2 and firstSpace then
        local ending = text:sub(firstSpace, textLen)
        if ending == " /" then
            AC.Indicator.onCleared()
            ISChat.instance.textEntry:setText("/")
            return
        end
    end

    if textLen == 0 then
        AC.Indicator.onCleared()
        return
    end

    local xyRange, zRange = AC.GetRangeFromMessage(text)
    if xyRange and xyRange > 0 then
        AC.Indicator.onTyping(xyRange, zRange)
        return
    end

    AC.Indicator.onCleared()
end

AC.ISChatOriginal.calcTabSize = AC.ISChatOriginal.calcTabSize or ISChat.calcTabSize
function ISChat:calcTabSize()
    local tabSize = AC.ISChatOriginal.calcTabSize(self)
    tabSize.height = tabSize.height - fntSize - 4
    return tabSize
end

AC.ISChatOriginal.render = AC.ISChatOriginal.render or ISChat.render
function ISChat:render()
    AC.ISChatOriginal.render(self)
    if not ISChat.instance or not ISChat.instance.chatText then return end

    if ISChat.instance.chatText then
        local chatText = ISChat.instance.chatText
        local scrolledToBottom = (chatText:getScrollHeight() <= chatText:getHeight()) or (chatText.vscroll and chatText.vscroll.pos == 1)
        if self.scrollToBottomButton:getIsVisible() == scrolledToBottom then
            self.scrollToBottomButton:setVisible(not scrolledToBottom)
        end
    end

    if ISChat.instance.showRangeTicks > 0 then
        if ISChat.instance.showRangeTicks == 1 then
            self.groundHighlighter:remove()
        end
        ISChat.instance.showRangeTicks = ISChat.instance.showRangeTicks - 1
    end

    local tabID = ISChat.instance.tabs[ISChat.instance.currentTabID].tabID
    local hasNoText = ISChat.instance.textEntry:getInternalText():len() == 0

    if hasNoText then
        if tabID == 0 then
            AC.Handlers.DrawGeneralPlaceholder(self)
        elseif tabID == AC.RadioTabId then
            AC.Handlers.DrawRadioPlaceholder(self)
        elseif tabID == AC.FocusTabId then
            AC.Handlers.DrawFocusPlaceholder(self)
        end
    end

    if not (ISWorldMap_instance and ISWorldMap_instance:isVisible()) then
        AC.Afk.ShowAfkOnPlayers()
        AC.Bio.ShowBioOnPlayers()
        AC.StatusIndicator.ShowStatusIndicatorOnHovered()
        AC.Name.ShowNamesOnPlayers()
        AC.Pvp.ShowPvpOnPlayers()

        if AC.Meta.GetOverheadTypingIndicator() then
            AC.Indicator.DrawOverheads(self)
        end
    end

    AC.Indicator.DrawTypingInChat(self)
end

AC.ISChatOriginal.createChildren = AC.ISChatOriginal.createChildren or ISChat.createChildren
function ISChat:createChildren()
    AC.ISChatOriginal.createChildren(self)
    self.textEntry:setMaxTextLength(1250)

    local btnWid = 20
    local btnHgt = 16
    local btnGap = 4
    local rightX = self.gearButton and self.gearButton:getX() or (self.width - 26)

    -- 1. Mute Typing Button
    local muteX = rightX - btnWid - btnGap
    self.muteTypingButton = ISButton:new(muteX, 1, btnWid, btnHgt, "", self, ISChat.onMuteTypingButtonClick)
    self.muteTypingButton.anchorRight = true
    self.muteTypingButton.anchorLeft = false
    self.muteTypingButton:initialise()
    self.muteTypingButton.borderColor.a = 0.0
    self.muteTypingButton.backgroundColor.a = 0.0
    self.muteTypingButton.backgroundColorMouseOver.a = 0.3
    if AC.Indicator.muteTyping then
        self.muteTypingButton:setImage(getTexture("media/ui/AC_typing_off.png"))
    else
        self.muteTypingButton:setImage(getTexture("media/ui/AC_typing_on.png"))
    end
    self.muteTypingButton.tooltip = "Toggle Overhead Typing Indicator"
    self.muteTypingButton:setUIName("toggle typing indicator")
    self:addChild(self.muteTypingButton)
    self.muteTypingButton:setVisible(true)

    -- 2. Voice Chatter Button
    local voiceX = muteX - btnWid - btnGap
    self.voiceChatterButton = ISButton:new(voiceX, 1, btnWid, btnHgt, "", self, ISChat.onVoiceChatterButtonClick)
    self.voiceChatterButton.anchorRight = true
    self.voiceChatterButton.anchorLeft = false
    self.voiceChatterButton:initialise()
    self.voiceChatterButton.borderColor.a = 0.0
    self.voiceChatterButton.backgroundColor.a = 0.0
    self.voiceChatterButton.backgroundColorMouseOver.a = 0.3
    local isVoiceOn = AC.Voice and AC.Voice.IsEnabled and AC.Voice.IsEnabled()
    if isVoiceOn then
        self.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_on.png"))
        self.voiceChatterButton.tooltip = "Voice Audio Chatter: Enabled (Click to Disable)"
    else
        self.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_off.png"))
        self.voiceChatterButton.tooltip = "Voice Audio Chatter: Disabled (Click to Enable)"
    end
    self.voiceChatterButton:setUIName("toggle voice audio chatter")
    self:addChild(self.voiceChatterButton)
    self.voiceChatterButton:setVisible(true)

    -- 3. Show Range Button
    local rangeX = voiceX - btnWid - btnGap
    self.showRangeButton = ISButton:new(rangeX, 1, btnWid, btnHgt, "", self, ISChat.onShowRangeButtonClick)
    self.showRangeButton.anchorRight = true
    self.showRangeButton.anchorLeft = false
    self.showRangeButton:initialise()
    self.showRangeButton.borderColor.a = 0.0
    self.showRangeButton.backgroundColor.a = 0.0
    self.showRangeButton.backgroundColorMouseOver.a = 0.3
    self.showRangeButton:setImage(getTexture("media/ui/AC_range.png"))
    self.showRangeButton.tooltip = "Toggle Chat Range Circles"
    self.showRangeButton:setUIName("toggle range indicator")
    self:addChild(self.showRangeButton)
    self.showRangeButton:setVisible(true)
    self.showRangeTicks = 0

    -- 4. Combat & Dice Button
    local diceX = rangeX - btnWid - btnGap
    self.combatDiceButton = ISButton:new(diceX, 1, btnWid, btnHgt, "", self, function() AC.OpenCombatMatchUI() end)
    self.combatDiceButton.anchorRight = true
    self.combatDiceButton.anchorLeft = false
    self.combatDiceButton:initialise()
    self.combatDiceButton.borderColor.a = 0.0
    self.combatDiceButton.backgroundColor.a = 0.0
    self.combatDiceButton.backgroundColorMouseOver.a = 0.3
    self.combatDiceButton:setImage(getTexture("media/ui/AC_dice.png"))
    self.combatDiceButton.tooltip = "Combat & Dice Roller"
    self.combatDiceButton:setUIName("open combat & dice manager")
    self:addChild(self.combatDiceButton)
    self.combatDiceButton:setVisible(true)

    -- 5. Scroll To Bottom Button
    self.scrollToBottomButton = ISButton:new(self.width - 20, self.height - self.textEntry.height - 30, 20, 16, "", self, ISChat.onScrollToBottomClick)
    self.scrollToBottomButton.anchorRight = true
    self.scrollToBottomButton.anchorLeft = false
    self.scrollToBottomButton.anchorBottom = true
    self.scrollToBottomButton.anchorTop = false
    self.scrollToBottomButton:initialise()
    self.scrollToBottomButton.borderColor.a = 0.0
    self.scrollToBottomButton.backgroundColor.a = 0.0
    self.scrollToBottomButton.backgroundColorMouseOver.a = 0.3
    self.scrollToBottomButton:setImage(getTexture("media/ui/AC_scrollBottom.png"))
    self.scrollToBottomButton.tooltip = "Scroll to Latest Message"
    self.scrollToBottomButton:setUIName("scroll to bottom")
    self:addChild(self.scrollToBottomButton)
    self.scrollToBottomButton:setVisible(false)

    -- Gear button tooltip
    if self.gearButton then
        self.gearButton.tooltip = "Chat Settings & Roleplay Actions"
    end

    self.groundHighlighter = GroundHightlighter:new()
    self.groundHighlighter:setColor(0.8, 0.8, 0.8, 0.5)
end

ISChat.minTextOpaque = 1.0
ISChat.maxTextOpaque = 1.0

AC.ISChatOriginal.makeFade = AC.ISChatOriginal.makeFade or ISChat.makeFade
function ISChat:makeFade(fraction)
    AC.ISChatOriginal.makeFade(self, fraction)
    if self.chatText and self.chatText.setContentTransparency then
        self.chatText:setContentTransparency(1.0)
    end
    if self.tabs then
        for _, tab in ipairs(self.tabs) do
            if tab and tab.setContentTransparency then
                tab:setContentTransparency(1.0)
            end
        end
    end
end

AC.ISChatOriginal.prerender = AC.ISChatOriginal.prerender or ISChat.prerender
function ISChat:prerender()
    local theme = AC.Meta and AC.Meta.GetActiveTheme and AC.Meta.GetActiveTheme()
    if theme then
        if self.backgroundColor then
            self.backgroundColor.r = theme.bg.r
            self.backgroundColor.g = theme.bg.g
            self.backgroundColor.b = theme.bg.b
        end
        if self.borderColor then
            self.borderColor.r = theme.border.r
            self.borderColor.g = theme.border.g
            self.borderColor.b = theme.border.b
        end
        if self.panel then
            if self.panel.backgroundColor then
                self.panel.backgroundColor.r = theme.bg.r
                self.panel.backgroundColor.g = theme.bg.g
                self.panel.backgroundColor.b = theme.bg.b
            end
            if self.panel.borderColor then
                self.panel.borderColor.r = theme.border.r
                self.panel.borderColor.g = theme.border.g
                self.panel.borderColor.b = theme.border.b
            end
        end
        if self.textEntry then
            if self.textEntry.backgroundColor then
                self.textEntry.backgroundColor.r = theme.textEntry.r
                self.textEntry.backgroundColor.g = theme.textEntry.g
                self.textEntry.backgroundColor.b = theme.textEntry.b
            end
            if self.textEntry.borderColor then
                self.textEntry.borderColor.r = theme.border.r
                self.textEntry.borderColor.g = theme.border.g
                self.textEntry.borderColor.b = theme.border.b
            end
        end
    end
    if self.chatText and self.chatText.setContentTransparency then
        self.chatText:setContentTransparency(1.0)
    end
    AC.ISChatOriginal.prerender(self)
end

AC.ISChatOriginal.onGearButtonClick = AC.ISChatOriginal.onGearButtonClick or ISChat.onGearButtonClick
function ISChat:onGearButtonClick()
    AC.ISChatOriginal.onGearButtonClick(self)
    local context = getPlayerContextMenu(0)
    if context then
        local myPlayer = getPlayer()
        local isStaff = AC_Utils and AC_Utils.isStaff and AC_Utils.isStaff(myPlayer)

        -- If not staff/admin, sanitize the context menu so no admin streams or admin tools appear
        if not isStaff and context.options then
            for i = #context.options, 1, -1 do
                local opt = context.options[i]
                if opt then
                    if opt.name == "Admin" or opt.name == "Server" or opt.name == "Server Chat" or opt.name == "Admin Chat" then
                        table.remove(context.options, i)
                    elseif opt.subOption and context.getSubMenu then
                        local sub = context:getSubMenu(opt.subOption)
                        if sub and sub.options then
                            for j = #sub.options, 1, -1 do
                                local subOpt = sub.options[j]
                                if subOpt and (subOpt.name == "Admin" or subOpt.name == "Server" or subOpt.name == "Server Chat" or subOpt.name == "Admin Chat") then
                                    table.remove(sub.options, j)
                                end
                            end
                        end
                    end
                end
            end
        end

        local players = getOnlinePlayers()
        AC.Meta.CreateCombatContext(context)
        AC.Meta.CreateActionsContext(context, myPlayer, players)
        AC.Meta.CreateCharacterContext(context, myPlayer)
        AC.Meta.CreateChatSettingsContext(context)
        if isStaff and AC.Override(true) then
            AC.Meta.CreateAdminContext(context, myPlayer, players)
        end
    end
end

AC.ISChatOriginal.onTabAdded = AC.ISChatOriginal.onTabAdded or ISChat.onTabAdded
function ISChat.onTabAdded(title, tabID)
    if tabID == 4 and not AC.Override(true) then
        return -- Block vanilla Admin tab for non-admins
    end

    if tabID == 0 then
        AC.ISChatOriginal.onTabAdded(title, tabID)
        AC.ISChatOriginal.onTabAdded("Focused", AC.FocusTabId)
        AC.ISChatOriginal.onTabAdded("Private", AC.PrivateTabId)
        AC.ISChatOriginal.onTabAdded("Radio", AC.RadioTabId)
        AC.ISChatOriginal.onTabAdded("OOC", AC.OocTabId)
        AC.ISChatOriginal.onTabAdded("Staff", AC.StaffTabId)
    elseif tabID == 1 then
        AC.ISChatOriginal.onTabAdded(title, 6)
    else
        AC.ISChatOriginal.onTabAdded(title, tabID)
    end
end

AC.ISChatOriginal.onTabRemoved = AC.ISChatOriginal.onTabRemoved or ISChat.onTabRemoved
function ISChat.onTabRemoved(tabTitle, tabID)
    if tabID == 0 then
        AC.ISChatOriginal.onTabRemoved(tabTitle, tabID)
        AC.ISChatOriginal.onTabRemoved("Focus", AC.FocusTabId)
        AC.ISChatOriginal.onTabRemoved("Private", AC.PrivateTabId)
        AC.ISChatOriginal.onTabRemoved("Radio", AC.RadioTabId)
        AC.ISChatOriginal.onTabRemoved("OOC", AC.OocTabId)
        AC.ISChatOriginal.onTabRemoved("Staff", AC.StaffTabId)
    elseif tabID == 1 then
        AC.ISChatOriginal.onTabRemoved(tabTitle, 6)
    else
        AC.ISChatOriginal.onTabRemoved(tabTitle, tabID)
    end
end

AC.ISChatOriginal.unfocus = AC.ISChatOriginal.unfocus or ISChat.unfocus
function ISChat:unfocus()
    if self.textEntry then
        self.chatDraft = self.textEntry:getText()
    end
    AC.ISChatOriginal.unfocus(self)
    AC.Indicator.onCleared(true)
end

AC.ISChatOriginal.focus = AC.ISChatOriginal.focus or ISChat.focus
function ISChat:focus()
    AC.ISChatOriginal.focus(self)
    if self.chatDraft and self.chatDraft ~= "" then
        self.textEntry:setText(self.chatDraft)
        ISChat.onTextChange()
    else
        if ISChat.instance.currentTabID == 5 then
            self.textEntry:setText(AC.Meta.IsSaveLastChatEnabled() and AC.Meta.LastOoc or "/ooc ")
        elseif ISChat.instance.currentTabID < 7 then
            self.textEntry:setText(AC.Meta.IsSaveLastChatEnabled() and AC.Meta.LastChat or "")
        end
    end
end

AC.ISChatOriginal.onCommandEntered = AC.ISChatOriginal.onCommandEntered or ISChat.onCommandEntered
function ISChat:onCommandEntered()
    local text = ISChat.instance.textEntry:getText()

    AC.Indicator.onCleared(true)
    local currentTabId = ISChat.instance.tabs[ISChat.instance.currentTabID].tabID
    if currentTabId ~= AC.PrivateTabId then
        AC.Indicator.doLog(text)
    end

    if AC.Handlers.SpecialCommand(text) or AC.Handlers.CommandEntered(text) or AC.Handlers.IsOutdated(text) then
        ISChat.instance:logChatCommand(text)
        ISChat.instance:unfocus()
        ISChat.instance.chatDraft = ""
        doKeyPress(false)
        ISChat.instance.timerTextEntry = 20
        return
    end

    AC.ISChatOriginal.onCommandEntered(self or ISChat.instance)
    ISChat.instance.chatDraft = ""
end

function ISChat:onMuteTypingButtonClick()
    AC.Indicator.muteTyping = not AC.Indicator.muteTyping
    if AC.Indicator.muteTyping then
        self.muteTypingButton:setImage(getTexture("media/ui/AC_typing_off.png"))
    else
        self.muteTypingButton:setImage(getTexture("media/ui/AC_typing_on.png"))
    end
end

function ISChat:onVoiceChatterButtonClick()
    local newState = AC.Voice.ToggleVoiceAudio()
    if self and self.voiceChatterButton then
        if newState then
            self.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_on.png"))
        else
            self.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_off.png"))
        end
    end
    if AC.Voice and AC.Voice.UpdateChatButton then
        AC.Voice.UpdateChatButton()
    end
end

function ISChat:onShowRangeButtonClick()
    if self.showRangeTicks > 0 then
        self.showRangeTicks = 1
    end

    local context = ISContextMenu.get(0, self:getAbsoluteX() + self:getWidth() / 2, self:getAbsoluteY() + self.showRangeButton:getY())
    if not context then return end

    for chatType, data in pairs(AC.ChatTypes) do
        context:addOption(chatType, ISChat.instance, ISChat.instance.showMessageRange, data.xyRange)
    end
end

function ISChat:onScrollToBottomClick()
    if ISChat.instance.chatText then
        ISChat.instance.chatText:setYScroll(-10000)
    end
end

function ISChat:showMessageRange(range)
    local p = getPlayer()
    local x = p:getX()
    local y = p:getY()
    local z = p:getZ()
    self.lastRange = range
    self.showRangeTicks = 100
    self.showRangeSwitch = false
    self.groundHighlighter:highlightCircle(x, y, range + .99, z)
end

if not AC.ISChatOriginal.TrueAddLineInChat then
    AC.ISChatOriginal.TrueAddLineInChat = AC.ISChatOriginal.addLineInChat or ISChat.addLineInChat
    AC.ISChatOriginal.addLineInChat = function(chatMessage, tabID)
        AC.ISChatOriginal.TrueAddLineInChat(chatMessage, tabID)
        
        -- Fix vanilla PZ memory leak where chatMessages is never pruned
        if ISChat.instance and ISChat.instance.tabs then
            local maxLines = ISChat.maxLine or 500
            for _, tab in ipairs(ISChat.instance.tabs) do
                if tab and tab.chatMessages then
                    while #tab.chatMessages > maxLines do
                        table.remove(tab.chatMessages, 1)
                    end
                end
            end
        end
    end
end

function ISChat.addLineInChat(chatMessage, tabID)
    if AC.Handlers.AddLineInChat(chatMessage, tabID) then
        return
    end

    if tabID == 1 then
        tabID = 6 -- Admin Chat
    end

    AC.ISChatOriginal.addLineInChat(chatMessage, tabID)
end

-- Compat with UdderlyUpToDate
if UdderlyUpToDate then
    function UdderlyUpToDate.message(msg, isAlert)
        local chatMsg = {
            getTextWithPrefix = function(self) return msg end,
            getText = function(self) return msg end,
            setText = function(self, newMsg) msg = newMsg end,
            isOverHeadSpeech = function() return not isAlert end,
            isServerAlert = function() return isAlert end,
            isShowAuthor = function() return false end,
            isServerAuthor = function() return true end,
            getAuthor = function() return false end,
            getRadioChannel = function() return -1 end
        }
        chatMsg.__index = chatMsg
        if not isAlert then
            msg = "[Server] "..msg
        end
        AC.ISChatOriginal.addLineInChat(setmetatable({ msg = msg.."\t" }, chatMsg), 0)
    end
end

function ISChat:onActivateView()
    if self.tabCnt > 1 then
        self.chatText = self.panel.activeView.view
    end
    for i,blinkedTab in ipairs(self.panel.blinkTabs) do
        if self.chatText.tabTitle and self.chatText.tabTitle == blinkedTab then
            table.remove(self.panel.blinkTabs, i)
            break
        end
    end
    for i,tab in ipairs(self.tabs) do
        if tab.tabTitle == self.chatText.tabTitle then
            self.currentTabID = i
            break
        end
    end
    if not self.chatText.tabTitle then
        self.currentTabID = 0
        return
    end
    if self.chatText.tabID == AC.FocusTabId
    or self.chatText.tabID == AC.RadioTabId
    or self.chatText.tabID == AC.OocTabId
    or self.chatText.tabID == AC.PrivateTabId
    or self.chatText.tabID == AC.StaffTabId then
        focusOnTab(0)
    elseif self.chatText.tabID == 6 then
        focusOnTab(1)
    else
        focusOnTab(self.chatText.tabID)
    end
end

AC.ISChatOriginal.onSwitchStream = AC.ISChatOriginal.onSwitchStream or ISChat.onSwitchStream
function ISChat.onSwitchStream()
    local tabId = ISChat.instance.currentTabID
    if tabId > 6 then
        AC.ISChatOriginal.onSwitchStream()
        return
    end

    if not ISChat.focused then return end

    local t = ISChat.instance.textEntry
    local internalText = t:getInternalText()
    local parts = AC.SplitString(internalText)
    local possibleCommands = {}
    for command, data in pairs(AC.SpecialCommands) do
        if not data.adminOnly or AC.Override() then
            table.insert(possibleCommands, command)
        end
    end
    if #parts == 0 then return end

    if #parts == 1 and internalText:sub(internalText:len(), internalText:len()) ~= " " then
        local complete = AC.TabListHandler(possibleCommands, parts[1])
        if complete then
            t:setText(complete)
            return
        end
    end

    if not AC.SpecialCommands[parts[1]] then return end
    local cnt = #parts
    local text = ""
    if internalText:sub(internalText:len(), internalText:len()) == " " then
        cnt = cnt + 1
    else
        text = parts[cnt]
    end
    local tabHandlers = AC.SpecialCommands[parts[1]].tabHandlers
    if cnt - 1 > #tabHandlers then return end
    local handler = tabHandlers[cnt - 1]
    if not handler or handler == "" then return end
    local complete = AC.TabHandlers[handler](text)
    if not complete then return end
    local newText = ""
    for i=1,cnt-1 do
        if parts[i]:find(" ") then
            newText = newText .. '"' .. parts[i] .. '" '
        else
            newText = newText .. parts[i] .. " "
        end
    end
    if complete:find(" ") then
        newText = newText .. '"' .. complete .. '"'
    else
        newText = newText .. complete
    end
    t:setText(newText)
end

-- *** ISTabPanel override ***
AC.ISTabPanel = {}

function AC.ISTabPanel:prerender()
    if ISTabPanel.mouseOut and ISTabPanel.viewDragging and not ISMouseDrag.dragView then
        self:clearStencilRect()
        self:setStencilRect(0 - self:getAbsoluteX(), 0 - self:getAbsoluteY(), getCore():getScreenWidth(), getCore():getScreenHeight())
        self:drawRectBorder(self:getMouseX(), self:getMouseY(), ISTabPanel.viewDragging.view:getWidth(), ISTabPanel.viewDragging.view:getHeight(), 1,1,1,1)
        self:clearStencilRect()
    end
    self:updateSmoothScrolling()

    -- Draw panel background & border in PRERENDER so it is drawn BEHIND chat text, never on top of it!
    local theme = AC.Meta and AC.Meta.GetActiveTheme and AC.Meta.GetActiveTheme()
    local bg = theme and theme.bg or self.backgroundColor
    local border = theme and theme.border or self.borderColor

    if bg and bg.a and bg.a > 0 then
        self:drawRect(0, self.tabHeight, self.width, self.height - self.tabHeight, bg.a * (self.tabTransparency or 1), bg.r, bg.g, bg.b)
    end
    if border and border.a and border.a > 0 then
        self:drawRectBorder(0, self.tabHeight, self.width, self.height - self.tabHeight, border.a * (self.tabTransparency or 1), border.r, border.g, border.b)
    end
end

function AC.ISTabPanel:render()
    local showPrivate = AC.Meta.HasPrivate(true)
    local showFocused = AC.Meta.HasFocus()
    local showRadio = ARU_Utils.AreAnyRadiosOn(getPlayer())

    if not showPrivate and self.activeView.name == "Private" then
        for i,v in ipairs(self.viewList) do
            if v.name == "Private" then
                local next = self.viewList[i % #self.viewList + 1].name
                self:activateView(next)
                break
            end
        end
    end

    if not showFocused and self.activeView.name == "Focused" then
        for i,v in ipairs(self.viewList) do
            if v.name == "Focused" then
                local next = self.viewList[i % #self.viewList + 1].name
                self:activateView(next)
                break
            end
        end
    end

    if not showRadio and self.activeView.name == "Radio" then
        for i,v in ipairs(self.viewList) do
            if v.name == "Radio" then
                local next = self.viewList[i % #self.viewList + 1].name
                self:activateView(next)
                break
            end
        end
    end

    local newViewList = {}
    local tabDragSelected = -1
    if self.draggingTab and not self.isDragging and ISTabPanel.xMouse > -1 and ISTabPanel.xMouse ~= self:getMouseX() then
        self.isDragging = self.allowDraggingTabs
    end
    local tabWidth = self.maxLength
    local inset = 1
    local gap = 1
    if self.isDragging and not ISTabPanel.mouseOut then
        for i,viewObject in ipairs(self.viewList) do
            if i ~= (self.draggingTab + 1) then
                table.insert(newViewList, viewObject)
            else
                ISTabPanel.viewDragging = viewObject
            end
        end
        tabDragSelected = self:getTabIndexAtX(self:getMouseX()) - 1
        tabDragSelected = math.min(#self.viewList - 1, math.max(tabDragSelected, 0))
        self:drawRectBorder(inset + (tabDragSelected * (tabWidth + gap)), 0, tabWidth, self.tabHeight - 1, 1,1,1,1)
    else
        newViewList = self.viewList
    end
    local theme = AC.Meta and AC.Meta.GetActiveTheme and AC.Meta.GetActiveTheme()
    local selColor = theme and theme.tabSelected or {r=0.14, g=0.18, b=0.25, a=0.90}
    local unselColor = theme and theme.tabUnselected or {r=0.06, g=0.07, b=0.10, a=0.70}
    local accentColor = theme and theme.tabAccent or {r=0.28, g=0.68, b=1.0, a=1.0}
    local x = inset
    if self.centerTabs and (self:getWidth() >= self:getWidthOfAllTabs()) then
        x = (self:getWidth() - self:getWidthOfAllTabs()) / 2
    else
        x = x + self.scrollX
    end
    local widthOfAllTabs = self:getWidthOfAllTabs()
    local overflowLeft = self.scrollX < 0
    local overflowRight = x + widthOfAllTabs > self.width
    self.blinkAlphaDirection = self.blinkAlphaDirection or 1
    self.blinkAlpha = (self.blinkAlpha or 0) + (self.blinkAlphaDirection * (UIManager.getMillisSinceLastRender() / 500))
    if self.blinkAlpha >= 1 then
        self.blinkAlpha = 1
        self.blinkAlphaDirection = -1
    elseif self.blinkAlpha <= 0 then
        self.blinkAlpha = 0
        self.blinkAlphaDirection = 1
    end
    local unreadTextColor, unreadBackgroundColor, unreadBlinking = AC.Meta.GetUnreadTabOptions()
    if widthOfAllTabs > self.width then
        self:setStencilRect(0, 0, self.width, self.tabHeight)
    end
    for i,viewObject in ipairs(newViewList) do
        if  (showFocused or viewObject.name ~= "Focused")
        and (showRadio or viewObject.name ~= "Radio")
        and (showPrivate or viewObject.name ~= "Private")
        then
            tabWidth = self.equalTabWidth and self.maxLength or viewObject.tabWidth
            if tabDragSelected ~= -1 and i == (tabDragSelected + 1) then
                x = x + tabWidth + gap
            end
            self.shouldBlink = self.blinkTab
            if self.blinkTabs then
                for j,tab in ipairs(self.blinkTabs) do
                    if tab and tab == viewObject.name then
                        self.shouldBlink = true
                    end
                end
            end

            local isSelected = (viewObject.name == self.activeView.name and not self.isDragging and not ISTabPanel.mouseOut)
            local isMouseOverTab = (self:getMouseY() >= 0 and self:getMouseY() < self.tabHeight and self:isMouseOver() and self:getTabIndexAtX(self:getMouseX()) == i)

            if isSelected then
                -- Active Tab Background
                self:drawTextureScaled(ISTabPanel.tabSelected, x, 0, tabWidth, self.tabHeight - 1, self.tabTransparency, selColor.r, selColor.g, selColor.b)
                self:drawRect(x, 0, tabWidth, self.tabHeight - 1, 0.40 * self.tabTransparency, selColor.r, selColor.g, selColor.b)

                -- Active Tab Bottom Accent Highlight Bar (3px vibrant indicator bar)
                self:drawRect(x, self.tabHeight - 3, tabWidth, 3, 1.0 * self.tabTransparency, accentColor.r, accentColor.g, accentColor.b)

                -- Active Tab Top subtle highlight line
                self:drawRect(x, 0, tabWidth, 1, 0.50 * self.tabTransparency, accentColor.r, accentColor.g, accentColor.b)

                self.shouldBlink = false
            else
                -- Inactive Tab Background
                self:drawTextureScaled(ISTabPanel.tabUnSelected, x, 0, tabWidth, self.tabHeight - 1, self.tabTransparency, unselColor.r, unselColor.g, unselColor.b)
                if isMouseOverTab then
                    viewObject.fade:setFadeIn(true)
                else
                    viewObject.fade:setFadeIn(false)
                end
                viewObject.fade:update()
                self:drawTextureScaled(ISTabPanel.tabSelected, x, 0, tabWidth, self.tabHeight - 1, 0.25 * viewObject.fade:fraction(), selColor.r, selColor.g, selColor.b)
            end

            if self.shouldBlink then
                self:drawTextureScaled(ISTabPanel.tabSelected, x, 0, tabWidth, self.tabHeight - 1, self.tabTransparency,1,1,1)
                self:drawRect(x, 0, tabWidth, self.tabHeight - 1,
                              (unreadBlinking and self.blinkAlpha or (0.5 * self.tabTransparency)) * 0.8,
                              unreadBackgroundColor.r, unreadBackgroundColor.g, unreadBackgroundColor.b)
                self:drawTextCentre(viewObject.name, x + (tabWidth / 2), 3, unreadTextColor.r, unreadTextColor.g, unreadTextColor.b, self.textTransparency, UIFont.Small)
            elseif isSelected then
                -- Active Tab Text: Full brightness white for instant visual pop
                self:drawTextCentre(viewObject.name, x + (tabWidth / 2), 2, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
            else
                -- Inactive Tab Text: Softly dimmed for clear visual hierarchy (brightens on mouseover)
                local textAlpha = isMouseOverTab and 0.95 or 0.70
                local textCol = isMouseOverTab and 0.90 or 0.65
                self:drawTextCentre(viewObject.name, x + (tabWidth / 2), 3, textCol, textCol, textCol + 0.05, textAlpha * self.textTransparency, UIFont.Small)
            end
            x = x + tabWidth + gap
        end
    end
    local butPadX = 3
    if overflowLeft then
        local tex = getTexture("media/ui/ArrowLeft.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(inset, 0, butWid, self.tabHeight, 1, 0, 0, 0)
        self:drawRectBorder(inset, 0, butWid, self.tabHeight, 1, 1, 1, 1)
        self:drawTexture(tex, inset + butPadX, (self.tabHeight - tex:getHeight()) / 2, 1, 1, 1, 1)
    end
    if overflowRight then
        local tex = getTexture("media/ui/ArrowRight.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(self.width - inset - butWid, 0, butWid, self.tabHeight, 1, 0, 0, 0)
        self:drawRectBorder(self.width - inset - butWid, 0, butWid, self.tabHeight, 1, 1, 1, 1)
        self:drawTexture(tex, self.width - butWid + butPadX, (self.tabHeight - tex:getHeight()) / 2, 1, 1, 1, 1)
    end
    if widthOfAllTabs > self.width then
        self:clearStencilRect()
    end
    if self.draggingTab and self.isDragging and not ISTabPanel.mouseOut then
        if self.draggingTab > 0 then
            self:drawTextureScaled(ISTabPanel.tabSelected, inset + (self.draggingTab * (tabWidth + gap)) + (self:getMouseX() - ISTabPanel.xMouse), 0, tabWidth, self.tabHeight - 1, 0.8,1,1,1)
            self:drawTextCentre(ISTabPanel.viewDragging.name, inset + (self.draggingTab * (tabWidth + gap)) + (self:getMouseX() - ISTabPanel.xMouse) + (tabWidth / 2), 3, 1, 1, 1, 1, UIFont.Normal)
        else
            self:drawTextureScaled(ISTabPanel.tabSelected, inset + (self:getMouseX() - ISTabPanel.xMouse), 0, tabWidth, self.tabHeight - 1, 0.8,1,1,1)
            self:drawTextCentre(ISTabPanel.viewDragging.name, inset + (self:getMouseX() - ISTabPanel.xMouse) + (tabWidth / 2), 3, 1, 1, 1, 1, UIFont.Normal)
        end
    end
end

function AC.ISTabPanel:getTabIndexAtX(x, scrollX)
    local inset = 1
    local gap = 1
    local left = inset
    if self.centerTabs and (self:getWidth() >= self:getWidthOfAllTabs()) then
        left = (self:getWidth() - self:getWidthOfAllTabs()) / 2
    else
        left = left + (scrollX or self.scrollX)
    end

    local showFocused = AC.Meta.HasFocus()
    local showRadio = ARU_Utils.AreAnyRadiosOn(getPlayer())
    local showPrivate = AC.Meta.HasPrivate(true)
    for index,viewObject in ipairs(self.viewList) do
        if  (showFocused or viewObject.name ~= "Focused")
        and (showRadio or viewObject.name ~= "Radio")
        and (showPrivate or viewObject.name ~= "Private")
        then
            local tabWidth = self.equalTabWidth and self.maxLength or viewObject.tabWidth
            if x >= left and x < left + tabWidth + gap then
                return index
            end
            left = left + tabWidth + gap
        end
    end
    return -1
end

function AC.ISTabPanel:getWidthOfAllTabs()
    local showFocused = AC.Meta.HasFocus()
    local showRadio = ARU_Utils.AreAnyRadiosOn(getPlayer())
    local showPrivate = AC.Meta.HasPrivate(true)

    local w = 0
    local gap = 1
    for _,viewObject in ipairs(self.viewList) do
        if  (showFocused or viewObject.name ~= "Focused")
        and (showRadio or viewObject.name ~= "Radio")
        and (showPrivate or viewObject.name ~= "Private")
        then
            w = w + (self.equalTabWidth and self.maxLength or viewObject.tabWidth) + gap
        end
    end
    return w
end

-- *** Dialog helpers ***
function AC.MakeShowDialogPrompt(message, callback)
    return function()
        local scale = getTextManager():MeasureStringY(UIFont.Small, "XXX") / 12
        local width = 200 * scale
        local height = 130 * scale
        local x = (getCore():getScreenWidth() / 2) - (width / 2)
        local y = (getCore():getScreenHeight() / 2) - (height / 2)
        local modal = ISTextBox:new(x, y, width, height, message, "", nil, function (_, button)
            if callback and button.internal == "OK" then
                callback(button.parent.entry:getText())
            end
        end, nil)
        modal:initialise()
        modal:addToUIManager()
        return modal
    end
end

local function getColors(numColors, numBrights)
    local colors = {}
    for bright=0,(numBrights-1) * 2,1 do
        table.insert(colors, {r=bright/((numBrights-1) * 2), g=bright/((numBrights-1) * 2), b=bright/((numBrights-1) * 2), a=1})
    end
    for hue=0,numColors-2,1 do
        for bright=1,numBrights,1 do
            local color = Color.HSBtoRGB(hue/(numColors-1), 1.0, bright/numBrights)
            table.insert(colors, {r=color:getRedFloat(), g=color:getGreenFloat(), b=color:getBlueFloat(), a=1})
        end
        for sat=0,numBrights-2,1 do
            local color = Color.HSBtoRGB(hue/(numColors-1), 1.0 - sat/numBrights, 1.0)
            table.insert(colors, {r=color:getRedFloat(), g=color:getGreenFloat(), b=color:getBlueFloat(), a=1})
        end
    end
    return colors
end

function AC.MakeColorDialogPrompt(message, callback)
    return function()
        local modal = AC.MakeShowDialogPrompt(message, callback)()
        modal.colorPicker.buttonSize = 14
        modal.colorPicker:setColors(getColors(18, 10), 19, 18)
        modal:enableColorPicker()
        modal.colorBtn.onclick = function (self, btn)
            local x = (getCore():getScreenWidth() / 2) - (self.colorPicker.width / 2)
            local y = (getCore():getScreenHeight() / 2) - (self.colorPicker.height / 2)
            self.colorPicker:setX(x)
            self.colorPicker:setY(y)
            self.colorPicker:setVisible(true)
            self.colorPicker:bringToTop()
            self.colorPicker.pickedFunc = modal.onPickedColor
        end
        modal.onPickedColor = function(self, color)
            self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1)
            self.colorBtn.backgroundColor = {r = color.r, g = color.g, b = color.b, a = 1}
            self.colorPicker:setVisible(false)
            local r = math.floor(color.r * 255)
            local g = math.floor(color.g * 255)
            local b = math.floor(color.b * 255)
            self.entry:setText(r .. "," .. g .. "," .. b)
        end
        modal.entry.onTextChange = function ()
            local r,g,b = modal.entry.javaObject:getInternalText():match("(%d+),(%d+),(%d+)")
            if r and g and b then
                modal.currentColor = ColorInfo.new(r/255, g/255, b/255, 1)
                modal.colorBtn.backgroundColor = {r = r/255, g = g/255, b = b/255, a = 1}
            end
        end
        return modal
    end
end
