AC = AC or {}
AC.Recorders = AC.Recorders or {}
AC.Recorders.RunningRecorders = AC.Recorders.RunningRecorders or {}
AC.Recorders.IsChecking = false

local function getOrCreateSubMenu(context, name)
    local option = context:getOptionFromName(name)
    if not option then
        option = context:addOption(name, nil, nil)
        local submenu = ISContextMenu:getNew(context)
        context:addSubMenu(option, submenu)
        return submenu
    else
        return context:getSubMenu(option.subOption)
    end
end

function AC.Recorders.CheckRecorders()
    for i = #AC.Recorders.RunningRecorders, 1, -1 do
        local player = AC.Recorders.RunningRecorders[i].player
        local recorder = AC.Recorders.RunningRecorders[i].recorder
        AC.Recorders.CheckRecorder(player, recorder)
    end
    if #AC.Recorders.RunningRecorders == 0 then
        AC.Recorders.IsChecking = false
        Events.OnTick.Remove(AC.Recorders.CheckRecorders)
    end
end

function AC.Recorders.CheckRecorder(player, recorder)
    local isInHand = player:getPrimaryHandItem() == recorder or player:getSecondaryHandItem() == recorder
    if not isInHand then
        AC.Recorders.StopRecording(player, recorder)
    end
end

function AC.Recorders.IsRecording(recorder)
    for _, data in ipairs(AC.Recorders.RunningRecorders) do
        if data.recorder:getID() == recorder:getID() then
            return true
        end
    end
    return false
end

function AC.Recorders.CanRecord(recorder)
    local md = recorder:getModData()
    return md.AC_HasTape and md.AC_HasBattery and md.AC_TapeUsed < 30
end

function AC.Recorders.StartRecording(player, recorder)
    player:playSound("ACRecorderStart")
    local soundId = player:playSound("ACRecorderWhirr")
    table.insert(AC.Recorders.RunningRecorders, {player = player, recorder = recorder, sound = soundId})
    AC.Recorders.IsChecking = true
    Events.OnTick.Add(AC.Recorders.CheckRecorders)
end

function AC.Recorders.StopRecording(player, recorder)
    player:playSound("ACRecorderStop")
    for i = #AC.Recorders.RunningRecorders, 1, -1 do
        if AC.Recorders.RunningRecorders[i].recorder == recorder then
            player:stopOrTriggerSound(AC.Recorders.RunningRecorders[i].sound)
            table.remove(AC.Recorders.RunningRecorders, i)
        end
    end
end

function AC.Recorders.SaveToRecorder(player, recorder, message)
    local md = recorder:getModData()
    local ind = md.AC_TapeUsed + 1

    if message:sub(1, 10) == "[Recorder]" then
        local newMessage = ""
        local inBracket = false
        local inCommand = false
        for i = 11, #message do
            local c = message:sub(i, i)
            local isSpace = c == " "
            if c == "[" then inBracket = true end
            if c == "/" then inCommand = true end
            if inCommand and isSpace then inCommand = false end
            if not isSpace and not inBracket and not inCommand and ZombRand(10) == 0 then c = "*" end
            if inBracket and c == "]" then inBracket = false end
            newMessage = newMessage .. c
        end
        message = newMessage
    end

    md["AC_Message" .. ind] = message
    md.AC_TapeUsed = ind
    if ind >= 30 then
        AC.Recorders.StopRecording(player, recorder)
        AC_Utils.addErrorToChat("The recorder's tape is full!")
    end
    local bat = md.AC_BatteryLevel
    if bat > 0 then
        md.AC_BatteryLevel = math.max(0, bat - 0.01)
    end
    if bat == 0 then
        md.AC_HasBattery = false
        AC.Recorders.StopRecording(player, recorder)
        AC_Utils.addErrorToChat("The recorder's battery is dead!")
    end
end

function AC.Recorders.CanPlay(recorder)
    local md = recorder:getModData()
    return md.AC_HasTape and md.AC_HasBattery and md.AC_TapeUsed > 0
end

function AC.Recorders.GetRecorderMessages(recorder)
    local md = recorder:getModData()
    return md.AC_TapeUsed
end

function AC.Recorders.PlayRecorderMessage(player, recorder, index)
    local md = recorder:getModData()
    local message = md["AC_Message" .. index]
    if message then
        local mutedRadios = {}
        local radiosOn = ARU_Utils.getPlayerRadios(player, true)
        for _, radio in ipairs(radiosOn) do
            if ARU_Utils.isRadioBroadcasting(radio) then
                ARU_Utils.setRadioBroadcastingInstant(player, radio, false)
                table.insert(mutedRadios, radio)
            end
        end
        processSayMessage("[Recorder]" .. message)
        for _, radio in ipairs(mutedRadios) do
            ARU_Utils.setRadioBroadcastingInstant(player, radio, true)
        end
        md.AC_BatteryLevel = math.max(0, md.AC_BatteryLevel - 0.001)
    end
end

function AC.Recorders.HasTape(recorder)
    local md = recorder:getModData()
    return md.AC_HasTape
end

function AC.Recorders.InsertTape(recorder, tape)
    local md = recorder:getModData()
    md.AC_HasTape = true
    local tapeMd = tape:getModData()
    if tapeMd.AC_TapeUsed then
        md.AC_TapeUsed = tapeMd.AC_TapeUsed
        for i = 1, tapeMd.AC_TapeUsed do
            md["AC_Message" .. i] = tapeMd["AC_Message" .. i]
        end
    else
        md.AC_TapeUsed = 0
    end
    if tape:isCustomName() then
        md.AC_TapeName = tape:getName()
    else
        md.AC_TapeName = nil
    end
end

function AC.Recorders.RemoveTape(recorder)
    local md = recorder:getModData()
    md.AC_HasTape = false
    local tape = InventoryItemFactory.CreateItem("ACRecorderTape")
    local tapeMd = tape:getModData()
    tapeMd["AC_Processed"] = true
    tapeMd.AC_TapeUsed = md.AC_TapeUsed
    for i = 1, md.AC_TapeUsed do
        tapeMd["AC_Message" .. i] = md["AC_Message" .. i]
    end
    if md.AC_TapeName then
        tape:setName(md.AC_TapeName)
        tape:setCustomName(true)
    else
        tape:setName("Recordable Tape")
        tape:setCustomName(false)
    end
    md.AC_TapeUsed = 0
    md.AC_HasTape = false
    return tape
end

function AC.Recorders.ClearTape(recorder)
    local md = recorder:getModData()
    md.AC_TapeUsed = 0
end

function AC.Recorders.HasBattery(recorder)
    local md = recorder:getModData()
    return md.AC_HasBattery and md.AC_BatteryLevel > 0
end

function AC.Recorders.InsertBattery(recorder, battery)
    local md = recorder:getModData()
    md.AC_HasBattery = true
    md.AC_BatteryLevel = battery:getUsedDelta()
end

function AC.Recorders.RemoveBattery(recorder)
    local md = recorder:getModData()
    if not md.AC_HasBattery then return end
    md.AC_HasBattery = false
    local battery = InventoryItemFactory.CreateItem("Battery")
    battery:setUsedDelta(md.AC_BatteryLevel)
    md.AC_BatteryLevel = 0
    return battery
end

local function isBlankTape(item)
    if item:getType() ~= "ACRecorderTape" then return false end
    local md = item:getModData()
    return not md.AC_TapeUsed or md.AC_TapeUsed == 0
end

ISInventoryMenuElements = ISInventoryMenuElements or {}
local MAXIMUM_RENAME_LENGTH = 28
function ISInventoryMenuElements.ContextACTapeRecorder()
    local self = ISMenuElement.new()
    self.invMenu = ISContextManager.getInstance().getInventoryMenu()

    function self.init()
        self.recorder = nil
        self.tape = nil
    end

    function self.createMenu(item)
        if item:getType() == "ACRecorder" then
            self.recorder = item
            self.doRecorderMenu()
            return
        else
            self.recorder = nil
        end
        if item:getType() == "ACRecorderTape" then
            self.tape = item
            self.doTapeMenu()
            return
        else
            self.tape = nil
        end
    end

    function self.doTapeMenu()
        local recorder = self.invMenu.player:getInventory():FindAndReturn("ACRecorder")
        if recorder and not AC.Recorders.HasTape(recorder) then
            self.recorder = recorder
            self.invMenu.context:addOption(getText("UI_AC_InsertToRecorder"), nil, self.insertTape)
        end
        self.invMenu.context:addOption(getText("UI_AC_RenameTape"), nil, self.renameTape)
        if getDebug() then
            self.invMenu.context:addOption("Debug: Randomize", self.tape, AC_RandomizeTape)
        end
    end

    function self.doRecorderMenu()
        local hasTape = AC.Recorders.HasTape(self.recorder)
        local hasBattery = AC.Recorders.HasBattery(self.recorder)
        local isRecording = AC.Recorders.IsRecording(self.recorder)
        local canRecord = AC.Recorders.CanRecord(self.recorder)
        local canPlay = AC.Recorders.CanPlay(self.recorder)

        if hasTape and hasBattery and not isRecording then
            if canRecord then
                self.invMenu.context:addOption(getText("UI_AC_StartRecording"), nil, self.startRecording)
            end
            if canPlay then
                local menu = getOrCreateSubMenu(self.invMenu.context, getText("UI_AC_PlayTape"))
                menu:addOption(getText("UI_AC_NormalSpeed"), 3000, self.playTape)
                menu:addOption(getText("UI_AC_FastSpeed"), 1500, self.playTape)
                menu:addOption(getText("UI_AC_SlowSpeed"), 4500, self.playTape)
                self.invMenu.context:addOption(getText("UI_AC_ClearTape"), nil, self.clearTape)
            end
        end
        if isRecording and canRecord then
            self.invMenu.context:addOption(getText("UI_AC_StopRecording"), nil, self.stopRecording)
        end
        if not hasTape then
            local tape = self.invMenu.player:getInventory():getFirstEvalRecurse(isBlankTape)
            if tape then
                self.tape = tape
                self.invMenu.context:addOption(getText("UI_AC_InsertBlankTape"), nil, self.insertTape)
            end
        end
        if not hasBattery then
            local invBattery = self.invMenu.player:getInventory():getFirstTypeRecurse("Battery")
            if invBattery then
                self.invMenu.context:addOption(getText("UI_AC_InsertBattery"), invBattery, self.insertBattery)
            end
        end
        if hasTape and not isRecording then
            self.invMenu.context:addOption(getText("UI_AC_RemoveTape"), nil, self.removeTape)
        end
        if hasBattery and not isRecording then
            self.invMenu.context:addOption(getText("UI_AC_RemoveBattery"), nil, self.removeBattery)
        end
    end

    function self.startRecording()
        local playerObj = self.invMenu.player
        if playerObj:getPrimaryHandItem() ~= self.recorder and playerObj:getSecondaryHandItem() ~= self.recorder then
            ISWorldObjectContextMenu.equip(playerObj, playerObj:getSecondaryHandItem(), self.recorder, false, false)
        end
        ISTimedActionQueue.add(ACStartRecordingAction:new(self.invMenu.player, self.recorder))
    end

    function self.stopRecording()
        ISTimedActionQueue.add(ACStopRecordingAction:new(self.invMenu.player, self.recorder))
    end

    function self.playTape(speed)
        local playerObj = self.invMenu.player
        if playerObj:getPrimaryHandItem() ~= self.recorder and playerObj:getSecondaryHandItem() ~= self.recorder then
            ISWorldObjectContextMenu.equip(playerObj, playerObj:getSecondaryHandItem(), self.recorder, false, false)
        end
        ISTimedActionQueue.add(ACPlayTapeAction:new(self.invMenu.player, self.recorder, speed))
    end

    function self.clearTape()
        ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, self.recorder)
        ISTimedActionQueue.add(ACClearTapeAction:new(self.invMenu.player, self.recorder))
    end

    function self.insertTape()
        ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, self.recorder)
        ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, self.tape)
        ISTimedActionQueue.add(ACInsertTapeAction:new(self.invMenu.player, self.recorder, self.tape))
    end

    function self.removeTape()
        ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, self.recorder)
        ISTimedActionQueue.add(ACRemoveTapeAction:new(self.invMenu.player, self.recorder))
    end

    function self.insertBattery(battery)
        if battery then
            ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, self.recorder)
            ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, battery)
            ISTimedActionQueue.add(ACInsertBatteryAction:new(self.invMenu.player, self.recorder, battery))
        end
    end

    function self.removeBattery()
        ISInventoryPaneContextMenu.transferIfNeeded(self.invMenu.player, self.recorder)
        ISTimedActionQueue.add(ACRemoveBatteryAction:new(self.invMenu.player, self.recorder))
    end

    function self.renameTape()
        local modal = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisBag"), self.tape:getName(), nil, self.renameTapeClick, self.invMenu.playerNum, self.tape)
        modal:initialise()
        modal:addToUIManager()
    end

    function self.renameTapeClick(_, button, tape)
        if button.internal == "OK" then
            local length = button.parent.entry:getInternalText():len()
            if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then
                if length <= MAXIMUM_RENAME_LENGTH then
                    tape:setName(button.parent.entry:getText())
                    tape:setCustomName(true)
                else
                    getPlayer():Say(getText("IGUI_PlayerText_ItemNameTooLong"))
                end
            end
        end
    end

    return self
end

-- Timed Actions --
ACInsertTapeAction = ACInsertTapeAction or ISBaseTimedAction:derive("ACInsertTapeAction")

function ACInsertTapeAction:new(character, recorder, tape)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.tape = tape
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACInsertTapeAction:isValid()
    return self.recorder:isInPlayerInventory() and self.tape:isInPlayerInventory()
end

function ACInsertTapeAction:perform()
    AC.Recorders.InsertTape(self.recorder, self.tape)
    self.character:getInventory():Remove(self.tape)
    ISBaseTimedAction.perform(self)
end

ACRemoveTapeAction = ACRemoveTapeAction or ISBaseTimedAction:derive("ACRemoveTapeAction")

function ACRemoveTapeAction:new(character, recorder)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACRemoveTapeAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACRemoveTapeAction:perform()
    local tape = AC.Recorders.RemoveTape(self.recorder)
    self.character:getInventory():AddItem(tape)
    ISBaseTimedAction.perform(self)
end

ACInsertBatteryAction = ACInsertBatteryAction or ISBaseTimedAction:derive("ACInsertBatteryAction")

function ACInsertBatteryAction:new(character, recorder, battery)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.battery = battery
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACInsertBatteryAction:isValid()
    return self.recorder:isInPlayerInventory() and self.battery:isInPlayerInventory()
end

function ACInsertBatteryAction:perform()
    AC.Recorders.InsertBattery(self.recorder, self.battery)
    self.character:getInventory():Remove(self.battery)
    ISBaseTimedAction.perform(self)
end

ACRemoveBatteryAction = ACRemoveBatteryAction or ISBaseTimedAction:derive("ACRemoveBatteryAction")

function ACRemoveBatteryAction:new(character, recorder)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACRemoveBatteryAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACRemoveBatteryAction:perform()
    local battery = AC.Recorders.RemoveBattery(self.recorder)
    self.character:getInventory():AddItem(battery)
    ISBaseTimedAction.perform(self)
end

ACStartRecordingAction = ACStartRecordingAction or ISBaseTimedAction:derive("ACStartRecordingAction")

function ACStartRecordingAction:new(character, recorder)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACStartRecordingAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACStartRecordingAction:perform()
    AC.Recorders.StartRecording(self.character, self.recorder)
    ISBaseTimedAction.perform(self)
end

ACStopRecordingAction = ACStopRecordingAction or ISBaseTimedAction:derive("ACStopRecordingAction")

function ACStopRecordingAction:new(character, recorder)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACStopRecordingAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACStopRecordingAction:perform()
    AC.Recorders.StopRecording(self.character, self.recorder)
    ISBaseTimedAction.perform(self)
end

ACStopPlayingAction = ACStopPlayingAction or ISBaseTimedAction:derive("ACStopPlayingAction")

function ACStopPlayingAction:new(character, recorder)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 20
    return o
end

function ACStopPlayingAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACStopPlayingAction:perform()
    AC.Recorders.StopPlaying(self.recorder)
    ISBaseTimedAction.perform(self)
end

ACClearTapeAction = ACClearTapeAction or ISBaseTimedAction:derive("ACClearTapeAction")

function ACClearTapeAction:new(character, recorder)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 100
    return o
end

function ACClearTapeAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACClearTapeAction:perform()
    AC.Recorders.ClearTape(self.recorder)
    ISBaseTimedAction.perform(self)
end

ACPlayTapeAction = ACPlayTapeAction or ISBaseTimedAction:derive("ACPlayTapeAction")

function ACPlayTapeAction:new(character, recorder, speed)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.recorder = recorder
    o.speed = speed
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = -1
    return o
end

function ACPlayTapeAction:isValid()
    return self.recorder:isInPlayerInventory()
end

function ACPlayTapeAction:start()
    self.lastPlay = 0
    self.lastIndx = 0
    self.maxIndx = AC.Recorders.GetRecorderMessages(self.recorder)
    self.character:playSound("ACRecorderStart")
    self.sound = self.character:playSound("ACRecorderWhirr")
end

function ACPlayTapeAction:update()
    local now = getTimestampMs()
    if now - self.lastPlay > self.speed then
        self.lastPlay = now
        self.lastIndx = self.lastIndx + 1
        if self.lastIndx > self.maxIndx or not AC.Recorders.HasBattery(self.recorder) then
            self:forceComplete()
            return
        end
        AC.Recorders.PlayRecorderMessage(self.character, self.recorder, self.lastIndx)
    end
end

function ACPlayTapeAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    self.character:playSound("ACRecorderStop")
    ISBaseTimedAction.perform(self)
end

function ACPlayTapeAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    self.character:playSound("ACRecorderStop")
    ISBaseTimedAction.stop(self)
end

-- Tooltip extensions --
local original_ISToolTipInv_removeFromUIManager = ISToolTipInv.removeFromUIManager
function ISToolTipInv:removeFromUIManager()
    original_ISToolTipInv_removeFromUIManager(self)
    if self.AC_Tooltip then
        self.AC_Tooltip:removeFromUIManager()
        self.AC_Tooltip = nil
    end
end

local original_ISToolTipInv_setVisible = ISToolTipInv.setVisible
function ISToolTipInv:setVisible(visible)
    original_ISToolTipInv_setVisible(self, visible)
    if self.AC_Tooltip and not visible then
        self.AC_Tooltip:setVisible(false)
        self.AC_Tooltip = nil
    end
end

local original_ISToolTipInv_render = ISToolTipInv.render
function ISToolTipInv:render()
    original_ISToolTipInv_render(self)

    if not self.AC_Tooltip then
        self.AC_Tooltip = ISToolTip:new()
        self.AC_Tooltip:initialise()
        self.AC_Tooltip:addToUIManager()
    end

    local x = self.tooltip:getX() - 11
    local y = self.tooltip:getY() + self.tooltip:getHeight()

    if self.item and self.item:getType() == "ACRecorder" then
        self.AC_Tooltip.description = self:AC_GetTapeRecorderInfo()
        self.AC_Tooltip:setVisible(true)
        self.AC_Tooltip:setDesiredPosition(x, y)
    elseif self.item and self.item:getType() == "ACRecorderTape" then
        self.AC_Tooltip.description = self:AC_GetTapeInfo()
        self.AC_Tooltip:setVisible(true)
        self.AC_Tooltip:setDesiredPosition(x, y)
    elseif self.AC_Tooltip then
        self.AC_Tooltip:setVisible(false)
    end
end

function ISToolTipInv:AC_GetTapeRecorderInfo()
    local desc = ""
    if AC.Recorders.IsRecording(self.item) then
        desc = desc .. "** Recording **\n\n"
    end
    if AC.Recorders.HasBattery(self.item) then
        desc = desc .. "Battery Level: " .. math.floor(self.item:getModData().AC_BatteryLevel * 100) .. "%\n"
    else
        desc = desc .. "No Battery\n"
    end
    if AC.Recorders.HasTape(self.item) then
        if self.item:getModData().AC_TapeName then
            desc = desc .. "Tape Name: " .. self.item:getModData().AC_TapeName .. "\n"
        end
        desc = desc .. "Messages on Tape: " .. AC.Recorders.GetRecorderMessages(self.item) .. "/30"
    else
        desc = desc .. "No Tape Inserted"
    end
    return desc
end

function ISToolTipInv:AC_GetTapeInfo()
    local md = self.item:getModData()
    if md.AC_TapeUsed then
        return "Messages on Tape: " .. md.AC_TapeUsed .. "/30"
    else
        return "Blank Tape"
    end
end
