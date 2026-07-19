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

    local sandbox = SandboxVars.AuroraChatLocal or {}
    if not sandbox.EnableBuffs then
        return
    end

    local player = getPlayer()

    local ts = getTimestamp()
    if AC.Buffs.LastApplied + AC.Buffs.DelayBetweenBuffs > ts then
        return
    end
    AC.Buffs.LastApplied = ts

    local stats = player:getStats()
    local apm = AC.Buffs.AmountsPerMessage
    local multiplier = getGameTime():getMultiplier()

    -- B42 API: use CharacterStat enums with stats:remove(stat, amount)
    -- remove() decreases the stat value (reduces boredom, hunger, etc.)
    if stats:get(CharacterStat.BOREDOM) > apm.boredom then
        stats:remove(CharacterStat.BOREDOM, apm.boredom * multiplier)
    end

    if stats:get(CharacterStat.HUNGER) > apm.hunger then
        stats:remove(CharacterStat.HUNGER, apm.hunger * multiplier)
    end

    if stats:get(CharacterStat.THIRST) > apm.thirst then
        stats:remove(CharacterStat.THIRST, apm.thirst * multiplier)
    end

    if stats:get(CharacterStat.STRESS) > apm.stressSmokes then
        stats:remove(CharacterStat.STRESS, apm.stressSmokes * multiplier)
    end

    if stats:get(CharacterStat.UNHAPPINESS) > apm.unhappyness then
        stats:remove(CharacterStat.UNHAPPINESS, apm.unhappyness * multiplier)
    end
end

function AC.Buffs.CleanCharacter()
    local player = getPlayer()
    -- B42 safe iteration: FromIndex is 0-based, MAX:index() gives the count
    local visual = player:getHumanVisual()
    for i=1, BloodBodyPartType.MAX:index() do
        local part = BloodBodyPartType.FromIndex(i-1)
        if part then
            visual:setBlood(part, 0)
            visual:setDirt(part, 0)
        end
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
