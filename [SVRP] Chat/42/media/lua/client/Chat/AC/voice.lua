if not isClient() then return end

AC = AC or {}
AC.Voice = AC.Voice or {}

AC.Voice.ActiveQueues = {}

--- Check if voice chatter is enabled for local player
function AC.Voice.IsEnabled()
    local myPlayer = getPlayer()
    if not myPlayer then return true end
    local modData = myPlayer:getModData()
    if modData and modData._AC_VoiceChatterDisabled ~= nil then
        return not modData._AC_VoiceChatterDisabled
    end
    return true
end

--- Set voice chatter enabled state for local player
function AC.Voice.SetEnabled(enabled)
    local myPlayer = getPlayer()
    if myPlayer then
        local modData = myPlayer:getModData()
        modData._AC_VoiceChatterDisabled = not enabled
    end
end

--- Toggle voice chatter on/off and notify player
function AC.Voice.ToggleVoiceAudio()
    local newState = not AC.Voice.IsEnabled()
    AC.Voice.SetEnabled(newState)
    if newState then
        AC_Utils.addInfoToChat("Voice audio chatter enabled.")
    else
        AC_Utils.addInfoToChat("Voice audio chatter disabled.")
    end
    return newState
end

-- Verified Project Zomboid Vanilla Player Voice Sound Script Names
local femaleSounds = {
    soft = {"VoiceFemaleWhisperHey", "VoiceFemaleWhisperPsst", "VoiceFemaleLureTsk", "VoiceFemaleSighBored"},
    normal = {"VoiceFemaleLureCmon", "VoiceFemaleSighReliefed", "VoiceFemaleWhisperHey", "VoiceFemaleExercise"},
    loud = {"VoiceFemaleLureCmon", "VoiceFemaleMeleeAttack", "VoiceFemaleShoutHey", "VoiceFemaleMeleeShove"},
    shout = {"VoiceFemaleShoutHey", "VoiceFemaleMeleeAttackHeavy", "VoiceFemaleShoutMegaphoneHey"},
}

local maleSounds = {
    soft = {"VoiceMaleWhisperHey", "VoiceMaleWhisperPsst", "VoiceMaleLureTsk", "VoiceMaleSighBored"},
    normal = {"VoiceMaleLureCmon", "VoiceMaleSighReliefed", "VoiceMaleWhisperHey", "VoiceMaleExercise"},
    loud = {"VoiceMaleLureCmon", "VoiceMaleMeleeAttack", "VoiceMaleShoutHey", "VoiceMaleMeleeShove"},
    shout = {"VoiceMaleShoutHey", "VoiceMaleMeleeAttackHeavy", "VoiceMaleShoutMegaphoneHey"},
}

--- Get sound list based on gender and volume
local function getVoicePool(isFemale, chatType)
    local pool = isFemale and femaleSounds or maleSounds
    if chatType == "whisper" then
        return pool.soft
    elseif chatType == "low" then
        return pool.soft
    elseif chatType == "say" then
        return pool.normal
    elseif chatType == "loud" then
        return pool.loud
    elseif chatType == "shout" then
        return pool.shout
    end
    return pool.normal
end

--- Determine how many chatter syllables to play based on character length (1 to 3 seconds)
local function getSyllableCount(text)
    local len = string.len(text or "")
    if len <= 18 then
        return 1
    elseif len <= 45 then
        return 2
    else
        return 3
    end
end

--- Get volume factor based on chat volume type
local function getVolumeFactor(chatType)
    if chatType == "whisper" then
        return 0.35
    elseif chatType == "low" then
        return 0.60
    elseif chatType == "say" then
        return 0.90
    elseif chatType == "loud" then
        return 1.20
    elseif chatType == "shout" then
        return 1.50
    end
    return 0.90
end

--- Play a voice sound on a player emitter or object with fallback
local function playVoiceClip(player, soundName, volume)
    if not player or not soundName then return end
    local played = false

    -- Try player:getEmitter()
    local emitter = player:getEmitter()
    if emitter then
        local ok, res = pcall(function()
            local soundId = emitter:playSound(soundName)
            if soundId and soundId > 0 then
                if emitter.setVolume then
                    emitter:setVolume(soundId, volume or 1.0)
                end
                return true
            end
            return false
        end)
        if ok and res then played = true end
    end

    -- Fallback to player:playSound()
    if not played then
        pcall(function()
            local soundId = player:playSound(soundName)
            if soundId and soundId > 0 then played = true end
        end)
    end

    -- Fallback to player:playSoundLocal()
    if not played then
        pcall(function()
            if player.playSoundLocal then
                player:playSoundLocal(soundName)
                played = true
            end
        end)
    end

    print(string.format("[SVRP Chat Voice] playVoiceClip: sound=%s, player=%s, volume=%.2f, success=%s",
        tostring(soundName), tostring(player:getUsername()), volume or 1.0, tostring(played)))
end

--- Play voice chatter for a player character
--- @param player IsoPlayer
--- @param chatType string ("whisper", "low", "say", "loud", "shout")
--- @param text string
--- @param isMuffled boolean
function AC.Voice.PlayChatVoice(player, chatType, text, isMuffled)
    if not player then
        print("[SVRP Chat Voice] PlayChatVoice: player is nil, skipping voice audio.")
        return
    end
    if not AC.Voice.IsEnabled() then
        print("[SVRP Chat Voice] PlayChatVoice: voice chatter is disabled in player settings.")
        return
    end

    local sandbox = SandboxVars.SVRPChat or {}
    if sandbox.EnableVoiceChatter == false then
        print("[SVRP Chat Voice] PlayChatVoice: voice chatter is disabled in Sandbox options.")
        return
    end

    local isFemale = player:isFemale()
    local pool = getVoicePool(isFemale, chatType)
    if not pool or #pool == 0 then
        print("[SVRP Chat Voice] PlayChatVoice: sound pool is empty for chatType=" .. tostring(chatType))
        return
    end

    local syllableCount = getSyllableCount(text)
    local volume = getVolumeFactor(chatType)
    if isMuffled then
        volume = volume * 0.5
    end

    local selectedSounds = {}
    for i = 1, syllableCount do
        local randIndex = ZombRand(#pool) + 1
        table.insert(selectedSounds, pool[randIndex])
    end

    print(string.format("[SVRP Chat Voice] PlayChatVoice: player=%s (female=%s), chatType=%s, textLen=%d, syllables=%d, muffled=%s, sounds=%s",
        tostring(player:getUsername()), tostring(isFemale), tostring(chatType), string.len(text or ""), syllableCount, tostring(isMuffled), table.concat(selectedSounds, ", ")))

    -- Play first sound immediately
    playVoiceClip(player, selectedSounds[1], volume)

    -- If more syllables, queue them with natural conversational cadence (~280ms)
    if #selectedSounds > 1 then
        table.insert(AC.Voice.ActiveQueues, {
            player = player,
            sounds = selectedSounds,
            index = 2,
            nextTime = getTimestampMs() + 280,
            volume = volume
        })
    end
end

--- Process active voice chatter queues on tick
function AC.Voice.Update()
    if #AC.Voice.ActiveQueues == 0 then return end

    local now = getTimestampMs()
    for i = #AC.Voice.ActiveQueues, 1, -1 do
        local item = AC.Voice.ActiveQueues[i]
        if now >= item.nextTime then
            local soundName = item.sounds[item.index]
            if item.player and soundName then
                playVoiceClip(item.player, soundName, item.volume)
            end

            item.index = item.index + 1
            if item.index > #item.sounds then
                table.remove(AC.Voice.ActiveQueues, i)
            else
                item.nextTime = now + 260 + ZombRand(80)
            end
        end
    end
end

Events.OnTick.Add(AC.Voice.Update)
