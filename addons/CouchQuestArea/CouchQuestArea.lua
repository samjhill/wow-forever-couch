-- Questie's Questie/pfQuest icon themes set questPOI to 0, which removes
-- Forever's shaded "travel here" areas on the map. Pins can stay on.
local function enableQuestAreas()
  local turnedOn = false
  if GetCVar and SetCVar and GetCVar("questPOI") ~= nil and GetCVar("questPOI") ~= "1" then
    SetCVar("questPOI", "1")
    turnedOn = true
  end
  if WorldMapQuestShowObjectives and WorldMapQuestShowObjectives.GetChecked and not WorldMapQuestShowObjectives:GetChecked() then
    pcall(function()
      WorldMapQuestShowObjectives:Click()
    end)
    turnedOn = true
  end
  return turnedOn
end

SLASH_COUCHQUESTAREA1 = "/couchquestarea"
SlashCmdList.COUCHQUESTAREA = function()
  if enableQuestAreas() then
    print("|cff66ff66Couch Quest Area:|r map quest areas on.")
  else
    print("|cff66ff66Couch Quest Area:|r map quest areas already on.")
  end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
  C_Timer.After(1.5, function()
    if enableQuestAreas() then
      print("|cff66ff66Couch Quest Area:|r shaded quest areas are on. Questie pins stay.")
    end
  end)
end)
