--[[ 
	Arena Historian Shadow (Horde) from Mal'Ganis (US)
]]

ArenaHistorian = LibStub("AceAddon-3.0"):NewAddon("ArenaHistorian", "AceEvent-3.0")

local L = ArenaHistLocals
local playerRaceInfo, partyMap, arenaTeams = {}, {}, {}
local inspectQueue, alreadyInspected, friendlyTalentData = {}, {}, {}
local inspectedUnit, modEnabled, matchRecorded, instanceType

local genderMap = {[1] = "FEMALE", [2] = "MALE", [3] = "FEMALE"}

function ArenaHistorian:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
			enableMax = false,
			maxRecords = 5,
			enableWeek = false,
			maxWeeks = 4,
			arenaPoints = 0,
			lastBracket = 2,
			lastType = "history",
			
			resets = {},
		}
	}
	
	if( not ArenaHistoryData ) then
		ArenaHistoryData = {[2] = {}, [3] = {}, [5] = {}}
	end

	if( not ArenaHistoryCustomData ) then
		ArenaHistoryCustomData = {}
	end

	-- Prevents us from having to do 50 concats
	for i=1, MAX_PARTY_MEMBERS do
		partyMap[i] = "party" .. i .. "target"
	end
	
	-- Init DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ArenaHistorianDB", self.defaults)
	self.revision = tonumber(string.match("$Revision$", "(%d+)")) or 1

	-- Register the talent guessing lib
	self.talents = LibStub:GetLibrary("TalentGuess-1.1"):Register()
	
	-- Set players race/sex
	playerRaceInfo[UnitName("player")] = string.format("%s_%s", string.upper(select(2, UnitRace("player"))), genderMap[UnitSex("player")])
end

function ArenaHistorian:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("HONOR_CURRENCY_UPDATE", "CheckArenaReset")
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
	
	self:ZONE_CHANGED_NEW_AREA()
end

function ArenaHistorian:OnDisable()
	instanceType = nil

	self:UnregisterAllEvents()
end

function ArenaHistorian:CheckArenaReset()
	if( GetArenaCurrency() > self.db.profile.arenaPoints ) then
		table.insert(self.db.profile.resets, time())
	end

	self.db.profile.arenaPoints = GetArenaCurrency()
end

-- Last ditch effort
function ArenaHistorian:RaceToToken(race)
	for token, localRace in pairs(L["TOKENS"]) do
		if( localRace == race ) then
			return token
		end
	end
	
	return ""
end

-- Record new data
function ArenaHistorian:UPDATE_BATTLEFIELD_SCORE()
	if( not GetBattlefieldWinner() or not select(2, IsActiveBattlefieldArena()) or matchRecorded ) then
		return
	end	
	
	matchRecorded = true

	-- Figure out what bracket we're in
	local bracket
	for i=1, MAX_BATTLEFIELD_QUEUES  do
		local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
		if( status == "active" ) then
			bracket = teamSize
			break
		end
	end

	-- Failed (bad)
	if( not bracket ) then
		return
	end

	-- Resave list of player teams
	for i=1, MAX_ARENA_TEAMS do
		local teamName, teamSize = GetArenaTeam(i)
		if( teamName and teamSize ) then
			arenaTeams[teamName .. teamSize] = true
		end
	end

	-- Record rating/team names
	local playerIndex, playerName, playerRating, playerChange, playerSkill, enemyName, enemyRating, enemyChange, enemySkill
	local playerWon = -1

	for i=0, 1 do
		local teamName, oldRating, newRating, teamSkill = GetBattlefieldTeamInfo(i)
		if( arenaTeams[teamName .. bracket] ) then
			playerName = teamName
			playerRating = newRating
			playerChange = newRating - oldRating
			playerSkill = teamSkill
			
			if( GetBattlefieldWinner() == i ) then
				playerWon = 1
			end

			playerIndex = i
		else
			enemyName = teamName
			enemyRating = newRating
			enemyChange = newRating - oldRating
			enemySkill = teamSkill
		end
	end

	-- Couldn't find player team data
	if( not playerName or not playerIndex ) then
		return
	end

	-- Check for draw game
	if( not GetBattlefieldTeamInfo(GetBattlefieldWinner()) ) then
		playerWon = 0
	end

	-- Score data
	local playerData = {}
	local enemyData = {}
	local enemyServer = ""
	
	for i=1, GetNumBattlefieldScores() do
		local name, _, _, _, _, faction, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)

		local server, parseName
		if( string.match(name, "-") ) then
			parseName, server = string.match(name, "(.-)%-(.*)$")
		else
			server = GetRealmName()	
			parseName = name
		end

		-- Grab talent data if we have it available
		local spec = ""

		-- We don't have to inspect ourself to get info, it's always available
		if( name == UnitName("player") ) then
			local firstPoints = select(3, GetTalentTabInfo(1)) or 0
			local secondPoints = select(3, GetTalentTabInfo(2)) or 0
			local thirdPoints = select(3, GetTalentTabInfo(3)) or 0

			spec = string.format("%d/%d/%d", firstPoints, secondPoints, thirdPoints)
			
		-- Group member data
		elseif( friendlyTalentData[name] ) then
			spec = friendlyTalentData[name]

		-- See if we have custom data on them
		elseif( faction ~= playerIndex ) then
			enemyServer = server
			
			local firstPoints, secondPoints, thirdPoints = self.talents:GetTalents(name)
			if( firstPoints and secondPoints and thirdPoints ) then
				spec = string.format("%d/%d/%d", firstPoints, secondPoints, thirdPoints)
			end
		end

		-- Add it to the team list
		local data = string.format("%s,%s,%s,%s,%s,%s", parseName, spec, classToken, playerRaceInfo[name] or self:RaceToToken(race), healingDone, damageDone)
		if( faction == playerIndex ) then
			table.insert(playerData, data)
		else
			table.insert(enemyData, data)
		end
	end

	-- Bugged game, this isn't really the best way of doing it though, but it works
	if( #(enemyData) == 0 or #(playerData) == 0 ) then
		return
	end

	-- Save player information
	--[[
		First set of name/class/race/spec are the players team, second set are enemy

		<team mate> format is <name>,<spec>,<classToken>,<race>,<healing>,<damage>

		[<time>::<playerTeam>::<enemyTeam>] = "<zone>:<bracket>:<runtime>:<true/false>:<prating>:<pchange>:<erating>:<echange>:<eserver>:<pserver>;<player team mates>;<enemy team mates>"
	]]

	-- Translate localized zone text to an unlocalized version
	local zoneText = GetRealZoneText()
	if( zoneText == L["Blade's Edge Arena"] ) then
		zoneText = "BEA"
	elseif( zoneText == L["Nagrand Arena"] ) then
		zoneText = "NA"
	elseif( zoneText == L["Ruins of Lordaeron"] ) then
		zoneText = "RoL"
	elseif( zoneText == L["Dalaran Arena"] ) then
		zoneText = "DA"
	elseif( zoneText == L["The Ring of Valor"] ) then
		zoneText = "RoV"
	else
		zoneText = ""
	end

	local runTime = GetBattlefieldInstanceRunTime() or 0
	local index = string.format("%d::%s::%s", time(), playerName, enemyName)
	local data = string.format("%s:%d:%d:%s:%d:%s:%d:%d:%d:%d:%s:%s;%s;%s", zoneText, bracket, runTime, playerWon, playerSkill, playerRating, playerChange, enemySkill, enemyRating, enemyChange, enemyServer, GetRealmName(), table.concat(playerData, ":"), table.concat(enemyData, ":"))

	-- Save
	ArenaHistoryData[bracket][index] = data
end

-- Get enemy/team mate races
function ArenaHistorian:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function ArenaHistorian:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function ArenaHistorian:ScanUnit(unit)
	if( UnitIsPlayer(unit) and UnitIsVisible(unit) ) then
		local name, server = UnitName(unit)
		if( server and server ~= "" ) then
			name = string.format("%s-%s", name, server)
		end

		playerRaceInfo[name] = string.format("%s_%s", string.upper(select(2, UnitRace(unit))), genderMap[UnitSex(unit)])
	end
end

function ArenaHistorian:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( msg == L["The Arena battle has begun!"] ) then
		self:UnregisterEvent("RAID_ROSTER_UPDATE")
		self:UnregisterEvent("INSPECT_TALENT_READY")
	end
end

-- Are we inside an arena?
function ArenaHistorian:ZONE_CHANGED_NEW_AREA()
	self:CheckArenaReset()

	local type = select(2, IsInInstance())
	
	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType and select(2, IsActiveBattlefieldArena()) ) then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:RegisterEvent("INSPECT_TALENT_READY")
		self:RegisterEvent("RAID_ROSTER_UPDATE")
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:RAID_ROSTER_UPDATE()
		
		-- Scan magic to make sure we get races of enemies
		if( not self.scanFrame ) then
			local timeElapsed = 0
			self.scanFrame = CreateFrame("Frame")
			self.scanFrame:SetScript("OnUpdate", function(self, elapsed)
				timeElapsed = timeElapsed + elapsed
				
				if( timeElapsed >= 2 ) then
					timeElapsed = 0
					for i=1, GetNumPartyMembers() do
						local unit = partyMap[i]
						if( UnitExists(unit) ) then
							ArenaHistorian:ScanUnit(unit)
						end
					end
				end
			end)
		else
			self.scanFrame:Show()
		end
				
		-- Enable talent module
		self.talents:EnableCollection()
		
		matchRecorded = nil
		modEnabled = true

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" and modEnabled ) then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:UnregisterEvent("RAID_ROSTER_UPDATE")
		self:UnregisterEvent("INSPECT_TALENT_READY")
		self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		
		if( self.scanFrame ) then
			self.scanFrame:Hide()
		end
		
		modEnabled = nil
		
		-- Clear temp, blah blah blah
		inspectedUnit = nil
		for i=#(inspectQueue), 1, -1 do
			table.remove(inspectQueue, i)
		end
		
		for k in pairs(alreadyInspected) do alreadyInspected[k] = nil end

		-- Disable talent module
		self.talents:DisableCollection()
	end
	
	instanceType = type
end

-- Record maximums, we only run these on logout for performance reasons
function ArenaHistorian:PLAYER_LOGOUT()
	self:CheckHistory(2)
	self:CheckHistory(3)
	self:CheckHistory(5)
end

local function sortHistory(a, b)
	if( not a ) then
		return true
	elseif( not b ) then
		return false
	end

	return a.time > b.time
end

function ArenaHistorian:CheckHistory(bracket)
	if( not self.db.profile.enableMax and not self.db.profile.enableWeek ) then
		return
	end

	local history = ArenaHistoryData[bracket]
	local parsedData = {}
	for id, data in pairs(history) do
		local time = string.split("::", id)
		time = tonumber(time) or 0
		
		if( time ) then
			table.insert(parsedData, {time = time, id = id})
		end
	end
	
	table.sort(parsedData, sortHistory)
	
	local cutOff = time() - ( self.db.profile.maxWeeks * 604800 )
	
	for id, data in pairs(parsedData) do
		if( not self.db.profile.enableMax or ( self.db.profile.enableMax and id > self.db.profile.maxRecords ) ) then
			if( not self.db.profile.enableWeek or ( self.db.profile.enableWeek and data.time < cutOff ) ) then
				history[id] = nil
			end
		end
	end
end

-- INSPECTION
-- Scan party for talents
function ArenaHistorian:RAID_ROSTER_UPDATE()
	-- Inspect raid
	for i=1, GetNumRaidMembers() do
		local unit = "raid" .. i
		local name = UnitName(unit)
				
		if( not UnitIsUnit("player", unit) and UnitIsVisible(unit) and not alreadyInspected[name] ) then
			alreadyInspected[name] = true
			self:ScanUnit(unit)
			
			table.insert(inspectQueue, unit)

			-- Nobody else is queued yet, so start it up
			if( not inspectedUnit ) then
				inspectedUnit = unit
				NotifyInspect(unit)
			end
		end
	end
end

-- Inspect finished for our guy
function ArenaHistorian:INSPECT_TALENT_READY()
	if( inspectedUnit and UnitExists(inspectedUnit) ) then
		-- Save their talent data
		local name, server = UnitName(inspectedUnit)
		if( server and server ~= "" ) then
			name = string.format("%s-%s", name, server)
		end
		
		local firstPoints = select(3, GetTalentTabInfo(1, true)) or 0
		local secondPoints = select(3, GetTalentTabInfo(2, true)) or 0
		local thirdPoints = select(3, GetTalentTabInfo(3, true)) or 0
		
		friendlyTalentData[name] = string.format("%d/%d/%d", firstPoints, secondPoints, thirdPoints)
				
		-- Remove them from queue
		for i=#(inspectQueue), 1, -1 do
			if( inspectQueue[i] == inspectedUnit ) then
				table.remove(inspectQueue, i)
			end
		end

		-- Check if we have someone else in queue
		inspectedUnit = inspectQueue[1]
		if( inspectedUnit ) then
			NotifyInspect(inspectedUnit)
		end
	end
end