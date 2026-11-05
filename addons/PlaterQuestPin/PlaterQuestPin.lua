-- Ensure Plater shows quest kill/loot progress on enemy nameplates (Forever).
-- Relies on tooltip quest lines (CVar showQuestTrackingTooltips) + Plater plate_config.
PlaterQuestPinDB = PlaterQuestPinDB or {}

local function setCVarSafe(name, value)
  if GetCVar and SetCVar and GetCVar(name) ~= nil then
    pcall(SetCVar, name, value)
    return true
  end
  return false
end

local function pinPlaterQuestTracking()
  -- Without this, unit tooltips often omit "3/10 Foo" lines Plater scans.
  local cvarOk = setCVarSafe("showQuestTrackingTooltips", "1")

  if not Plater or not Plater.db or not Plater.db.profile then
    return false, cvarOk
  end

  local profile = Plater.db.profile
  profile.indicator_quest = true

  local plate = profile.plate_config
  if not plate then
    return false, cvarOk
  end

  if plate.enemynpc then
    plate.enemynpc.quest_enabled = true
    plate.enemynpc.quest_color_enabled = true
  end
  if plate.friendlynpc then
    plate.friendlynpc.quest_enabled = true
    plate.friendlynpc.quest_color_enabled = true
  end

  -- Refresh cached plate config pointers Plater uses in combat updates.
  if Plater.RefreshDBUpvalues then
    pcall(Plater.RefreshDBUpvalues)
  elseif Plater.UpdatePlateConfig then
    pcall(Plater.UpdatePlateConfig)
  end

  PlaterQuestPinDB.ts = time()
  PlaterQuestPinDB.cvar = cvarOk
  PlaterQuestPinDB.enemy = plate.enemynpc and plate.enemynpc.quest_enabled or nil
  return true, cvarOk
end

SLASH_PLATERQUESTPIN1 = "/platerquestpin"
SLASH_PLATERQUESTPIN2 = "/pqpin"
SlashCmdList.PLATERQUESTPIN = function()
  local ok, cvarOk = pinPlaterQuestTracking()
  if ok then
    print(
      "|cff66ff66Plater Quest Pin:|r Track Quests Progress + Use Quest Color ON"
        .. (cvarOk and "; showQuestTrackingTooltips=1" or "; CVar missing on this client")
    )
  else
    print("|cffff6666Plater Quest Pin:|r Plater profile not ready — try again after login.")
  end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
  C_Timer.After(2.0, function()
    local ok = pinPlaterQuestTracking()
    if ok then
      print(
        "|cff66ff66Plater Quest Pin:|r quest mob color + progress tracking enabled."
          .. " Hostile quest NPCs tint orange; amounts come from the unit tooltip."
      )
    end
  end)
end)
