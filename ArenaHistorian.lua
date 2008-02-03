--[[ 
	Arena Historian Mayen (Horde) from Icecrown (US) PvE
]]

local AH = LibStub("AceAddon-3.0"):NewAddon("ArenaHistorian", "AceEvent-3.0")

local L = ArenaHistLocals
local arenaTeams = {}
local instanceType

function AH:OnInitialize()
	self.defaults = {
		profile = {
		}
	}
	
	if( not ArenaHistory ) then
		ArenaHistory = {
			[2] = {},
			[3] = {},
			[5] = {},
		}
	end
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ArenaHistDB", self.defaults)
end

function AH:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "ZONE_CHANGED_NEW_AREA")
	
	self:ZONE_CHANGED_NEW_AREA()
	self:ARENA_TEAM_UPDATE()
end

function AH:OnDisable()
	self:UnregisterAllEvents()
	instanceType = nil
end

function AH:ARENA_TEAM_UPDATE()
	for i=1, MAX_ARENA_TEAMS do
		local teamName, teamSize = GetArenaTeam(i)
		if( teamName ) then
			arenaTeams[teamName .. teamSize] = true
		end
	end
end

-- Record new data
function AH:UPDATE_BATTLEFIELD_SCORE()
	if( select(2, IsActiveBattlefieldArena()) ) then
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
		
		-- Score data
		local playerData = {}
		local enemyData = {}
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, faction, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)
			
			if( faction == playerIndex ) then
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
				
				table.insert(enemyData, string.format("%s,%s,%s,%s,%s,%s", name, "", classToken, race, healingDone, damageDone))
			end
		end
		
		-- Save player information
		--[[
			First set of name/class/race/spec are the players team, second set are enemy
			
			<team mate> format is <name>,<spec>,<classToken>,<race>,<healing>,<damage>:
			
			[<time>::<playerTeam>::<enemyTeam>] = "<t/f>:<prating>:<pchange>:<erating>:<echange>;<player team mates>;<enemy team mates>"
		]]
		
		local index = string.format("%d::%s::%s", time(), playerName, enemyName)
		local data = string.format("%s:%d:%d:%d:%d;%s:;%s:", tostring(playerWon), playerRating, playerChange, enemyRating, enemyChange, table.concat(playerData, ":"), table.concat(enemyData, ":"))
		
		-- Save
		ArenaHistory[bracket][index] = data
	end
	
	self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
end

-- Are we inside an arena?
function AH:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
	end
	
	instanceType = type
end