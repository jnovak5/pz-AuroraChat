if not isClient() then return end -- only in MP
AC = AC or {}
local sandbox = (SandboxVars and SandboxVars.AuroraChatLocal) or {}

-- Define chat types
AC.ChatTypes = {}
AC.ChatTypes["whisper"] = {
    name = "Whisper",
    command = {"whisper", "w"},
    xyRange = sandbox.RangeXYWhisper or 2,
    zRange = sandbox.RangeZWhisper or 1,
    questionPrefix = "whisper asks",
    exclamationPrefix = "whisper exclaims",
    defaultPrefix = "whispers",
    volumePrefix = "Whisper",
}
AC.ChatTypes["low"] = {
    name = "Low",
    command = {"low", "l", "quiet", "q"},
    xyRange = sandbox.RangeXYLow or 5,
    zRange = sandbox.RangeZLow or 1,
    questionPrefix = "quietly asks",
    exclamationPrefix = "quietly exclaims",
    defaultPrefix = "quietly says",
    volumePrefix = "Quiet",
}
AC.ChatTypes["say"] = {
    name = "Say",
    command = {"say", ""},
    xyRange = sandbox.RangeXYSay or 20,
    zRange = sandbox.RangeZSay or 1,
    questionPrefix = "asks",
    exclamationPrefix = "exclaims",
    defaultPrefix = "says",
    volumePrefix = "Normal",
}
AC.ChatTypes["loud"] = {
    name = "Loud",
    command = {"loud", "yell", "y"},
    xyRange = sandbox.RangeXYLoud or 40,
    zRange = sandbox.RangeZLoud or 2,
    questionPrefix = "loudly asks",
    exclamationPrefix = "loudly exclaims",
    defaultPrefix = "loudly says",
    volumePrefix = "Loud",
}
AC.ChatTypes["shout"] = {
    name = "Shout",
    command = {"shout", "s"},
    xyRange = sandbox.RangeXYShout or 60,
    zRange = sandbox.RangeZShout or 3,
    questionPrefix = "shouts",
    exclamationPrefix = "shouts",
    defaultPrefix = "shouts",
    volumePrefix = "Shout",
}

-- Define chat modifiers
AC.ChatModifiers = {}
AC.ChatModifiers["me"] = {
    command = {"me", "m"},
    type = "emote",
}
AC.ChatModifiers["env"] = {
    command = {"env", "e"},
    type = "environment",
    hideName = true,
}
AC.ChatModifiers["ooc"] = {
    command = {"ooc", "o"},
    type = "ooc",
    singleLine = true,
}
AC.ChatModifiers["alert"] = {
    command = {"alert", "a"},
    type = "alert",
    singleLine = true,
}

-- Define chat colors for each modifier type
AC.ChatColors = {}
AC.ChatColors["playerDefault"] = { r = 0.8, g = 0.8, b = 0.8 }
AC.ChatColors["emote"] = "<RGB:0.5,0.5,1>"
AC.ChatColors["emotemuted"] = "<RGB:0.3,0.3,0.8>"
AC.ChatColors["environment"] = "<RGB:0.5,1,0.5>"
AC.ChatColors["ooc"] = "<RGB:0.4,0.4,0.4>"
AC.ChatColors["alert"] = "<RGB:1,0,0>"
AC.ChatColors["text"] = "<RGB:0.8,0.8,0.8>"
AC.ChatColors["textmuted"] = "<RGB:0.5,0.5,0.5>"
AC.ChatColors["error"] = "<RGB:1,0,0>"
AC.ChatColors["info"] = "<RGB:0.4,0.4,1>"
AC.ChatColors["langprefix"] = "<RGB:0.5,0.5,0.5>"
AC.ChatColors["radiochannel"] = "<RGB:1,1,1>"
AC.ChatColors["admintag"] = "<RGB:0,1,0>"
AC.ChatColors["roll"] = "<RGB:1,0.5,0>"

AC.ChatColors["volumeprefixes"] = {}
AC.ChatColors["volumeprefixes"]["whisper"] = "<RGB:0.4,0.4,0.4>"
AC.ChatColors["volumeprefixes"]["low"] = "<RGB:0.5,0.5,0.5>"
AC.ChatColors["volumeprefixes"]["say"] = "<RGB:0.6,0.6,0.6>"
AC.ChatColors["volumeprefixes"]["loud"] = "<RGB:0.7,0.7,0.7>"
AC.ChatColors["volumeprefixes"]["shout"] = "<RGB:1,0.4,0.4>"

AC.SpecialCommands = {}
AC.SpecialCommands["/roll"] = {
    handler = "Roll",
    tabHandlers = {},
    usage = "/roll [NumSides] <LINE> /roll [NumDice]d[NumSides] <LINE> /roll [NumDice]d[NumSides]+[Bonus]",
    help = "Roll a set of dice.",
    adminOnly = false,
}
AC.SpecialCommands["/name"] = {
    handler = "SetName",
    tabHandlers = {},
    usage = "/name <name>",
    help = "Change your display name.",
    adminOnly = false,
}
AC.SpecialCommands["/color"] = {
    handler = "SetColor",
    tabHandlers = {},
    usage = "/color <color code>",
    help = "Change your display name color.",
    adminOnly = false,
}
AC.SpecialCommands["/radiosync"] = {
    handler = "RadioSync",
    tabHandlers = {"RadioFrequencies"},
    usage = "/radiosync",
    help = "Sync one radio station with General Chat.",
    adminOnly = false,
}
AC.SpecialCommands["/lang"] = {
    handler = "SetLang",
    tabHandlers = {"MyLangs"},
    usage = "/lang <language code>",
    help = "Change your current language.",
    adminOnly = false,
}
AC.SpecialCommands["/addlang"] = {
    handler = "AddLang",
    tabHandlers = {"Username", "AnyLang"},
    usage = '/addlang "User Name" <language code>',
    help = "Add a language to a players known languages.",
    adminOnly = true,
}
AC.SpecialCommands["/removelang"] = {
    handler = "RemoveLang",
    tabHandlers = {"Username", "AnyLang"},
    usage = '/removelang "User Name" <language code>',
    help = "Remove a language from a players known languages.",
    adminOnly = true,
}
AC.SpecialCommands["/focus"] = {
    handler = "Focus",
    tabHandlers = {"UsernameNotSelf"},
    usage = '/focus "User Name"',
    help = "Focus on a player. Only see messages from that player.",
    adminOnly = false,
}
AC.SpecialCommands["/unfocus"] = {
    handler = "Unfocus",
    tabHandlers = {"FocusedUsername"},
    usage = '/unfocus "User Name"',
    help = "Unfocus on a player. Stop focusing messages from that player.",
    adminOnly = false,
}
AC.SpecialCommands["/hammer"] = {
    handler = "Hammer",
    tabHandlers = {"OnOff"},
    usage = "/hammer on/off",
    help = "Toggle admin hammer.",
    adminOnly = true,
}
AC.SpecialCommands["/pm"] = {
    handler = "SendPM",
    tabHandlers = {"Username"},
    usage = '/pm "User Name" <message>',
    help = "Send a private message to a player.",
    adminOnly = false,
}
AC.SpecialCommands["/afk"] = {
    handler = "GoAFK",
    tabHandlers = {},
    usage = "/afk",
    help = "Go AFK. Will alert nearby players you are AFK.",
    adminOnly = false,
}
AC.SpecialCommands["/coords"] = {
    handler = "Coords",
    tabHandlers = {},
    usage = "/coords",
    help = "Get your current coordinates.",
    adminOnly = false,
}
AC.SpecialCommands["/growbeard"] = {
    handler = "GrowBeard",
    tabHandlers = {},
    usage = "/growbeard",
    help = "Grow a beard.",
    adminOnly = false,
}
AC.SpecialCommands["/growhair"] = {
    handler = "GrowHair",
    tabHandlers = {},
    usage = "/growhair",
    help = "Grow hair.",
    adminOnly = false,
}
AC.SpecialCommands["/sethaircolor"] = {
    handler = "SetHairColor",
    tabHandlers = {},
    usage = "/sethaircolor <color code>",
    help = "Set hair color.",
    adminOnly = false,
}
AC.SpecialCommands["/setbeardcolor"] = {
    handler = "SetBeardColor",
    tabHandlers = {},
    usage = "/setbeardcolor <color code>",
    help = "Set beard color.",
    adminOnly = false,
}
AC.SpecialCommands["/override"] = {
    handler = "Override",
    tabHandlers = {"OnOff"},
    usage = "/override on/off",
    help = "Enable or Disable the admin chat override.",
    adminOnly = true,
}
AC.SpecialCommands["/keeplast"] = {
    handler = "KeepLast",
    tabHandlers = {"OnOff"},
    usage = "/keeplast on/off",
    help = "Enable or Disable keeping the last chat type in the chat box.",
    adminOnly = false,
}
AC.SpecialCommands["/trade"] = {
    handler = "Trade",
    tabHandlers = {"UsernameNotSelf"},
    usage = '/trade "User Name"',
    help = "Trade with a player.",
    adminOnly = false,
}
AC.SpecialCommands["/med"] = {
    handler = "MedicalCheck",
    tabHandlers = {"UsernameNotSelf"},
    usage = '/med "User Name"',
    help = "Perform a medical check on a player.",
    adminOnly = false,
}
AC.SpecialCommands["/injure"] = {
    handler = "Injure",
    tabHandlers = {"BodyPart", "InjuryType"},
    usage = "/injure <body part> <injury type>",
    help = "Injure a body part.",
    adminOnly = false,
}
AC.SpecialCommands["/status"] = {
    handler = "SetStatus",
    tabHandlers = {},
    usage = "/status clear or <status message>",
    help = "Shows, sets, or clears your current status.",
    adminOnly = false,
}
AC.SpecialCommands["/private"] = {
    handler = "PrivateChat",
    tabHandlers = {"UsernameNotSelf"},
    usage = "/private <username>",
    help = "Send a private message to a player.",
    adminOnly = false,
}
AC.SpecialCommands["/stopprivate"] = {
    handler = "StopPrivateChat",
    tabHandlers = {},
    usage = "/stopprivate",
    help = "Stop a private chat",
    adminOnly = false,
}
AC.SpecialCommands["/howto"] = {
    handler = "ListAllCommands",
    tabHandlers = {},
    usage = "/howto",
    help = "Shows all the possible chat combinations for Aurora Chat.",
    adminOnly = false,
}
AC.SpecialCommands["/help"] = {
    handler = "Help",
    tabHandlers = {},
    usage = "/help <command>",
    help = "Get help on a command.",
    adminOnly = false,
}
