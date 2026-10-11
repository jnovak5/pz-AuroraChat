if isClient() then return end

local function FindItemRecursive(container, itemID)
    if not container then return nil, nil end
    local item = container:getItemById(itemID)
    if item then return item, container end
    
    local items = container:getItems()
    if not items then return nil, nil end
    for i=0, items:size()-1 do
        local childItem = items:get(i)
        if childItem:IsInventoryContainer() then
            local childContainer = childItem:getInventory()
            if childContainer then
                local found, foundCont = FindItemRecursive(childContainer, itemID)
                if found then return found, foundCont end
            end
        end
    end
    return nil, nil
end

local function OnClientCommand(module, command, player, args)
    if module == "SVRPChat" and command == "DeleteItem" then
        if not args or not args.itemID then return end
        
        local inv = player:getInventory()
        local item, itemContainer = FindItemRecursive(inv, args.itemID)
        
        if item and itemContainer then
            if player:isEquipped(item) then
                player:removeFromHands(item)
            end
            if player:isAttachedItem(item) then
                player:removeAttachedItem(item)
            end
            itemContainer:Remove(item)
        end
    elseif module == "AC" and command == "RestoreHairColors" then
        -- Server-authoritative restore of hair/beard colors from mod data.
        -- The client requests this on join so the server's HumanVisual record
        -- matches the persisted mod data, preventing the server from
        -- overwriting the client's hair color during sync.
        local md = player:getModData()
        if not md then return end
        local changed = false
        if md._AC_HairColor then
            local c = md._AC_HairColor
            pcall(function()
                player:getHumanVisual():setHairColor(ImmutableColor.new(c.r, c.g, c.b, 1))
                player:getHumanVisual():setNaturalHairColor(ImmutableColor.new(c.r, c.g, c.b, 1))
            end)
            changed = true
        end
        if md._AC_BeardColor then
            local c = md._AC_BeardColor
            pcall(function()
                player:getHumanVisual():setBeardColor(ImmutableColor.new(c.r, c.g, c.b, 1))
                player:getHumanVisual():setNaturalBeardColor(ImmutableColor.new(c.r, c.g, c.b, 1))
            end)
            changed = true
        end
        if changed then
            sendHumanVisual(player)
            player:resetModel()
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand)

