require "ISUI/ISCollapsableWindow"

AC_CalendarUI = ISCollapsableWindow:derive("AC_CalendarUI")

local function getUSHoliday(month, day, year)
    if month == 1 and day == 1 then return "New Year's" end
    if month == 2 and day == 14 then return "Valentine's" end
    if month == 3 and day == 17 then return "St. Patrick's" end
    if month == 7 and day == 4 then return "July 4th" end
    if month == 10 and day == 31 then return "Halloween" end
    if month == 11 and day == 11 then return "Veterans Day" end
    if month == 12 and day == 24 then return "Xmas Eve" end
    if month == 12 and day == 25 then return "Christmas" end
    if month == 12 and day == 31 then return "NYE" end

    local t = os.time{year=year, month=month, day=day}
    local wday = os.date("*t", t).wday
    
    if month == 1 and wday == 2 and day >= 15 and day <= 21 then return "MLK Day" end
    if month == 2 and wday == 2 and day >= 15 and day <= 21 then return "Presidents'" end
    if month == 5 and wday == 2 and day >= 25 then return "Memorial Day" end
    if month == 9 and wday == 2 and day <= 7 then return "Labor Day" end
    if month == 11 and wday == 5 and day >= 22 and day <= 28 then return "Thanksgiving" end
    
    return nil
end

function AC_CalendarUI:initialise()
    ISCollapsableWindow.initialise(self)
    
    local gt = GameTime:getInstance()
    self.viewMonth = gt:getMonth() + 1
    self.viewYear = gt:getYear()
    
    self:createCalendar()
end

function AC_CalendarUI:createCalendar()
    if self.contentPanel then
        self:removeChild(self.contentPanel)
    end
    
    local th = self:titleBarHeight()
    self.contentPanel = ISPanel:new(0, th, self.width, self.height - th)
    self.contentPanel:initialise()
    self.contentPanel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.contentPanel.borderColor = {r=0, g=0, b=0, a=0}
    self:addChild(self.contentPanel)

    local gt = GameTime:getInstance()
    local currentMonth = gt:getMonth() + 1
    local currentDay = gt:getDay() + 1
    local currentYear = gt:getYear()
    local minsPerDay = gt:getMinutesPerDay()
    local daysPerIrl = 1440 / minsPerDay
    local currentIrlBlock = math.ceil(currentDay / daysPerIrl)
    local currentDateReal = os.time()
    
    local monthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
    local viewMonthName = monthNames[self.viewMonth] or tostring(self.viewMonth)
    
    self.title = " SVRP Calendar"

    -- Header Panel for Month Navigation
    local headerH = 40
    local headerBg = ISPanel:new(0, 0, self.width, headerH)
    headerBg:initialise()
    headerBg.backgroundColor = {r=0, g=0, b=0, a=0.4}
    headerBg.borderColor = {r=0, g=0, b=0, a=0.5}
    self.contentPanel:addChild(headerBg)
    
    local prevBtn = ISButton:new(10, 5, 30, 30, "<", self, self.onPrevMonth)
    prevBtn:initialise()
    prevBtn.backgroundColor = {r=0, g=0, b=0, a=0.6}
    headerBg:addChild(prevBtn)
    
    local nextBtn = ISButton:new(self.width - 40, 5, 30, 30, ">", self, self.onNextMonth)
    nextBtn:initialise()
    nextBtn.backgroundColor = {r=0, g=0, b=0, a=0.6}
    headerBg:addChild(nextBtn)
    
    local season = "winter"
    local seasonColor = {r=0.5, g=0.8, b=0.9} -- Icy Cyan
    if self.viewMonth >= 3 and self.viewMonth <= 5 then
        season = "spring"
        seasonColor = {r=0.6, g=0.9, b=0.6} -- Light Green
    elseif self.viewMonth >= 6 and self.viewMonth <= 8 then
        season = "summer"
        seasonColor = {r=1.0, g=0.8, b=0.3} -- Sunny Yellow
    elseif self.viewMonth >= 9 and self.viewMonth <= 11 then
        season = "autumn"
        seasonColor = {r=1.0, g=0.6, b=0.3} -- Orange
    end
    
    self.sunsetTexture = getTexture("media/ui/AC_season_" .. season .. ".png")
    
    local seasonName = season:sub(1,1):upper() .. season:sub(2)
    local seasonLbl = ISLabel:new(50, 10, 20, seasonName, seasonColor.r, seasonColor.g, seasonColor.b, 1, UIFont.Medium, true)
    seasonLbl:initialise()
    headerBg:addChild(seasonLbl)
    
    local monthLbl = ISLabel:new(self.width / 2, 10, 20, viewMonthName .. " " .. self.viewYear, 1, 1, 1, 1, UIFont.Large, true)
    monthLbl:initialise()
    monthLbl.center = true
    headerBg:addChild(monthLbl)
    
    -- Weekday Header
    local dayNames = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
    local cellW = 90
    local cellH = 75
    local gridStartY = th + headerH
    
    local weekBg = ISPanel:new(0, gridStartY, self.width, 25)
    weekBg:initialise()
    weekBg.backgroundColor = {r=0, g=0, b=0, a=0.3}
    weekBg.borderColor = {r=0, g=0, b=0, a=0.5}
    self.contentPanel:addChild(weekBg)
    
    for i=1, 7 do
        local lbl = ISLabel:new((i-1)*cellW + (cellW/2), 2, 20, dayNames[i], 0.7, 0.7, 0.7, 1, UIFont.Medium, true)
        lbl.center = true
        weekBg:addChild(lbl)
    end
    
    gridStartY = gridStartY + 25
    
    -- Grid Drawing
    local timeT = os.time{year=self.viewYear, month=self.viewMonth, day=1}
    local startWday = os.date("*t", timeT).wday -- 1 is Sunday
    local daysInMonth = gt:daysInMonth(self.viewYear, self.viewMonth - 1)
    
    local row = 0
    local col = startWday - 1
    
    for d=1, daysInMonth do
        local cellX = col * cellW
        local cellY = gridStartY + row * cellH
        
        local panel = ISPanel:new(cellX, cellY, cellW, cellH)
        panel:initialise()
        
        local isToday = (d == currentDay and self.viewMonth == currentMonth and self.viewYear == currentYear)
        
        if isToday then
            -- Golden sunset highlight for today! Tone down brightness
            panel.backgroundColor = {r=0.9, g=0.7, b=0.2, a=0.3}
            panel.borderColor = {r=1.0, g=0.8, b=0.4, a=0.8}
        else
            panel.backgroundColor = {r=0, g=0, b=0, a=0.85}
            panel.borderColor = {r=1, g=1, b=1, a=0.3}
        end
        self.contentPanel:addChild(panel)
        
        local dayColor = isToday and {r=1,g=1,b=1} or {r=0.8,g=0.8,b=0.8}
        local lblDay = ISLabel:new(5, 5, 20, tostring(d), dayColor.r, dayColor.g, dayColor.b, 1, UIFont.Medium, true)
        panel:addChild(lblDay)
        
        -- Calculate IRL date difference
        -- To keep it accurate, we calculate how many days away this is from the current in-game day
        local daysDiff = 0
        if self.viewYear == currentYear and self.viewMonth == currentMonth then
            daysDiff = d - currentDay
        else
            -- Simple approximation for now if navigating across months
            local viewT = os.time{year=self.viewYear, month=self.viewMonth, day=d}
            local currT = os.time{year=currentYear, month=currentMonth, day=currentDay}
            daysDiff = math.floor((viewT - currT) / 86400)
        end
        
        local blockDiff = math.floor(daysDiff / daysPerIrl)
        local realDateForDay = currentDateReal + (blockDiff * 86400)
        local realDateStr = os.date("%b %d", realDateForDay)
        
        local lblIrlColor = isToday and {r=1,g=0.9,b=0.6} or {r=0.9,g=0.85,b=0.75}
        local lblIrl = ISLabel:new(5, 55, 20, realDateStr, lblIrlColor.r, lblIrlColor.g, lblIrlColor.b, 1, UIFont.Small, true)
        panel:addChild(lblIrl)
        
        local holiday = getUSHoliday(self.viewMonth, d, self.viewYear)
        if holiday then
            local holLbl = ISLabel:new(5, 25, 20, holiday, 0.5, 0.8, 1.0, 1, UIFont.Small, true)
            panel:addChild(holLbl)
        end
        
        col = col + 1
        if col >= 7 then
            col = 0
            row = row + 1
        end
    end
    
    -- Dynamically adjust window height based on rows
    local finalRow = col == 0 and row or (row + 1)
    local targetHeight = gridStartY + (finalRow * cellH) + self:titleBarHeight()
    if targetHeight ~= self.height then
        self:setHeight(targetHeight)
        if self.contentPanel then
            self.contentPanel:setHeight(targetHeight - self:titleBarHeight())
        end
    end
end

function AC_CalendarUI:prerender()
    local th = self:titleBarHeight()
    if not self.isCollapsed and self.sunsetTexture then
        -- Draw the beautiful sunset gradient
        self:drawTextureScaled(self.sunsetTexture, 0, th, self.width, self.height - th, 0.9, 1, 1, 1)
    end
    ISCollapsableWindow.prerender(self)
end

function AC_CalendarUI:update()
    if not self.pin then
        local mx = self:getMouseX()
        local my = self:getMouseY()
        local isOver = (mx >= 0 and mx <= self.width and my >= 0 and my <= self.height)
        
        if isOver then
            self.collapseCounter = 0
            if self.isCollapsed then
                self:uncollapse()
            end
        else
            self.collapseCounter = self.collapseCounter + (getGameTime():getMultiplier() / getGameTime():getTrueMultiplier()) / 0.8
            if self.collapseCounter > 20 and not self.isCollapsed then
                self.isCollapsed = true
                self:setMaxDrawHeight(self:titleBarHeight())
            end
        end
    end
end

function AC_CalendarUI:onPrevMonth()
    self.viewMonth = self.viewMonth - 1
    if self.viewMonth < 1 then
        self.viewMonth = 12
        self.viewYear = self.viewYear - 1
    end
    self:createCalendar()
end

function AC_CalendarUI:onNextMonth()
    self.viewMonth = self.viewMonth + 1
    if self.viewMonth > 12 then
        self.viewMonth = 1
        self.viewYear = self.viewYear + 1
    end
    self:createCalendar()
end

function AC_CalendarUI:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.sunsetTexture = getTexture("media/ui/AC_season_summer.png") -- Default fallback
    o.backgroundColor = {r=0, g=0, b=0, a=0} -- Let the gradient show through
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1} -- Neutral border
    o.width = width
    o.height = height
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.pin = true
    o.isCollapsed = false
    o.collapseCounter = 0
    o.title = " SVRP Calendar"
    o.resizable = false
    return o
end

function AC.OpenCalendarUI()
    if AC.CalendarUI then
        AC.CalendarUI:removeFromUIManager()
        AC.CalendarUI = nil
    else
        local width = 7 * 90
        local height = 600 -- It will auto adjust
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        
        AC.CalendarUI = AC_CalendarUI:new(x, y, width, height)
        AC.CalendarUI:initialise()
        AC.CalendarUI:addToUIManager()
    end
end
