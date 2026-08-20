local ISWriteBio = require "Chat/AC_ISWriteBio"

local function onBioMenu(player, canEdit)
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local core = getCore()
    local width = 400 * FONT_SCALE
    local height = 600 * FONT_SCALE
    local ui = ISWriteBio:new((core:getScreenWidth() - width)/2, (core:getScreenHeight() - height)/2, width, height, player, canEdit)
    ui:initialise()
    ui:addToUIManager()
end

Events.OnFillWorldObjectContextMenu.Add(function(player, context, worldObjects, test)
    if test then return true end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local clickedPlayer = nil
    for _, v in ipairs(worldObjects) do
        local sq = v:getSquare()
        if sq then
            local movingObjects = sq:getMovingObjects()
            for i = 0, movingObjects:size() - 1 do
                local o = movingObjects:get(i)
                if instanceof(o, "IsoPlayer") then
                    clickedPlayer = o
                    break
                end
            end
        end
        if clickedPlayer then break end
    end

    if clickedPlayer then
        if clickedPlayer ~= playerObj then
            local targetUser = clickedPlayer:getUsername()
            local targetName = AC.Meta.GetName(targetUser) .. " (" .. targetUser .. ")"
            local rpOption = context:addOption("Roleplay (" .. AC.Meta.GetName(targetUser) .. ")", nil, nil)
            local rpContext = context:getNew(context)
            context:addSubMenu(rpOption, rpContext)

            rpContext:addOption("View Bio", clickedPlayer, onBioMenu, false)
            rpContext:addOption("Focus On", '"' .. targetUser .. '"', AC.Commands.Focus)
            rpContext:addOption("Trade With", '"' .. targetUser .. '"', AC.Commands.Trade)
            rpContext:addOption("Medical Check", '"' .. targetUser .. '"', AC.Commands.MedicalCheck)
        else
            local rpOption = context:addOption("SVRP Roleplay & Chat", nil, nil)
            local rpContext = context:getNew(context)
            context:addSubMenu(rpOption, rpContext)

            rpContext:addOption("Edit Character Bio", clickedPlayer, onBioMenu, true)
            rpContext:addOption("Combat & Turn Manager", nil, AC.OpenCombatMatchUI)

            local quickDiceOption = rpContext:addOption("Quick Dice Roll", nil, nil)
            local quickDiceContext = rpContext:getNew(rpContext)
            rpContext:addSubMenu(quickDiceOption, quickDiceContext)
            local diceList = {"d4", "d6", "d8", "d10", "d12", "d20", "d100"}
            for _, dName in ipairs(diceList) do
                quickDiceContext:addOption("Roll 1" .. dName, dName, function(d)
                    if AC_ISCombatMatchUI and AC_ISCombatMatchUI.doRollDice then
                        AC_ISCombatMatchUI.doRollDice(d)
                    else
                        AC.Commands.Roll(d)
                    end
                end)
            end

            local voiceChatter = AC.Voice and AC.Voice.IsEnabled and AC.Voice.IsEnabled()
            rpContext:addOption((voiceChatter and "Disable" or "Enable") .. " Voice Audio Chatter", not voiceChatter, AC.Voice.ToggleVoiceAudio)
            rpContext:addOption("Go AFK / Return", nil, AC.Commands.GoAFK)
        end
    end
end)
