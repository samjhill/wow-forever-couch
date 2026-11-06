-- Missing / expiring self-buff reminders for Forever couch play.
-- Pair with SelfBuffs for the actual buff icon strip + countdowns.
CouchBuffReminderDB = CouchBuffReminderDB or {}

local WARN_SECONDS = 60

-- Any matching aura name counts as "up". Keep Classic/Forever names.
local CLASS_BUFFS = {
  WARLOCK = {
    { label = "Armor", names = { "Demon Armor", "Demon Skin", "Fel Armor" } },
  },
  MAGE = {
    { label = "Armor", names = { "Frost Armor", "Ice Armor", "Mage Armor", "Molten Armor" } },
  },
  PRIEST = {
    { label = "Inner Fire", names = { "Inner Fire" } },
  },
  DRUID = {
    { label = "Mark of the Wild", names = { "Mark of the Wild", "Gift of the Wild" } },
    { label = "Thorns", names = { "Thorns" } },
  },
  HUNTER = {
    {
      label = "Aspect",
      names = {
        "Aspect of the Hawk",
        "Aspect of the Monkey",
        "Aspect of the Cheetah",
        "Aspect of the Pack",
        "Aspect of the Wild",
        "Aspect of the Viper",
        "Aspect of the Dragonhawk",
      },
    },
  },
  SHAMAN = {
    { label = "Shield", names = { "Lightning Shield", "Water Shield", "Earth Shield" } },
  },
  PALADIN = {
    { label = "Seal", names = {
      "Seal of Righteousness", "Seal of the Crusader", "Seal of Command",
      "Seal of Justice", "Seal of Light", "Seal of Wisdom", "Seal of Blood",
      "Seal of Vengeance", "Seal of Corruption", "Seal of the Martyr",
    }},
    { label = "Blessing", names = {
      "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings",
      "Blessing of Sanctuary", "Blessing of Light", "Blessing of Salvation",
      "Greater Blessing of Might", "Greater Blessing of Wisdom",
      "Greater Blessing of Kings", "Greater Blessing of Sanctuary",
      "Greater Blessing of Light", "Greater Blessing of Salvation",
    }},
  },
  WARRIOR = {
    { label = "Shout", names = { "Battle Shout", "Commanding Shout" } },
  },
  ROGUE = {},
}

local function defaults()
  return {
    enabled = true,
    warnSeconds = WARN_SECONDS,
    scale = 1.35,
    announce = true,
  }
end

local function db()
  for k, v in pairs(defaults()) do
    if CouchBuffReminderDB[k] == nil then
      CouchBuffReminderDB[k] = v
    end
  end
  return CouchBuffReminderDB
end

local function playerClass()
  local _, class = UnitClass("player")
  return class
end

local function auraMatches(auraName, names)
  if not auraName then
    return false
  end
  for _, n in ipairs(names) do
    if auraName == n then
      return true
    end
  end
  return false
end

-- Returns remaining seconds for first matching buff, or nil if missing.
-- Forever treats many aura fields as secret while tainted — never let that spam errors.
local function findBuffRemaining(names)
  if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
    local i = 1
    while i <= 80 do
      local ok, data = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
      if not ok then
        return nil
      end
      if not data then
        break
      end
      local nameOk, auraName = pcall(function()
        return data.name
      end)
      if nameOk and auraMatches(auraName, names) then
        local expOk, expirationTime = pcall(function()
          return data.expirationTime
        end)
        if expOk and expirationTime and expirationTime > 0 then
          return expirationTime - GetTime()
        end
        return 99999 -- permanent / no timer / secret expiry
      end
      i = i + 1
    end
    return nil
  end

  for i = 1, 40 do
    local ok, name, _, _, _, _, expirationTime = pcall(UnitBuff, "player", i)
    if not ok then
      return nil
    end
    if not name then
      break
    end
    if auraMatches(name, names) then
      if expirationTime and expirationTime > 0 then
        return expirationTime - GetTime()
      end
      return 99999
    end
  end
  return nil
end

local frame = CreateFrame("Frame", "CouchBuffReminderFrame", UIParent)
frame:SetSize(420, 48)
frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 210)
frame:Hide()
frame:SetFrameStrata("HIGH")

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.05, 0.02, 0.02, 0.72)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER")
text:SetWidth(400)
text:SetJustifyH("CENTER")
text:SetTextColor(1, 0.82, 0.2, 1)

local lastAnnounce = {}

local function update()
  local cfg = db()
  if not cfg.enabled or UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then
    frame:Hide()
    return
  end

  local class = playerClass()
  local list = CLASS_BUFFS[class]
  if not list or #list == 0 then
    frame:Hide()
    return
  end

  local missing, expiring = {}, {}
  local warnAt = cfg.warnSeconds or WARN_SECONDS

  for _, entry in ipairs(list) do
    local rem = findBuffRemaining(entry.names)
    if rem == nil then
      missing[#missing + 1] = entry.label
    elseif rem < warnAt then
      expiring[#expiring + 1] = string.format("%s (%ds)", entry.label, math.max(0, math.floor(rem)))
    end
  end

  if #missing == 0 and #expiring == 0 then
    frame:Hide()
    return
  end

  local parts = {}
  if #missing > 0 then
    parts[#parts + 1] = "Missing: " .. table.concat(missing, ", ")
  end
  if #expiring > 0 then
    parts[#parts + 1] = "Expiring: " .. table.concat(expiring, ", ")
  end
  local msg = table.concat(parts, "  ·  ")
  text:SetText(msg)
  frame:SetScale(cfg.scale or 1.35)
  frame:Show()

  if cfg.announce then
    local key = msg
    local now = GetTime()
    if (lastAnnounce[key] or 0) + 30 < now then
      lastAnnounce[key] = now
      print("|cffffaa00Couch Buffs:|r " .. msg)
    end
  end
end

frame:SetScript("OnUpdate", function(self, elapsed)
  self.t = (self.t or 0) + elapsed
  if self.t < 0.5 then
    return
  end
  self.t = 0
  update()
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("UNIT_AURA")
boot:RegisterEvent("PLAYER_REGEN_DISABLED")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:SetScript("OnEvent", function(_, event, unit)
  if event == "UNIT_AURA" and unit ~= "player" then
    return
  end
  if event == "PLAYER_LOGIN" then
    db()
    print(
      "|cff66ff66Couch Buff Reminder:|r watching class self-buffs."
        .. " Pair with SelfBuffs (/sb) for icon timers. /cbr status"
    )
  end
  update()
end)

SLASH_COUCHBUFFREMINDER1 = "/cbr"
SLASH_COUCHBUFFREMINDER2 = "/couchbuffs"
SlashCmdList.COUCHBUFFREMINDER = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  local cfg = db()
  if msg == "off" then
    cfg.enabled = false
    frame:Hide()
    print("|cff66ff66Couch Buff Reminder:|r off")
  elseif msg == "on" then
    cfg.enabled = true
    update()
    print("|cff66ff66Couch Buff Reminder:|r on")
  elseif msg == "status" then
    print(
      "|cff66ff66Couch Buff Reminder:|r enabled=",
      tostring(cfg.enabled),
      "class=",
      tostring(playerClass()),
      "warnSeconds=",
      tostring(cfg.warnSeconds)
    )
    update()
  else
    print("|cff66ff66Couch Buff Reminder:|r /cbr on | off | status")
  end
end
