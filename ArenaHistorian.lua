--[[ 
	Arena Historian Mayen (Horde) from Icecrown (US) PvE
]]

ArenaHistorian = LibStub("AceAddon-3.0"):NewAddon("ArenaHistorian", "AceEvent-3.0")

local L = ArenaHistLocals
local playerRaceInfo = {}
local partyMap = {}
local instanceType
local arenaTeams = {}
local alreadyInspected = {}
local inspectQueue = {}
local inspectedUnit
local playerName

function ArenaHistorian:OnInitialize()
	-- Defaults
	self.defaults = {
		profile = {
		}
	}
	
	if( not ArenaHistoryData ) then
		ArenaHistoryData = {
			[2] = {},
			[3] = {},
			[5] = {},
		}
	end
	
	-- Prevents us from having to do 50 concats
	for i=1, MAX_PARTY_MEMBERS do
		partyMap[i] = "party" .. i .. "target"
	end

	-- Init DB
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ArenaHistorianDB", self.defaults)
	self.history = setmetatable(ArenaHistoryData, {})
	
	playerName = UnitName("player")
end

function ArenaHistorian:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	
	self:ZONE_CHANGED_NEW_AREA()
end

function ArenaHistorian:OnDisable()
	self:UnregisterAllEvents()
	instanceType = nil
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
	if( GetBattlefieldWinner() ) then
		-- Figure out what bracket we're in
		local bracket
		for i=1, MAX_BATTLEFIELD_QUEUES do
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
			if( teamName ) then
				arenaTeams[teamName .. teamSize] = true
			end
		end
		
		-- Record rating/team names
		local playerIndex, playerWon, playerName, playerRating, playerChange, enemyName, enemyRating, enemyChange
		for i=0, 1 do
			local teamName, oldRating, newRating = GetBattlefieldTeamInfo(i)
			if( arenaTeams[teamName .. bracket] ) then
				playerName = teamName
				playerRating = newRating
				playerChange = newRating - oldRating
				
				if( GetBattlefieldWinner() == i ) then
					playerWon = true
				end
				
				playerIndex = i
			else
				enemyName = teamName
				enemyRating = newRating
				enemyChange = newRating - oldRating
			end
		end
		
		-- Couldn't get data
		if( not enemyName or not playerName or not playerIndex ) then
			return
		end
		
		-- Score data
		local playerData = {}
		local enemyData = {}
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, faction, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)
			
			local server, parseName
			if( string.match(name, "-") ) then
				parseName, server = string.match(name, "(.-)%-(.*)$")
			else
				server = GetRealmName()	
				parseName = name
			end

			-- Get talent data from Remembrance if available
			local spec = ""
			
			-- We don't have to inspect ourself to get info, it's always available
			if( parseName == playerName ) then
				spec = (select(3, GetTalentTabInfo(1)) or 0) .. "/" ..  (select(3, GetTalentTabInfo(2)) or 0) .. "/" ..  (select(3, GetTalentTabInfo(3)) or 0)

			-- Check if Remembrance has data on them
			elseif( IsAddOnLoaded("Remembrance") ) then
				local tree1, tree2, tree3 = Remembrance:GetTalents(parseName, server)
				if( tree1 and tree2 and tree3 ) then
					spec = tree1 .. "/" .. tree2 .. "/" .. tree3
				end
			end
			
			-- Add it into our teammate list
			if( faction == playerIndex ) then
				table.insert(playerData, string.format("%s,%s,%s,%s,%s,%s", parseName, spec, classToken, playerRaceInfo[name] or self:RaceToToken(race), healingDone, damageDone))
			else
				table.insert(enemyData, string.format("%s,%s,%s,%s,%s,%s", parseName, spec, classToken, playerRaceInfo[name] or self:RaceToToken(race), healingDone, damageDone))
			end
		end
		
		-- Save player information
		--[[
			First set of name/class/race/spec are the players team, second set are enemy
			
			<team mate> format is <name>,<spec>,<classToken>,<race>,<healing>,<damage>
			
			[<time>::<playerTeam>::<enemyTeam>] = "<zone>:<bracket>:<runtime>:<true/false>:<prating>:<pchange>:<erating>:<echange>;<player team mates>;<enemy team mates>"
		]]
		
		-- Translate localized zone text to an unlocalized version
		local zoneText = GetRealZoneText()
		if( zoneText == L["Blade's Edge Arena"] ) then
			zoneText = "BEA"
		elseif( zoneText == L["Nagrand Arena"] ) then
			zoneText = "NA"
		elseif( zoneText == L["Ruins of Lordaeron"] ) then
			zoneText = "RoL"
		else
			zoneText = nil
		end
		
		local index = string.format("%d::%s::%s", time(), playerName, enemyName)
		local data = string.format("%s:%d:%d:%s:%d:%d:%d:%d;%s;%s", zoneText or "", bracket, GetBattlefieldInstanceRunTime() or 0, tostring(playerWon), playerRating, playerChange, enemyRating, enemyChange, table.concat(playerData, ":"), table.concat(enemyData, ":"))
		
		-- Save
		self.history[bracket][index] = data

		self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
	end
end

-- Get enemy/team mate races
function ArenaHistorian:PLAYER_TARGET_CHANGED()
	self:ScanUnit("mouseover")
end

function ArenaHistorian:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function ArenaHistorian:ScanUnit(unit)
	if( UnitIsPlayer(unit) and UnitIsVisible(unit) ) then
		local name, server = UnitName(unit)
		if( server ) then
			name = name .. "-" .. server
		end

		if( not playerRaceInfo[name] ) then
			if( UnitSex(unit) == 2 ) then
				playerRaceInfo[name] = string.upper(select(2, UnitRace(unit))) .. "_MALE" 
			else
				playerRaceInfo[name] = string.upper(select(2, UnitRace(unit))) .. "_FEMALE"
			end
		end
	end
end

-- Are we inside an arena?
function ArenaHistorian:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	
	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType and select(2, IsActiveBattlefieldArena()) ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		
		-- Get party talents as well if Remembrance is installed
		if( IsAddOnLoaded("Remembrance") ) then
			self:RegisterEvent("INSPECT_TALENT_READY")
			self:RegisterEvent("RAID_ROSTER_UPDATE")
			self:RAID_ROSTER_UPDATE()
		end
		
		-- Scan magic to make sure we get races of enemies
		if( not self.scanFrame ) then
			local timeElapsed = 0
			self.scanFrame = CreateFrame("Frame")
			self.scanFrame:SetScript("OnUpdate", function(self, elapsed)
				timeElapsed = timeElapsed + elapsed
				
				if( timeElapsed >= 1 ) then
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

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:UnregisterEvent("RAID_ROSTER_UPDATE")
		self:UnregisterEvent("INSPECT_TALENT_READY")
		self.scanFrame:Hide()
		
		-- Clear temp, blah blah blah
		inspectedUnit = nil
		for i=#(inspectQueue), 1, -1 do
			table.remove(inspectQueue, i)
		end
	end
	
	instanceType = type
end

-- INSPECTION
-- Scan party for talents
function ArenaHistorian:RAID_ROSTER_UPDATE()
	-- Arena started, stop inspecting
	if( not GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		self:UnregisterEvent("RAID_ROSTER_UPDATE")
		self:UnregisterEvent("INSPECT_TALENT_READY")
		return
	end

	-- Inspect raid
	for i=1, GetNumRaidMembers() do
		local unit = "raid" .. i
		local name = UnitName(unit)
		
		if( UnitIsVisible(unit) and not alreadyInspected[name] ) then
			alreadyInspected[name] = nil
			self:ScanUnit(unit)
			
			table.insert(inspectQueue, name)
			
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
		if( not server or server == "" ) then
			server = GetRealmName()
		end
		
		Remembrance:SaveTalentInfo(name, server, (UnitClass(inspectedUnit)))	

		-- Remove them from queue
		for i=1, #(inspectQueue) do
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