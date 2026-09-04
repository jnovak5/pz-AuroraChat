if isClient() then return end

local function OnClientCommand(module, command, player, args)
    if module == "SVRPChat" and command == "DeleteItem" then
        if not args or not args.itemID then return end
        
        local inv = player:getInventory()
        local item = inv:getItemById(args.itemID)
        
        if item then
            if player:isEquipped(item) then
                player:removeFromHands(item)
            end
            if player:isAttachedItem(item) then
                player:removeAttachedItem(item)
            end
            inv:Remove(item)
            player:sendObjectChange("inventory") 
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand)
