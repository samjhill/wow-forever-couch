-- Couch helpers for ConsolePort on Forever (Camelot):
-- 1) Apply Xbox recommended bindings when shoulders/triggers are blank.
-- 2) Pin Menu/Start → Escape game menu (not crosshair ↔ free-cursor flip).
local ADDON = ...

ConsolePortCouchDB = ConsolePortCouchDB or {}

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
    return true
  end
  if not force and not shouldersEmpty() and ConsolePortCouchDB.applied then
    pinGameMenuBindings(false)
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
      "CursorAutoEnable=",
      tostring(GetCVar and GetCVar("GamePadCursorAutoEnable"))
    )
  else
    print("|cff66ff66ConsolePort Couch:|r /cpcouch apply | menu | status")
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
      end
    end)
  elseif event == "UPDATE_BINDINGS" then
    if not ConsolePortCouchDB.applied and shouldersEmpty() then
      tryApply(false)
    else
      pinGameMenuBindings(false)
    end
  end
end)
