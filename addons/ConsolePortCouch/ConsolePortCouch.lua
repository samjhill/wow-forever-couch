-- Couch helpers for ConsolePort on Forever (interface 16001).
--
-- Forever notes:
--   * Macros: plain /cast /use /sit only (255-char). /run cannot UseContainerItem.
--   * Secure snippets broken — never SecureActionButton /click for cast/use.
--   * Food/drink: use the AutoFeed addon macros (AutoFeed / AutoDrink), not custom ones.
--
-- 1) Apply Xbox recommended bindings when shoulders/triggers are blank.
-- 2) Pin Menu/Start → Escape game menu.
-- 3) Pin RB → InviteNearest; park Interact on empty LT.
-- 4) Plain Campsite + FishingCouch account macros.
local ADDON = ...

ConsolePortCouchDB = ConsolePortCouchDB or {}

local INVITE_MACRO_NAME = "InviteNearest"
local INVITE_MACRO_ICON = "INV_Misc_GroupLooking"
local INVITE_MACRO_BODY = "/click StaticPopup1Button1\n/targetfriendplayer\n/invite"
local INVITE_BINDING = "MACRO " .. INVITE_MACRO_NAME

-- Plain Forever-safe macros only (/use /cast — no /run, no /click helpers).
local CAMP_MACRO_NAME = "Campsite"
local CAMP_MACRO_ICON = "Spell_Fire_Fire"
local CAMP_MACRO_BODY =
  "#showtooltip\n/use Expert Campfire Kit\n/use Journeyman Campfire Kit\n/use Basic Campfire Kit"

local FISH_MACRO_NAME = "FishingCouch"
local FISH_MACRO_ICON = "Trade_Fishing"
local FISH_MACRO_BODY = "#showtooltip\n/cast Fishing"

-- Face + d-pad → ConsolePort gamepad bar (restored if wiped empty/JUMP).
local GAMEPAD_BAR_CLICKS = {
  PAD1 = "CLICK ConsolePortGamepadBar1Slot2:LeftButton",
  PAD2 = "CLICK ConsolePortGamepadBar1Slot5:LeftButton",
  PAD3 = "CLICK ConsolePortGamepadBar1Slot3:LeftButton",
  PAD4 = "CLICK ConsolePortGamepadBar1Slot4:LeftButton",
  SHIFT_PAD1 = "CLICK ConsolePortGamepadBar1Slot1:LeftButton",
  SHIFT_PAD2 = "CLICK ConsolePortGamepadBar1Slot8:LeftButton",
  SHIFT_PAD3 = "CLICK ConsolePortGamepadBar1Slot6:LeftButton",
  SHIFT_PAD4 = "CLICK ConsolePortGamepadBar1Slot7:LeftButton",
  PADDUP = "CLICK ConsolePortGamepadBar2Slot2:LeftButton",
  PADDDOWN = "CLICK ConsolePortGamepadBar2Slot4:LeftButton",
  PADDLEFT = "CLICK ConsolePortGamepadBar2Slot1:LeftButton",
  PADDRIGHT = "CLICK ConsolePortGamepadBar2Slot3:LeftButton",
}

local function restoreGamepadBarClicks()
  if InCombatLockdown and InCombatLockdown() then
    return false
  end
  local function chord(key)
    if key:sub(1, 6) == "SHIFT_" then
      return "SHIFT-" .. key:sub(7)
    end
    return key
  end
  local function needsRestore(current)
    return current == nil
      or current == ""
      or current == "NONE"
      or current == "JUMP"
  end
  for key, action in pairs(GAMEPAD_BAR_CLICKS) do
    local button = chord(key)
    local current = GetBindingAction(button, true) or ""
    if needsRestore(current) then
      SetBinding(button, action)
    end
  end
  return true
end

local function getDb()
  if not ConsolePort then
    return nil
  end
  if ConsolePort.GetData then
    return ConsolePort:GetData()
  end
  if ConsolePort.DB then
    return ConsolePort:DB()
  end
  return nil
end

local function getXboxDevice(db)
  if not db or not db.Gamepad then
    return nil
  end
  if db.Gamepad.GetDevice then
    local d = db.Gamepad:GetDevice("Xbox")
    if d then
      return d
    end
  end
  if db.Gamepad.EnumerateDevices then
    for name, device in db.Gamepad:EnumerateDevices() do
      if name == "Xbox" then
        return device
      end
    end
  end
  if db.Gamepad.GetActiveDevice then
    return db.Gamepad:GetActiveDevice()
  end
  return db("Gamepad/Active")
end

local function shouldersEmpty()
  local lb = GetBindingAction("PADLSHOULDER", true)
  local rb = GetBindingAction("PADRSHOULDER", true)
  local lt = GetBindingAction("PADLTRIGGER", true)
  local rt = GetBindingAction("PADRTRIGGER", true)
  return (lb == nil or lb == "")
    and (rb == nil or rb == "")
    and (lt == nil or lt == "")
    and (rt == nil or rt == "")
end

local function setCVarSafe(name, value)
  if GetCVar and SetCVar and GetCVar(name) ~= nil then
    pcall(SetCVar, name, value)
  end
end

local function pinGameMenuBindings(force)
  if InCombatLockdown and InCombatLockdown() then
    return false
  end

  setCVarSafe("GamePadCursorAutoEnable", "0")
  setCVarSafe("GamePadCursorCenteredEmulation", "0")
  setCVarSafe("GamePadCursorLeftClick", "none")
  setCVarSafe("GamePadCursorRightClick", "none")

  local function ensure(button, action)
    local current = GetBindingAction(button, true) or ""
    if current ~= action then
      SetBinding(button, action)
    end
  end

  ensure("PADFORWARD", "TOGGLEGAMEMENU")
  local systemAction = GetBindingAction("PADSYSTEM", true) or ""
  if force or systemAction == "" or systemAction == "NONE" then
    ensure("PADSYSTEM", "TOGGLEGAMEMENU")
  end

  -- Never SaveBindings here — it can wipe ConsolePort gamepad-bar CLICK binds on Forever.

  local db = getDb()
  if db then
    pcall(function()
      db("Settings/gameMenuEnable", true)
    end)
    pcall(function()
      db("bindingAutomaticBackup", false)
    end)
  end

  ConsolePortCouchDB.menuPinned = true
  ConsolePortCouchDB.menuTs = time()
  return true
end

local function ensureAccountMacro(name, icon, body)
  if not CreateMacro or not EditMacro or not GetMacroIndexByName then
    return false
  end
  local index = GetMacroIndexByName(name) or 0
  if index > 0 then
    EditMacro(index, name, icon, body)
    return true
  end
  -- false = account macro
  local ok, created = pcall(CreateMacro, name, icon, body, false)
  if ok and created then
    return true
  end
  ok, created = pcall(CreateMacro, name, icon, body, true)
  return ok and created and true or false
end

local function ensureInviteMacro()
  return ensureAccountMacro(INVITE_MACRO_NAME, INVITE_MACRO_ICON, INVITE_MACRO_BODY)
end

local function ensureCampsiteMacro()
  local ok = ensureAccountMacro(CAMP_MACRO_NAME, CAMP_MACRO_ICON, CAMP_MACRO_BODY)
  if ok then
    ConsolePortCouchDB.campsitePinned = true
    ConsolePortCouchDB.campsiteTs = time()
  end
  return ok
end

local function ensureFishingMacro()
  local ok = ensureAccountMacro(FISH_MACRO_NAME, FISH_MACRO_ICON, FISH_MACRO_BODY)
  if ok then
    ConsolePortCouchDB.fishingPinned = true
    ConsolePortCouchDB.fishingTs = time()
  end
  return ok
end

local function pinInviteNearestBindings(force)
  if InCombatLockdown and InCombatLockdown() then
    return false
  end
  if not ensureInviteMacro() then
    return false
  end

  local function ensure(button, action)
    local current = GetBindingAction(button, true) or ""
    if (force or current ~= action) and current ~= action then
      SetBinding(button, action)
    end
  end

  ensure("PADRSHOULDER", INVITE_BINDING)

  local lt = GetBindingAction("PADLTRIGGER", true) or ""
  if lt == "" or lt == "NONE" then
    ensure("PADLTRIGGER", "INTERACTTARGET")
  end

  restoreGamepadBarClicks()

  ConsolePortCouchDB.invitePinned = true
  ConsolePortCouchDB.inviteTs = time()
  return true
end

local function applyPreset(force)
  local db = getDb()
  if not db then
    print("|cffff6666ConsolePort Couch:|r ConsolePort data not ready.")
    return false
  end
  local device = getXboxDevice(db)
  if not device or not device.ApplyPresetBindings then
    print("|cffff6666ConsolePort Couch:|r Xbox device preset not found.")
    return false
  end
  if not force and not shouldersEmpty() then
    pinGameMenuBindings(false)
    pinInviteNearestBindings(false)
    ConsolePortCouchDB.applied = true
    return true
  end
  if not force and ConsolePortCouchDB.applied then
    pinGameMenuBindings(false)
    pinInviteNearestBindings(false)
    return true
  end

  local setID = GetCurrentBindingSet and GetCurrentBindingSet() or 1
  local ok, err = pcall(function()
    device:ApplyPresetBindings(setID)
  end)
  if not ok then
    print("|cffff6666ConsolePort Couch:|r apply failed:", tostring(err))
    return false
  end
  ConsolePortCouchDB.applied = true
  ConsolePortCouchDB.device = device.Name or "Xbox"
  ConsolePortCouchDB.ts = time()
  pinGameMenuBindings(true)
  pinInviteNearestBindings(true)
  print(
    "|cff66ff66ConsolePort Couch:|r applied |cffffffff"
      .. (device.Name or "Xbox")
      .. "|r recommended bindings. Place abilities on the gamepad bar; tweak in /consoleport."
  )
  return true
end

local function tryApply(force)
  if InCombatLockdown and InCombatLockdown() then
    print("|cffffaa00ConsolePort Couch:|r wait until out of combat, then /cpcouch apply")
    return
  end
  C_Timer.After(force and 0.5 or 2.0, function()
    applyPreset(force)
  end)
end

local function printMacroReady(name, body)
  print("|cff66ff66ConsolePort Couch:|r account macro |cffffffff" .. name .. "|r ready. Drag it onto a bar.")
  for line in string.gmatch(body, "[^\n]+") do
    print("  " .. line)
  end
end

SLASH_CPCOUCH1 = "/cpcouch"
SlashCmdList.CPCOUCH = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  if msg == "apply" or msg == "reset" or msg == "force" then
    ConsolePortCouchDB.applied = nil
    tryApply(true)
  elseif msg == "menu" or msg == "pinmenu" then
    if InCombatLockdown and InCombatLockdown() then
      print("|cffffaa00ConsolePort Couch:|r wait until out of combat, then /cpcouch menu")
      return
    end
    pinGameMenuBindings(true)
    print(
      "|cff66ff66ConsolePort Couch:|r Menu/Start → TOGGLEGAMEMENU"
        .. " (PADFORWARD + PADSYSTEM); cursor auto-enable off."
    )
  elseif msg == "invite" or msg == "pininvite" then
    if InCombatLockdown and InCombatLockdown() then
      print("|cffffaa00ConsolePort Couch:|r wait until out of combat, then /cpcouch invite")
      return
    end
    if pinInviteNearestBindings(true) then
      print(
        "|cff66ff66ConsolePort Couch:|r RB → "
          .. INVITE_BINDING
          .. " (accept invite popup + target nearest friend + invite)."
      )
    else
      print("|cffff6666ConsolePort Couch:|r could not create/pin InviteNearest macro.")
    end
  elseif msg == "camp" or msg == "campsite" or msg == "pincamp" then
    if ensureCampsiteMacro() then
      printMacroReady(CAMP_MACRO_NAME, CAMP_MACRO_BODY)
    else
      print("|cffff6666ConsolePort Couch:|r could not create Campsite macro.")
    end
  elseif msg == "fish" or msg == "fishing" or msg == "pinfish" then
    if ensureFishingMacro() then
      printMacroReady(FISH_MACRO_NAME, FISH_MACRO_BODY)
    else
      print("|cffff6666ConsolePort Couch:|r could not create FishingCouch macro.")
    end
  elseif msg == "eat" or msg == "food" or msg == "drink" then
    print(
      "|cff66ff66ConsolePort Couch:|r food/drink → AutoFeed addon macros "
        .. "|cffffffffAutoFeed|r (eat) + |cffffffffAutoDrink|r (drink). "
        .. "Create via /af if missing, then drag onto a bar."
    )
  elseif msg == "status" then
    print(
      "|cff66ff66ConsolePort Couch:|r applied=",
      tostring(ConsolePortCouchDB.applied),
      "device=",
      tostring(ConsolePortCouchDB.device),
      "CampsiteMacro=",
      tostring(GetMacroIndexByName and GetMacroIndexByName(CAMP_MACRO_NAME) or 0),
      "FishingMacro=",
      tostring(GetMacroIndexByName and GetMacroIndexByName(FISH_MACRO_NAME) or 0),
      "AutoFeed=",
      tostring(GetMacroIndexByName and GetMacroIndexByName("AutoFeed") or 0),
      "AutoDrink=",
      tostring(GetMacroIndexByName and GetMacroIndexByName("AutoDrink") or 0)
    )
  else
    print("|cff66ff66ConsolePort Couch:|r /cpcouch apply | menu | invite | camp | fish | eat | status")
  end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("UPDATE_BINDINGS")
boot:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    tryApply(false)
    ensureCampsiteMacro()
    ensureFishingMacro()
    C_Timer.After(2.0, function()
      if not InCombatLockdown or not InCombatLockdown() then
        pinGameMenuBindings(false)
        restoreGamepadBarClicks()
        pinInviteNearestBindings(false)
        ensureCampsiteMacro()
        ensureFishingMacro()
      end
    end)
  elseif event == "UPDATE_BINDINGS" then
    if not ConsolePortCouchDB.applied and shouldersEmpty() then
      tryApply(false)
    else
      pinGameMenuBindings(false)
      pinInviteNearestBindings(false)
    end
  end
end)
