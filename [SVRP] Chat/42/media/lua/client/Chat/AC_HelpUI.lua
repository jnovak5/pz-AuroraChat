require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISRichTextPanel"

AC_HelpUI = ISPanel:derive("AC_HelpUI")

local function buildPages(isStaff)
    local pages = {}

    pages[1] = {
        title = "Welcome",
        sections = {
            {
                header = "Welcome to [SVRP] Chat!",
                text = "Thank you for playing on the server and using <SPACE><RGB:0.7,0.85,1.0>[SVRP] Chat!\n\n<RGB:0.85,0.85,0.85>This mod replaces the default chat with a feature-rich roleplay toolkit designed to make your experience more immersive and fun.\n\nThis guide will walk you through everything you need to know."
            },
            {
                header = "Quick Start",
                text = "Look at the top-right of your chat box. You will see a row of small icon buttons.\n\n" ..
                       " <IMAGE:media/ui/AC_info.png,16,16> <SPACE><RGB:0.85,0.85,0.85>This Help Guide\n" ..
                       " <IMAGE:media/ui/AC_dice.png,16,16> <SPACE><RGB:0.85,0.85,0.85>Combat and Dice Roller\n" ..
                       " <IMAGE:media/ui/AC_calendar.png,16,16> <SPACE><RGB:0.85,0.85,0.85>In-Game Calendar\n" ..
                       " <IMAGE:media/ui/AC_range.png,16,16> <SPACE><RGB:0.85,0.85,0.85>Chat Range Circles\n" ..
                       " <IMAGE:media/ui/AC_voice_on.png,16,16> <SPACE><RGB:0.85,0.85,0.85>Voice Audio Toggle\n" ..
                       " <IMAGE:media/ui/AC_typing_on.png,16,16> <SPACE><RGB:0.85,0.85,0.85>Typing Indicator Toggle\n" ..
                       " <IMAGE:media/ui/AC_user.png,16,16> <SPACE><RGB:0.85,0.85,0.85>Roleplay and Character Actions\n" ..
                       " <IMAGE:media/ui/inventoryPanes/Button_Gear.png,16,16> <SPACE><RGB:0.85,0.85,0.85>Chat Settings and Preferences\n\n" ..
                       " <RGB:0.85,0.85,0.85>Use the PREVIOUS and NEXT buttons below to navigate the guide."
            }
        }
    }

    pages[2] = {
        title = "Chat Basics",
        sections = {
            {
                header = "Speaking In-Character",
                text = "Just type and press <SPACE><RGB:0.7,0.85,1.0>Enter <SPACE><RGB:0.85,0.85,0.85>to speak normally at <SPACE><RGB:1.0,0.9,0.6>Say <SPACE><RGB:0.85,0.85,0.85>range. Your speech appears above your head for nearby players to see."
            },
            {
                header = "Volume Prefixes",
                text = "You can change how far your voice travels by using volume prefixes at the start of your message:\n\n" ..
                       " <RGB:0.7,0.85,1.0>/w <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>= Whisper (very short range)\n" ..
                       " <RGB:0.7,0.85,1.0>/l <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>= Low voice (short range)\n" ..
                       " <RGB:0.7,0.85,1.0>/say <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>= Say (normal speaking range)\n" ..
                       " <RGB:0.7,0.85,1.0>/lo <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>= Loud voice (extended range)\n" ..
                       " <RGB:0.7,0.85,1.0>/s <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>= Shout (long range, everyone nearby)\n\n" ..
                       " <RGB:0.9,0.7,0.7>Example: <SPACE><RGB:0.7,0.85,1.0>/w <SPACE><RGB:1.0,1.0,1.0>I think they heard us."
            },
            {
                header = "Radio Frequencies",
                text = "To speak over a radio, simply make sure your radio is <SPACE><RGB:0.6,0.9,0.6>powered on <SPACE><RGB:0.85,0.85,0.85>and <SPACE><RGB:0.6,0.9,0.6>unmuted <SPACE><RGB:0.85,0.85,0.85>in your inventory or hands.\n\n" ..
                       "Once your radio is active, all you need to do is talk normally. Your speech will automatically be broadcast over your active radio frequency to anyone listening.\n\n" ..
                       "You <SPACE><RGB:1.0,0.6,0.6>do not <SPACE><RGB:0.85,0.85,0.85>need to use any special chat commands to broadcast."
            },
            {
                header = "Chat Tabs",
                text = " <RGB:0.7,0.85,1.0>General <SPACE><RGB:0.85,0.85,0.85>- Main in-character speech channel\n" ..
                       " <RGB:0.7,0.85,1.0>Focused <SPACE><RGB:0.85,0.85,0.85>- Only messages from players you are focusing on\n" ..
                       " <RGB:0.7,0.85,1.0>Private <SPACE><RGB:0.85,0.85,0.85>- Direct messages (DMs) between players\n" ..
                       " <RGB:0.7,0.85,1.0>Radio <SPACE><RGB:0.85,0.85,0.85>- Radio frequency transmissions\n" ..
                       " <RGB:0.7,0.85,1.0>OOC <SPACE><RGB:0.85,0.85,0.85>- Out-of-character chat"
            },
            {
                header = "Useful Commands",
                text = " <RGB:0.7,0.85,1.0>/me <SPACE><RGB:1.0,1.0,1.0>action <SPACE><RGB:0.85,0.85,0.85>= Emote an action.\n <RGB:0.9,0.7,0.7>Example: <SPACE><RGB:0.7,0.85,1.0>/me <SPACE><RGB:1.0,1.0,1.0>unlocks the door.\n\n" ..
                       " <RGB:0.7,0.85,1.0>/do <SPACE><RGB:1.0,1.0,1.0>description <SPACE><RGB:0.85,0.85,0.85>= Describe something.\n <RGB:0.9,0.7,0.7>Example: <SPACE><RGB:0.7,0.85,1.0>/do <SPACE><RGB:1.0,1.0,1.0>The door is jammed.\n\n" ..
                       " <RGB:0.7,0.85,1.0>/pm <SPACE><RGB:1.0,1.0,1.0>username message <SPACE><RGB:0.85,0.85,0.85>= Private message.\n <RGB:0.9,0.7,0.7>Example: <SPACE><RGB:0.7,0.85,1.0>/pm <SPACE><RGB:1.0,1.0,1.0>Bob Are you there?\n\n" ..
                       " <RGB:0.7,0.85,1.0>/ooc <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>= Speak out-of-character.\n <RGB:0.9,0.7,0.7>Example: <SPACE><RGB:0.7,0.85,1.0>/ooc <SPACE><RGB:1.0,1.0,1.0>brb getting water."
            },
            {
                header = "Advanced Roleplay (Action + Speech)",
                text = "You can combine physical actions and spoken dialogue in a single message by using the <SPACE><RGB:0.7,0.85,1.0>/me <SPACE><RGB:0.85,0.85,0.85>command and wrapping your speech in quotes.\n\n" ..
                       " <RGB:0.9,0.7,0.7>Example:\n" ..
                       " <RGB:0.7,0.85,1.0>/me <SPACE><RGB:1.0,1.0,1.0>reaches into his pocket and slowly pulls out a weathered Cigarette Pack. Tearing off the top as it dangled by a thread, tossing it onto the puddle besides him from the recent storm. <SPACE><RGB:1.0,0.9,0.6>\"Never a better time then now. . .\" <SPACE><RGB:1.0,1.0,1.0>Joshua mentioned as he reached for the one of the final two cigarettes in the package before putting it to his lips and lighting it behind his hands to prevent the wind from stopping the flame. Joshua would take a deep inhale and slowly exhale. <SPACE><RGB:1.0,0.9,0.6>\"Let's get this day started.\""
            }
        }
    }

    pages[3] = {
        title = "Range/Focus",
        sections = {
            {
                header = "Range Circles",
                text = "Click the Range icon button (circle icon) in the chat bar to temporarily show colored range circles on the ground around you.\n\n" ..
                       " <RGB:0.7,0.85,1.0>Inner <SPACE><RGB:1.0,1.0,1.0>circle <SPACE><RGB:0.85,0.85,0.85>= Whisper range\n" ..
                       " <RGB:0.7,0.85,1.0>Middle <SPACE><RGB:1.0,1.0,1.0>circle <SPACE><RGB:0.85,0.85,0.85>= Low and Say range\n" ..
                       " <RGB:0.7,0.85,1.0>Outer <SPACE><RGB:1.0,1.0,1.0>circle <SPACE><RGB:0.85,0.85,0.85>= Loud and Shout range\n\n" ..
                       "Circles fade automatically after a few seconds."
            },
            {
                header = "Focus System",
                text = "The Focused tab only shows messages from players you have focused. Great for tracking a specific scene in a crowded area.\n\n" ..
                       "To Focus on a player:\n" ..
                       " 1. Click the User Icon button in the chat bar\n" ..
                       " 2. Go to <SPACE><RGB:0.7,0.85,1.0>RP Actions <SPACE><RGB:0.85,0.85,0.85>then <SPACE><RGB:0.7,0.85,1.0>Focus On <SPACE><RGB:0.85,0.85,0.85>then pick a player.\n\n" ..
                       "To remove focus, use <SPACE><RGB:0.7,0.85,1.0>RP Actions <SPACE><RGB:0.85,0.85,0.85>then <SPACE><RGB:0.7,0.85,1.0>Unfocus From<RGB:0.85,0.85,0.85>.\nYou can focus on multiple players at the same time."
            }
        }
    }

    pages[4] = {
        title = "Voice Audio",
        sections = {
            {
                header = "Voice Audio Chatter",
                text = "When enabled, your character plays in-game voice audio each time you send a message. Nearby players will also hear it.\n\n" ..
                       "Toggle on or off by clicking the Speaker icon in the chat bar."
            },
            {
                header = "Native Voice Styles",
                text = "Choose which in-engine voice profile your character uses.\n\n" ..
                       "Male Voices:\n" ..
                       " <RGB:0.7,0.85,1.0>Bob <SPACE><RGB:0.85,0.85,0.85>(Deep and Steady)\n" ..
                       " <RGB:0.7,0.85,1.0>Hank <SPACE><RGB:0.85,0.85,0.85>(Gruff and Rough)\n" ..
                       " <RGB:0.7,0.85,1.0>James <SPACE><RGB:0.85,0.85,0.85>(Youthful)\n" ..
                       " <RGB:0.7,0.85,1.0>Chris <SPACE><RGB:0.85,0.85,0.85>(Classic Survivor)\n\n" ..
                       "Female Voices:\n" ..
                       " <RGB:0.7,0.85,1.0>Kate <SPACE><RGB:0.85,0.85,0.85>(Classic and Clear)\n" ..
                       " <RGB:0.7,0.85,1.0>Casey-Jo <SPACE><RGB:0.85,0.85,0.85>(Youthful)\n" ..
                       " <RGB:0.7,0.85,1.0>Maryanne <SPACE><RGB:0.85,0.85,0.85>(Warm)\n" ..
                       " <RGB:0.7,0.85,1.0>Janine <SPACE><RGB:0.85,0.85,0.85>(Gravelly and Tough)"
            },
            {
                header = "Voice Pitch",
                text = " <RGB:0.7,0.85,1.0>Deep / Low <SPACE><RGB:1.0,1.0,1.0>| <SPACE><RGB:0.7,0.85,1.0>Standard / Natural <SPACE><RGB:1.0,1.0,1.0>| <SPACE><RGB:0.7,0.85,1.0>High / Bright <RGB:0.85,0.85,0.85>\n\n" ..
                       "To change voice: User Icon > Character > Character Voice Style\n" ..
                       "To change pitch: User Icon > Character > Character Voice Pitch"
            }
        }
    }

    pages[5] = {
        title = "RP/Character",
        sections = {
            {
                header = "Combat and Dice Roller",
                text = "Opens the full Combat Manager window. Roll any type of dice: d4, d6, d8, d10, d12, d20, d100. Results are posted in chat.\n\n" ..
                       "Manage initiative order and turn-based RP combat."
            },
            {
                header = "RP Actions",
                text = " <RGB:0.7,0.85,1.0>Focus On and Unfocus From <SPACE><RGB:0.85,0.85,0.85>- Filter the Focused chat tab\n" ..
                       " <RGB:0.7,0.85,1.0>Trade With <SPACE><RGB:0.85,0.85,0.85>- Open a trade panel with a nearby player\n" ..
                       " <RGB:0.7,0.85,1.0>Medical Check <SPACE><RGB:0.85,0.85,0.85>- View a nearby player's visible injuries"
            },
            {
                header = "Character Options",
                text = " <RGB:0.7,0.85,1.0>Character Voice Style <SPACE><RGB:0.85,0.85,0.85>- Pick your character's in-engine voice\n" ..
                       " <RGB:0.7,0.85,1.0>Character Voice Pitch <SPACE><RGB:0.85,0.85,0.85>- Deep, Standard, or High pitch setting\n" ..
                       " <RGB:0.7,0.85,1.0>Trim Beard and Shave <SPACE><RGB:0.85,0.85,0.85>- Change your character's facial hair look\n" ..
                       " <RGB:0.7,0.85,1.0>Add Injury (RP only) <SPACE><RGB:0.85,0.85,0.85>- Simulate an injury on your character"
            }
        }
    }

    pages[6] = {
        title = "Settings",
        sections = {
            {
                header = "Chat Colors",
                text = "Customize the color of your name and speech text in chat.\n" ..
                       "Enter a hex code like <SPACE><RGB:0.7,0.85,1.0>#FF8800 <SPACE><RGB:0.85,0.85,0.85>or leave blank to reset to default."
            },
            {
                header = "Chatbox Color Scheme",
                text = "Change the overall theme of the chat window background:\n\n" ..
                       " <RGB:0.7,0.85,1.0>Midnight Slate <SPACE><RGB:0.85,0.85,0.85>- Modern dark blue-grey (default theme)\n" ..
                       " <RGB:0.7,0.85,1.0>Charcoal Noir <SPACE><RGB:0.85,0.85,0.85>- Classic sleek stealth look\n" ..
                       " <RGB:0.7,0.85,1.0>Warm Amber <SPACE><RGB:0.85,0.85,0.85>- Post-apocalypse warm amber tones"
            },
            {
                header = "Unread Tab Indicators",
                text = "Customize the color shown on tabs with unread messages.\nEnable or disable the blinking animation on unread tabs."
            },
            {
                header = "Other Options",
                text = " <RGB:0.7,0.85,1.0>Keep Last Chat <SPACE><RGB:0.85,0.85,0.85>- Restores your last typed message when you focus\n" ..
                       " <RGB:0.7,0.85,1.0>Overhead Typing <SPACE><RGB:0.85,0.85,0.85>- Toggle the overhead dot indicator when you type\n" ..
                       " <RGB:0.7,0.85,1.0>Voice Chatter <SPACE><RGB:0.85,0.85,0.85>- Toggle voice audio playback on or off"
            }
        }
    }

    pages[7] = {
        title = "Calendar",
        sections = {
            {
                header = "What It Shows",
                text = "Click the Calendar icon button to open the Calendar window.\n\n" ..
                       " - The current in-game month, day, and year\n" ..
                       " - The current real-world date for cross-reference\n" ..
                       " - The current in-game season\n" ..
                       " - Recognized US holidays where applicable\n\n" ..
                       "Navigate between months using the arrow buttons in the calendar."
            },
            {
                header = "Why Use It",
                text = " - Track in-game time to build consistent RP story arcs\n" ..
                       " - Schedule roleplay events with other players\n" ..
                       " - Know the season for weather and environmental roleplay\n" ..
                       " - Record dates of significant in-character events\n\n" ..
                       "Tip: The calendar refreshes automatically each time you open it."
            }
        }
    }

    if isStaff then
        pages[8] = {
            title = "Admin Tools",
            isAdmin = true,
            sections = {
                {
                    header = "SVRP Chat Admin Menu",
                    text = "Click the Gear icon. At the bottom you will see SVRP Chat Admin.\n\n" ..
                           " <RGB:1.0,0.6,0.6>Admin Hammer <SPACE><RGB:0.85,0.85,0.85>- Toggle moderation mode for instant actions\n" ..
                           " <RGB:1.0,0.6,0.6>Admin Chat Override <SPACE><RGB:0.85,0.85,0.85>- Bypass all RP chat restrictions\n" ..
                           " <RGB:1.0,0.6,0.6>Hide Player Overheads <SPACE><RGB:0.85,0.85,0.85>- Remove overhead speech text for all players\n" ..
                           " <RGB:1.0,0.6,0.6>Add Language <SPACE><RGB:0.85,0.85,0.85>- Grant a player access to a specific language\n" ..
                           " <RGB:1.0,0.6,0.6>Remove Language <SPACE><RGB:0.85,0.85,0.85>- Revoke a player language access"
                },
                {
                    header = "Admin Chat Commands",
                    text = " <RGB:1.0,0.7,0.4>/a <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>- Broadcast in Admin Chat (staff only channel)\n" ..
                           " <RGB:1.0,0.7,0.4>/server <SPACE><RGB:1.0,1.0,1.0>message <SPACE><RGB:0.85,0.85,0.85>- Server-wide announcement to all players"
                },
                {
                    header = "Important Notes",
                    text = "Admin channels are completely invisible to non-staff players.\n" ..
                           "The Gear icon menu auto-removes Admin entries for regular players.\n\n" ..
                           "Admin Override removes RP range and format restrictions entirely, allowing you to moderate without RP rules applying to you."
                }
            }
        }
    end

    return pages
end

function AC_HelpUI:initialise()
    ISPanel.initialise(self)
    local myPlayer = getPlayer()
    self.isStaff = AC_Utils and AC_Utils.isStaff and AC_Utils.isStaff(myPlayer)
    self.pages = buildPages(self.isStaff)
    self.currentPage = 1
    self:buildUI()
end

function AC_HelpUI:buildUI()
    self.backgroundColor = {r=0.07, g=0.07, b=0.10, a=0.97}
    self.borderColor     = {r=0.25, g=0.25, b=0.35, a=1.0}

    local W = self.width
    local H = self.height

    self.tabPanel = ISPanel:new(0, 36, W, 28)
    self.tabPanel:initialise()
    self.tabPanel.backgroundColor = {r=0.04, g=0.04, b=0.07, a=1.0}
    self.tabPanel.borderColor = {r=0, g=0, b=0, a=0}
    self:addChild(self.tabPanel)

    self.scrollPanel = ISPanel:new(10, 74, W - 20, H - 120)
    self.scrollPanel:initialise()
    self.scrollPanel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.scrollPanel.borderColor = {r=0, g=0, b=0, a=0}
    self.scrollPanel:addScrollBars(true)
    self.scrollPanel:setScrollChildren(true)
    
    self.scrollPanel.prerender = function(this)
        this:setStencilRect(0, 0, this.width, this.height)
        ISPanel.prerender(this)
    end
    self.scrollPanel.render = function(this)
        ISPanel.render(this)
        this:clearStencilRect()
    end

    self:addChild(self.scrollPanel)

    local btnW, btnH = 100, 24
    local navY = H - 36

    self.prevBtn = ISButton:new(18, navY, btnW, btnH, "< Previous", self, AC_HelpUI.onPrev)
    self.prevBtn:initialise()
    self.prevBtn:instantiate()
    self.prevBtn.borderColor     = {r=0.3, g=0.3, b=0.4, a=1.0}
    self.prevBtn.backgroundColor = {r=0.12, g=0.12, b=0.18, a=1.0}
    self.prevBtn.textColor       = {r=0.8, g=0.8, b=0.9, a=1.0}
    self:addChild(self.prevBtn)

    self.closeBtn = ISButton:new(W/2 - 50, navY, 100, btnH, "Close", self, AC_HelpUI.close)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.borderColor     = {r=0.35, g=0.15, b=0.15, a=1.0}
    self.closeBtn.backgroundColor = {r=0.2, g=0.08, b=0.08, a=1.0}
    self.closeBtn.textColor       = {r=1.0, g=0.6, b=0.6, a=1.0}
    self:addChild(self.closeBtn)

    self.nextBtn = ISButton:new(W - 18 - btnW, navY, btnW, btnH, "Next >", self, AC_HelpUI.onNext)
    self.nextBtn:initialise()
    self.nextBtn:instantiate()
    self.nextBtn.borderColor     = {r=0.3, g=0.3, b=0.4, a=1.0}
    self.nextBtn.backgroundColor = {r=0.12, g=0.12, b=0.18, a=1.0}
    self.nextBtn.textColor       = {r=0.8, g=0.8, b=0.9, a=1.0}
    self:addChild(self.nextBtn)

    self.tabButtons = {}
    self:rebuildTabs()
    self:updatePage()
end

function AC_HelpUI:rebuildTabs()
    for _, btn in ipairs(self.tabButtons) do
        self.tabPanel:removeChild(btn)
    end
    self.tabButtons = {}
    local totalPages = #self.pages
    local tabW = math.floor((self.width - 4) / totalPages)
    for i, page in ipairs(self.pages) do
        local idx = i
        local btn = ISButton:new((idx-1)*tabW + 2, 3, tabW - 2, 22, page.title, self, function() self:goToPage(idx) end)
        btn:initialise()
        btn:instantiate()
        btn.font = UIFont.Small
        btn.borderColor     = {r=0.2, g=0.2, b=0.3, a=1.0}
        btn.backgroundColor = {r=0.08, g=0.08, b=0.12, a=1.0}
        btn.textColor       = {r=0.7, g=0.7, b=0.8, a=1.0}
        if page.isAdmin then
            btn.borderColor     = {r=0.5, g=0.1, b=0.1, a=1.0}
            btn.backgroundColor = {r=0.15, g=0.04, b=0.04, a=1.0}
            btn.textColor       = {r=1.0, g=0.5, b=0.5, a=1.0}
        end
        self.tabPanel:addChild(btn)
        self.tabButtons[i] = btn
    end
end

function AC_HelpUI:updatePage()
    local totalPages = #self.pages
    for i, btn in ipairs(self.tabButtons) do
        local page = self.pages[i]
        if i == self.currentPage then
            btn.backgroundColor = page and page.isAdmin and {r=0.35, g=0.05, b=0.05, a=1.0} or {r=0.15, g=0.18, b=0.35, a=1.0}
            btn.borderColor     = page and page.isAdmin and {r=0.8, g=0.2, b=0.2, a=1.0}  or {r=0.4, g=0.5, b=0.8, a=1.0}
            btn.textColor       = {r=0.95, g=0.95, b=1.0, a=1.0}
        else
            btn.backgroundColor = page and page.isAdmin and {r=0.15, g=0.04, b=0.04, a=1.0} or {r=0.08, g=0.08, b=0.12, a=1.0}
            btn.borderColor     = page and page.isAdmin and {r=0.5, g=0.1, b=0.1, a=1.0}  or {r=0.2, g=0.2, b=0.3, a=1.0}
            btn.textColor       = page and page.isAdmin and {r=1.0, g=0.5, b=0.5, a=1.0}  or {r=0.7, g=0.7, b=0.8, a=1.0}
        end
    end
    self.prevBtn.textColor = self.currentPage > 1 and {r=0.8,g=0.8,b=0.9,a=1.0} or {r=0.35,g=0.35,b=0.4,a=1.0}
    self.nextBtn.textColor = self.currentPage < totalPages and {r=0.8,g=0.8,b=0.9,a=1.0} or {r=0.35,g=0.35,b=0.4,a=1.0}
    self.pageCounterText = "Page " .. self.currentPage .. " of " .. totalPages

    self.scrollPanel:clearChildren()
    self.scrollPanel:addScrollBars(false)
    self.sections = {}
    local page = self.pages[self.currentPage]

    for i, sec in ipairs(page.sections) do
        local btn = ISButton:new(5, 0, self.scrollPanel.width - 25, 26, "", self, function()
            sec.collapsed = not sec.collapsed
            self:layoutContent()
        end)
        btn:initialise()
        btn:instantiate()
        btn.backgroundColor = {r=0.15, g=0.15, b=0.20, a=1.0}
        btn.borderColor = {r=0.25, g=0.3, b=0.4, a=1.0}
        btn.textColor = {r=1.0, g=0.85, b=0.3, a=1.0}
        btn.font = UIFont.Medium

        local textPanel = ISRichTextPanel:new(10, 0, self.scrollPanel.width - 35, 10)
        textPanel:initialise()
        textPanel.background = false
        textPanel:setMargins(10, 10, 10, 10)
        textPanel.autosetheight = true
        textPanel.clip = true
        textPanel.text = "<RGB:0.85,0.85,0.85>" .. sec.text:gsub("\n", " <LINE> ")
        textPanel:paginate()

        if sec.collapsed == nil then sec.collapsed = false end

        self.scrollPanel:addChild(btn)
        self.scrollPanel:addChild(textPanel)
        table.insert(self.sections, {btn = btn, textPanel = textPanel, secData = sec})
    end

    self:layoutContent()
end

function AC_HelpUI:layoutContent()
    local y = 5
    for _, s in ipairs(self.sections) do
        s.btn:setY(y)
        if s.secData.collapsed then
            s.btn.title = "[+]  " .. s.secData.header
            s.textPanel:setVisible(false)
            y = y + s.btn.height + 5
        else
            s.btn.title = "[-]  " .. s.secData.header
            s.textPanel:setVisible(true)
            s.textPanel:setY(y + s.btn.height)
            y = y + s.btn.height + s.textPanel.height + 10
        end
    end
    self.scrollPanel:setScrollHeight(y + 60)
end

function AC_HelpUI:goToPage(n)
    self.currentPage = math.max(1, math.min(n, #self.pages))
    self.scrollPanel:setYScroll(0)
    self:updatePage()
end

function AC_HelpUI:onPrev()
    if self.currentPage > 1 then self:goToPage(self.currentPage - 1) end
end

function AC_HelpUI:onNext()
    if self.currentPage < #self.pages then self:goToPage(self.currentPage + 1) end
end

function AC_HelpUI:prerender()
    ISPanel.prerender(self)
    local W, H = self.width, self.height

    self:drawRect(0, 0, W, 36, 1.0, 0.10, 0.10, 0.16)
    self:drawRectBorder(0, 0, W, 36, 1.0, 0.3, 0.3, 0.5)
    self:drawTextCentre("[SVRP] Chat  -  Help and Features Guide", W/2, 10, 1.0, 1.0, 1.0, 1.0, UIFont.Medium)

    self:drawRect(18, 66, W-36, 1, 0.8, 0.25, 0.25, 0.4)

    if self.pageCounterText then
        self:drawTextCentre(self.pageCounterText, W/2, H - 40, 0.4, 0.4, 0.55, 1.0, UIFont.Small)
    end

    self:drawRect(0, H - 44, W, 1, 0.8, 0.2, 0.2, 0.3)
end

function AC_HelpUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    AC.HelpUI_Instance = nil
end

function AC_HelpUI:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.moveWithMouse = true
    return o
end

function AC.OpenHelpUI()
    if AC.HelpUI_Instance then AC.HelpUI_Instance:close() end
    local w, h = 650, 540
    local x = math.floor((getCore():getScreenWidth()  / 2) - (w / 2))
    local y = math.floor((getCore():getScreenHeight() / 2) - (h / 2))
    AC.HelpUI_Instance = AC_HelpUI:new(x, y, w, h)
    AC.HelpUI_Instance:initialise()
    AC.HelpUI_Instance:addToUIManager()
end
