if not isClient() then return end -- only in MP
AC = AC or {}
AC.Buffs = {}

AC.Buffs.AmountsPerMessage = {
    boredom = 3,
    hunger = 0.001,
    thirst = 0.001,
    stressSmokes = 0.002,
    unhappyness = 0.002
}
AC.Buffs.DelayBetweenBuffs = 30 -- seconds
AC.Buffs.LastApplied = 0

function AC.Buffs.IsAutoCleanEnabled()
    local md = getPlayer():getModData()
    return md["AC_Buffs_AutoCleanEnabled"] or false
end

function AC.Buffs.SetAutoCleanEnabled(enabled)
    local md = getPlayer():getModData()
    md["AC_Buffs_AutoCleanEnabled"] = enabled
    if enabled then
        AC.Buffs.CleanCharacter()
        AC.Buffs.CleanClothing()
    end
end

function AC.Buffs.IsPlayersNearby()
    local players = getOnlinePlayers()
    for i=0,players:size()-1 do
        local otherPlayer = players:get(i)
        if AC.CanSeePlayer(otherPlayer, false, 15) then
            return true
        end
    end
    return false
end

local function normalizeValue(initial, adjustment)
    local value = math.max(initial - adjustment, adjustment)
    return math.floor(value * 10000) / 10000
end

function AC.Buffs.ApplyRpBuffs()
    if AC.Buffs.IsAutoCleanEnabled() then
        AC.Buffs.CleanCharacter()
        AC.Buffs.CleanClothing()
    end

    if not SandboxVars.AuroraChat.EnableBuffs then
        return
    end

    local player = getPlayer()

    local ts = getTimestamp()
    if AC.Buffs.LastApplied + AC.Buffs.DelayBetweenBuffs > ts then
        return
    end
    AC.Buffs.LastApplied = ts

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    local apm = AC.Buffs.AmountsPerMessage
    local multiplier = getGameTime():getMultiplier()

    local boredom = bodyDamage:getBoredomLevel()
    if boredom > apm.boredom then
        local boredomNew = normalizeValue(boredom, apm.boredom * multiplier)
        bodyDamage:setBoredomLevel(boredomNew)
    end

    local hunger = stats:getHunger()
    if hunger > apm.hunger then
        local hungerNew = normalizeValue(hunger, apm.hunger * multiplier)
        stats:setHunger(hungerNew)
    end

    local thirst = stats:getThirst()
    if thirst > apm.thirst then
        local thirstNew = normalizeValue(thirst, apm.thirst * multiplier)
        stats:setThirst(thirstNew)
    end

    local stressSmokes = stats:getStressFromCigarettes()
    if stressSmokes > apm.stressSmokes then
        local stressSmokesNew = normalizeValue(stressSmokes, apm.stressSmokes * multiplier)
        stats:setStressFromCigarettes(stressSmokesNew)
    end

    local unhappyness = bodyDamage:getUnhappynessLevel()
    if unhappyness > apm.unhappyness then
        local unhappynessNew = normalizeValue(unhappyness, apm.unhappyness * multiplier)
        bodyDamage:setUnhappynessLevel(unhappynessNew)
    end
end

function AC.Buffs.CleanCharacter()
    local player = getPlayer()
    -- B42 safe iteration: loop until FromIndex returns nil
    local i = 0
    while true do
        local part = BloodBodyPartType.FromIndex(i)
        if not part then break end
        player:getHumanVisual():setBlood(part, 0)
        player:getHumanVisual():setDirt(part, 0)
        i = i + 1
    end
    sendVisual(player)
    triggerEvent("OnClothingUpdated", player)
    player:resetModel()
end

function AC.Buffs.CleanClothing()
    local player = getPlayer()
    local wornClothing = player:getWornItems()
    for i=0,wornClothing:size()-1 do
        local item = wornClothing:get(i):getItem()
        if item:hasBlood() or item:hasDirt() then
            item:getVisual():removeBlood()
            item:getVisual():removeDirt()
        end
    end
    sendVisual(player)
    triggerEvent("OnClothingUpdated", player)
end

if getDebug() then
    function AC.DebugBuffs()
        AC.Buffs.LastApplied = 0
        AC.Buffs.ApplyRpBuffs()
    end
end
