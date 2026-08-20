if isServer() and not isClient() then return end

AC = AC or {}
AC.Alert = AC.Alert or {}

AC.Alert.CurrentMessage = nil
AC.Alert.Author = nil
AC.Alert.IsCell = false
AC.Alert.Timer = 0
AC.Alert.TotalDuration = 0
AC.Alert.Lines = {}

local FONT_TITLE = UIFont.Title or UIFont.Massive or UIFont.Large
local FONT_HEADER = UIFont.Medium or UIFont.Small

--- Split message text into wrapped lines if it exceeds maxWidth
local function wrapText(text, font, maxWidth)
    local tm = getTextManager()
    local words = {}
    for word in string.gmatch(text or "", "%S+") do
        table.insert(words, word)
    end
    if #words == 0 then return { text or "" } end

    local lines = {}
    local currentLine = ""
    for _, word in ipairs(words) do
        local testLine = (currentLine == "") and word or (currentLine .. " " .. word)
        local w = tm:MeasureStringX(font, testLine)
        if w > maxWidth and currentLine ~= "" then
            table.insert(lines, currentLine)
            currentLine = word
        else
            currentLine = testLine
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    return lines
end

AC.Alert.LastAlertText = nil
AC.Alert.LastAlertTime = 0

--- Play a clean, gentle notification chime for server announcements
function AC.Alert.PlayAlertSound()
    pcall(function()
        local player = getPlayer()
        local emitter = player and player.getEmitter and player:getEmitter()
        if emitter then
            local sId = emitter:playSound("UIPauseMenuEnter")
            if sId ~= nil and emitter.setVolume then
                emitter:setVolume(sId, 0.50)
            end
        else
            getSoundManager():playUISound("UIPauseMenuEnter")
        end
    end)
end

--- Show a high-visibility server alert broadcast (server-wide)
function AC.Alert.ShowServerMessage(text, author)
    if not text or text == "" then return end

    local now = getTimestampMs()
    if AC.Alert.LastAlertText == text and (now - AC.Alert.LastAlertTime) < 3000 then
        return
    end
    AC.Alert.LastAlertText = text
    AC.Alert.LastAlertTime = now

    AC.Alert.IsCell = false
    AC.Alert.CurrentMessage = text
    AC.Alert.Author = (author and author ~= "" and author ~= "Server") and author or nil

    -- Display duration: minimum 10 seconds, up to 18 seconds for longer messages
    local duration = math.min(18000, math.max(10000, string.len(text) * 120))
    AC.Alert.TotalDuration = duration
    AC.Alert.Timer = duration

    -- Wrap lines to fit comfortable center screen width (max 75% of screen width)
    local screenW = getCore():getScreenWidth()
    local maxBannerW = math.min(1200, math.floor(screenW * 0.75))
    local maxTextW = maxBannerW - 80

    AC.Alert.Lines = wrapText(text, FONT_TITLE, maxTextW)

    -- Play prominent attention-grabbing chime
    AC.Alert.PlayAlertSound()
end

--- Show a high-visibility local area alert broadcast (50x50 tile cell)
function AC.Alert.ShowCellMessage(text, author)
    if not text or text == "" then return end

    local now = getTimestampMs()
    if AC.Alert.LastAlertText == text and (now - AC.Alert.LastAlertTime) < 3000 then
        return
    end
    AC.Alert.LastAlertText = text
    AC.Alert.LastAlertTime = now

    AC.Alert.IsCell = true
    AC.Alert.CurrentMessage = text
    AC.Alert.Author = (author and author ~= "" and author ~= "Server") and author or nil

    local duration = math.min(18000, math.max(10000, string.len(text) * 120))
    AC.Alert.TotalDuration = duration
    AC.Alert.Timer = duration

    local screenW = getCore():getScreenWidth()
    local maxBannerW = math.min(1200, math.floor(screenW * 0.75))
    local maxTextW = maxBannerW - 80

    AC.Alert.Lines = wrapText(text, FONT_TITLE, maxTextW)

    AC.Alert.PlayAlertSound()
end

--- Render the high-visibility server or local area alert broadcast on screen
function AC.Alert.Render(uiElement)
    if not AC.Alert.CurrentMessage or AC.Alert.Timer <= 0 then
        return
    end

    local delta = UIManager.getMillisSinceLastRender()
    AC.Alert.Timer = AC.Alert.Timer - delta
    if AC.Alert.Timer <= 0 then
        AC.Alert.CurrentMessage = nil
        AC.Alert.Timer = 0
        return
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local tm = getTextManager()

    -- Calculate fade in / fade out alpha
    local elapsed = AC.Alert.TotalDuration - AC.Alert.Timer
    local alpha = 1.0
    if elapsed < 400 then
        alpha = elapsed / 400
    elseif AC.Alert.Timer < 800 then
        alpha = AC.Alert.Timer / 800
    end
    alpha = math.max(0.0, math.min(1.0, alpha))

    local lineH = tm:getFontHeight(FONT_TITLE) + 6
    local headerH = tm:getFontHeight(FONT_HEADER) + 8
    local textBlockH = (#AC.Alert.Lines * lineH)
    local paddingY = 22
    local paddingX = 40

    local isCell = AC.Alert.IsCell == true
    local headerText = ""
    if isCell then
        headerText = AC.Alert.Author and ("[ LOCAL AREA ANNOUNCEMENT - " .. string.upper(AC.Alert.Author) .. " ]") or "[ LOCAL AREA ANNOUNCEMENT ]"
    else
        headerText = AC.Alert.Author and ("[ SERVER ANNOUNCEMENT - " .. string.upper(AC.Alert.Author) .. " ]") or "[ SERVER ANNOUNCEMENT ]"
    end

    -- Determine banner width based on widest line
    local maxMeasuredW = 0
    for _, line in ipairs(AC.Alert.Lines) do
        local lw = tm:MeasureStringX(FONT_TITLE, line)
        if lw > maxMeasuredW then maxMeasuredW = lw end
    end
    local headerW = tm:MeasureStringX(FONT_HEADER, headerText)
    if headerW > maxMeasuredW then maxMeasuredW = headerW end

    local bannerW = math.max(650, maxMeasuredW + (paddingX * 2))
    local bannerH = headerH + textBlockH + (paddingY * 2) + 8

    local bannerX = math.floor((screenW - bannerW) / 2)
    local bannerY = math.floor(screenH * 0.12) -- 12% from top of screen

    local ui = uiElement or ISAlert.instance or ISChat.instance
    if not ui then return end

    -- Color scheme: Server = Crimson/Gold, Cell = Vivid Cyan/Teal
    local glowR, glowG, glowB = 0.85, 0.15, 0.15
    local topR, topG, topB = 0.95, 0.25, 0.15
    local borderR, borderG, borderB = 0.85, 0.35, 0.15
    local headR, headG, headB = 1.0, 0.80, 0.20

    if isCell then
        glowR, glowG, glowB = 0.10, 0.65, 0.85
        topR, topG, topB = 0.15, 0.85, 0.95
        borderR, borderG, borderB = 0.25, 0.75, 0.90
        headR, headG, headB = 0.30, 0.95, 0.85
    end

    -- 1. Dark semi-transparent background with rich glass styling
    -- Backdrop shadow / glow
    ui:drawRect(bannerX - 4, bannerY - 4, bannerW + 8, bannerH + 8, alpha * 0.45, glowR, glowG, glowB)
    -- Main background panel (deep obsidian)
    ui:drawRect(bannerX, bannerY, bannerW, bannerH, alpha * 0.94, 0.04, 0.04, 0.07)
    -- Accent top bar
    ui:drawRect(bannerX, bannerY, bannerW, 4, alpha * 0.98, topR, topG, topB)
    -- Double glowing border
    ui:drawRectBorder(bannerX, bannerY, bannerW, bannerH, alpha * 0.88, borderR, borderG, borderB)
    ui:drawRectBorder(bannerX + 1, bannerY + 1, bannerW - 2, bannerH - 2, alpha * 0.55, topR, topG, topB)

    -- 2. Header Tag
    local curY = bannerY + paddingY - 6

    -- Shadow
    ui:drawTextCentre(headerText, bannerX + (bannerW / 2) + 1, curY + 1, 0, 0, 0, alpha * 0.9, FONT_HEADER)
    -- Main header text
    ui:drawTextCentre(headerText, bannerX + (bannerW / 2), curY, headR, headG, headB, alpha, FONT_HEADER)

    curY = curY + headerH + 6

    -- 3. Draw Message Lines with Multi-Layer Drop Shadows for Ultimate Readability
    for _, line in ipairs(AC.Alert.Lines) do
        local centerX = bannerX + (bannerW / 2)

        -- 8-Direction thick black drop shadow
        for dx = -2, 2 do
            for dy = -2, 2 do
                if dx ~= 0 or dy ~= 0 then
                    ui:drawTextCentre(line, centerX + dx, curY + dy, 0, 0, 0, alpha * 0.95, FONT_TITLE)
                end
            end
        end

        -- Main Crisp, High-Contrast Text (Pure Brilliant White)
        ui:drawTextCentre(line, centerX, curY, 1.0, 1.0, 1.0, alpha, FONT_TITLE)
        curY = curY + lineH
    end
end

-- Override vanilla ISAlert rendering to use our enhanced broadcast banner
local original_ISAlert_prerender = ISAlert.prerender
function ISAlert:prerender()
    if self.servermsg and self.servermsg ~= "" then
        AC.Alert.ShowServerMessage(self.servermsg, nil)
        self.servermsg = nil
        self.servermsgTimer = 0
    end
    AC.Alert.Render(self)
end

function AC.Alert.OnAlertMessage(message, tabID)
    if message then
        local text = message:getText() or ""
        local author = message:isShowAuthor() and message:getAuthor() or nil
        AC.Alert.ShowServerMessage(text, author)
    end
end

Events.OnAlertMessage.Add(AC.Alert.OnAlertMessage)
