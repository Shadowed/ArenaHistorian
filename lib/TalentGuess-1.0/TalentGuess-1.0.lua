local major = "TalentGuess-1.0"
local minor = tonumber(string.match("$Revision: 702$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Talents = LibStub:NewLibrary(major, minor)
if( not Talents ) then return end

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d for '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from a registered %s object.",
}

Talents.spells = TalentGuess10Spells
Talents.castSpells = TalentGuess10CastOnly
Talents.enemySpellRecords = Talents.enemySpellRecords or {}
Talents.totalRegistered = Talents.totalRegistered or 0
Talents.registeredObjs = Talents.registeredObjs or {}
Talents.frame = Talents.frame or CreateFrame("Frame")

local enemySpellRecords = Talents.enemySpellRecords
local registeredObjs = Talents.registeredObjs
local talentPoints = {}
local checkBuffs = {}
local methods = {"EnableCollection", "DisableCollection", "GetTalents"}

-- Validation for passed arguments
local function assert(level, condition, message)
	if( not condition ) then
		error(message, level)
	end
end

local function argcheck(value, num, ...)
	if( type(num) ~= "number" ) then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if( type(value) == select(i, ...) ) then return end
	end

	local types = string.join(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["BAD_ARGUMENT"]:format(num, name, types, type(value)), 3)
end

-- PUBLIC METHODS
function Talents:Register()
	Talents.totalRegistered = Talents.totalRegistered + 1
	local id = Talents.totalRegistered
	
	registeredObjs[id] = {}
	registeredObjs[id].id = id
	registeredObjs[id].collecting = false
	
	for _, func in pairs(methods) do
		registeredObjs[id][func] = Talents[func]
	end
	
	return registeredObjs[id]
end

function Talents.EnableCollection(self)
	assert(3, self.id and registeredObjs[self.id], string.format(L["MUST_CALL"], "EnableCollection", major))
	
	registeredObjs[self.id].collecting = true
	Talents:CheckCollecting()
end

function Talents.DisableCollection(self)
	assert(3, self.id and registeredObjs[self.id], string.format(L["MUST_CALL"], "DisableCollection", major))
	
	registeredObjs[self.id].collecting = false
	Talents:CheckCollecting()
end

-- Return our guess at their talents
function Talents:GetTalents(name)
	argcheck(name, 1, "string")
	
	if( not enemySpellRecords[name] ) then
		return nil
	end
	
	talentPoints[1] = 0
	talentPoints[2] = 0
	talentPoints[3] = 0
	
	for spellID in pairs(enemySpellRecords[name]) do
		local treeNum, points, isBuff
		if( Talents.spells[spellID] ) then
			treeNum, points, isBuff = string.split(":", Talents.spells[spellID])
		elseif( Talents.castSpells[spellID] ) then
			treeNum, points, isBuff = string.split(":", Talents.castSpells[spellID])
		end
		
		treeNum = tonumber(treeNum)
		points = tonumber(points)
		
		if( talentPoints[treeNum] < points ) then
			talentPoints[treeNum] = points
		end
	end
	
	return talentPoints[1], talentPoints[2], talentPoints[3]
end

-- PRIVATE METHODS
-- Add a new spell record for this person
local function addSpell(spellID, guid, name)
	-- Record that they either used, or gained this spellID so we can parse it later
	if( not enemySpellRecords[name] ) then
		enemySpellRecords[name] = {}
	end

	enemySpellRecords[name][spellID] = true
end

-- Buff scan for figuring out talents if we need to
local function PLAYER_TARGET_CHANGED()
	-- Make sure it's a valid unit
	if( not UnitExists("target") or not UnitIsPlayer("target") or not UnitIsEnemy("player", "target") or UnitIsCharmed("target") or UnitIsCharmed("player") ) then
		return
	end

	local fullName, server = UnitName("target")
	if( server and server ~= "" ) then
		fullName = string.format("%s-%s", fullName, server)
	end
	
	local id = 0

	while( true ) do
		id = id + 1
		local name, rank = UnitBuff("target", id)
		if( not name ) then break end
		
		local spellID = checkBuffs[name .. (rank or "")]
		if( spellID ) then
			addSpell(spellID, UnitGUID("target"), fullName)
		end
	end
end

-- Data recording!
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
local ENEMY_AFFILIATION = bit.bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_TYPE_PLAYER)

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_CAST_SUCCESS"] = true, ["SPELL_CAST_START"] = true}
local function COMBAT_LOG_EVENT_UNFILTERED(timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if( not eventRegistered[eventType] ) then
		return
	end
	
	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" and bit.band(destFlags, ENEMY_AFFILIATION) == ENEMY_AFFILIATION ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( Talents.spells[spellID] and auraType == "BUFF" ) then
			addSpell(spellID, destGUID, destName)
		end
	
	-- Spell started to cast
	elseif( eventType == "SPELL_CAST_START"  and bit.band(sourceFlags, ENEMY_AFFILIATION) == ENEMY_AFFILIATION ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( Talents.spells[spellID] or Talents.castSpells[spellID] ) then
			addSpell(spellID, sourceGUID, sourceName)
		end

	-- Spell casted succesfully
	elseif( eventType == "SPELL_CAST_SUCCESS" and bit.band(sourceFlags, ENEMY_AFFILIATION) == ENEMY_AFFILIATION ) then
		local spellID, spellName, spellSchool, auraType = ...
		if( Talents.spells[spellID] or Talents.castSpells[spellID] ) then
			addSpell(spellID, sourceGUID, sourceName)
		end
	end
end

local function OnEvent(self, event, ...)
	if( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
		COMBAT_LOG_EVENT_UNFILTERED(...)
	elseif( event == "PLAYER_TARGET_CHANGED" ) then
		PLAYER_TARGET_CHANGED(...)
	end
end

-- Check if we need to enable, or disable the event
function Talents:CheckCollecting()
	for _, obj in pairs(registeredObjs) do
		if( obj.collecting ) then
			Talents.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			Talents.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
			return
		end
	end
	
	Talents.frame:UnregisterAllEvents()
end

Talents.frame:SetScript("OnEvent", OnEvent)
Talents:CheckCollecting()

-- Cache our list of buffs that we should scan when targeting
for spellID, data in pairs(Talents.spells) do
	local treeNum, points, isBuff = string.split(":", data)
	if( isBuff == "true" ) then
		local name, rank = GetSpellInfo(spellID)
		if( name ) then
			checkBuffs[name .. (rank or "")] = spellID
		end
	end
end

-- DEBUG
--[[
function used(name)
	local list = {}
	for spellID in pairs(enemySpellRecords[name]) do
		local name, rank = GetSpellInfo(spellID)
		if( name ) then
			if( rank and rank ~= "" ) then
				table.insert(list, string.format("[#%d] %s (%s)", spellID, name, rank))
			else
				table.insert(list, string.format("[#%d] %s", spellID, name))
			end
		end
	end
	
	ChatFrame1:AddMessage(table.concat(list, ", "))
end


function test()
	for name in pairs(enemySpellRecords) do
		local one, two, three = Talents:GetTalents(name)
		if( one and two and three ) then
			ChatFrame1:AddMessage(string.format("[%s] %d/%d/%d", name, one, two, three))
			used(name)
		end
	end
end
]]