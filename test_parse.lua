local AC = {}
AC.Parsing = {}
AC.ChatColors = { emotes = { text = '<RGB:0.8,0.8,0.8>' } }
AC.Meta = {
    GetEmoteColor = function() return AC.ChatColors.emotes.text end
}

function AC.Parsing.ParseModifier(text, emoteColor, lang, chatType)
    local quoteIndexStart = text:find('%"')
    local quoteIndexEnd = text:find('%"', (quoteIndexStart or 0) + 1)
    
    if quoteIndexStart and quoteIndexEnd then
        local firstPart = text:sub(1, quoteIndexStart)
        local quotedPart = text:sub(quoteIndexStart + 1, quoteIndexEnd - 1)
        local lastPart = text:sub(quoteIndexEnd)
        
        quotedPart = quotedPart:gsub("%*(.-)%*", function(insideAsterisks)
            return '*\"' .. emoteColor .. insideAsterisks .. ' <RGB:1,1,1>\"*'
        end)
        
        return firstPart .. quotedPart .. lastPart
    end
    return text
end

print(AC.Parsing.ParseModifier('User says \"Hello *smiles* there\"', '<RGB:0.8,0.8,0.8>', 'en', 'say'))
