local currentPlayerName = UnitName("player")
local _, _, classIndex = UnitClass("player")
local playerGuid = UnitGUID("player")

-- Constants
local HUNTER_CLASS_INDEX = 3

local brezMatchStrings = {
  "brez",
  "battle rez",
  "rez",
  "resurrect",
  "battle resurrection",
  "battlerez"
}

local spells = {
  20484, -- Rebirth (Druid)
  20707, -- Soulstone (Warlock)
  61999, -- Raise Ally (Death Knight)
  391054, -- Intercession (Paladin)
  159956, -- Dust of Life (Hunter Pet)
  159931  -- Gift of Chi-Ji (Hunter Pet)
}

local function playerIsHunter(playerClassIndex, hunterClassIndex)
  return playerClassIndex == hunterClassIndex
end

local function containsSubstring(inputString)
  for _, substring in ipairs(brezMatchStrings) do
      if string.find(inputString:lower(), substring) then
          return true, substring
      end
  end
  return false, nil
end

local function findKnownSpell(spells)
  for _, spell in ipairs(spells) do
      if isSpellKnown(spell, playerIsHunter(classIndex, HUNTER_CLASS_INDEX)) then
          return spell
      end
  end
  return nil
end

function formatTime(seconds)
  if seconds < 60 then
      return string.format("0:%02d", seconds)
  else
      local minutes = math.floor(seconds / 60)
      local remainingSeconds = seconds % 60
      return string.format("%d:%02d", minutes, remainingSeconds)
  end
end


local function sendUpdateMessage(text, senderGuid)

  local isInCombat = InCombatLockdown()
  local isInInstance = IsInInstance()
  local battleRezSpell = findKnownSpell(spells)
  local textMatch = containsSubstring(text)

  if senderGuid == playerGuid or not textMatch or not isInInstance or not isInCombat or not battleRezSpell then
    return false
  end

  local spellLink = GetSpellLink(battleRezSpell)
  local brezCooldown = GetSpellCooldown(battleRezSpell)

  if brezCooldown > 0 then
    local message = currentPlayerName .. " - " .. spellLink .. " has " .. formatTime(brezCooldown) .. " remaining on cooldown."
    if IsInGroup(2) then
      SendChatMessage(message,"INSTANCE_CHAT")
    elseif IsInGroup() and not IsInGroup(2) then
		  SendChatMessage(message,"PARTY")
	  elseif IsInGroup() and not IsInGroup(2) and IsInRaid() then
		  SendChatMessage(message,"RAID")
    end
  end
end

-- Handle Events
local f = CreateFrame("Frame");
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
f:RegisterEvent("CHAT_MSG_PARTY")
f:RegisterEvent("CHAT_MSG_SAY")
f:RegisterEvent("CHAT_MSG_YELL")

function f:CHAT_MSG_SAY(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, ChannelIndex, channelBaseName, languageID, guid)
  sendUpdateMessage(text, guid)
end

function f:CHAT_MSG_YELL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, ChannelIndex, channelBaseName, languageID, guid)
  sendUpdateMessage(text, guid)
end

function f:CHAT_MSG_PARTY(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, ChannelIndex, channelBaseName, languageID, guid)
  sendUpdateMessage(text, guid)
end

function f:CHAT_MSG_INSTANCE_CHAT(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, ChannelIndex, channelBaseName, languageID, guid)
  sendUpdateMessage(text, guid)
end

f:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)
