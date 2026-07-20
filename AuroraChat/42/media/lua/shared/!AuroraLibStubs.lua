-- AuroraChat: Library stubs. These are used when WastelandLib is not installed.
-- If WastelandLib is installed, it provides these already.
if getActivatedMods():contains("WastelandLib") then return end

AC_Utils = {}
AC_Utils.MagicSpace = " <SPACE> "

--- Returns true if the player has any staff access level (Admin, Moderator, Overseer, GM or Observer)
--- @param player IsoPlayer
--- @return boolean
function AC_Utils.isStaff(player)
    if not isClient() and not isServer() then return true end -- SP
    if not player then return false end
    local accessLevel = player:getAccessLevel()
    return accessLevel ~= "None"
end

--- Returns true if the player is a moderator or admin
--- @param player IsoPlayer|nil will use getPlayer() if nil
--- @return boolean
function AC_Utils.canModerate(player)
    if not isClient() and not isServer() then return true end -- SP
    if not player then player = getPlayer() end
    local accessLevel = player:getAccessLevel()
    return accessLevel == "Moderator" or accessLevel == "Admin"
end

--- Add a AC_FakeMessage to the chat window
--- @param message AC_FakeMessage
function AC_Utils.addFakeMessageToChatWindow(message)
    if not ISChat or not ISChat.instance or not ISChat.instance.chatText then return end
    local line = message:getTextWithPrefix()
    local chatText = ISChat.instance.chatText
    if message:getChatID() then
        for _,v in ipairs(ISChat.instance.tabs) do
            if v.tabID == message:getChatID() then
                chatText = v
                break
            end
        end
    end
    if chatText.tabTitle ~= ISChat.instance.chatText.tabTitle then
        local alreadyExist = false
        for i,blinkedTab in ipairs(ISChat.instance.panel.blinkTabs) do
            if blinkedTab == chatText.tabTitle then
                alreadyExist = true
                break
            end
        end
        if alreadyExist == false then
            table.insert(ISChat.instance.panel.blinkTabs, chatText.tabTitle)
        end
    end
    local vscroll = chatText.vscroll
    local scrolledToBottom = (chatText:getScrollHeight() <= chatText:getHeight()) or (vscroll and vscroll.pos == 1)
    if #chatText.chatTextLines > ISChat.maxLine then
        local newLines = {}
        for i,v in ipairs(chatText.chatTextLines) do
            if i ~= 1 then
                table.insert(newLines, v)
            end
        end
        table.insert(newLines, line .. " <LINE> ")
        chatText.chatTextLines = newLines
    else
        table.insert(chatText.chatTextLines, line .. " <LINE> ")
    end
    chatText.text = ""
    local newText = ""
    for i,v in ipairs(chatText.chatTextLines) do
        if i == #chatText.chatTextLines then
            v = string.gsub(v, " <LINE> $", "")
        end
        newText = newText .. v
    end
    chatText.text = newText
    table.insert(chatText.chatMessages, message)
    if #chatText.chatMessages > ISChat.maxLine then
        local newMessages = {}
        for i,v in ipairs(chatText.chatMessages) do
            if i ~= 1 then
                table.insert(newMessages, v)
            end
        end
        chatText.chatMessages = newMessages
    end
    chatText:paginate()
    if scrolledToBottom then
        chatText:setYScroll(-100000)
    end
end

--- Add a message to the chat window
--- @param text string
--- @param options AC_ChatOptions|nil
function AC_Utils.addToChat(text, options)
    local message = AC_FakeMessage:new(text, options)
    AC_Utils.addFakeMessageToChatWindow(message)
end

--- Add a message to the chat window with a red color
--- @param text string
--- @param options AC_ChatOptions|nil
function AC_Utils.addErrorToChat(text, options)
    options = options or {}
    options.color = "1.0,0.2,0.2"
    AC_Utils.addToChat(text, options)
end

--- Add a message to the chat window with a blue color
--- @param text string
--- @param options AC_ChatOptions|nil
function AC_Utils.addInfoToChat(text, options)
    options = options or {}
    options.color = "0.2,0.2,1.0"
    AC_Utils.addToChat(text, options)
end


--- @class AC_ChatOptions
--- @field author string|nil
--- @field radioChannel number|nil
--- @field datetimeStr string|nil
--- @field color string|nil
--- @field showOverhead boolean|nil
--- @field chatId number|nil


--- @class AC_FakeMessage
AC_FakeMessage = {}

---Create a new AC_FakeMessage
---@param text string
---@param options AC_ChatOptions|nil
---@return AC_FakeMessage
function AC_FakeMessage:new(text, options)
    options = options or {}
    local o = {}
    setmetatable(o, self)
    o.__index = self
    o.text = text
    o.author = options.author or ""
    o.radioChannel = options.radioChannel or 0
    o.datetimeStr = options.datetimeStr or nil
    o.color = options.color or nil
    o.showOverhead = options.showOverhead or false
    o.chatId = options.chatId or 1
    return o
end

function AC_FakeMessage:setText(text)
    self.text = text
end
function AC_FakeMessage:getText()
    if self.color then
        return "<RGB:" .. self.color .. ">" .. self.text
    end
    return self.text
end
function AC_FakeMessage:getAuthor()
    return self.author
end
function AC_FakeMessage:getRadioChannel()
    return self.radioChannel
end
function AC_FakeMessage:isServerAlert()
    return false
end
function AC_FakeMessage:getTextWithPrefix()
    local message = self:getText()
    if ISChat.instance.showTimestamp and self.datetimeStr then
        message = "<RGB:0.4,0.4,0.4>[" .. self.datetimeStr .. "] " .. message
    end
    if ISChat.instance.chatFont then
        message = "<SIZE:" .. ISChat.instance.chatFont .. ">" .. message
    end
    return message
end
function AC_FakeMessage:isOverHeadSpeech()
    return self.showOverhead
end
function AC_FakeMessage:getChatID()
    return self.chatId
end
function AC_FakeMessage:getDatetimeStr()
    return self.datetimeStr
end
function AC_FakeMessage:setOverHeadSpeech() end
function AC_FakeMessage:setShouldAttractZombies() end

-- GroundHightlighter — inlined stub (B42 removed the vanilla version)
--- @class Bounds
--- @class Color
--- @class Center
--- @class GroundHightlighter
GroundHightlighter = {}

function GroundHightlighter:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.type = "none"
    o.bounds = {x1 = 0, y1 = 0, x2 = 0, y2 = 0}
    o.radius = 0
    o.center = {x = 0, y = 0, z = 0}
    o.color = {r = 0.0, g = 1.0, b = 0, a = 1.0}
    o.xray = false
    return o
end

function GroundHightlighter:isPointInRadius(x, y)
    local dx = x - self.center.x
    local dy = y - self.center.y
    return (dx * dx) + (dy * dy) <= (self.radius * self.radius)
end

function GroundHightlighter:isVisible(x, y)
    if self.type == "square" then
        return x >= self.bounds.x1 and x <= self.bounds.x2 and y >= self.bounds.y1 and y <= self.bounds.y2
    end
    if self.type == "circle_edge" then
        local dx = math.abs(x - self.center.x)
        local dy = math.abs(y - self.center.y)
        local r = math.floor(self.radius)
        if dx > r or dy > r then return false end
        if dy >= dx then
            local exactDy = math.sqrt(r*r - dx*dx)
            return dy == math.floor(exactDy + 0.5)
        else
            local exactDx = math.sqrt(r*r - dy*dy)
            return dx == math.floor(exactDx + 0.5)
        end
    end
    return self:isPointInRadius(x, y)
end

function GroundHightlighter:tryHighlightWorldSquare(sq, enabled)
    if enabled and not self:isVisible(sq:getX(), sq:getY()) then return end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if obj:isFloor() or self.xray or not enabled then
            obj:setHighlighted(0, enabled, false)
            obj:setOutlineHighlight(0, enabled)
            if enabled then
                if not self.colorInfo then self.colorInfo = ColorInfo.new(self.color.r, self.color.g, self.color.b, self.color.a) end
                obj:setHighlightColor(0, self.colorInfo)
                obj:setOutlineHighlightCol(0, self.colorInfo)
            end
        end
    end
end

function GroundHightlighter:setHightlighted(enabled)
    local cell = getCell()
    for x = self.bounds.x1, self.bounds.x2 do
        for y = self.bounds.y1, self.bounds.y2 do
            local sq = cell:getGridSquare(x, y, self.center.z)
            if sq then self:tryHighlightWorldSquare(sq, enabled) end
        end
    end
end

function GroundHightlighter:remove()
    if self.type ~= "none" then
        self:setHightlighted(false)
        self.type = "none"
    end
end

function GroundHightlighter:setColor(r, g, b, a)
    self.color.r = r
    self.color.g = g
    self.color.b = b
    self.color.a = a or 1.0
    self.colorInfo = ColorInfo.new(r, g, b, self.color.a)
    if self.type ~= "none" then
        self:setHightlighted(false)
        self:setHightlighted(true)
    end
end

function GroundHightlighter:enableXray(enabled)
    self.xray = enabled
    if self.type ~= "none" then
        self:remove()
        self:setHightlighted(true)
    end
end

function GroundHightlighter:highlightSquare(x1, y1, x2, y2, z)
    self:remove()
    self.type = "square"
    self.bounds.x1 = math.floor(x1)
    self.bounds.y1 = math.floor(y1)
    self.bounds.x2 = math.floor(x2)
    self.bounds.y2 = math.floor(y2)
    self.center.x = math.floor((x1 + x2) / 2)
    self.center.y = math.floor((y1 + y2) / 2)
    self.center.z = z or 0
    self:setHightlighted(true)
end

function GroundHightlighter:highlightCircle(x, y, radius, z)
    self:remove()
    self.type = "circle_edge"
    self.radius = radius
    self.center.x = math.floor(x)
    self.center.y = math.floor(y)
    self.center.z = z or 0
    self.bounds.x1 = math.floor(x - radius)
    self.bounds.y1 = math.floor(y - radius)
    self.bounds.x2 = math.floor(x + radius)
    self.bounds.y2 = math.floor(y + radius)
    self:setHightlighted(true)
end
