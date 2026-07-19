if not isClient() then return end -- only in MP
AC = AC or {}

-- Define possible languages
AC.Languages = {}
AC.Languages["en"] = { name = "English", canPartiallyUnderstand = {} }
AC.Languages["asl"] = { name = "American Sign Language", canPartiallyUnderstand = {} }
AC.Languages["es"] = { name = "Spanish", canPartiallyUnderstand = {"pt"} }
AC.Languages["fr"] = { name = "French", canPartiallyUnderstand = {} }
AC.Languages["de"] = { name = "German", canPartiallyUnderstand = {"nl"} }
AC.Languages["it"] = { name = "Italian", canPartiallyUnderstand = {"es", "pt", "ro"} }
AC.Languages["ru"] = { name = "Russian", canPartiallyUnderstand = {"uk", "bg"} }
AC.Languages["zh"] = { name = "Chinese", canPartiallyUnderstand = {} }
AC.Languages["ja"] = { name = "Japanese", canPartiallyUnderstand = {} }
AC.Languages["ko"] = { name = "Korean", canPartiallyUnderstand = {} }
AC.Languages["pt"] = { name = "Portuguese", canPartiallyUnderstand = {"es"} }
AC.Languages["pl"] = { name = "Polish", canPartiallyUnderstand = {} }
AC.Languages["sv"] = { name = "Swedish", canPartiallyUnderstand = {"no", "da"} }
AC.Languages["nl"] = { name = "Dutch", canPartiallyUnderstand = {"de", "af"} }
AC.Languages["cs"] = { name = "Czech", canPartiallyUnderstand = {"sk"} }
AC.Languages["hu"] = { name = "Hungarian", canPartiallyUnderstand = {} }
AC.Languages["fi"] = { name = "Finnish", canPartiallyUnderstand = {} }
AC.Languages["tr"] = { name = "Turkish", canPartiallyUnderstand = {} }
AC.Languages["no"] = { name = "Norwegian", canPartiallyUnderstand = {"sv", "da"} }
AC.Languages["da"] = { name = "Danish", canPartiallyUnderstand = {"sv", "no"} }
AC.Languages["ro"] = { name = "Romanian", canPartiallyUnderstand = {"it"} }
AC.Languages["bg"] = { name = "Bulgarian", canPartiallyUnderstand = {"ru", "sr", "mk"} }
AC.Languages["el"] = { name = "Greek", canPartiallyUnderstand = {} }
AC.Languages["uk"] = { name = "Ukrainian", canPartiallyUnderstand = {"ru"} }
AC.Languages["sk"] = { name = "Slovak", canPartiallyUnderstand = {"cs"} }
AC.Languages["hr"] = { name = "Croatian", canPartiallyUnderstand = {"sr"} }
AC.Languages["sr"] = { name = "Serbian", canPartiallyUnderstand = {"hr", "bg", "mk"} }
AC.Languages["sl"] = { name = "Slovenian", canPartiallyUnderstand = {} }
AC.Languages["lt"] = { name = "Lithuanian", canPartiallyUnderstand = {} }
AC.Languages["lv"] = { name = "Latvian", canPartiallyUnderstand = {} }
AC.Languages["et"] = { name = "Estonian", canPartiallyUnderstand = {} }
AC.Languages["ar"] = { name = "Arabic", canPartiallyUnderstand = {} }
AC.Languages["he"] = { name = "Hebrew", canPartiallyUnderstand = {} }
AC.Languages["th"] = { name = "Thai", canPartiallyUnderstand = {} }
AC.Languages["vi"] = { name = "Vietnamese", canPartiallyUnderstand = {} }
AC.Languages["id"] = { name = "Indonesian", canPartiallyUnderstand = {"ms"} }
AC.Languages["ms"] = { name = "Malay", canPartiallyUnderstand = {"id"} }
AC.Languages["hi"] = { name = "Hindi", canPartiallyUnderstand = {"ur"} }
AC.Languages["bn"] = { name = "Bengali", canPartiallyUnderstand = {} }
AC.Languages["fa"] = { name = "Persian", canPartiallyUnderstand = {} }
AC.Languages["ur"] = { name = "Urdu", canPartiallyUnderstand = {"hi"} }
AC.Languages["sw"] = { name = "Swahili", canPartiallyUnderstand = {} }
AC.Languages["af"] = { name = "Afrikaans", canPartiallyUnderstand = {"nl"} }
AC.Languages["eo"] = { name = "Esperanto", canPartiallyUnderstand = {} }
AC.Languages["is"] = { name = "Icelandic", canPartiallyUnderstand = {} }
AC.Languages["cy"] = { name = "Welsh", canPartiallyUnderstand = {} }
AC.Languages["yi"] = { name = "Yiddish", canPartiallyUnderstand = {} }
AC.Languages["la"] = { name = "Latin", canPartiallyUnderstand = {} }
AC.Languages["ga"] = { name = "Gaelic", canPartiallyUnderstand = {} }
AC.Languages["hw"] = { name = "Hawaiian", canPartiallyUnderstand = {} }
AC.Languages["nt"] = { name = "Noren Tala", canPartiallyUnderstand = {} }
AC.Languages["fil"] = { name = "Filipino", canPartiallyUnderstand = {} }
