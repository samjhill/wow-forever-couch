--[[
  CouchDictateRoute — set sticky chat type for external voice dictation.

  Policy (matches host inject override docs):
    - Raid                        → RAID
    - Party of 3+                 → PARTY
    - Solo or party of 1–2        → SAY

  Does NOT call SendChatMessage. Message send stays on the player's physical
  confirm (controller Enter) or host draft/send inject. Only adjusts the
  default chat type used when Enter opens the edit box.
]]

local ADDON = ...
local f = CreateFrame("Frame")

local OVERRIDE = nil -- nil = auto; otherwise "SAY" | "PARTY" | "RAID"

local function groupSize()
  if IsInGroup and IsInGroup() then
    return GetNumGroupMembers() or 0
  end
  return 0
end

-- Pure policy used by host-side unit tests (keep in sync with resolve_channel.py).
local function resolveChatType()
  if OVERRIDE then
    return OVERRIDE, "override"
  end
  if IsInRaid and IsInRaid() then
    return "RAID", "raid"
  end
  local n = groupSize()
  if n >= 3 then
    return "PARTY", "party3+"
  end
  return "SAY", (n >= 1) and "party2" or "solo"
end

local function eachEditBox(fn)
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local frame = _G["ChatFrame" .. i]
    local editBox = frame and frame.editBox
    if editBox and editBox.SetAttribute then
      fn(editBox)
    end
  end
  -- Some builds keep a global ChatFrame1EditBox alias
  if ChatFrame1EditBox and ChatFrame1EditBox.SetAttribute then
    fn(ChatFrame1EditBox)
  end
end

local function applySticky(quiet)
  local chatType, reason = resolveChatType()
  eachEditBox(function(editBox)
    -- SetAttribute chatType/stickyType is the supported Blizzard path used by
    -- ChatFrame_OpenChat; it is not a protected action and does not send chat.
    editBox:SetAttribute("chatType", chatType)
    editBox:SetAttribute("stickyType", chatType)
    if ChatEdit_UpdateHeader then
      ChatEdit_UpdateHeader(editBox)
    end
  end)
  if CouchDictateRouteDB then
    CouchDictateRouteDB.lastType = chatType
    CouchDictateRouteDB.lastReason = reason
  end
  if not quiet then
    local msg = ("CouchDictateRoute: sticky → %s (%s)"):format(chatType, reason)
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff" .. msg .. "|r")
    end
  end
  return chatType, reason
end

local deferFrame = CreateFrame("Frame")
local function deferApply()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      applySticky(true)
    end)
    return
  end
  -- Fallback if C_Timer is unavailable: one OnUpdate tick.
  deferFrame:SetScript("OnUpdate", function(self)
    self:SetScript("OnUpdate", nil)
    applySticky(true)
  end)
end

local function onEvent(_, event)
  if event == "ADDON_LOADED" then
    return
  end
  deferApply()
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("RAID_ROSTER_UPDATE") then
  f:RegisterEvent("RAID_ROSTER_UPDATE")
end
f:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    CouchDictateRouteDB = CouchDictateRouteDB or {}
    if CouchDictateRouteDB.override == "" then
      CouchDictateRouteDB.override = nil
    end
    OVERRIDE = CouchDictateRouteDB.override
    return
  end
  onEvent(self, event)
end)
f:RegisterEvent("ADDON_LOADED")

SLASH_COUCHDICTATEROUTE1 = "/cdr"
SLASH_COUCHDICTATEROUTE2 = "/couchdictate"
SlashCmdList.COUCHDICTATEROUTE = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""
  if msg == "" or msg == "status" then
    local chatType, reason = resolveChatType()
    print(("CouchDictateRoute: would use %s [%s]  size=%s raid=%s override=%s"):format(
      chatType,
      reason,
      tostring(groupSize()),
      tostring(IsInRaid and IsInRaid() or false),
      tostring(OVERRIDE or "auto")
    ))
    return
  end
  if msg == "auto" or msg == "clear" then
    OVERRIDE = nil
    if CouchDictateRouteDB then
      CouchDictateRouteDB.override = nil
    end
    applySticky(false)
    return
  end
  local map = { say = "SAY", s = "SAY", party = "PARTY", p = "PARTY", raid = "RAID", r = "RAID" }
  local t = map[msg]
  if not t then
    print("CouchDictateRoute: /cdr status | auto | say | party | raid")
    return
  end
  OVERRIDE = t
  if CouchDictateRouteDB then
    CouchDictateRouteDB.override = t
  end
  applySticky(false)
end

-- Export for other addons / debugging
_G.CouchDictateRoute_Resolve = resolveChatType
_G.CouchDictateRoute_Apply = applySticky
