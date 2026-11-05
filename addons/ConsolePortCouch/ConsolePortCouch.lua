-- Couch helpers for ConsolePort on Forever (interface 16001).
--
-- Forever notes (verified against Forever macro/addon docs):
--   * Uses the modern macro system: /cast /use /sit work; 255-char limit.
--   * Secure snippets are broken (loadstring_untainted is nil) — do NOT use
--     SecureActionButton /click helpers for casts or item use.
--   * Keep Campsite / FishingCouch as plain account macros only (same style as InviteNearest).
--
-- 1) Apply Xbox recommended bindings when shoulders/triggers are blank.
-- 2) Pin Menu/Start → Escape game menu.
-- 3) Pin RB → InviteNearest; park Interact on empty LT.
-- 4) Ensure simple Campsite + FishingCouch account macros.
-- 5) EatBest / DrinkBest: /sit + /run picks highest restore food/drink in bags.
local ADDON = ...

ConsolePortCouchDB = ConsolePortCouchDB or {}

local INVITE_MACRO_NAME = "InviteNearest"
local INVITE_MACRO_ICON = "INV_Misc_GroupLooking"
local INVITE_MACRO_BODY = "/click StaticPopup1Button1\n/targetfriendplayer\n/invite"
local INVITE_BINDING = "MACRO " .. INVITE_MACRO_NAME

-- Plain Forever-safe macros (no nested /click SecureActionButton).
-- Eat/Drink need a short /run to scan bags; the /run itself uses the item (no second cast line).
local CAMP_MACRO_NAME = "Campsite"
local CAMP_MACRO_ICON = "Spell_Fire_Fire"
local CAMP_MACRO_BODY =
  "#showtooltip\n/use Expert Campfire Kit\n/use Journeyman Campfire Kit\n/use Basic Campfire Kit\n/sit"

local FISH_MACRO_NAME = "FishingCouch"
local FISH_MACRO_ICON = "Trade_Fishing"
local FISH_MACRO_BODY = "#showtooltip Fishing\n/cast Fishing"

local EAT_MACRO_NAME = "EatBest"
local EAT_MACRO_ICON = "INV_Misc_Food_15"
local EAT_MACRO_BODY =
  "#showtooltip\n/sit\n/run if ConsolePortCouch_Eat then ConsolePortCouch_Eat() end"

local DRINK_MACRO_NAME = "DrinkBest"
local DRINK_MACRO_ICON = "INV_Drink_07"
local DRINK_MACRO_BODY =
  "#showtooltip\n/sit\n/run if ConsolePortCouch_Drink then ConsolePortCouch_Drink() end"

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

local function ensureEatDrinkMacros()
  local okEat = ensureAccountMacro(EAT_MACRO_NAME, EAT_MACRO_ICON, EAT_MACRO_BODY)
  local okDrink = ensureAccountMacro(DRINK_MACRO_NAME, DRINK_MACRO_ICON, DRINK_MACRO_BODY)
  if okEat then
    ConsolePortCouchDB.eatPinned = true
  end
  if okDrink then
    ConsolePortCouchDB.drinkPinned = true
  end
  return okEat and okDrink
end

-- Tooltip scan for "Restores N health/mana" (Forever Food & Drink). Avoid UnitHealth
-- arithmetic — Forever may treat those as secret values.
local scanTip = CreateFrame("GameTooltip", "ConsolePortCouchScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function containerNumSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    return C_Container.GetContainerNumSlots(bag) or 0
  end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function containerItemLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then
    return C_Container.GetContainerItemLink(bag, slot)
  end
  return GetContainerItemLink and GetContainerItemLink(bag, slot)
end

local function useContainerItem(bag, slot)
  if C_Container and C_Container.UseContainerItem then
    C_Container.UseContainerItem(bag, slot)
    return true
  end
  if UseContainerItem then
    UseContainerItem(bag, slot)
    return true
  end
  return false
end

local function itemOnCooldown(bag, slot)
  if not GetContainerItemID and not (C_Container and C_Container.GetContainerItemID) then
    return false
  end
  local id
  if C_Container and C_Container.GetContainerItemID then
    id = C_Container.GetContainerItemID(bag, slot)
  else
    id = GetContainerItemID(bag, slot)
  end
  if not id or not GetItemCooldown then
    return false
  end
  local start, duration, enable = GetItemCooldown(id)
  return enable ~= 0 and duration and duration > 0 and (start + duration - GetTime()) > 0
end

local function parseFoodDrinkScores(bag, slot)
  scanTip:ClearLines()
  scanTip:SetBagItem(bag, slot)
  local health, mana = 0, 0
  local seated = false
  local alcohol = false
  for i = 1, scanTip:NumLines() do
    local fs = _G["ConsolePortCouchScanTipTextLeft" .. i]
    local text = fs and fs:GetText()
    if text then
      local lower = text:lower()
      if lower:find("alcoholic", 1, true) then
        alcohol = true
      end
      if lower:find("seated while eating", 1, true) or lower:find("seated while drinking", 1, true) then
        seated = true
      end
      local bothH, bothM = text:match("[Rr]estores (%d+) health and (%d+) mana")
      if bothH then
        health = math.max(health, tonumber(bothH) or 0)
        mana = math.max(mana, tonumber(bothM) or 0)
      else
        local h = text:match("[Rr]estores (%d+) health")
        local m = text:match("[Rr]estores (%d+) mana")
        if h then
          health = math.max(health, tonumber(h) or 0)
        end
        if m then
          mana = math.max(mana, tonumber(m) or 0)
        end
      end
      -- Percent foods (no UnitHealthMax math — Forever secret values).
      local hpct = text:match("[Rr]estores (%d+)%% of your health")
      local mpct = text:match("(%d+)%% of your mana")
      if hpct then
        health = math.max(health, (tonumber(hpct) or 0) * 80)
      end
      if mpct then
        mana = math.max(mana, (tonumber(mpct) or 0) * 80)
      end
      local hps = text:match("(%d+)%% of your health per second")
      local mps = text:match("(%d+)%% of your mana per second")
      if hps then
        health = math.max(health, (tonumber(hps) or 0) * 80 * 25)
      end
      if mps then
        mana = math.max(mana, (tonumber(mps) or 0) * 80 * 25)
      end
    end
  end
  if alcohol then
    return 0, 0
  end
  -- Require seated eat/drink text, or a restore line (covers most Forever food/drink).
  if not seated and health == 0 and mana == 0 then
    return 0, 0
  end
  return health, mana
end

local function findBestConsumable(want)
  -- want: "food" (max health score) or "drink" (max mana score)
  local bestBag, bestSlot, bestScore, bestName = nil, nil, -1, nil
  local level = UnitLevel and UnitLevel("player") or 1
  for bag = 0, 4 do
    local slots = containerNumSlots(bag)
    for slot = 1, slots do
      local link = containerItemLink(bag, slot)
      if link and not itemOnCooldown(bag, slot) then
        local name, _, _, itemLevel, minLevel = GetItemInfo(link)
        if name and (not minLevel or level >= minLevel) then
          local health, mana = parseFoodDrinkScores(bag, slot)
          local score = (want == "drink") and mana or health
          -- Prefer pure-ish matches: food needs health, drink needs mana.
          if score > bestScore and score > 0 then
            bestBag, bestSlot, bestScore, bestName = bag, slot, score, name
          elseif score == bestScore and score > 0 and itemLevel and bestBag then
            local _, _, _, bestIlvl = GetItemInfo(containerItemLink(bestBag, bestSlot))
            if (itemLevel or 0) > (bestIlvl or 0) then
              bestBag, bestSlot, bestName = bag, slot, name
            end
          end
        end
      end
    end
  end
  return bestBag, bestSlot, bestName, bestScore
end

function ConsolePortCouch_Eat()
  if InCombatLockdown and InCombatLockdown() then
    print("|cffffaa00EatBest:|r cannot eat in combat")
    return
  end
  local bag, slot, name, score = findBestConsumable("food")
  if not bag then
    print("|cffff6666EatBest:|r no food in bags")
    return
  end
  if useContainerItem(bag, slot) then
    print("|cff66ff66EatBest:|r " .. (name or "?") .. " (score " .. tostring(score) .. ")")
  end
end

function ConsolePortCouch_Drink()
  if InCombatLockdown and InCombatLockdown() then
    print("|cffffaa00DrinkBest:|r cannot drink in combat")
    return
  end
  local bag, slot, name, score = findBestConsumable("drink")
  if not bag then
    print("|cffff6666DrinkBest:|r no drink in bags")
    return
  end
  if useContainerItem(bag, slot) then
    print("|cff66ff66DrinkBest:|r " .. (name or "?") .. " (score " .. tostring(score) .. ")")
  end
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
  elseif msg == "eat" or msg == "food" then
    if ensureEatDrinkMacros() then
      printMacroReady(EAT_MACRO_NAME, EAT_MACRO_BODY)
    end
    ConsolePortCouch_Eat()
  elseif msg == "drink" then
    if ensureEatDrinkMacros() then
      printMacroReady(DRINK_MACRO_NAME, DRINK_MACRO_BODY)
    end
    ConsolePortCouch_Drink()
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
      "CampsiteMacro=",
      tostring(GetMacroIndexByName and GetMacroIndexByName(CAMP_MACRO_NAME) or 0),
      "FishingMacro=",
      tostring(GetMacroIndexByName and GetMacroIndexByName(FISH_MACRO_NAME) or 0),
      "EatMacro=",
      tostring(GetMacroIndexByName and GetMacroIndexByName(EAT_MACRO_NAME) or 0),
      "DrinkMacro=",
      tostring(GetMacroIndexByName and GetMacroIndexByName(DRINK_MACRO_NAME) or 0),
      "CursorAutoEnable=",
      tostring(GetCVar and GetCVar("GamePadCursorAutoEnable"))
    )
  else
    print("|cff66ff66ConsolePort Couch:|r /cpcouch apply | menu | invite | camp | fish | eat | drink | status")
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
    ensureEatDrinkMacros()
    C_Timer.After(5.0, function()
      if not InCombatLockdown or not InCombatLockdown() then
        pinGameMenuBindings(false)
        restoreGamepadBarClicks()
        pinInviteNearestBindings(false)
        ensureCampsiteMacro()
        ensureFishingMacro()
        ensureEatDrinkMacros()
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
