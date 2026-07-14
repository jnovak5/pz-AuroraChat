# AuroraChat

A feature-rich Roleplay (RP) chat overhaul mod for **Project Zomboid Build 42** servers. AuroraChat introduces robust proximity chatting, multi-channel tabs, language barriers, in-game recording tapes, and extensive character customization tools directly tied to the chat box.

## Core Features

- **Proximity-Based Chat & Volumes**: Control exactly how far your voice carries. Shift smoothly between whispering, speaking low, talking normally, speaking loud, and shouting.
- **Language System**: Over 50+ languages with partial-understanding mechanics. If you don't speak a language, text becomes garbled.
- **Emotes & Actions**: Seamless integration of `/me` and `/do` commands alongside unique shorthand syntax (`'s`, `,`, `:`) to weave actions directly into your speech.
- **Tape Recorder Item**: Find recorders and blank tapes in the world. Record your chat logs onto a physical tape and play them back later for others to hear! 
- **Typing Indicators**: Visual overhead indicators and chat-box notifications when someone is currently typing.
- **AFK System**: Toggle your AFK status manually with `/afk` to display an overhead indicator.
- **Focus & Private Chat**: Use `/focus` to filter your main chat tab to a specific person, or use `/private <name>` to open a secure proximity channel with another player that automatically closes when you walk away.
- **Radio Integration**: Chat natively interfaces with Project Zomboid's radio channels, allowing walkie-talkie roleplay directly in the text box.

## Commands

AuroraChat uses a wide array of slash commands to customize your character and manage chat. Use `/help` in-game for an overview.

### Chat & Roleplay Commands
- `/w <text>` - Whisper (Smallest radius)
- `/l <text>` - Speak Low (Small radius)
- `/s <text>` - Speak normally (Medium radius)
- `/y <text>` - Speak loudly (Large radius)
- `/sh <text>` - Shout (Largest radius)
- `/me <action>` - Perform an action (e.g. *John smiles*)
- `/do <environment>` - Describe an environmental action
- `/ooc <text>` - Out Of Character chat
- `/pm <username> <text>` - Send a private message across the server
- `/roll` - Roll a 20-sided die in chat for RNG events.

### Character Customization & Utility
- `/name <First> <Last>` - Change your character's display name.
- `/color <r,g,b>` - Change your name's color in the chat box.
- `/growhair` - Instantly grows your character's hair.
- `/growbeard` - Instantly grows your character's beard (Males only).
- `/sethaircolor <r,g,b>` - Change your character's hair color.
- `/setbeardcolor <r,g,b>` - Change your character's beard color.
- `/status <message>` - Set a custom status message (or use `clear`).
- `/injure` - Apply injuries to yourself (if enabled in Sandbox).
- `/trade <username>` - Send a trade request to a nearby player.
- `/coords` - Get your current X, Y coordinates (if enabled in Sandbox).
- `/afk` - Toggle your AFK status.

### System & Settings
- `/focus <username>` - Filter the main chat to only see messages from a specific player. Use `/unfocus` to revert.
- `/private <username>` - Start a proximity-based private conversation. Use `/stopprivate` to end it.
- `/radiosync <channel>` - Sync your chat to a specific radio channel.
- `/lang <language>` - Switch the language you are currently speaking.
- `/keeplast` - Toggle whether the chat box remembers your last sent message type (e.g., keeping you in `/ooc` mode automatically).

### Admin Commands
*Requires Moderator or Admin access levels.*
- `/addlang <username> <language>` - Teach a player a new language.
- `/removelang <username> <language>` - Remove a language from a player.
- `/override` - Toggle chat override mode (see all ranges and languages).
- `/hammer` - Toggle the Admin Hammer icon next to your name.

## Installation

1. Place the `AuroraChat` folder into your server's `mods/` directory.
2. Enable **AuroraChat** in the Mod Manager.
3. Configure your ranges and toggles under **Sandbox Options → AuroraChat**.

## Sandbox Options

Server owners have full control over AuroraChat's features. Some key configurations include:
- **Enable/Disable Features**: Individually toggle PMs, OOC, Private Chat, and Stat Buffs.
- **Ranges**: Set the exact X, Y, and Z ranges for Whisper, Low, Say, Loud, and Shout.
- **Roleplay Traits**: Enable Hard of Hearing and Deaf integration.
- **Customization Limits**: Restrict `/coords`, self-injury, and character modification commands if desired.

## Credits

Ported, rebuilt, and heavily expanded for **Project Zomboid Build 42**. Originally based on WastelandsRpChat, now natively utilizing B42 UI components, JSON localization, and action queues. Built for the Aurora RP community.
