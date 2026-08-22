if isServer() and not isClient() then return end

local function onBioMenu(clickedPlayer, isMe)
    if isMe then
        AC_ISBioUI.Open(clickedPlayer)
    else
        AC_ISBioInspectUI.Open(clickedPlayer)
    end
end

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    if test then return true end

    local clickedPlayer = nil
    for _, v in ipairs(worldObjects) do
        if instanceof(v, "IsoPlayer") then
            clickedPlayer = v
            break
        end
    end

    if not clickedPlayer then
        local myPlayer = getSpecificPlayer(playerIndex) or getPlayer()
        if myPlayer then
            clickedPlayer = myPlayer
        end
    end

    if clickedPlayer then
        local myPlayer = getSpecificPlayer(playerIndex) or getPlayer()
        local isMe = (myPlayer and clickedPlayer:getUsername() == myPlayer:getUsername())

        if not isMe then
            local targetUser = clickedPlayer:getUsername()
            local rpOption = context:addOption("SVRP Roleplay", nil, nil)
            local rpContext = context:getNew(context)
            context:addSubMenu(rpOption, rpContext)

            rpContext:addOption("Inspect Character Bio", clickedPlayer, onBioMenu, false)
            rpContext:addOption("Trade / Barter", clickedPlayer, function(p)
                AC_Utils.addInfoToChat("Initiated trade offer with " .. (p:getUsername() or "player"))
            end)
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

            -- In-Game Character Voice Style Selection Submenu
            if AC.Voice and AC.Voice.NativeVoiceStyles then
                local isFemale = clickedPlayer:isFemale()
                local styleList = isFemale and AC.Voice.NativeVoiceStyles.female or AC.Voice.NativeVoiceStyles.male
                local currentVoiceId = AC.Voice.GetNativeVoice(clickedPlayer)

                local voiceOption = rpContext:addOption("Character Voice Style", nil, nil)
                local voiceContext = rpContext:getNew(rpContext)
                rpContext:addSubMenu(voiceOption, voiceContext)

                for _, vInfo in ipairs(styleList) do
                    local isSelected = (vInfo.id == currentVoiceId)
                    local label = (isSelected and "[X] " or "[ ] ") .. vInfo.name
                    voiceContext:addOption(label, vInfo.id, function(vid)
                        AC.Voice.SetNativeVoice(clickedPlayer, vid)
                        AC_Utils.addInfoToChat("Character Voice Style set to: " .. vInfo.name)
                    end)
                end

                -- Voice Pitch Selection
                local currentPitchId = AC.Voice.GetNativePitch(clickedPlayer)
                local pitchOption = rpContext:addOption("Character Voice Pitch", nil, nil)
                local pitchContext = rpContext:getNew(rpContext)
                rpContext:addSubMenu(pitchOption, pitchContext)

                for _, pInfo in ipairs(AC.Voice.NativePitchStyles) do
                    local isSelected = (pInfo.id == currentPitchId)
                    local label = (isSelected and "[X] " or "[ ] ") .. pInfo.name
                    pitchContext:addOption(label, pInfo.id, function(pid)
                        AC.Voice.SetNativePitch(clickedPlayer, pid)
                        AC_Utils.addInfoToChat("Character Voice Pitch set to: " .. pInfo.name)
                    end)
                end
            end

            local voiceChatter = AC.Voice and AC.Voice.IsEnabled and AC.Voice.IsEnabled()
            rpContext:addOption((voiceChatter and "Disable" or "Enable") .. " Voice Audio Chatter", nil, function()
                AC.Voice.ToggleVoiceAudio()
            end)

            rpContext:addOption("Go AFK / Return", nil, AC.Commands.GoAFK)
        end
    end
end)
