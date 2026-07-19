
local ISWriteBio = ISPanel:derive("ISWriteBio")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_SCALE = FONT_HGT_SMALL / 14
local function ltrim(s)
  if type(s) ~= "string" then return s end
  return s:match'^%s*(.*)';
end

function ISWriteBio:setVisible(visible)
  self.javaObject:setVisible(visible)
end

function ISWriteBio:render()
  local z = 15 * FONT_SCALE

  self:drawTextCentre(ltrim(self.targetPlayerName) .. "'s Bio", self.width/2, z, 1,1,1,1, UIFont.Medium)
end

function ISWriteBio.onLoad(args)
  ISWriteBio.instance.entry:setText(args and args.description or "No Bio Set.")
end



local function OnServerCommand(module, command, args)
  if module == "AC" and command == "BioLoad" then
    Events.OnServerCommand.Remove(OnServerCommand)
    ISWriteBio.onLoad(args)
  end
end

function ISWriteBio:createChildren()
  local btnWid = 150 * FONT_SCALE
  local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
  local padBottom = 10 * FONT_SCALE
  local height = 35 * FONT_HGT_SMALL + 4



  self.entry = ISTextEntryBox:new("Loading...", padBottom, 30 * FONT_SCALE + FONT_HGT_MEDIUM, self.width - 20 * FONT_SCALE, height-100)
  self.entry:initialise()
  self.entry:instantiate()
  self.entry:setMultipleLine(true)
  self.entry.javaObject:setMaxLines(35)
  self:addChild(self.entry)
  Events.OnServerCommand.Add(OnServerCommand)
  sendClientCommand("AC", "BioLoad", {self.targetPlayerUsername})


  if self.canEdit then

    self.save = ISButton:new(padBottom, self.height - padBottom - btnHgt, btnWid, btnHgt, "SAVE", self, ISWriteBio.onSave)
    self.save:initialise()
    self.save.borderColor = self.buttonBorderColor
    self:addChild(self.save)
  else
    self.entry:setEditable(false)
  end

  self.cancel = ISButton:new(self.width - btnWid - padBottom, self.height - padBottom - btnHgt, btnWid, btnHgt, getText("UI_btn_close"), self, ISWriteBio.close)
  self.cancel:initialise()
  self.cancel.borderColor = self.buttonBorderColor
  self:addChild(self.cancel)
end
local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ISWriteBio:onSave(button, x, y)
  sendClientCommand("AC", "BioSave", {self.entry:getText()})
  processSayMessage(getPlayer():getDescriptor():getForename().." updated their description.")
  local sandbox = SandboxVars.AuroraChatLocal or {}
  if sandbox.EnableBioShortDescription then
    getPlayer():addLineChatElement("Remember to always re-save your description after setting your /name!", 1, 0, 0);
    local function lines(str)
      local result = {}
      for line in str:gmatch '[^\n]+' do
        table.insert(result, line)
      end
      return result
    end
    local foreName = ltrim(AC.Meta.GetName(getPlayer():getUsername())) or ltrim(getPlayer():getDescriptor():getForename());
    local txt = self.entry:getText() or " "
    local newLine = "";
    if lines(string.sub(txt,1,50))[1] == nil then txt = " "; end
    local shortDescription = lines(string.sub(txt,1,50))[1];
    if string.len(shortDescription) > 29 and not luautils.stringEnds(shortDescription, " ") and not luautils.stringEnds(shortDescription, ".") then
      shortDescription = shortDescription.."...";
    end
    if string.len(shortDescription) > 2 then
      newLine = "\n "
    end
    getPlayer():getModData()['_CharacterBioShortDescription'] = shortDescription
  end
  sendPlayerStatsChange(getPlayer())
  self:close()
end





function ISWriteBio:close()
  self:setVisible(false)
  self:removeFromUIManager()
  ISWriteBio.instance = nil
end

function ISWriteBio:new(x, y, width, height, targetPlayer, canEdit)
  local o = ISPanel:new(x, y, width, height)
  setmetatable(o, self)
  self.__index = self
  o.variableColor = {r=0.9, g=0.55, b=0.1, a=1}
  o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
  o.backgroundColor = {r=0, g=0, b=0, a=0.8}
  o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
  o.moveWithMouse = true
  o.targetPlayerName = targetPlayer:getDescriptor():getForename()
  o.targetPlayerUsername = targetPlayer:getUsername()

  o.canEdit = canEdit
  ISWriteBio.instance = o
  return o
end

return ISWriteBio
