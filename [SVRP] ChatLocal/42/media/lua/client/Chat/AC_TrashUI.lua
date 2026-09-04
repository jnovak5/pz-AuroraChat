require "ISUI/ISPanel"

AC_TrashUI = ISPanel:derive("AC_TrashUI")

function AC_TrashUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function AC_TrashUI:create()
    self.trashIcon = getTexture("media/ui/AC_trash.png")
    self.moveWithMouse = true
end

function AC_TrashUI:prerender()
    -- Draw a nice background panel
    self:drawRect(0, 0, self.width, self.height, 0.7, 0.1, 0.1, 0.1)
    self:drawRectBorder(0, 0, self.width, self.height, 1.0, 0.4, 0.4, 0.4)
    
    if self.trashIcon then
        local a = 0.5
        if self:isMouseOver() or (ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus ~= self) then
            if self:isMouseOver() then
                a = 1.0
            else
                a = 0.8
            end
        end
        self:drawTextureScaledAspect(self.trashIcon, 0, 0, self.width, self.height, a, 1, 1, 1)
    end
end

function AC_TrashUI:onMouseUp(x, y)
    if not self:getIsVisible() then return end
    
    if self.moving then
        local player = getPlayer()
        if player then
            local md = player:getModData()
            md.AC_TrashUI_X = self:getX()
            md.AC_TrashUI_Y = self:getY()
        end
    end
    
    ISPanel.onMouseUp(self, x, y)
    
    if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus ~= self then
        local deletedCount = 0
        for k,v in ipairs(ISMouseDrag.dragging) do
            if instanceof(v, "InventoryItem") then
                if not v:isFavorite() then
                    self:deleteItem(v)
                    deletedCount = deletedCount + 1
                end
            elseif v.items and type(v.items)=="table" and #v.items > 1 then
                for k2,v2 in ipairs(v.items) do
                    if k2 ~= 1 and instanceof(v2, "InventoryItem") then
                        if not v2:isFavorite() then
                            self:deleteItem(v2)
                            deletedCount = deletedCount + 1
                        end
                    end
                end
            end
        end
        
        if deletedCount > 0 then
            getSoundManager():PlayWorldSound("TrashcanEmpty", getPlayer():getCurrentSquare(), 0, 10, 1, false)
        end
    end
end

function AC_TrashUI:onMouseUpOutside(x, y)
    if not self:getIsVisible() then return end
    if self.moving then
        local player = getPlayer()
        if player then
            local md = player:getModData()
            md.AC_TrashUI_X = self:getX()
            md.AC_TrashUI_Y = self:getY()
        end
    end
    ISPanel.onMouseUpOutside(self, x, y)
end

function AC_TrashUI:deleteItem(item)
    local container = item:getContainer()
    if container then
        local player = getPlayer()
        if container:getParent() == player then
            -- Item is inside player inventory. Remove locally and notify server.
            -- DoRemoveItem handles local removal and UI update.
            container:DoRemoveItem(item)
            sendClientCommand(player, "SVRPChat", "DeleteItem", {itemID = item:getID()})
        else
            -- Item is inside another container (box, floor, etc.)
            if isClient() then
                container:removeItemOnServer(item)
            end
            container:DoRemoveItem(item)
        end
    end
end

function AC_TrashUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.0}
    o.borderColor = {r=0, g=0, b=0, a=0.0}
    o.width = width
    o.height = height
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = false
    o.anchorBottom = true
    o.tooltip = "Drag items here to permanently delete them."
    return o
end

local function initTrashUI()
    if not AC_TrashUI_Instance then
        local w = 48
        local h = 48
        -- Place it below the default UI buttons on the left
        local x = 10
        local y = getCore():getScreenHeight() / 2 + 150
        
        local player = getPlayer()
        if player then
            local md = player:getModData()
            if md.AC_TrashUI_X and md.AC_TrashUI_Y then
                x = md.AC_TrashUI_X
                y = md.AC_TrashUI_Y
            end
        end
        
        AC_TrashUI_Instance = AC_TrashUI:new(x, y, w, h)
        AC_TrashUI_Instance:initialise()
        AC_TrashUI_Instance:addToUIManager()
    end
end

Events.OnGameStart.Add(initTrashUI)
