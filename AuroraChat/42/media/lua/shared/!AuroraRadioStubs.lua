-- AuroraChat: Radio utility stubs. Used when WastelandRadioUtilities is not installed.
if getActivatedMods():contains("WastelandRadioUtilities") then return end

ARU_Utils = ARU_Utils or {}

-- Known "radio" devices which are not actually radios
local knownRadios = ArrayList.new()
knownRadios:add("Tsarcraft.TCWalkman")
knownRadios:add("Tsarcraft.TCBoombox")

function ARU_Utils.isRadio(item)
    if not item then return false end
    if knownRadios:contains(item:getFullType()) then return false end
    return instanceof(item, "Radio")
end

function ARU_Utils.isRadioOn(radio)
    return radio:getDeviceData():getIsTurnedOn()
end

function ARU_Utils.isRadioBroadcasting(radio)
    local data = radio:getDeviceData()
    if not data then return false end
    return data:getIsTurnedOn() and data:getIsTwoWay() and not data:getMicIsMuted()
end

function ARU_Utils.getRadioRange(radio)
    return radio:getDeviceData():getTransmitRange()
end

function ARU_Utils.getRadioFrequency(radio)
    return radio:getDeviceData():getChannel()
end

function ARU_Utils.getRadioFrequencyString(radio)
    return tostring(ARU_Utils.getRadioFrequency(radio)/1000).." MHz"
end

function ARU_Utils.AreAnyRadiosOn(player)
    local inv = player:getInventory()
    if not inv then return false end
    local items = inv:getItems()
    for i=0,items:size()-1 do
        local item = items:get(i)
        if ARU_Utils.isRadio(item) and ARU_Utils.isRadioOn(item) then
            return true
        end
    end
    return false
end

function ARU_Utils.AreAnyRadiosTransmitting(player)
    local radios = ARU_Utils.getPlayerRadios(player, true, true, true)
    return #radios > 0
end

ARU_Utils.CachedWorldRadios = {}
ARU_Utils.CachedWorldRadiosTime = 0

function ARU_Utils.getNearbyWorldRadios(player)
    local currentTime = getTimestampMs()
    if currentTime - ARU_Utils.CachedWorldRadiosTime < 1000 then
        return ARU_Utils.CachedWorldRadios
    end
    ARU_Utils.CachedWorldRadiosTime = currentTime
    local radios = {}
    local playerX = math.floor(player:getX())
    local playerY = math.floor(player:getY())
    local playerZ = math.floor(player:getZ())
    local cell = getCell()
    for x=playerX-10, playerX+10 do
        for y=playerY-10, playerY+10 do
            local square = cell:getGridSquare(x, y, playerZ)
            if square then
                local objects = square:getObjects()
                for i=0,objects:size()-1 do
                    local object = objects:get(i)
                    if instanceof(object, "IsoRadio") then
                        table.insert(radios, object)
                    end
                end
                local movingObjects = square:getMovingObjects()
                for i=0,movingObjects:size()-1 do
                    local object = movingObjects:get(i)
                    if instanceof(object, "BaseVehicle") then
                        for j=0,object:getPartCount()-1 do
                            local part = object:getPartByIndex(j)
                            if part:getDeviceData() then
                                table.insert(radios, part)
                            end
                        end
                    end
                end
            end
        end
    end
    ARU_Utils.CachedWorldRadios = radios
    return radios
end

function ARU_Utils.getPlayerRadios(player, onlyOn, onlyTransmitting, includeWorld)
    local radios = {}
    local inv = player:getInventory()
    if inv then
        local items = inv:getItems()
        for i=0,items:size()-1 do
            local item = items:get(i)
            if ARU_Utils.isRadio(item)
            and (not onlyOn or ARU_Utils.isRadioOn(item))
            and (not onlyTransmitting or ARU_Utils.isRadioBroadcasting(item))
            then
                table.insert(radios, item)
            end
        end
    end
    if includeWorld then
        local worldRadios = ARU_Utils.getNearbyWorldRadios(player)
        for _, radio in ipairs(worldRadios) do
            if (not onlyOn or ARU_Utils.isRadioOn(radio))
            and (not onlyTransmitting or ARU_Utils.isRadioBroadcasting(radio))
            then
                table.insert(radios, radio)
            end
        end
    end
    return radios
end

function ARU_Utils.getRadioRanges(radios)
    local ranges = {}
    local player = getPlayer()
    local sq = player:getSquare()
    if not sq then return {} end
    local centerX = sq:getX()
    local centerY = sq:getY()
    for _, item in pairs(radios) do
        if ARU_Utils.isRadioOn(item) then
            local range = ARU_Utils.getRadioRange(item)
            if ranges[range] then
                ranges[range].freq = ranges[range].freq .. ", " .. ARU_Utils.getRadioFrequencyString(item)
            else
                ranges[range] = {
                    x1 = centerX-range,
                    y1 = centerY-range,
                    x2 = centerX+range,
                    y2 = centerY+range,
                    freq = getText("IGUI_RadioFrequency").. ": " .. ARU_Utils.getRadioFrequencyString(item)
                }
            end
        end
    end
    return ranges
end

function ARU_Utils.setRadioBroadcasting(player, radio, shouldBroadcast)
    if radio:getDeviceData():getMicIsMuted() == shouldBroadcast then
        ISTimedActionQueue.add(ISRadioAction:new("MuteMicrophone", player, radio, not shouldBroadcast))
    end
end

function ARU_Utils.setRadioBroadcastingInstant(player, radio, shouldBroadcast)
    if radio:getDeviceData():getMicIsMuted() == shouldBroadcast then
        radio:getDeviceData():setMicIsMuted(not shouldBroadcast)
    end
end

function ARU_Utils.setRadioPower(player, radio, shouldBeOn)
    if radio:getDeviceData():getIsTurnedOn() ~= shouldBeOn then
        ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff", player, radio))
    end
end

function ARU_Utils.setRadioPowerInstant(player, radio, shouldBeOn)
    if radio:getDeviceData():getIsTurnedOn() ~= shouldBeOn then
        radio:getDeviceData():setIsTurnedOn(shouldBeOn)
    end
end
