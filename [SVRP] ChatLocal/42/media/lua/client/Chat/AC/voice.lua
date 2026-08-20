if not isClient() then return end

AC = AC or {}
AC.Voice = AC.Voice or {}

AC.Voice.LastPlayTimes = {}
AC.Voice.LastMessageTexts = {}
AC.Voice.ActiveSoundIds = {}

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

-- Strictly categorized natural voice pools for each chat range
local femaleVoicePools = {
    whisper = { "VoiceFemaleWhisperHey", "VoiceFemaleWhisperPsst" },
    low     = { "VoiceFemaleSighReliefed", "VoiceFemaleSighBored", "VoiceFemaleLureTsk" },
    say     = { "VoiceFemale", "VoiceFemaleSighReliefed" },
    loud    = { "VoiceFemaleLureCmon", "VoiceFemaleMeleeAttack" },
    shout   = { "VoiceFemaleShoutHey" }
}

local maleVoicePools = {
    whisper = { "VoiceMaleWhisperHey", "VoiceMaleWhisperPsst" },
    low     = { "VoiceMaleSighReliefed", "VoiceMaleSighBored", "VoiceMaleLureTsk" },
    say     = { "VoiceMale", "VoiceMaleSighReliefed" },
    loud    = { "VoiceMaleLureCmon", "VoiceMaleMeleeAttack" },
    shout   = { "VoiceMaleShoutHey" }
}

--- Get volume factor based on chat volume type
local function getVolumeFactor(chatType)
    if chatType == "whisper" then
        return 0.30
    elseif chatType == "low" then
        return 0.55
    elseif chatType == "say" then
        return 0.85
    elseif chatType == "loud" then
        return 1.15
    elseif chatType == "shout" then
        return 1.45
    end
    return 0.85
end

--- Play a voice sound with pitch & volume modulation on player emitter
local function playVoiceClip(player, playerKey, soundName, volume, pitch)
    if not player or not soundName then return end
    local emitter = player:getEmitter()
    if emitter then
        -- Stop any existing voice sound currently playing on this player's emitter
        if AC.Voice.ActiveSoundIds[playerKey] then
            pcall(function()
                emitter:stopSound(AC.Voice.ActiveSoundIds[playerKey])
            end)
            AC.Voice.ActiveSoundIds[playerKey] = nil
        end

        pcall(function()
            local soundId = emitter:playSound(soundName)
            if soundId and soundId > 0 then
                AC.Voice.ActiveSoundIds[playerKey] = soundId
                if emitter.setVolume then
                    emitter:setVolume(soundId, volume or 1.0)
                end
                if emitter.setPitch and pitch then
                    emitter:setPitch(soundId, pitch)
                end

                -- Apply character's chosen named voice (Bob, Hank, James, Chris / Kate, Casey-Jo, Maryanne, Janine)
                local desc = player.getDescriptor and player:getDescriptor()
                if desc and emitter.setParameterValueByName then
                    local vType = desc.getVoiceType and desc:getVoiceType()
                    local vPitch = desc.getVoicePitch and desc:getVoicePitch()
                    if vType ~= nil then
                        emitter:setParameterValueByName(soundId, "CharacterVoiceType", tonumber(vType) or 0)
                    end
                    if vPitch ~= nil then
                        emitter:setParameterValueByName(soundId, "CharacterVoicePitch", tonumber(vPitch) or 0)
                    end
                end
            end
        end)
    else
        pcall(function()
            player:playSound(soundName)
        end)
    end
end

--- Play voice chatter for a player character
--- @param player IsoPlayer
--- @param chatType string ("whisper", "low", "say", "loud", "shout")
--- @param text string
--- @param isMuffled boolean
function AC.Voice.PlayChatVoice(player, chatType, text, isMuffled)
    if not player then return end
    if not AC.Voice.IsEnabled() then return end

    local sandbox = SandboxVars.SVRPChatLocal or SandboxVars.SVRPChat or {}
    if sandbox.EnableVoiceChatter == false then return end

    local playerKey = (player.getUsername and player:getUsername()) or (player.getOnlineID and tostring(player:getOnlineID())) or tostring(player)
    local now = getTimestampMs()

    -- 1. Exact Message Deduplication (prevents multiple tabs from re-triggering for the same message)
    if text and text ~= "" then
        local lastText = AC.Voice.LastMessageTexts and AC.Voice.LastMessageTexts[playerKey]
        local lastTextTime = AC.Voice.LastPlayTimes[playerKey] or 0
        if lastText == text and (now - lastTextTime) < 2500 then
            return
        end
    end

    -- 2. Debounce: Minimum cooldown (1000ms) between voice triggers for the same player
    local lastTime = AC.Voice.LastPlayTimes[playerKey] or 0
    if (now - lastTime) < 1000 then
        return
    end

    AC.Voice.LastPlayTimes[playerKey] = now
    AC.Voice.LastMessageTexts = AC.Voice.LastMessageTexts or {}
    AC.Voice.LastMessageTexts[playerKey] = text

    local isFemale = player:isFemale()
    local pools = isFemale and femaleVoicePools or maleVoicePools
    local pool = pools[chatType] or pools.say
    if not pool or #pool == 0 then return end

    local chosenSound = pool[ZombRand(#pool) + 1]

    -- Volume calculation with muffling
    local volume = getVolumeFactor(chatType)
    if isMuffled then
        volume = volume * 0.45
    end

    -- Pitch variation: slight organic variance (0.94 - 1.06) + punctuation awareness
    local pitch = 0.94 + (ZombRand(12) / 100)
    if text then
        if string.find(text, "%?") then
            pitch = pitch + 0.10 -- Inquisitive rising pitch for questions
        elseif string.find(text, "%!") then
            pitch = pitch + 0.05 -- Energetic pitch for exclamations
            volume = math.min(1.50, volume * 1.1)
        end
    end

    playVoiceClip(player, playerKey, chosenSound, volume, pitch)
end
