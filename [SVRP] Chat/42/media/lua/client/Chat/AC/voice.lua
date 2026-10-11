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
            ISChat.instance.voiceChatterButton.tooltip = "Voice Audio Chatter: Enabled (Click to Disable)"
        else
            ISChat.instance.voiceChatterButton:setImage(getTexture("media/ui/AC_voice_off.png"))
            ISChat.instance.voiceChatterButton.tooltip = "Voice Audio Chatter: Disabled (Click to Enable)"
        end
    end
end

--- Check if voice chatter is enabled for local player
function AC.Voice.IsEnabled()
    if AC.Voice.enabled ~= nil then
        return AC.Voice.enabled == true
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
            AC.Voice.enabled = (modData._AC_VoiceChatterDisabled ~= true)
            return AC.Voice.enabled
        end
    end
    AC.Voice.enabled = true
    return true
end

--- Set voice chatter enabled state for local player
function AC.Voice.SetEnabled(enabled)
    local isBool = (enabled == true)
    AC.Voice.enabled = isBool
    if AC.Meta and AC.Meta.SetVoiceChatterPref then
        AC.Meta.SetVoiceChatterPref(isBool)
    end
    local myPlayer = getPlayer()
    if myPlayer then
        local modData = myPlayer:getModData()
        if modData then
            modData._AC_VoiceChatterDisabled = not isBool
        end
        if isClient() then
            sendClientCommand(getPlayer(), "AC", "SetVoiceChatterPref", { isBool })
        end
    end
    if not isBool then
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
    -- If it's an action/emote command (/me, /do, /it, /emote, /roll, /status, /env, /event) or enclosed in asterisks *...*, there is no spoken dialogue
    local isActionChat = (chatType == "me" or chatType == "do" or chatType == "it" or chatType == "emote")
        or clean:match("^/me%s") or clean:match("^/do%s") or clean:match("^/it%s")
        or clean:match("^/roll") or clean:match("^/status") or clean:match("^/env") or clean:match("^/event")
        or clean:match("^%*.*%*$")

    if isActionChat then
        return nil -- Purely flavor / action narration, do not speak
    end

    -- 3. If it's a regular dialogue command (say, loud, shout, whisper, low, yell, mesay, meloud, etc.)
    -- Strip command prefixes and action asterisks if present
    local dialogue = clean:gsub("^/[%a%d_]+%s*", ""):gsub("^%*[%a%d%s_%p]+%*%s*", "")
    return (dialogue and dialogue:match("%S")) and dialogue or nil
end

AC.Voice.ExtractSpokenDialogue = extractSpokenDialogue

--- Deterministic string hash function to synchronize voice clip and pitch across all clients
local function hashText(str)
    if not str or str == "" then return 1 end
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 1000000007
    end
    return math.abs(hash)
end

--- Get consistent, robust player identifier key for deduplication and active sound tracking
local function getPlayerKey(player, pos, text, username)
    if username and username ~= "" then
        return "user_" .. tostring(username)
    end
    if player then
        local uName = player.getUsername and player:getUsername()
        if uName and uName ~= "" then return "user_" .. uName end
        local oId = player.getOnlineID and player:getOnlineID()
        if oId and oId >= 0 then return "oid_" .. tostring(oId) end
        local desc = player.getDescriptor and player:getDescriptor()
        if desc then
            local fname = desc.getForename and desc:getForename() or ""
            local sname = desc.getSurname and desc:getSurname() or ""
            if fname ~= "" or sname ~= "" then return "name_" .. fname .. "_" .. sname end
        end
        local pNum = player.getPlayerNum and player:getPlayerNum()
        if pNum ~= nil then return "pnum_" .. tostring(pNum) end
    end
    if pos and pos.x and pos.y then
        return string.format("pos_%d_%d", math.floor(pos.x), math.floor(pos.y))
    end
    if text and text ~= "" then
        return "txt_" .. tostring(text:sub(1, 20))
    end
    return "global_default"
end

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

--- Play a voice sound with pitch & volume modulation using a client-side 3D positional emitter
--- NOTE: Uses unattached / standalone emitters so it NEVER sends network sound packets in multiplayer.
local function playVoiceClip(player, playerKey, soundName, volume, pitch, pos)
    if not soundName then return end
    if not AC.Voice.IsEnabled() then return end

    -- 1. Check if currently playing voice clip for this character:
    -- If already playing, do not cut them off or play overlapping sounds
    if AC.Voice.ActiveSoundIds and AC.Voice.ActiveSoundIds[playerKey] then
        local prev = AC.Voice.ActiveSoundIds[playerKey]
        if prev and prev.emitter and prev.soundId then
            local isPlaying = false
            pcall(function()
                if prev.emitter.isPlaying and prev.emitter:isPlaying(prev.soundId) then
                    isPlaying = true
                end
            end)
            if isPlaying then
                return
            end
        end
        AC.Voice.ActiveSoundIds[playerKey] = nil
    end

    local px = (player and player.getX and player:getX()) or (pos and pos.x) or 0
    local py = (player and player.getY and player:getY()) or (pos and pos.y) or 0
    local pz = (player and player.getZ and player:getZ()) or (pos and pos.z) or 0

    local played = false
    local emitter = nil

    -- 2. Obtain a client-side standalone FMOD sound emitter (strictly local / non-networked)
    if getSoundManager and getSoundManager().createSoundEmitter then
        pcall(function() emitter = getSoundManager():createSoundEmitter() end)
    end
    if not emitter and IsoWorld and IsoWorld.instance and IsoWorld.instance.getFreeEmitter then
        pcall(function() emitter = IsoWorld.instance:getFreeEmitter(px, py, pz) end)
        if not emitter then
            pcall(function() emitter = IsoWorld.instance:getFreeEmitter() end)
        end
    end

    if emitter then
        pcall(function() emitter:setPos(px, py, pz) end)
        local soundId = nil
        local success = pcall(function() soundId = emitter:playSound(soundName) end)

        if success and soundId ~= nil then
            played = true
            AC.Voice.ActiveSoundIds[playerKey] = { emitter = emitter, soundId = soundId }

            if emitter.setVolume then
                pcall(function() emitter:setVolume(soundId, volume or 1.0) end)
            end
            if emitter.setPitch and pitch then
                pcall(function() emitter:setPitch(soundId, pitch) end)
            end

            -- Apply character's chosen named voice (Bob, Hank, James, Chris / Kate, Casey-Jo, Maryanne, Janine)
            local vType = AC.Voice.GetNativeVoice(player)
            local vPitch = AC.Voice.GetNativePitch(player)
            if emitter.setParameterValueByName then
                if vType ~= nil then
                    pcall(function() emitter:setParameterValueByName(soundId, "CharacterVoiceType", tonumber(vType) or 0) end)
                end
                if vPitch ~= nil then
                    pcall(function() emitter:setParameterValueByName(soundId, "CharacterVoicePitch", tonumber(vPitch) or 1) end)
                end
            end

            if emitter.tick then
                pcall(function() emitter:tick() end)
            end
        end
    end

    -- 3. Fallback ONLY if standalone emitter was not created or completely failed
    if not emitter and not played then
        local sq = (player and player.getSquare and player:getSquare()) or (getCell() and getCell():getGridSquare(px, py, pz))
        if sq and getSoundManager() and getSoundManager().PlayWorldSoundLocal then
            pcall(function()
                getSoundManager():PlayWorldSoundLocal(soundName, sq, 0.0, 15.0, volume or 1.0, false)
            end)
        elseif getSoundManager() and getSoundManager().PlaySoundLocal then
            pcall(function()
                getSoundManager():PlaySoundLocal(soundName, false, volume or 1.0)
            end)
        elseif getSoundManager() and getSoundManager().PlaySound then
            pcall(function()
                getSoundManager():PlaySound(soundName, false, volume or 1.0)
            end)
        end
    end
end

--- Play voice chatter for a player character
--- @param player IsoPlayer|nil
--- @param chatType string ("whisper", "low", "say", "loud", "shout", "mesay", "meloud", etc.)
--- @param text string
--- @param isMuffled boolean
--- @param pos table|nil
--- @param username string|nil
function AC.Voice.PlayChatVoice(player, chatType, text, isMuffled, pos, username)
    if not AC.Voice.IsEnabled() then return end

    local sandbox = SandboxVars.SVRPChatLocal or SandboxVars.SVRPChat or {}
    if sandbox.EnableVoiceChatter == false then return end

    chatType = chatType or "say"
    if chatType == "" then chatType = "say" end

    -- 0. Extract Spoken Dialogue (Filter out flavor text & action narration)
    local spokenDialogue = extractSpokenDialogue(text, chatType)
    if not spokenDialogue or spokenDialogue == "" then
        return -- No spoken words in this message (e.g. pure /me body language or silent action)
    end

    local playerKey = getPlayerKey(player, pos, spokenDialogue, username)
    local now = getTimestampMs()

    -- 1. Check if speaker is already playing audio (prevents overlapping clips)
    if AC.Voice.ActiveSoundIds and AC.Voice.ActiveSoundIds[playerKey] then
        local prev = AC.Voice.ActiveSoundIds[playerKey]
        if prev and prev.emitter and prev.soundId then
            local isPlaying = false
            pcall(function()
                if prev.emitter.isPlaying and prev.emitter:isPlaying(prev.soundId) then
                    isPlaying = true
                end
            end)
            if isPlaying then
                return
            end
        end
    end

    -- 2. Per-Speaker Cooldown (4.0s): Guarantees long messages, multiple chunks, or sentences in the same paragraph only trigger ONE voice line
    local lastTime = AC.Voice.LastPlayTimes[playerKey] or 0
    if (now - lastTime) < 4000 then
        return
    end

    -- 3. Message Deduplication (6.0s window per message content)
    AC.Voice.RecentSpoken = AC.Voice.RecentSpoken or {}
    local msgKey = playerKey .. "::" .. spokenDialogue:sub(1, 40)
    local lastMsgTime = AC.Voice.RecentSpoken[msgKey] or 0
    if (now - lastMsgTime) < 6000 then
        return
    end

    AC.Voice.RecentSpoken[msgKey] = now
    AC.Voice.LastPlayTimes[playerKey] = now
    AC.Voice.LastMessageTexts = AC.Voice.LastMessageTexts or {}
    AC.Voice.LastMessageTexts[playerKey] = spokenDialogue

    local isFemale = player and player.isFemale and player:isFemale()
    local pools = isFemale and femaleVoicePools or maleVoicePools
    local pool = pools[chatType] or pools.say

    -- 3. Execute Sentiment & Context Analysis on the extracted spoken dialogue
    local sentiment = analyzeSentiment(spokenDialogue, player, chatType)
    local seed = hashText(spokenDialogue)

    local chosenSound = nil
    if sentiment.overrideSound == "cmon" then
        local cmonPool = isFemale and femaleCmonPool or maleCmonPool
        chosenSound = cmonPool[(seed % #cmonPool) + 1]
    elseif sentiment.overrideSound == "shout_hey" then
        local heyPool = isFemale and femaleShoutHeyPool or maleShoutHeyPool
        chosenSound = heyPool[(seed % #heyPool) + 1]
    elseif sentiment.overrideSound == "soft_hey" then
        local heyPool = isFemale and femaleSoftHeyPool or maleSoftHeyPool
        chosenSound = heyPool[(seed % #heyPool) + 1]
    elseif sentiment.overrideSound == "sad" then
        local sadPool = isFemale and femaleSadPool or maleSadPool
        chosenSound = sadPool[(seed % #sadPool) + 1]
    elseif sentiment.overrideSound == "relief" then
        local reliefPool = isFemale and femaleReliefPool or maleReliefPool
        chosenSound = reliefPool[(seed % #reliefPool) + 1]
    elseif sentiment.overrideSound == "danger" then
        local dangerPool = isFemale and femaleDangerPool or maleDangerPool
        chosenSound = dangerPool[(seed % #dangerPool) + 1]
    elseif sentiment.overrideSound == "stealth" then
        local stealthPool = isFemale and femaleStealthPool or maleStealthPool
        chosenSound = stealthPool[(seed % #stealthPool) + 1]
    elseif sentiment.overrideSound == "cough" then
        local coughPool = isFemale and femaleCoughPool or maleCoughPool
        chosenSound = coughPool[(seed % #coughPool) + 1]
    elseif pool and #pool > 0 then
        chosenSound = pool[(seed % #pool) + 1]
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

    -- 5. Calculate Final Pitch (Deterministic Organic Variation + Sentiment Modulation)
    local pitchSeed = hashText(spokenDialogue .. "_pitch")
    local basePitch = 0.96 + ((pitchSeed % 8) / 100)
    local pitch = math.max(0.75, math.min(1.35, basePitch + (sentiment.pitchMod or 0.0)))

    print(string.format("[SVRP Voice] Playing '%s' for '%s' (vol=%.2f, pitch=%.2f, emotion=%s)", tostring(chosenSound), tostring(playerKey), volume, pitch, sentiment.emotion or "neutral"))
    playVoiceClip(player, playerKey, chosenSound, volume, pitch, pos)
end
