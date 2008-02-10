--[[ 
	Arena Historian Mayen (Horde) from Icecrown (US) PvE
]]

ArenaHistorian = LibStub("AceAddon-3.0"):NewAddon("ArenaHistorian", "AceEvent-3.0")

local L = ArenaHistLocals
local enemyRaceInfo = {}
local partyMap = {}
local instanceType

function ArenaHistorian:OnInitialize()
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
	
	for i=1, MAX_PARTY_MEMBERS do
		partyMap[i] = "party" .. i .. "target"
	end

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ArenaHistorianDB", self.defaults)
	self.history = setmetatable(ArenaHistoryData, {})
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
	if( select(2, IsActiveBattlefieldArena()) and GetBattlefieldWinner() ) then
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
		if( not enemyName or not playerName ) then
			return
		end
		
		-- Score data
		local playerData = {}
		local enemyData = {}
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, faction, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)
			
			if( faction == playerIndex ) then
				-- We SHOULD be able to get race information as if their name is a unit, but will fall back
				-- to basically guessing it if we can't
				if( UnitExists(name) ) then
					if( UnitSex(name) == 2 ) then
						race = string.upper(select(2, UnitRace(name))) .. "_MALE" 
					else
						race = string.upper(select(2, UnitRace(name))) .. "_FEMALE"
					end
				else
					race = self:RaceToToken(race)
				end
			
				table.insert(playerData, string.format("%s,%s,%s,%s,%s,%s", name, "", classToken, race, healingDone, damageDone))
			else
				local spec = ""
				if( IsAddOnLoaded("Remembrance") ) then
					-- Get talent data if available
					local server
					if( string.match(name, "-") ) then
						name, server = string.match(name, "(.-)%-(.*)$")
					else
						server = GetRealmName()	
					end

					local tree1, tree2, tree3 = Remembrance:GetTalents(name, server)
					if( tree1 and tree2 and tree3 ) then
						spec = tree1 .. "/" .. tree2 .. "/" .. tree3
					end
				end
				
				table.insert(enemyData, string.format("%s,%s,%s,%s,%s,%s", name, spec, classToken, enemyRaceInfo[name] or self:RaceToToken(race), healingDone, damageDone))
			end
		end
		
		-- Save player information
		--[[
			First set of name/class/race/spec are the players team, second set are enemy
			
			<team mate> format is <name>,<spec>,<classToken>,<race>,<healing>,<damage>
			
			[<time>::<playerTeam>::<enemyTeam>] = "<zone>:<bracket>:<runtime>:<true/false>:<prating>:<pchange>:<erating>:<echange>;<player team mates>;<enemy team mates>"
		]]
		
		local index = string.format("%d::%s::%s", time(), playerName, enemyName)
		local data = string.format("%s:%d:%d:%s:%d:%d:%d:%d;%s;%s", GetRealZoneText(), bracket, GetBattlefieldInstanceRunTime() or 0, tostring(playerWon), playerRating, playerChange, enemyRating, enemyChange, table.concat(playerData, ":"), table.concat(enemyData, ":"))
		
		-- Save
		self.history[bracket][index] = data

		self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
	end
end

function ArenaHistorian:PLAYER_TARGET_CHANGED()
	self:ScanUnit("mouseover")
end

function ArenaHistorian:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function ArenaHistorian:ScanUnit(unit)
	if( UnitIsPlayer(unit) and UnitIsVisible(unit) and UnitIsEnemy("player", unit) ) then
		local name, server = UnitName(unit)
		name = name .. "-" .. server

		if( not enemyRaceInfo[name] ) then
			if( UnitSex(unit) == 2 ) then
				enemyRaceInfo[name] = string.upper(select(2, UnitRace(unit))) .. "_MALE" 
			else
				enemyRaceInfo[name] = string.upper(select(2, UnitRace(unit))) .. "_FEMALE"
			end
		end
	end
end
-- Are we inside an arena?
function ArenaHistorian:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		
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
							self:ScanUnit(unit)
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
		self.scanFrame:Hide()
	end
	
	instanceType = type
end