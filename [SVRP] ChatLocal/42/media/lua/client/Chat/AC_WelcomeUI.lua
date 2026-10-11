require "ISUI/ISPanel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

AC_WelcomeUI = ISPanel:derive("AC_WelcomeUI")

function AC_WelcomeUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function AC_WelcomeUI:create()
    -- Terminal background
    self.backgroundColor = {r=0.03, g=0.03, b=0.05, a=0.98}
    self.borderColor = {r=0.3, g=0.6, b=0.8, a=1.0}

    -- Add the Rich Text Panel inside
    self.chatText = ISRichTextPanel:new(20, 50, self.width - 40, self.height - 100)
    self.chatText:initialise()
    self.chatText.background = false
    self.chatText.autosetheight = false
    self.chatText.clip = true
    self.chatText:setMargins(10, 10, 10, 10)
    self.chatText.text = self.msg
    self.chatText:paginate()
    self:addChild(self.chatText)

    -- Add Close Button
    self.closeBtn = ISButton:new((self.width / 2) - 60, self.height - 40, 120, 25, getText("UI_btn_close") or "CLOSE", self, self.close)
    self.closeBtn.internal = "CLOSE"
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.borderColor = {r=0.3, g=0.6, b=0.8, a=1.0}
    self.closeBtn.backgroundColor = {r=0.05, g=0.05, b=0.1, a=1.0}
    self.closeBtn.textColor = {r=0.3, g=0.8, b=1.0, a=1.0}
    self:addChild(self.closeBtn)
end

function AC_WelcomeUI:prerender()
    ISPanel.prerender(self)
    -- Draw title bar
    self:drawRect(0, 0, self.width, 35, 1.0, 0.05, 0.08, 0.15)
    self:drawRectBorder(0, 0, self.width, 35, 1.0, 0.3, 0.6, 0.8)
    
    -- Draw decorative corner accents
    self:drawRect(0, 0, 10, 2, 1.0, 0.3, 0.6, 0.8)
    self:drawRect(0, 0, 2, 10, 1.0, 0.3, 0.6, 0.8)
    
    self:drawRect(self.width-10, 0, 10, 2, 1.0, 0.3, 0.6, 0.8)
    self:drawRect(self.width-2, 0, 2, 10, 1.0, 0.3, 0.6, 0.8)

    self:drawRect(0, self.height-2, 10, 2, 1.0, 0.3, 0.6, 0.8)
    self:drawRect(0, self.height-10, 2, 10, 1.0, 0.3, 0.6, 0.8)
    
    self:drawRect(self.width-10, self.height-2, 10, 2, 1.0, 0.3, 0.6, 0.8)
    self:drawRect(self.width-2, self.height-10, 2, 10, 1.0, 0.3, 0.6, 0.8)
    
    -- Title Text
    self:drawTextCentre("- SECURE COMMLINK ESTABLISHED -", self.width/2, 10, 0.35, 0.8, 1.0, 1.0, UIFont.Medium)
end

function AC_WelcomeUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function AC_WelcomeUI:new(x, y, w, h, msg)
    local o = {}
    o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.msg = msg
    o.moveWithMouse = true
    return o
end
