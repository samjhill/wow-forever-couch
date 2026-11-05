-- Couch helpers for ConsolePort on Forever (Camelot):
-- 1) Apply Xbox recommended bindings when shoulders/triggers are blank.
-- 2) Pin Menu/Start → Escape game menu (not crosshair ↔ free-cursor flip).
-- 3) Pin RB → account macro InviteNearest; park Interact on empty LT.
-- 4) Campsite: secure button + account macro place fire, profession object, then /sit.
-- 5) Fishing: secure button + account macro for Forever poles/lures/food/camp features + cast.
local ADDON = ...

ConsolePortCouchDB = ConsolePortCouchDB or {}

local INVITE_MACRO_NAME = "InviteNearest"
local INVITE_MACRO_ICON = "INV_Misc_GroupLooking"
local INVITE_MACRO_BODY = "/click StaticPopup1Button1\n/targetfriendplayer\n/invite"
local INVITE_BINDING = "MACRO " .. INVITE_MACRO_NAME

-- Forever camping: /click CPCCouchCamp picks best kit + profession feature, errors loudly.
local CAMP_MACRO_NAME = "Campsite"
local CAMP_MACRO_ICON = "Spell_Fire_Fire"
local CAMP_BUTTON_NAME = "CPCCouchCamp"
local CAMP_MACRO_BODY = "#showtooltip\n/click " .. CAMP_BUTTON_NAME

-- Best-first campfire kits (Cooking).
local CAMP_FIRES = {
  "Expert Campfire Kit",
  "Journeyman Campfire Kit",
  "Basic Campfire Kit",
}

-- Cooking recipes that create those kits (best first). Spell tooltips name the recipe
-- "Basic/Journeyman/Expert Campfire"; kits are the bag items.
local CAMP_FIRE_RECIPES = {
  {
    kit = "Expert Campfire Kit",
    names = { "Expert Campfire", "Expert Campfire Kit" },
    reagent = "Thick Logs",
  },
  {
    kit = "Journeyman Campfire Kit",
    names = { "Journeyman Campfire", "Journeyman Campfire Kit" },
    reagent = "Star Wood",
  },
  {
    kit = "Basic Campfire Kit",
    names = { "Basic Campfire", "Basic Campfire Kit" },
    reagent = "Simple Wood",
  },
}

-- Profession camp features: each line is best-first (tier 3 → 1). One object per player.
local CAMP_FEATURE_LINES = {
  { profession = "Fishing", items = { "Fishing Hut", "Fishing Rack", "Fish Bowl" } },
  { profession = "First Aid", items = { "Plague Doctor's Laboratory", "Toxin Study", "First Aid Kit" } },
  { profession = "Skinning", items = { "Trapper's Workbench", "Field Guide", "Camp Chair" } },
  { profession = "Leatherworking", items = { "Sewing Machine", "Tanning Rack", "Camp Tent" } },
  { profession = "Enchanting", items = { "Arcane Forge", "Arcane Salvager", "Enchanted Lute" } },
  { profession = "Mining", items = { "Molten Foundry", "Rock Garden", "Lodestone" } },
  { profession = "Alchemy", items = { "Alchemy Laboratory", "Fermenter", "Mana Well" } },
  { profession = "Blacksmithing", items = { "Master Forge", "Anvil", "Sharpening Wheel" } },
  { profession = "Herbalism", items = { "Seed Hybridizer", "Greenhouse", "Incense Candle" } },
  { profession = "Tailoring", items = { "Loom", "Spinning Wheel", "Faction Banner" } },
  { profession = "Engineering", items = { "Anarchist's Workbench", "Repair Bot", "Reagent Bot" } },
  { profession = "Cooking", items = { "Iron Oven", "Cookie's Feast" } },
}

-- Forever fishing: /click CPCCouchFish (pole + lure + food + Rack/Hut + cast).
local FISH_MACRO_NAME = "FishingCouch"
local FISH_MACRO_ICON = "Trade_Fishing"
local FISH_BUTTON_NAME = "CPCCouchFish"
local FISH_MACRO_BODY = "#showtooltip Fishing\n/click " .. FISH_BUTTON_NAME

-- Best-first poles (+skill). Include Forever extras (Darkwood, Ravaged).
local FISH_POLES = {
  "Arcanite Fishing Pole",
  "Nat Pagle's Extreme Angler FC-5000",
  "Big Iron Fishing Pole",
  "Darkwood Fishing Pole",
  "Ravaged Fishing Pole",
  "Strong Fishing Pole",
  "Blump Family Fishing Pole",
  "Fishing Pole",
}

-- Best-first lures (+skill).
local FISH_LURES = {
  "Aquadynamic Fish Attractor",
  "Bright Baubles",
  "Flesh Eating Worm",
  "Nightcrawlers",
  "Aquadynamic Fish Lens",
  "Shiny Bauble",
}

-- Forever +Fishing Well Fed dishes (best first).
local FISH_FOOD = {
  "Spinefin Halibut",
  "Filet of Redgill",
  "Rockscale Cod",
  "Bristle Whisker Catfish",
  "Fillet of Frenzy",
  "Loch Frenzy Delight",
}

-- Forever fishing camp features (best first) — uncommon/rare catches + Fish Bowl buff.
local FISH_CAMP_FEATURES = {
  "Fishing Hut",
  "Fishing Rack",
  "Fish Bowl",
}

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

  -- Do not call SaveBindings here. On Forever/ConsolePort, saving after a partial
  -- SetBinding can rewrite ConsolePortShared character Bindings and wipe
  -- CLICK ConsolePortGamepadBar* face/dpad assignments.

  local db = getDb()
  if db then
    -- Prefer Blizzard Escape menu chrome on Forever; keep CP overlay available.
    pcall(function()
      db("Settings/gameMenuEnable", true)
    end)
    -- Prevent Shared character Bindings backup from overwriting gamepad-bar clicks
    -- with empty GetBindingAction snapshots after partial SetBinding.
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
  -- false = account macro (shared across characters)
  local ok, created = pcall(CreateMacro, name, icon, body, false)
  if ok and created then
    return true
  end
  -- Fallback: character macro if account slots are full / API differs
  ok, created = pcall(CreateMacro, name, icon, body, true)
  return ok and created and true or false
end

-- Account-wide invite+accept: click party popup Accept, target nearest friend, invite.
local function ensureInviteMacro()
  return ensureAccountMacro(INVITE_MACRO_NAME, INVITE_MACRO_ICON, INVITE_MACRO_BODY)
end

local function campPrint(kind, msg)
  local color = "|cff66ff66"
  if kind == "error" then
    color = "|cffff6666"
  elseif kind == "warn" then
    color = "|cffffaa00"
  end
  local text = color .. "Campsite:|r " .. msg
  print(text)
  if UIErrorsFrame and UIErrorsFrame.AddMessage then
    local r, g, b = 1, 0.4, 0.4
    if kind == "ok" then
      r, g, b = 0.4, 1, 0.4
    elseif kind == "warn" then
      r, g, b = 1, 0.7, 0.2
    end
    UIErrorsFrame:AddMessage(msg, r, g, b, 1.0)
  end
end

local function containerNumSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    return C_Container.GetContainerNumSlots(bag) or 0
  end
  if GetContainerNumSlots then
    return GetContainerNumSlots(bag) or 0
  end
  return 0
end

local function containerItemLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then
    return C_Container.GetContainerItemLink(bag, slot)
  end
  if GetContainerItemLink then
    return GetContainerItemLink(bag, slot)
  end
  return nil
end

local function containerItemInfo(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if type(info) == "table" then
      return info.stackCount or info.quantity or 1
    end
  end
  if GetContainerItemInfo then
    local texture, count = GetContainerItemInfo(bag, slot)
    if texture then
      return count or 1
    end
  end
  return 0
end

local function linkItemName(link)
  if not link then
    return nil
  end
  return link:match("%[(.-)%]")
end

-- Forever/Classic: GetItemCount(name) often returns 0 until the item is cached.
-- Count by scanning bag item links (and equipped main-hand for poles).
local function itemCount(name)
  if not name or name == "" then
    return 0
  end
  local total = 0
  if GetItemCount then
    local n = GetItemCount(name, false, false)
    if type(n) == "number" and n > 0 then
      total = n
    end
  end
  if total > 0 then
    return total
  end
  for bag = 0, 4 do
    local slots = containerNumSlots(bag)
    for slot = 1, slots do
      local link = containerItemLink(bag, slot)
      local linkName = linkItemName(link)
      if linkName == name then
        total = total + (containerItemInfo(bag, slot) or 1)
      end
    end
  end
  return total
end

local function itemCooldownRemaining(name)
  if not GetItemCooldown then
    return 0
  end
  local itemId = nil
  if GetItemInfo then
    local _
    _, _, _, _, _, _, _, _, _, _, itemId = GetItemInfo(name)
  end
  -- Resolve id from a bag link when name isn't cached yet.
  if not itemId then
    for bag = 0, 4 do
      local slots = containerNumSlots(bag)
      for slot = 1, slots do
        local link = containerItemLink(bag, slot)
        if linkItemName(link) == name then
          itemId = link:match("item:(%d+)")
          if itemId then
            itemId = tonumber(itemId)
          end
          break
        end
      end
      if itemId then
        break
      end
    end
  end
  if not itemId then
    itemId = name
  end
  local start, duration, enable = GetItemCooldown(itemId)
  if not start or not duration or duration <= 0 or enable == 0 then
    return 0
  end
  local left = (start + duration) - GetTime()
  if left < 0 then
    return 0
  end
  return left
end

local function formatCd(sec)
  if sec >= 60 then
    return string.format("%dm %ds", math.floor(sec / 60), math.floor(sec % 60))
  end
  return string.format("%ds", math.floor(sec + 0.5))
end

local function pickFirstOwned(list)
  for _, name in ipairs(list) do
    if itemCount(name) > 0 then
      return name
    end
  end
  return nil
end

-- First matching profession line (priority order), highest tier in that line.
local function pickBestFeature()
  for _, line in ipairs(CAMP_FEATURE_LINES) do
    for tier, name in ipairs(line.items) do
      if itemCount(name) > 0 then
        return name, line.profession, tier
      end
    end
  end
  return nil, nil, nil
end

local function campInventoryReport()
  local fire = pickFirstOwned(CAMP_FIRES)
  local feat, prof = pickBestFeature()
  campPrint("ok", "fire=" .. (fire or "none") .. " feature=" .. (feat or "none")
    .. (prof and (" (" .. prof .. ")") or ""))
  return fire, feat, prof
end

local function hasCookingSkill()
  if not GetNumSkillLines or not GetSkillLineInfo then
    return nil
  end
  for i = 1, GetNumSkillLines() do
    local name, _, _, rank = GetSkillLineInfo(i)
    if name == "Cooking" then
      return true, rank or 0
    end
  end
  return false, 0
end

local function findCraftableCampfireRecipe()
  if not GetNumTradeSkills or not GetTradeSkillInfo or not DoTradeSkill then
    return nil, nil, "no_tradeskill_api"
  end
  local line = GetTradeSkillLine and GetTradeSkillLine()
  if line and line ~= "Cooking" then
    return nil, nil, "wrong_tradeskill"
  end
  local knownButEmpty = nil
  for _, entry in ipairs(CAMP_FIRE_RECIPES) do
    for i = 1, GetNumTradeSkills() do
      local name, skillType = GetTradeSkillInfo(i)
      if skillType ~= "header" and name then
        for _, rname in ipairs(entry.names) do
          if name == rname then
            local avail = GetTradeSkillNumAvailable and (GetTradeSkillNumAvailable(i) or 0) or 0
            if avail > 0 then
              return i, entry, nil
            end
            knownButEmpty = knownButEmpty or entry
            break
          end
        end
      end
    end
  end
  if knownButEmpty then
    return nil, knownButEmpty, "missing_reagents"
  end
  return nil, nil, "recipe_not_found"
end

local function diagnoseCampfireCraftFailure(entry, reason)
  local hasCooking, rank = hasCookingSkill()
  if hasCooking == false then
    campPrint("error", "Cooking not learned — train Cooking to craft campfire kits")
    return
  end
  if itemCount("Flint and Tinder") < 1 then
    campPrint("error", "need Flint and Tinder in bags (Cooking tool) to craft a campfire")
    return
  end
  if entry and entry.reagent and itemCount(entry.reagent) < 1 then
    campPrint("error", "need " .. entry.reagent .. " to craft " .. entry.kit)
    return
  end
  if
    itemCount("Simple Wood") < 1
    and itemCount("Star Wood") < 1
    and itemCount("Thick Logs") < 1
  then
    campPrint("error", "need Simple Wood (or Star Wood / Thick Logs) to craft a campfire kit")
    return
  end
  if reason == "recipe_not_found" then
    campPrint(
      "error",
      "campfire recipe not in Cooking window"
        .. (rank and (" (Cooking " .. tostring(rank) .. ")") or "")
        .. " — open Cooking once or re-train Basic Campfire"
    )
    return
  end
  campPrint("error", "cannot craft a campfire kit right now (" .. tostring(reason or "unknown") .. ")")
end

local campCraftPending = false
local campCraftWatcher = CreateFrame("Frame")

-- Returns true if a craft was started (caller should abort place/sit this click).
local function startCraftCampfireKit()
  if campCraftPending then
    campPrint("warn", "already opening Cooking to craft — wait a moment")
    return true
  end
  if InCombatLockdown and InCombatLockdown() then
    campPrint("error", "in combat — cannot craft a campfire kit")
    return false
  end

  local function tryCraftNow()
    local idx, entry, reason = findCraftableCampfireRecipe()
    if idx and entry and DoTradeSkill then
      DoTradeSkill(idx, 1)
      campPrint(
        "ok",
        "crafting " .. entry.kit .. " (~10s) — press Campsite again when the kit appears"
      )
      return true
    end
    diagnoseCampfireCraftFailure(entry, reason)
    return false
  end

  local line = GetTradeSkillLine and GetTradeSkillLine()
  if line == "Cooking" and GetNumTradeSkills and GetNumTradeSkills() > 0 then
    return tryCraftNow()
  end

  if not CastSpellByName then
    campPrint("error", "cannot open Cooking to craft a campfire kit")
    return false
  end

  campCraftPending = true
  campCraftWatcher:RegisterEvent("TRADE_SKILL_SHOW")
  campCraftWatcher:SetScript("OnEvent", function(self, event)
    if event ~= "TRADE_SKILL_SHOW" then
      return
    end
    self:UnregisterEvent("TRADE_SKILL_SHOW")
    campCraftPending = false
    if C_Timer and C_Timer.After then
      C_Timer.After(0.05, function()
        tryCraftNow()
      end)
    else
      tryCraftNow()
    end
  end)
  CastSpellByName("Cooking")
  campPrint("ok", "opening Cooking to craft a campfire kit…")
  return true
end

local function buildCampMacrotext()
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
    campPrint("error", "you are dead — cannot place a camp")
    return nil
  end
  if InCombatLockdown and InCombatLockdown() then
    campPrint("error", "in combat — wait, then try again")
    return nil
  end

  local fire = pickFirstOwned(CAMP_FIRES)
  if not fire then
    campPrint("warn", "no campfire kit in bags — trying to craft one")
    if startCraftCampfireKit() then
      -- Craft takes ~10s; place on the next press once the kit lands in bags.
      return nil
    end
  end

  fire = pickFirstOwned(CAMP_FIRES)
  local feat, prof = pickBestFeature()
  local hadFire, hadFeat = fire ~= nil, feat ~= nil
  local lines = {}

  if fire then
    local cd = itemCooldownRemaining(fire)
    if cd > 0 then
      campPrint("error", fire .. " on cooldown (" .. formatCd(cd) .. ")")
      fire = nil
    else
      table.insert(lines, "/use " .. fire)
    end
  end

  if feat then
    local cd = itemCooldownRemaining(feat)
    if cd > 0 then
      campPrint("error", feat .. " on cooldown (" .. formatCd(cd) .. ") — camping features share a 1h CD")
      feat = nil
    else
      table.insert(lines, "/use " .. feat)
    end
  end

  if not fire and not feat then
    -- Still allow sit so visiting another player's camp works.
    if not hadFire and not hadFeat then
      campPrint("warn", "no campfire kit or profession camp object in bags — sitting only")
    else
      campPrint("warn", "no usable camp items right now — sitting only")
    end
  else
    if fire then
      campPrint("ok", "placing " .. fire)
    elseif hadFeat then
      campPrint("warn", "no campfire kit — feature needs a campfire nearby")
    end
    if feat then
      campPrint("ok", "placing " .. feat .. (prof and (" [" .. prof .. "]") or ""))
    elseif hadFire then
      campPrint("warn", "no profession camp object in bags (craft at skill 20+)")
    end
  end

  table.insert(lines, "/sit")
  return table.concat(lines, "\n")
end

local campButton = _G[CAMP_BUTTON_NAME]
  or CreateFrame("Button", CAMP_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
campButton:RegisterForClicks("AnyUp", "AnyDown")
campButton:SetScript("PreClick", function(self)
  if InCombatLockdown and InCombatLockdown() then
    campPrint("error", "in combat — wait, then try again")
    self:SetAttribute("type", nil)
    self:SetAttribute("macrotext", nil)
    return
  end
  local body = buildCampMacrotext()
  if not body then
    self:SetAttribute("type", nil)
    self:SetAttribute("macrotext", nil)
    return
  end
  self:SetAttribute("type", "macro")
  self:SetAttribute("macrotext", body)
end)

local function ensureCampsiteMacro()
  local ok = ensureAccountMacro(CAMP_MACRO_NAME, CAMP_MACRO_ICON, CAMP_MACRO_BODY)
  if ok then
    ConsolePortCouchDB.campsitePinned = true
    ConsolePortCouchDB.campsiteTs = time()
  end
  return ok
end

local function runCampsite()
  ensureCampsiteMacro()
  if InCombatLockdown and InCombatLockdown() then
    campPrint("error", "in combat — wait, then try again")
    return false
  end
  -- Drive the same secure path the action-bar macro uses.
  local body = buildCampMacrotext()
  if not body then
    return false
  end
  campButton:SetAttribute("type", "macro")
  campButton:SetAttribute("macrotext", body)
  campButton:Click()
  return true
end

local function fishPrint(kind, msg)
  local color = "|cff66ff66"
  if kind == "error" then
    color = "|cffff6666"
  elseif kind == "warn" then
    color = "|cffffaa00"
  end
  local text = color .. "Fishing:|r " .. msg
  print(text)
  if UIErrorsFrame and UIErrorsFrame.AddMessage then
    local r, g, b = 1, 0.4, 0.4
    if kind == "ok" then
      r, g, b = 0.4, 1, 0.4
    elseif kind == "warn" then
      r, g, b = 1, 0.7, 0.2
    end
    UIErrorsFrame:AddMessage(msg, r, g, b, 1.0)
  end
end

local function knowsFishing()
  -- SpellID 7620 = Fishing (Classic / Forever).
  if IsPlayerSpell and IsPlayerSpell(7620) then
    return true
  end
  if IsSpellKnown and IsSpellKnown(7620) then
    return true
  end
  -- If APIs are missing, still attempt /cast Fishing (errors in UI if unknown).
  if not IsPlayerSpell and not IsSpellKnown then
    return true
  end
  return false
end

-- Prefer link + item subtype ("Fishing Pole") and known names.
local function fishingPoleNameFromLink(link)
  if not link then
    return nil
  end
  local name = linkItemName(link)
  if name then
    for _, pole in ipairs(FISH_POLES) do
      if name == pole then
        return pole
      end
    end
  end
  if GetItemInfo then
    local itemName, _, _, _, _, _, itemSubType = GetItemInfo(link)
    local sub = itemSubType and tostring(itemSubType) or ""
    local subLower = sub:lower()
    if subLower == "fishing pole" or subLower == "fishing poles" or subLower:find("fishing", 1, true) then
      return itemName or name
    end
  end
  if name then
    local lower = name:lower()
    if lower:find("fishing pole", 1, true) or lower:find("angler", 1, true) then
      return name
    end
  end
  return nil
end

local function equippedPoleName()
  local link = GetInventoryItemLink and GetInventoryItemLink("player", 16)
  return fishingPoleNameFromLink(link)
end

local function poleRank(name)
  if not name then
    return 999
  end
  for i, n in ipairs(FISH_POLES) do
    if n == name then
      return i
    end
  end
  -- Unknown Forever pole: prefer over the vendor stick, worse than named list.
  return #FISH_POLES
end

local function findBestPoleInBags()
  local bestName, bestRank = nil, 999
  -- 0=backpack, 1-4=bags (Classic/Forever). Bank not needed for fishing cast.
  for bag = 0, 4 do
    local slots = containerNumSlots(bag)
    for slot = 1, slots do
      local link = containerItemLink(bag, slot)
      local name = fishingPoleNameFromLink(link)
      if name then
        local rank = poleRank(name)
        if rank < bestRank then
          bestName, bestRank = name, rank
        end
      end
    end
  end
  return bestName
end

local function bestPoleToEquip()
  local equipped = equippedPoleName()
  local bagPole = findBestPoleInBags()
  if not bagPole then
    return nil, equipped
  end
  if not equipped or poleRank(bagPole) < poleRank(equipped) then
    return bagPole, equipped
  end
  return nil, equipped
end

local function hasWeaponLure()
  if not GetWeaponEnchantInfo then
    return false
  end
  local hasMainHandEnchant = GetWeaponEnchantInfo()
  return hasMainHandEnchant and true or false
end

local function isWellFed()
  if not UnitBuff then
    return false
  end
  for i = 1, 40 do
    local name = UnitBuff("player", i)
    if not name then
      break
    end
    if name == "Well Fed" or name == "Food" or name == "Drink" then
      return true
    end
  end
  return false
end

local function fishInventoryReport()
  local equipPole = equippedPoleName()
  local wantPole = findBestPoleInBags()
  local lure = pickFirstOwned(FISH_LURES)
  local food = pickFirstOwned(FISH_FOOD)
  local feat = pickFirstOwned(FISH_CAMP_FEATURES)
  local fire = pickFirstOwned(CAMP_FIRES)
  fishPrint(
    "ok",
    "pole="
      .. (equipPole or "none")
      .. (wantPole and (" bag=" .. wantPole) or "")
      .. " lure="
      .. (lure or "none")
      .. (hasWeaponLure() and " (applied)" or "")
      .. " food="
      .. (food or "none")
      .. " camp="
      .. (feat or "none")
      .. " fire="
      .. (fire or "none")
  )
end

local function buildFishMacrotext()
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
    fishPrint("error", "you are dead — cannot fish")
    return nil
  end
  if InCombatLockdown and InCombatLockdown() then
    fishPrint("error", "in combat — wait, then try again")
    return nil
  end
  if not knowsFishing() then
    fishPrint("error", "Fishing skill not learned — visit a fishing trainer")
    return nil
  end

  local lines = {}
  local equipPole, currentPole = bestPoleToEquip()
  if equipPole then
    table.insert(lines, "/equip " .. equipPole)
    fishPrint("ok", "equipping " .. equipPole)
  elseif not currentPole then
    if not findBestPoleInBags() then
      fishPrint("error", "no fishing pole equipped or in bags")
      return nil
    end
  else
    fishPrint("ok", "using " .. currentPole)
  end

  if not hasWeaponLure() then
    local lure = pickFirstOwned(FISH_LURES)
    if lure then
      local cd = itemCooldownRemaining(lure)
      if cd > 0 then
        fishPrint("warn", lure .. " on cooldown (" .. formatCd(cd) .. ") — casting without new lure")
      else
        table.insert(lines, "/use " .. lure)
        fishPrint("ok", "applying " .. lure)
      end
    else
      fishPrint("warn", "no lure in bags (Shiny Bauble / Nightcrawlers / Bright Baubles / Attractor)")
    end
  else
    fishPrint("ok", "lure already on pole")
  end

  if not isWellFed() then
    local food = pickFirstOwned(FISH_FOOD)
    if food then
      table.insert(lines, "/use " .. food)
      fishPrint("ok", "eating " .. food .. " (+Fishing)")
    end
  end

  -- Forever uncommon/rare catches need Rack/Hut at a campfire.
  local feat = pickFirstOwned(FISH_CAMP_FEATURES)
  if feat then
    local cd = itemCooldownRemaining(feat)
    if cd > 0 then
      fishPrint("warn", feat .. " on cooldown (" .. formatCd(cd) .. ") — camping features share 1h CD")
    else
      local fire = pickFirstOwned(CAMP_FIRES)
      if not fire then
        fishPrint("warn", "no campfire kit — crafting one before placing " .. feat)
        if startCraftCampfireKit() then
          return nil
        end
        fire = pickFirstOwned(CAMP_FIRES)
      end
      if fire then
        local fcd = itemCooldownRemaining(fire)
        if fcd > 0 then
          fishPrint("warn", fire .. " on cooldown — place " .. feat .. " near an existing fire")
        else
          table.insert(lines, "/use " .. fire)
          fishPrint("ok", "placing " .. fire)
        end
      else
        fishPrint("warn", "no campfire kit — " .. feat .. " needs a campfire nearby")
      end
      table.insert(lines, "/use " .. feat)
      fishPrint("ok", "placing " .. feat .. " (Forever uncommon/rare fishing)")
    end
  else
    fishPrint(
      "warn",
      "no Fishing Hut/Rack/Bowl in bags — craft at Fishing 20/140/300 for Forever catches"
    )
  end

  table.insert(lines, "/cast Fishing")
  return table.concat(lines, "\n")
end

local fishButton = _G[FISH_BUTTON_NAME]
  or CreateFrame("Button", FISH_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
fishButton:RegisterForClicks("AnyUp", "AnyDown")
fishButton:SetScript("PreClick", function(self)
  if InCombatLockdown and InCombatLockdown() then
    fishPrint("error", "in combat — wait, then try again")
    self:SetAttribute("type", nil)
    self:SetAttribute("macrotext", nil)
    return
  end
  local body = buildFishMacrotext()
  if not body then
    self:SetAttribute("type", nil)
    self:SetAttribute("macrotext", nil)
    return
  end
  self:SetAttribute("type", "macro")
  self:SetAttribute("macrotext", body)
end)

local function ensureFishingMacro()
  local ok = ensureAccountMacro(FISH_MACRO_NAME, FISH_MACRO_ICON, FISH_MACRO_BODY)
  if ok then
    ConsolePortCouchDB.fishingPinned = true
    ConsolePortCouchDB.fishingTs = time()
  end
  return ok
end

local function runFishing()
  ensureFishingMacro()
  if InCombatLockdown and InCombatLockdown() then
    fishPrint("error", "in combat — wait, then try again")
    return false
  end
  local body = buildFishMacrotext()
  if not body then
    return false
  end
  fishButton:SetAttribute("type", "macro")
  fishButton:SetAttribute("macrotext", body)
  fishButton:Click()
  return true
end

local function pinInviteNearestBindings(force)
  if InCombatLockdown and InCombatLockdown() then
    return false
  end
  if not ensureInviteMacro() then
    return false
  end

  -- Session-only SetBinding; never SaveBindings (see pinGameMenuBindings).
  -- Persist RB via scripts/pin-invite-nearest-macro.sh (bindings-cache + Shared).
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
  -- Never re-apply the Xbox preset over an existing layout. Only apply when
  -- shoulders/triggers are blank, or the user force-runs /cpcouch apply.
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
  elseif msg == "camp" or msg == "campsite" or msg == "usecamp" or msg == "place" then
    runCampsite()
  elseif msg == "pincamp" then
    if ensureCampsiteMacro() then
      print(
        "|cff66ff66ConsolePort Couch:|r account macro |cffffffff"
          .. CAMP_MACRO_NAME
          .. "|r → /click "
          .. CAMP_BUTTON_NAME
          .. " (fire + profession object + /sit). Drag onto a gamepad bar slot."
      )
    else
      print("|cffff6666ConsolePort Couch:|r could not create Campsite macro.")
    end
  elseif msg == "campstatus" or msg == "campinv" then
    campInventoryReport()
  elseif msg == "fish" or msg == "fishing" then
    runFishing()
  elseif msg == "pinfish" then
    if ensureFishingMacro() then
      print(
        "|cff66ff66ConsolePort Couch:|r account macro |cffffffff"
          .. FISH_MACRO_NAME
          .. "|r → /click "
          .. FISH_BUTTON_NAME
          .. " (pole + lure + food + Hut/Rack + cast). Drag onto a gamepad bar slot."
      )
    else
      print("|cffff6666ConsolePort Couch:|r could not create FishingCouch macro.")
    end
  elseif msg == "fishstatus" or msg == "fishinv" then
    fishInventoryReport()
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
      "CursorAutoEnable=",
      tostring(GetCVar and GetCVar("GamePadCursorAutoEnable"))
    )
    campInventoryReport()
    fishInventoryReport()
  else
    print(
      "|cff66ff66ConsolePort Couch:|r /cpcouch apply | menu | invite | camp | fish | pincamp | pinfish | campstatus | fishstatus | status"
    )
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
    -- Re-pin after Forever/CP finish remapping gamepad actions.
    C_Timer.After(5.0, function()
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
