if isServer() and not isClient() then return end

AC = AC or {}
AC.Voice = AC.Voice or {}

AC.Voice.LastPlayTimes = {}
AC.Voice.LastMessageTexts = {}
AC.Voice.ActiveSoundIds = {}

--- Native Character Voice Profiles (In-Engine FMOD Models)
AC.Voice.NativeVoiceStyles = {
    male = {
        { id = 0, name = "Bob (Deep & Steady)" },
        { id = 1, name = "Hank (Gruff & Rough)" },
        { id = 2, name = "James (Youthful & Energetic)" },
        { id = 3, name = "Chris (Classic Survivor)" },
    },
    female = {
        { id = 0, name = "Kate (Classic & Clear)" },
        { id = 1, name = "Casey-Jo (Youthful & Expressive)" },
        { id = 2, name = "Maryanne (Warm & Gentle)" },
        { id = 3, name = "Janine (Gravelly & Tough)" },
    }
}

AC.Voice.NativePitchStyles = {
    { id = 0, name = "Deep / Low Pitch" },
    { id = 1, name = "Standard / Natural Pitch" },
    { id = 2, name = "High / Bright Pitch" },
}

AC.Voice.enabled = nil

--- Stop any currently playing voice audio clips on the local client
function AC.Voice.StopAllActiveSounds()
    if not AC.Voice.ActiveSoundIds then return end
    for playerKey, data in pairs(AC.Voice.ActiveSoundIds) do
        if data then
            pcall(function()
                if type(data) == "table" and data.emitter and data.soundId then
                    if data.emitter.stopSound then
                        data.emitter:stopSound(data.soundId)
                    end
                elseif type(data) == "number" then
                    local myPlayer = getPlayer()
                    if myPlayer and myPlayer.getEmitter then
                        local em = myPlayer:getEmitter()
                        if em and em.stopSound then
                            em:stopSound(data)
                        end
                    end
                end
            end)
        end
    end
    AC.Voice.ActiveSoundIds = {}
end

--- Synchronize the chatbox button icon with current enabled state
function AC.Voice.UpdateChatButton()
    if ISChat.instance and ISChat.instance.voiceChatterButton then
        local enabled = AC.Voice.IsEnabled()
        if enabled then
            ISChat.instance.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_on.png"))
        else
            ISChat.instance.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_off.png"))
        end
    end
end

--- Check if voice chatter is enabled for local player
function AC.Voice.IsEnabled()
    if AC.Voice.enabled ~= nil then
        return AC.Voice.enabled
    end
    if AC.Meta and AC.Meta.GetVoiceChatter then
        local pref = AC.Meta.GetVoiceChatter()
        if pref ~= nil then
            AC.Voice.enabled = (pref == true)
            return AC.Voice.enabled
        end
    end
    local myPlayer = getPlayer()
    if myPlayer then
        local modData = myPlayer:getModData()
        if modData and modData._AC_VoiceChatterDisabled ~= nil then
            AC.Voice.enabled = not modData._AC_VoiceChatterDisabled
            return AC.Voice.enabled
        end
    end
    AC.Voice.enabled = true
    return true
end

--- Set voice chatter enabled state for local player
function AC.Voice.SetEnabled(enabled)
    AC.Voice.enabled = (enabled == true)
    if AC.Meta and AC.Meta.SetVoiceChatterPref then
        AC.Meta.SetVoiceChatterPref(AC.Voice.enabled)
    end
    local myPlayer = getPlayer()
    if myPlayer then
        local modData = myPlayer:getModData()
        if modData then
            modData._AC_VoiceChatterDisabled = not AC.Voice.enabled
        end
    end
    if not AC.Voice.enabled then
        AC.Voice.StopAllActiveSounds()
    end
    AC.Voice.UpdateChatButton()
end

--- Toggle voice chatter on/off and notify player
function AC.Voice.ToggleVoiceAudio(explicitState)
    local newState
    if type(explicitState) == "boolean" then
        newState = explicitState
    else
        newState = not AC.Voice.IsEnabled()
    end
    AC.Voice.SetEnabled(newState)
    if newState then
        AC_Utils.addInfoToChat("Voice audio chatter enabled.")
    else
        AC_Utils.addInfoToChat("Voice audio chatter disabled.")
    end
    return newState
end

--- Get character's native voice style ID
--- @param player IsoPlayer
--- @return number
function AC.Voice.GetNativeVoice(player)
    if not player then return 0 end
    local desc = player.getDescriptor and player:getDescriptor()
    if desc and desc.getVoiceType then
        local vt = desc:getVoiceType()
        if vt ~= nil then return tonumber(vt) or 0 end
    end
    local modData = player.getModData and player:getModData()
    if modData and modData._AC_NativeVoiceType ~= nil then
        return modData._AC_NativeVoiceType
    end
    return 0
end

--- Set character's native voice style ID
--- @param player IsoPlayer
--- @param voiceTypeId number
function AC.Voice.SetNativeVoice(player, voiceTypeId)
    if not player or voiceTypeId == nil then return end
    local desc = player.getDescriptor and player:getDescriptor()
    if desc and desc.setVoiceType then
        pcall(function() desc:setVoiceType(voiceTypeId) end)
    end
    local modData = player.getModData and player:getModData()
    if modData then
        modData._AC_NativeVoiceType = voiceTypeId
    end
end

--- Get character's native voice pitch ID
--- @param player IsoPlayer
--- @return number
function AC.Voice.GetNativePitch(player)
    if not player then return 1 end
    local desc = player.getDescriptor and player:getDescriptor()
    if desc and desc.getVoicePitch then
        local vp = desc:getVoicePitch()
        if vp ~= nil then return tonumber(vp) or 1 end
    end
    local modData = player.getModData and player:getModData()
    if modData and modData._AC_NativeVoicePitch ~= nil then
        return modData._AC_NativeVoicePitch
    end
    return 1
end

--- Set character's native voice pitch ID
--- @param player IsoPlayer
--- @param pitchId number
function AC.Voice.SetNativePitch(player, pitchId)
    if not player or pitchId == nil then return end
    local desc = player.getDescriptor and player:getDescriptor()
    if desc and desc.setVoicePitch then
        pcall(function() desc:setVoicePitch(pitchId) end)
    end
    local modData = player.getModData and player:getModData()
    if modData then
        modData._AC_NativeVoicePitch = pitchId
    end
end

-- Curated Natural Vanilla Voice Pools (Contextual & Emotion-Driven)
local femaleVoicePools = {
    whisper   = { "VoiceFemaleWhisperPsst", "VoiceFemaleWhisperHey" },
    mewhisper = { "VoiceFemaleWhisperPsst", "VoiceFemaleWhisperHey" },
    low       = { "VoiceFemaleWhisperHey", "VoiceFemaleSighBored" },
    melow     = { "VoiceFemaleWhisperHey", "VoiceFemaleSighBored" },
    say       = { "VoiceFemaleWhisperHey", "VoiceFemaleSighBored", "VoiceFemaleSighReliefed" },
    mesay     = { "VoiceFemaleWhisperHey", "VoiceFemaleSighBored", "VoiceFemaleSighReliefed" },
    loud      = { "VoiceFemaleLureCmon", "VoiceFemaleShoutHey" },
    meloud    = { "VoiceFemaleLureCmon", "VoiceFemaleShoutHey" },
    shout     = { "VoiceFemaleShoutHey" },
    meshout   = { "VoiceFemaleShoutHey" },
    yell      = { "VoiceFemaleShoutHey" },
    meyell    = { "VoiceFemaleShoutHey" }
}

local maleVoicePools = {
    whisper   = { "VoiceMaleWhisperPsst", "VoiceMaleWhisperHey" },
    mewhisper = { "VoiceMaleWhisperPsst", "VoiceMaleWhisperHey" },
    low       = { "VoiceMaleWhisperHey", "VoiceMaleSighBored" },
    melow     = { "VoiceMaleWhisperHey", "VoiceMaleSighBored" },
    say       = { "VoiceMaleWhisperHey", "VoiceMaleSighBored", "VoiceMaleSighReliefed" },
    mesay     = { "VoiceMaleWhisperHey", "VoiceMaleSighBored", "VoiceMaleSighReliefed" },
    loud      = { "VoiceMaleLureCmon", "VoiceMaleShoutHey" },
    meloud    = { "VoiceMaleLureCmon", "VoiceMaleShoutHey" },
    shout     = { "VoiceMaleShoutHey" },
    meshout   = { "VoiceMaleShoutHey" },
    yell      = { "VoiceMaleShoutHey" },
    meyell    = { "VoiceMaleShoutHey" }
}

-- Specialized contextual & emotional voice events
local femaleCmonPool = { "VoiceFemaleLureCmon" }
local maleCmonPool = { "VoiceMaleLureCmon" }
local femaleShoutHeyPool = { "VoiceFemaleShoutHey" }
local maleShoutHeyPool = { "VoiceMaleShoutHey" }
local femaleSoftHeyPool = { "VoiceFemaleWhisperHey" }
local maleSoftHeyPool = { "VoiceMaleWhisperHey" }
local femaleSadPool = { "VoiceFemaleSighSad" }
local maleSadPool = { "VoiceMaleSighSad" }
local femaleReliefPool = { "VoiceFemaleSighReliefed" }
local maleReliefPool = { "VoiceMaleSighReliefed" }
local femaleDangerPool = { "VoiceFemaleShoutHey", "VoiceFemaleLureCmon" }
local maleDangerPool = { "VoiceMaleShoutHey", "VoiceMaleLureCmon" }
local femaleStealthPool = { "VoiceFemaleWhisperPsst" }
local maleStealthPool = { "VoiceMaleWhisperPsst" }
local femaleCoughPool = { "VoiceFemaleCough", "VoiceFemaleMuffledCough" }
local maleCoughPool = { "VoiceMaleCough", "VoiceMaleMuffledCough" }

--- Get volume factor based on chat volume type
local function getVolumeFactor(chatType)
    if chatType == "whisper" or chatType == "mewhisper" then
        return 0.30
    elseif chatType == "low" or chatType == "melow" then
        return 0.55
    elseif chatType == "say" or chatType == "mesay" then
        return 0.85
    elseif chatType == "loud" or chatType == "meloud" then
        return 1.15
    elseif chatType == "shout" or chatType == "meshout" or chatType == "yell" or chatType == "meyell" then
        return 1.45
    end
    return 0.85
end

--- Extract purely spoken dialogue from text, filtering out narration and flavor action text
--- @param text string
--- @param chatType string
--- @return string|nil
local function extractSpokenDialogue(text, chatType)
    if not text or text == "" then return nil end

    local clean = text
    clean = clean:gsub("%[UN:[^%]]-%]", "")
    clean = clean:gsub("%[POS:[^%]]-%]", "")
    clean = clean:gsub("%[LANG:[^%]]-%]", "")
    clean = clean:gsub("%[VOICE:[^%]]-%]", "")
    clean = clean:gsub("%[radio%]", "")
    clean = clean:gsub("%[emote%]", "")
    clean = clean:gsub("%[Recorder%]", "")
    clean = clean:gsub("%[npc%]", "")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")

    -- 1. Check for quoted dialogue ("..." or “...”)
    local quotes = {}
    for q in clean:gmatch('"([^"]-)"') do
        if q and q:match("%S") then table.insert(quotes, q) end
    end
    if #quotes == 0 then
        for q in clean:gmatch('“([^”]-)”') do
            if q and q:match("%S") then table.insert(quotes, q) end
        end
    end

    -- If quotes were found, return the combined spoken dialogue
    if #quotes > 0 then
        return table.concat(quotes, " ")
    end

    -- 2. If no quotes are found:
    -- If it's an action/emote command (/me, /do, /it, /emote) or enclosed in asterisks *...*, there is no spoken dialogue
    local isActionChat = (chatType == "me" or chatType == "do" or chatType == "it" or chatType == "emote")
        or clean:match("^/me%s") or clean:match("^/do%s") or clean:match("^/it%s") or clean:match("^%*.*%*$")

    if isActionChat then
        return nil -- Purely flavor / action narration, do not speak
    end

    -- 3. If it's a regular dialogue command (say, loud, shout, whisper, low, yell, mesay, meloud, etc.)
    -- Strip command prefixes and action asterisks if present
    local dialogue = clean:gsub("^/[%a%d_]+%s*", ""):gsub("^%*[%a%d%s_%p]+%*%s*", "")
    return (dialogue and dialogue:match("%S")) and dialogue or nil
end

AC.Voice.ExtractSpokenDialogue = extractSpokenDialogue

--- Analyze message text, punctuation, and player condition to determine sentiment, pitch, and voice sound
local function analyzeSentiment(text, player, chatType)
    local lowerText = string.lower(text or "")
    local sentiment = {
        emotion = "neutral",
        pitchMod = 0.0,
        rateMod = 0.0,
        volumeMod = 1.0,
        overrideSound = nil
    }

    -- 1. All-Caps Detection (Screaming / Heightened Urgency)
    local lettersOnly = text and string.gsub(text, "[^%a]", "") or ""
    if #lettersOnly >= 4 then
        local upperOnly = string.gsub(lettersOnly, "[^%u]", "")
        if (#upperOnly / #lettersOnly) >= 0.75 then
            sentiment.pitchMod = sentiment.pitchMod + 0.08
            sentiment.rateMod = sentiment.rateMod + 0.12
            sentiment.volumeMod = sentiment.volumeMod * 1.20
            sentiment.overrideSound = "shout_hey"
        end
    end

    -- 2. Keyword & Context Sentiment Matching
    if string.find(lowerText, "cmon") or string.find(lowerText, "c'mon") or string.find(lowerText, "come on")
    or string.find(lowerText, "over here") or string.find(lowerText, "follow me") or string.find(lowerText, "this way")
    or string.find(lowerText, "hurry") or string.find(lowerText, "lets go") or string.find(lowerText, "let's go")
    or string.find(lowerText, "move it") or (string.find(lowerText, "move") and string.find(lowerText, "!")) then
        sentiment.emotion = "cmon"
        sentiment.volumeMod = sentiment.volumeMod * 1.10
        sentiment.overrideSound = "cmon"

    elseif string.find(lowerText, "watch out") or string.find(lowerText, "look out") or string.find(lowerText, "behind you")
    or string.find(lowerText, "incoming") or string.find(lowerText, "horde") or string.find(lowerText, "trapped")
    or string.find(lowerText, "surrounded") or string.find(lowerText, "get down") or string.find(lowerText, "duck")
    or string.find(lowerText, "take cover") or string.find(lowerText, "zombies") or (string.find(lowerText, "run") and string.find(lowerText, "!")) then
        sentiment.emotion = "danger"
        sentiment.pitchMod = sentiment.pitchMod + 0.12
        sentiment.rateMod = sentiment.rateMod + 0.15
        sentiment.volumeMod = sentiment.volumeMod * 1.25
        sentiment.overrideSound = "danger"

    elseif string.find(lowerText, "hey!") or string.find(lowerText, "heads up") or string.find(lowerText, "look here")
    or string.find(lowerText, "listen up") or (string.find(lowerText, "hey") and string.find(lowerText, "!")) then
        sentiment.emotion = "shout_hey"
        sentiment.pitchMod = sentiment.pitchMod + 0.08
        sentiment.volumeMod = sentiment.volumeMod * 1.20
        sentiment.overrideSound = "shout_hey"

    elseif lowerText:match("^hey%s") or lowerText:match("^hey$") or lowerText:match("^hey%p")
    or lowerText:match("^hi%s") or lowerText:match("^hi$") or lowerText:match("^hi%p")
    or lowerText:match("^hello") or lowerText:match("^yo%s") or lowerText:match("^yo$") or lowerText:match("^yo%p") then
        sentiment.emotion = "soft_hey"
        sentiment.pitchMod = sentiment.pitchMod + 0.04
        sentiment.overrideSound = "soft_hey"

    elseif string.find(lowerText, "shh") or string.find(lowerText, "quiet") or string.find(lowerText, "hush")
    or string.find(lowerText, "sneak") or string.find(lowerText, "silent") or string.find(lowerText, "dont make a sound")
    or string.find(lowerText, "don't make a sound") or string.find(lowerText, "keep it down") or string.find(lowerText, "freeze")
    or string.find(lowerText, "psst") or string.find(lowerText, "pst") then
        sentiment.emotion = "stealth"
        sentiment.pitchMod = sentiment.pitchMod - 0.02
        sentiment.rateMod = sentiment.rateMod - 0.10
        sentiment.volumeMod = sentiment.volumeMod * 0.70
        sentiment.overrideSound = "stealth"

    elseif string.find(lowerText, "sad") or string.find(lowerText, "crying") or string.find(lowerText, "tears")
    or string.find(lowerText, "rest in peace") or string.find(lowerText, "rip") or string.find(lowerText, "mourn")
    or string.find(lowerText, "grief") or string.find(lowerText, "hopeless") or string.find(lowerText, "broke my heart")
    or string.find(lowerText, "heartbroken") or string.find(lowerText, "forgive me") or string.find(lowerText, "so sorry")
    or string.find(lowerText, "i'm sorry") or string.find(lowerText, "im sorry") or string.find(lowerText, "oh no")
    or string.find(lowerText, ":%(") or string.find(lowerText, ":%-(") then
        sentiment.emotion = "sadness"
        sentiment.pitchMod = sentiment.pitchMod - 0.08
        sentiment.rateMod = sentiment.rateMod - 0.08
        sentiment.volumeMod = sentiment.volumeMod * 0.85
        sentiment.overrideSound = "sad"

    elseif string.find(lowerText, "sigh") or string.find(lowerText, "%*sigh%*") or string.find(lowerText, "tired")
    or string.find(lowerText, "exhausted") or string.find(lowerText, "finally") or string.find(lowerText, "made it")
    or string.find(lowerText, "whew") or string.find(lowerText, "phew") or string.find(lowerText, "safe now")
    or string.find(lowerText, "survived") or string.find(lowerText, "thank god") or string.find(lowerText, "thank goodness")
    or string.find(lowerText, "catching my breath") then
        sentiment.emotion = "relief"
        sentiment.pitchMod = sentiment.pitchMod - 0.04
        sentiment.rateMod = sentiment.rateMod - 0.06
        sentiment.volumeMod = sentiment.volumeMod * 0.90
        sentiment.overrideSound = "relief"

    elseif string.find(lowerText, "cough") or string.find(lowerText, "%*cough%*") or string.find(lowerText, "sneeze")
    or string.find(lowerText, "%*sneeze%*") or string.find(lowerText, "achoo") then
        sentiment.emotion = "cough"
        sentiment.overrideSound = "cough"

    elseif string.find(lowerText, "haha") or string.find(lowerText, "hehe") or string.find(lowerText, "lmao")
    or string.find(lowerText, "rofl") or string.find(lowerText, "lol") or string.find(lowerText, "yay")
    or string.find(lowerText, "awesome") or string.find(lowerText, "great") or string.find(lowerText, "glad")
    or string.find(lowerText, "happy") or string.find(lowerText, "cheers") or string.find(lowerText, "giggle")
    or string.find(lowerText, "pff") or string.find(lowerText, "thanks") or string.find(lowerText, "thank you")
    or string.find(lowerText, "good job") or string.find(lowerText, "love") or string.find(lowerText, "nice")
    or string.find(lowerText, ":%)") or string.find(lowerText, ":%-%)") or string.find(lowerText, ":d")
    or string.find(lowerText, ":%-d") or string.find(lowerText, "xd") or string.find(lowerText, "%%^%%^") then
        sentiment.emotion = "joy"
        sentiment.pitchMod = sentiment.pitchMod + 0.10
        sentiment.rateMod = sentiment.rateMod + 0.05
        sentiment.volumeMod = sentiment.volumeMod * 1.08

    elseif string.find(lowerText, "fuck") or string.find(lowerText, "shit") or string.find(lowerText, "bastard")
    or string.find(lowerText, "damn it") or string.find(lowerText, "dammit") or string.find(lowerText, "shut up")
    or string.find(lowerText, "hate") or string.find(lowerText, "idiot") or string.find(lowerText, "moron")
    or string.find(lowerText, "screw you") or string.find(lowerText, "get lost") or string.find(lowerText, "piss off") then
        sentiment.emotion = "anger"
        sentiment.pitchMod = sentiment.pitchMod - 0.03
        sentiment.rateMod = sentiment.rateMod + 0.08
        sentiment.volumeMod = sentiment.volumeMod * 1.15
    end

    -- 3. Punctuation & Syntax Inflections
    if text then
        if string.find(text, "%?%!") or string.find(text, "%!%?") then
            sentiment.pitchMod = sentiment.pitchMod + 0.12
            sentiment.rateMod = sentiment.rateMod + 0.10
            sentiment.volumeMod = sentiment.volumeMod * 1.15
        elseif string.find(text, "%?") then
            sentiment.pitchMod = sentiment.pitchMod + 0.08
        elseif string.find(text, "%!") then
            sentiment.pitchMod = sentiment.pitchMod + 0.05
            sentiment.rateMod = sentiment.rateMod + 0.05
            sentiment.volumeMod = sentiment.volumeMod * 1.08
        elseif string.find(text, "%.%.%.$") then
            sentiment.pitchMod = sentiment.pitchMod - 0.04
            sentiment.rateMod = sentiment.rateMod - 0.10
        end
    end

    -- 4. Player Physical & Psychological Condition Integration (Safe stats query)
    if player and player.getStats then
        pcall(function()
            local stats = player:getStats()
            if stats then
                local panic = (stats.getPanic and stats:getPanic()) or 0
                if panic >= 25 then
                    sentiment.pitchMod = sentiment.pitchMod + ((panic / 100) * 0.08)
                    sentiment.rateMod = sentiment.rateMod + ((panic / 100) * 0.10)
                end

                local endurance = (stats.getEndurance and stats:getEndurance()) or 1.0
                if endurance < 0.4 then
                    sentiment.pitchMod = sentiment.pitchMod - 0.04
                    sentiment.rateMod = sentiment.rateMod - 0.08
                    sentiment.volumeMod = sentiment.volumeMod * 0.90
                end

                local pain = (stats.getPain and stats:getPain()) or 0
                if pain >= 25 then
                    sentiment.pitchMod = sentiment.pitchMod + 0.03
                end

                local drunk = (stats.getDrunkenness and stats:getDrunkenness()) or 0
                if drunk >= 25 then
                    sentiment.pitchMod = sentiment.pitchMod + ((ZombRand(14) - 7) / 100)
                end
            end
        end)
    end

    return sentiment
end

--- Play a voice sound with pitch & volume modulation on player emitter
local function playVoiceClip(player, playerKey, soundName, volume, pitch)
    if not player or not soundName then return end

    local played = false
    local emitter = player.getEmitter and player:getEmitter()

    if emitter then
        pcall(function()
            local soundId = emitter:playSound(soundName)
            if soundId ~= nil then
                played = true
                AC.Voice.ActiveSoundIds[playerKey] = { emitter = emitter, soundId = soundId }

                if emitter.setVolume then
                    pcall(function() emitter:setVolume(soundId, volume or 1.0) end)
                end
                if emitter.setPitch and pitch then
                    pcall(function() emitter:setPitch(soundId, pitch) end)
                end

                -- Apply character's chosen named voice (Bob, Hank, James, Chris / Kate, Casey-Jo, Maryanne, Janine)
                local desc = player.getDescriptor and player:getDescriptor()
                if desc and emitter.setParameterValueByName then
                    local vType = desc.getVoiceType and desc:getVoiceType()
                    local vPitch = desc.getVoicePitch and desc:getVoicePitch()
                    if vType ~= nil then
                        pcall(function() emitter:setParameterValueByName(soundId, "CharacterVoiceType", tonumber(vType) or 0) end)
                    end
                    if vPitch ~= nil then
                        pcall(function() emitter:setParameterValueByName(soundId, "CharacterVoicePitch", tonumber(vPitch) or 0) end)
                    end
                end
            end
        end)
    end

    if not played then
        pcall(function()
            if player.playSound then
                player:playSound(soundName)
            elseif player.getSquare and getSoundManager() then
                getSoundManager():PlayWorldSound(soundName, player:getSquare(), 0.0, 15.0, volume or 1.0, false)
            end
        end)
    end
end

--- Play voice chatter for a player character
--- @param player IsoPlayer|nil
--- @param chatType string ("whisper", "low", "say", "loud", "shout", "mesay", "meloud", etc.)
--- @param text string
--- @param isMuffled boolean
--- @param pos table|nil
function AC.Voice.PlayChatVoice(player, chatType, text, isMuffled, pos)
    if not AC.Voice.IsEnabled() then return end

    local sandbox = SandboxVars.SVRPChat or SandboxVars.SVRPChat or {}
    if sandbox.EnableVoiceChatter == false then return end

    chatType = chatType or "say"
    if chatType == "" then chatType = "say" end

    -- 0. Extract Spoken Dialogue (Filter out flavor text & action narration)
    local spokenDialogue = extractSpokenDialogue(text, chatType)
    if not spokenDialogue or spokenDialogue == "" then
        return -- No spoken words in this message (e.g. pure /me body language or silent action)
    end

    local playerKey = (player and player.getUsername and player:getUsername())
        or (player and player.getOnlineID and tostring(player:getOnlineID()))
        or (pos and (tostring(pos.x) .. "_" .. tostring(pos.y)))
        or (spokenDialogue and ("txt_" .. spokenDialogue:sub(1, 15)))
        or "unknown"
    local now = getTimestampMs()

    -- 1. Exact Message Deduplication (prevents multiple tabs from re-triggering for the same message)
    if spokenDialogue and spokenDialogue ~= "" then
        local lastText = AC.Voice.LastMessageTexts and AC.Voice.LastMessageTexts[playerKey]
        local lastTextTime = AC.Voice.LastPlayTimes[playerKey] or 0
        if lastText == spokenDialogue and (now - lastTextTime) < 2500 then
            return
        end
    end

    -- 2. Debounce: Minimum cooldown (800ms) between voice triggers for the same player
    local lastTime = AC.Voice.LastPlayTimes[playerKey] or 0
    if (now - lastTime) < 800 then
        return
    end

    AC.Voice.LastPlayTimes[playerKey] = now
    AC.Voice.LastMessageTexts = AC.Voice.LastMessageTexts or {}
    AC.Voice.LastMessageTexts[playerKey] = spokenDialogue

    local isFemale = player and player.isFemale and player:isFemale()
    local pools = isFemale and femaleVoicePools or maleVoicePools
    local pool = pools[chatType] or pools.say

    -- 3. Execute Sentiment & Context Analysis on the extracted spoken dialogue
    local sentiment = analyzeSentiment(spokenDialogue, player, chatType)

    local chosenSound = nil
    if sentiment.overrideSound == "cmon" then
        local cmonPool = isFemale and femaleCmonPool or maleCmonPool
        chosenSound = cmonPool[ZombRand(#cmonPool) + 1]
    elseif sentiment.overrideSound == "shout_hey" then
        local heyPool = isFemale and femaleShoutHeyPool or maleShoutHeyPool
        chosenSound = heyPool[ZombRand(#heyPool) + 1]
    elseif sentiment.overrideSound == "soft_hey" then
        local heyPool = isFemale and femaleSoftHeyPool or maleSoftHeyPool
        chosenSound = heyPool[ZombRand(#heyPool) + 1]
    elseif sentiment.overrideSound == "sad" then
        local sadPool = isFemale and femaleSadPool or maleSadPool
        chosenSound = sadPool[ZombRand(#sadPool) + 1]
    elseif sentiment.overrideSound == "relief" then
        local reliefPool = isFemale and femaleReliefPool or maleReliefPool
        chosenSound = reliefPool[ZombRand(#reliefPool) + 1]
    elseif sentiment.overrideSound == "danger" then
        local dangerPool = isFemale and femaleDangerPool or maleDangerPool
        chosenSound = dangerPool[ZombRand(#dangerPool) + 1]
    elseif sentiment.overrideSound == "stealth" then
        local stealthPool = isFemale and femaleStealthPool or maleStealthPool
        chosenSound = stealthPool[ZombRand(#stealthPool) + 1]
    elseif sentiment.overrideSound == "cough" then
        local coughPool = isFemale and femaleCoughPool or maleCoughPool
        chosenSound = coughPool[ZombRand(#coughPool) + 1]
    elseif pool and #pool > 0 then
        chosenSound = pool[ZombRand(#pool) + 1]
    end

    -- If no contextual/emotional voice sound applies (e.g. normal conversational typing), keep silent and natural
    if not chosenSound then
        return
    end

    -- 4. Calculate Final Volume
    local volume = getVolumeFactor(chatType) * (sentiment.volumeMod or 1.0)
    if isMuffled then
        volume = volume * 0.45
    end
    volume = math.max(0.15, math.min(1.60, volume))

    -- 5. Calculate Final Pitch (Base Organic Variation + Sentiment Modulation)
    local basePitch = 0.96 + (ZombRand(8) / 100)
    local pitch = math.max(0.75, math.min(1.35, basePitch + (sentiment.pitchMod or 0.0)))

    if player then
        print(string.format("[SVRP Voice] Playing '%s' on player '%s' (vol=%.2f, pitch=%.2f, emotion=%s)", tostring(chosenSound), tostring(playerKey), volume, pitch, sentiment.emotion or "neutral"))
        playVoiceClip(player, playerKey, chosenSound, volume, pitch)
    elseif pos and pos.x and pos.y then
        print(string.format("[SVRP Voice] Playing '%s' at pos (%s, %s) (vol=%.2f, emotion=%s)", tostring(chosenSound), tostring(pos.x), tostring(pos.y), volume, sentiment.emotion or "neutral"))
        local sq = getCell() and getCell():getGridSquare(pos.x, pos.y, pos.z or 0)
        if sq then
            pcall(function()
                getSoundManager():PlayWorldSound(chosenSound, sq, 0.0, 15.0, volume, false)
            end)
        else
            pcall(function()
                getSoundManager():PlaySound(chosenSound, false, volume)
            end)
        end
    end
end
