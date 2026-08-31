if isServer() and not isClient() then return end
AC = AC or {}
AC.Buffs = {}

AC.Buffs.AmountsPerMessage = {
    boredom = 3,
    hunger = 0.001,
    thirst = 0.001,
    stressSmokes = 0.002,
    unhappyness = 2
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
    if not players then return false end
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

    local sandbox = SandboxVars.SVRPChatLocal or SandboxVars.SVRPChat or {}
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

    sendClientCommand(getPlayer(), "AC", "ApplyRpBuffs", {
        boredom = apm.boredom * multiplier,
        hunger = apm.hunger * multiplier,
        thirst = apm.thirst * multiplier,
        stressSmokes = apm.stressSmokes * multiplier,
        unhappyness = apm.unhappyness * multiplier
    })
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
