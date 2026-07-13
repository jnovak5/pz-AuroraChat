if not isClient() then return end -- only in MP
AC = AC or {}

AC.Indicator = AC.Indicator or {
    players = {},
    tickDelay = 0,
    muteTyping = false,
}

function AC.Indicator.shouldSync()
    return not AC.Indicator.muteTyping and not getPlayer():isGhostMode()
end

local isTyping = false
local lastUpdate = 0
local isCleared = false

local nextXyRange = 0
local nextZRange = 0
local emptyObject = {}
function AC.Indicator.onTyping(xyRange, zRange)
    if not AC.Indicator.shouldSync() then
        isTyping = false
        return
    end
    nextXyRange = xyRange
    nextZRange = zRange
    isTyping = true
end

function AC.Indicator.onCleared(immediately)
    isTyping = false
    if immediately then
        lastUpdate = 0
    end
end

function AC.Indicator.doLog(text)
    local p = getPlayer()
    local x = math.floor(p:getX())
    local y = math.floor(p:getY())
    local z = math.floor(p:getZ())
    local currentLanguage = AC.Meta.GetCurrentLanguage(p:getUsername())
    sendClientCommand(p, 'AC', 'doLog', {x, y, z, text, currentLanguage})
end

function AC.Indicator.update()
    local ts = getTimestampMs()

    if isTyping and (isCleared or ts - lastUpdate > 4000) then
        sendClientCommand(getPlayer(), 'AC', 'onTyping', {nextXyRange, nextZRange})
        isCleared = false
        lastUpdate = ts
    end

    if not isTyping and not isCleared and ts - lastUpdate > 4000 then
        sendClientCommand(getPlayer(), 'AC', 'onCleared', emptyObject)
        isCleared = true
        lastUpdate = ts
    end

    if AC.Indicator.tickDelay > 0 then
        AC.Indicator.tickDelay = AC.Indicator.tickDelay - 1
    else
        AC.Indicator.tickDelay = 30
        local toRemove = {}
        for username, lastTs in pairs(AC.Indicator.players) do
            if lastTs + 8000 < ts then
                table.insert(toRemove, username)
            end
        end
        for _, username in pairs(toRemove) do
            AC.Indicator.players[username] = nil
        end
    end
end

AC.Indicator.IndicatorWidth = getTextManager():MeasureStringX(UIFont.Small, "...")
AC.Indicator.IndicatorHeight = getTextManager():MeasureStringY(UIFont.Small, "...")
AC.Indicator.UiElements = AC.Indicator.UiElements or {}
function AC.Indicator.DrawOverheads()
    local zoom = getCore():getZoom(0)
    local me = getPlayer()
    local c = math.floor(getTimestampMs()/1000) % 3
    local typingText = string.rep(".", c + 1)
    for _,x in pairs(AC.Indicator.UiElements) do x.seen = false end
    for username, _ in pairs(AC.Indicator.players) do
        local player = getPlayerFromUsername(username)
        if player and me:CanSee(player) then
            local x = isoToScreenX(0, player:getX(), player:getY(), player:getZ())
            local y = isoToScreenY(0, player:getX(), player:getY(), player:getZ())
            y = y - (130 / zoom) - (3*zoom)
            local ele = AC.Indicator.UiElements[username]
            if ele then
                ele:setX(x - (ele.width / 2))
                ele:setY(y)
            else
                ele = ISUIElement:new(x - (AC.Indicator.IndicatorWidth/2), y, AC.Indicator.IndicatorWidth, AC.Indicator.IndicatorHeight)
                ele.anchorTop = false
                ele.anchorBottom = true
                ele:initialise()
                ele:addToUIManager()
                ele:backMost()
                AC.Indicator.UiElements[username] = ele
            end
            ele.seen = true
            ele:drawTextCentre(typingText, AC.Indicator.IndicatorWidth/2, 0, 1, 1, 1, 1, UIFont.Small)
        end
    end
    for k,v in pairs(AC.Indicator.UiElements) do
        if not v.seen then
            v:removeFromUIManager()
            AC.Indicator.UiElements[k] = nil
        end
    end
end

local fntSize = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
function AC.Indicator.DrawTypingInChat(chatInstance)
    local typers = {}
    for username, _ in pairs(AC.Indicator.players) do
        table.insert(typers, AC.Meta.GetName(username))
    end

    if #typers > 0 then
        table.sort(typers)
        local text = getText("UI_AC_Typing") .. table.concat(typers, ", ")
        local textEntry = chatInstance.textEntry
        local x = textEntry:getX() + 2
        local y = textEntry:getY() - fntSize - 2
        local width = getTextManager():MeasureStringX(UIFont.Small, text)
        if width > textEntry:getWidth() then
            text = getText("UI_AC_ManyTyping")
        end
        chatInstance:drawText(text, x, y, 1, 1, 1, 1, UIFont.Small)
    end
end
