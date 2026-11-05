-- Couch helpers for ConsolePort on Forever (Camelot):
-- 1) Apply Xbox recommended bindings when shoulders/triggers are blank.
-- 2) Pin Menu/Start → Escape game menu (not crosshair ↔ free-cursor flip).
-- 3) Pin RB → account macro InviteNearest; park Interact on empty LT.
local ADDON = ...

ConsolePortCouchDB = ConsolePortCouchDB or {}

local INVITE_MACRO_NAME = "InviteNearest"
local INVITE_MACRO_ICON = "INV_Misc_GroupLooking"
local INVITE_MACRO_BODY = "/click StaticPopup1Button1\n/targetfriendplayer\n/invite"
local INVITE_BINDING = "MACRO " .. INVITE_MACRO_NAME

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

-- Forever's gamepad Escape path often toggles center-crosshair ↔ free mouse
-- when GamePadCursorAutoEnable is on, so the real game menu never appears.
-- Also pin Menu on both PADFORWARD (Start/☰) and PADSYSTEM in case the
-- Linux/Steam raw map swaps Start with Guide.
local function pinGameMenuBindings(force)
  if InCombatLockdown and InCombatLockdown() then
    return false
  end

  setCVarSafe("GamePadCursorAutoEnable", "0")
  setCVarSafe("GamePadCursorCenteredEmulation", "0")
  setCVarSafe("GamePadCursorLeftClick", "none")
  setCVarSafe("GamePadCursorRightClick", "none")

  local dirty = false
  local function ensure(button, action)
    local current = GetBindingAction(button, true) or ""
    if current ~= action then
      if SetBinding(button, action) then
        dirty = true
      end
    end
  end

  ensure("PADFORWARD", "TOGGLEGAMEMENU")
  -- Backup: some Wine/Steam stacks deliver Menu/Start as PADSYSTEM.
  local systemAction = GetBindingAction("PADSYSTEM", true) or ""
  if force or systemAction == "" or systemAction == "NONE" then
    ensure("PADSYSTEM", "TOGGLEGAMEMENU")
  end

  if dirty and SaveBindings and GetCurrentBindingSet then
    SaveBindings(GetCurrentBindingSet())
  end

  local db = getDb()
  if db then
    -- Prefer Blizzard Escape menu chrome on Forever; keep CP overlay available.
    pcall(function()
      db("Settings/gameMenuEnable", true)
    end)
  end

  ConsolePortCouchDB.menuPinned = true
  ConsolePortCouchDB.menuTs = time()
  return true
end

-- Account-wide invite+accept: click party popup Accept, target nearest friend, invite.
local function ensureInviteMacro()
  if not CreateMacro or not EditMacro or not GetMacroIndexByName then
    return false
  end
  local index = GetMacroIndexByName(INVITE_MACRO_NAME) or 0
  if index > 0 then
    EditMacro(index, INVITE_MACRO_NAME, INVITE_MACRO_ICON, INVITE_MACRO_BODY)
    return true
  end
  -- false = account macro (shared across characters)
  local ok, created = pcall(CreateMacro, INVITE_MACRO_NAME, INVITE_MACRO_ICON, INVITE_MACRO_BODY, false)
  if ok and created then
    return true
  end
  -- Fallback: character macro if account slots are full / API differs
  ok, created = pcall(CreateMacro, INVITE_MACRO_NAME, INVITE_MACRO_ICON, INVITE_MACRO_BODY, true)
  return ok and created and true or false
end

local function pinInviteNearestBindings(force)
  if InCombatLockdown and InCombatLockdown() then
    return false
  end
  if not ensureInviteMacro() then
    return false
  end

  local dirty = false
  local function ensure(button, action)
    local current = GetBindingAction(button, true) or ""
    if force or current ~= action then
      if current ~= action and SetBinding(button, action) then
        dirty = true
      end
    end
  end

  ensure("PADRSHOULDER", INVITE_BINDING)

  local lt = GetBindingAction("PADLTRIGGER", true) or ""
  if lt == "" or lt == "NONE" then
    ensure("PADLTRIGGER", "INTERACTTARGET")
  end

  if dirty and SaveBindings and GetCurrentBindingSet then
    SaveBindings(GetCurrentBindingSet())
  end

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
  if not force and ConsolePortCouchDB.applied and not shouldersEmpty() then
    pinGameMenuBindings(false)
    pinInviteNearestBindings(false)
    return true
  end
  if not force and not shouldersEmpty() and ConsolePortCouchDB.applied then
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
  elseif msg == "status" then
    print(
      "|cff66ff66ConsolePort Couch:|r applied=",
      tostring(ConsolePortCouchDB.applied),
      "device=",
      tostring(ConsolePortCouchDB.device),
      "shouldersEmpty=",
      tostring(shouldersEmpty()),
      "PADFORWARD=",
      tostring(GetBindingAction("PADFORWARD", true)),
      "PADSYSTEM=",
      tostring(GetBindingAction("PADSYSTEM", true)),
      "PADRSHOULDER=",
      tostring(GetBindingAction("PADRSHOULDER", true)),
      "PADLTRIGGER=",
      tostring(GetBindingAction("PADLTRIGGER", true)),
      "CursorAutoEnable=",
      tostring(GetCVar and GetCVar("GamePadCursorAutoEnable"))
    )
  else
    print("|cff66ff66ConsolePort Couch:|r /cpcouch apply | menu | invite | status")
  end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("UPDATE_BINDINGS")
boot:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    tryApply(false)
    -- Re-pin after Forever/CP finish remapping gamepad actions.
    C_Timer.After(5.0, function()
      if not InCombatLockdown or not InCombatLockdown() then
        pinGameMenuBindings(false)
        pinInviteNearestBindings(true)
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
