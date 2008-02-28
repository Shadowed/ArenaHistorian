local GUI = ArenaHistorian:NewModule("GUI")

local L = ArenaHistLocals
local arenaData = {[2] = {}, [3] = {}, [5] = {}}
local arenaStats = {[2] = {}, [3] = {}, [5] = {}}
local arenaMap = {[2] = {}, [3] = {}, [5] = {}}
local alreadyParsed = {}

local MAX_TEAMS_SHOWN = 5
local MAX_TEAM_MEMBERS = 5
local DEEP_THRESHOLD = 30
local FONT_SIZE = 10
local ICON_SIZE = 16

-- Stolen out of GlueXML
local RACE_ICONS = {
	["HUMAN_MALE"] = {0, 0.125, 0, 0.25}, ["DWARF_MALE"] = {0.125, 0.25, 0, 0.25}, ["GNOME_MALE"] = {0.25, 0.375, 0, 0.25}, ["NIGHTELF_MALE"] = {0.375, 0.5, 0, 0.25},
	["TAUREN_MALE"] = {0, 0.125, 0.25, 0.5}, ["SCOURGE_MALE"] = {0.125, 0.25, 0.25, 0.5}, ["TROLL_MALE"] = {0.25, 0.375, 0.25, 0.5}, ["ORC_MALE"] = {0.375, 0.5, 0.25, 0.5},
	["HUMAN_FEMALE"] = {0, 0.125, 0.5, 0.75}, ["DWARF_FEMALE"] = {0.125, 0.25, 0.5, 0.75}, ["GNOME_FEMALE"] = {0.25, 0.375, 0.5, 0.75},
	["NIGHTELF_FEMALE"] = {0.375, 0.5, 0.5, 0.75}, ["TAUREN_FEMALE"] = {0, 0.125, 0.75, 1.0}, ["SCOURGE_FEMALE"] = {0.125, 0.25, 0.75, 1.0}, 
	["TROLL_FEMALE"] = {0.25, 0.375, 0.75, 1.0}, ["ORC_FEMALE"] = {0.375, 0.5, 0.75, 1.0}, ["BLOODELF_MALE"] = {0.5, 0.625, 0.25, 0.5},
	["BLOODELF_FEMALE"] = {0.5, 0.625, 0.75, 1.0},  ["DRAENEI_MALE"] = {0.5, 0.625, 0, 0.25}, ["DRAENEI_FEMALE"] = {0.5, 0.625, 0.5, 0.75}, 
}

-- Tree data
local TREE_ICONS = {
	["SHAMAN"] = {"Spell_Nature_Lightning", "Spell_Nature_LightningShield", "Spell_Nature_MagicImmunity"},
	["MAGE"] = {"Spell_Holy_MagicalSentry", "Spell_Fire_FlameBolt", "Spell_Frost_FrostBolt02"},
	["WARLOCK"] = {"Spell_Shadow_DeathCoil", "Spell_Shadow_Metamorphosis", "Spell_Shadow_RainOfFire"},
	["DRUID"] = {"Spell_Nature_Lightning", "Ability_Racial_BearForm", "Spell_Nature_HealingTouch"},
	["WARRIOR"] = {"Ability_Rogue_Eviscerate", "Ability_Warrior_InnerRage", "INV_Shield_06"},
	["ROGUE"] = {"Ability_Rogue_Eviscerate", "Ability_BackStab", "Ability_Stealth"},
	["PALADIN"] = {"Spell_Holy_HolyBolt", "Spell_Holy_DevotionAura", "Spell_Holy_AuraOfLight"},
	["HUNTER"] = {"Ability_Hunter_BeastTaming", "Ability_Marksmanship", "Ability_Hunter_SwiftStrike"},
	["PRIEST"] = {"Spell_Holy_WordFortitude", "Spell_Holy_HolyBolt", "Spell_Shadow_ShadowWordPain"},
}

function GUI:GetSpecName(class, spec)
	local tree1, tree2, tree3 = string.split("/", spec)
	tree1 = tonumber(tree1) or 0
	tree2 = tonumber(tree2) or 0
	tree3 = tonumber(tree3) or 0	
	
	if( tree1 == 0 and tree2 == 0 and tree3 == 0 ) then
		return "INV_Misc_QuestionMark", L["Unknown"]
	end
	
	-- Check for a hybrid spec
	local deepTrees = 0
	if( tree1 >= DEEP_THRESHOLD ) then
		deepTrees = deepTrees + 1
	end
	if( tree2 >= DEEP_THRESHOLD ) then
		deepTrees = deepTrees + 1
	end
	if( tree3 >= DEEP_THRESHOLD ) then
		deepTrees = deepTrees + 1
	end

	if( deepTrees > 1 ) then
		return "Spell_Nature_ElementalAbsorption", string.format("%d/%d/%d", tree1, tree2, tree3)
	end
		
	-- Now check specifics
	if( tree1 > tree2 and tree1 > tree3 ) then
		return TREE_ICONS[class][1], string.format("%d/%d/%d", tree1, tree2, tree3)
	elseif( tree2 > tree1 and tree2 > tree3 ) then
		return TREE_ICONS[class][2], string.format("%d/%d/%d", tree1, tree2, tree3)
	elseif( tree3 > tree1 and tree3 > tree2 ) then
		return TREE_ICONS[class][3], string.format("%d/%d/%d", tree1, tree2, tree3)
	end
	
	return "INV_Misc_QuestionMark", L["Unknown"]
end

local function sortTeamInfo(a, b)
	if( not a ) then
		return true
	elseif( not b ) then
		return false
	end

	return a.name < b.name
end

local function sortHistory(a, b)
	if( not a ) then
		return true
	elseif( not b ) then
		return false
	end

	return a.time > b.time
end

-- Parse the team data into a table for handy access
local function parseTeamData(...)
	local teamData = {}
	for i=1, select("#", ...) do
		local name, spec, classToken, race, healingDone, damageDone = string.split(",", (select(i, ...)))
		
		local row = {
			name = name,
			race = race,
			classToken = classToken,
			spec = (spec ~= "" and spec or nil),
			healingDone = tonumber(healingDone) or 0,
			damageDone = tonumber(damageDone) or 0,
		}
		
		table.insert(teamData, row)
	end

	-- Alpha sort
	table.sort(teamData, sortTeamInfo)
	
	-- Create the team id
	local teamID = ""
	for id, data in pairs(teamData) do
		teamID = teamID .. data.name
	end
	
	return teamData, teamID
end

local function updateCache()
	local self = GUI
	local history = arenaData[self.frame.bracket]
	local mapStats = arenaMap[self.frame.bracket]
	local stats = arenaStats
	
	-- Convert it from our compact format, to the tably one
	for id, data in pairs(ArenaHistoryData[self.frame.bracket]) do
		local bracket = select(2, string.split(":", data))
		-- Basically, this makes sure we only parse everything once
		if( not alreadyParsed[bracket .. id] ) then
			alreadyParsed[bracket .. id] = true
			
			local endTime, _, playerTeamName, _, enemyTeamName = string.split("::", id)
			endTime = tonumber(endTime)
			
			if( endTime ) then
				local matchData, playerTeam, enemyTeam = string.split(";", data)
				local arenaZone, _, runTime, playerWon, pRating, pChange, eRating, eChange = string.split(":", matchData)
				
				-- Generate the player and enemy team mate info
				local playerTeam, playerTeamID = parseTeamData(string.split(":", playerTeam))
				local enemyTeam, enemyTeamID = parseTeamData(string.split(":", enemyTeam))
				
				-- Map stat
				if( not mapStats[arenaZone] ) then
					mapStats[arenaZone] = {played = 0, won = 0, lost = 0}
				end

				mapStats[arenaZone].played = mapStats[arenaZone].played + 1

				-- Store our win/lost record against this team, by the players they and we used
				local teamID = playerTeamID .. enemyTeamID .. bracket .. enemyTeamName
				
				if( not stats[teamID] ) then
					stats[teamID] = {won = 0, lost = 0}
				end
				
				if( playerWon == "true" ) then
					stats[teamID].won = stats[teamID].won + 1
					mapStats[arenaZone].won = mapStats[arenaZone].won + 1
				else
					stats[teamID].lost = stats[teamID].lost + 1
					mapStats[arenaZone].lost = mapStats[arenaZone].lost + 1
				end
				

				-- Match information
				local matchTbl = {
					zone = arenaZone,
					time = tonumber(endTime) or 0,
					runTime = tonumber(runTime) or 0,
					won = (playerWon == "true"),
					teamID = teamID,
					
					pTeamName = playerTeamName,
					pRating = tonumber(pRating) or 0,
					pChange = tonumber(pChange) or 0,
					
					eTeamName = enemyTeamName,
					eRating = tonumber(eRating) or 0,
					eChange = tonumber(eChange) or 0,
					
					playerTeam = playerTeam,
					enemyTeam = enemyTeam,
				}

				table.insert(history, matchTbl)
			end
		end
	end
	
	table.sort(history, sortHistory)
end

local function setupTeamInfo(nameLimit, fsLimit, teamRows, teamData)
	for i=1, MAX_TEAM_MEMBERS do
		local row = teamRows[i]
		local data = teamData[i]

		if( data ) then
			-- Name, colored by class
			row.name.tooltip = string.format(L["%s - Damage (%d) / Healing (%d)"], data.name, data.damageDone, data.healingDone)
			row.name:SetText(data.name)
			row.name:SetTextColor(RAID_CLASS_COLORS[data.classToken].r, RAID_CLASS_COLORS[data.classToken].g, RAID_CLASS_COLORS[data.classToken].b)
			row.name:SetWidth(nameLimit)
			
			row.name.fs:SetHeight(15)
			row.name.fs:SetWidth(fsLimit)
			row.name.fs:SetJustifyH("LEFT")

			-- Spec icon
			if( data.spec and data.spec ~= "" ) then
				local icon, tooltip = GUI:GetSpecName(data.classToken, data.spec)

				row.specIcon.tooltip = tooltip
				row.specIcon:SetNormalTexture("Interface\\Icons\\" .. icon)
				row.specIcon:Show()
			else
				row.specIcon.tooltip = L["Unknown"]
				row.specIcon:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				row.specIcon:Show()
			end

			-- Race icon
			if( RACE_ICONS[data.race] ) then
				local coords = RACE_ICONS[data.race]
				row.raceIcon.tooltip = L[data.race] or L["Unknown"]
				row.raceIcon:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races")
				row.raceIcon:GetNormalTexture():SetTexCoord(coords[1], coords[2], coords[3], coords[4])
				row.raceIcon:Show()
			else
				row.raceIcon.tooltip = L["Unknown"]
				row.raceIcon:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				row.raceIcon:Show()
			end

			row:Show()
		else
			row:Hide()
		end
	end
end

local function updateRecords()
	local self = GUI
	local history = arenaData[self.frame.bracket]
	

	-- Check how many rows are supposed to be used
	local totalVisible = 0
	for _, matchInfo in pairs(history) do
		if( not matchInfo.hidden ) then
			totalVisible = totalVisible + 1
		end
	end
	
	FauxScrollFrame_Update(self.frame.scroll, totalVisible, MAX_TEAMS_SHOWN, 75)
	
	-- Word wrap settings
	local nameLimit = 55
	local fsLimit = 60
	
	-- When we're only showing 2 or 3 players, you can't possibly overflow so change the width limits
	if( self.frame.bracket == 2 or self.frame.bracket == 3 ) then
		nameLimit = 70
		fsLimit = 70
	end
	
	-- Display
	local offset = FauxScrollFrame_GetOffset(self.frame.scroll)
	local usedRows = 0
	local totalRows = 0
	for id, matchInfo in pairs(history) do
		if( not matchInfo.hidden ) then
			totalRows = totalRows + 1
			
			if( totalRows > offset and usedRows < MAX_TEAMS_SHOWN ) then
				usedRows = usedRows + 1

				local row = self.rows[usedRows]
				row:Show()

				local zone
				if( matchInfo.zone == "BEA" ) then
					zone = L["Blade's Edge Arena"]
				elseif( matchInfo.zone == "RoL" ) then
					zone = L["Ruins of Lordaeron"]
				elseif( matchInfo.zone == "NA" ) then
					zone = L["Nagrand Arena"]
				end

				-- Match info
				row.matchInfo:SetFormattedText(L["Run Time: %s"], SecondsToTime(matchInfo.runTime / 1000))
				row.zoneText:SetText(zone or L["Unknown"])

				-- Team stats
				row.teamRecord:SetFormattedText(L["Record: %s/%s"], GREEN_FONT_COLOR_CODE .. arenaStats[matchInfo.teamID].won .. FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE .. arenaStats[matchInfo.teamID].lost .. FONT_COLOR_CODE_CLOSE)

				-- Enemy team display
				row.enemyTeam:SetText(matchInfo.eTeamName)
				row.enemyInfo:SetFormattedText(L["%d Rating (%d Points)"], matchInfo.eRating, matchInfo.eChange)

				setupTeamInfo(nameLimit, fsLimit, row.enemyRows, matchInfo.enemyTeam)

				-- Player team display
				row.playerTeam:SetText(matchInfo.pTeamName)
				row.playerInfo:SetFormattedText(L["%d Rating (%d Points)"], matchInfo.pRating, matchInfo.pChange)

				setupTeamInfo(nameLimit, fsLimit, row.playerRows, matchInfo.playerTeam)

				-- Green border if we won, red if we lost
				if( matchInfo.won ) then
					row:SetBackdropBorderColor(0.0, 1.0, 0.0, 1.0)
				else
					row:SetBackdropBorderColor(1.0, 0.0, 0.0, 1.0)
				end
			end
		end

	end
	
	-- Set record numbers
	local browseMax = offset + MAX_TEAMS_SHOWN
	if( browseMax > totalVisible ) then
		browseMax = totalVisible
	end
	

	if( usedRows < MAX_TEAMS_SHOWN ) then
		offset = totalVisible - (MAX_TEAMS_SHOWN - (MAX_TEAMS_SHOWN - usedRows))
	end
	
	self.tabFrame.totalRecords:SetFormattedText("|cffffffff%d|r", #(history))
	self.tabFrame.totalVisible:SetFormattedText("|cffffffff%d|r", totalVisible)
	self.tabFrame.browsing:SetFormattedText("|cffffffff%d|r - |cffffffff%d|r", offset, browseMax)
	
	-- Now set map stats
	self.tabFrame.RoL:SetText("---------")
	self.tabFrame.BEA:SetText("---------")
	self.tabFrame.NA:SetText("---------")
	

	for key, data in pairs(arenaMap[self.frame.bracket]) do
		self.tabFrame[key]:SetFormattedText("%.1f%% - %s:%s (%.1f%%)", data.played / #(history) * 100, GREEN_FONT_COLOR_CODE .. data.won .. FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE .. data.lost .. FONT_COLOR_CODE_CLOSE, data.won / ( data.won + data.lost ) * 100)

	end

	-- Hide unused
	for i=usedRows + 1, MAX_TEAMS_SHOWN do
		self.rows[i]:Hide()
	end
end

-- Update which rows are visible
local function updateFilters()
	local self = GUI
	local history = arenaData[self.frame.bracket]
	local filters = self.frame.filters
	
	for id, matchInfo in pairs(history) do
		matchInfo.hidden = true

		-- Check if team name matches (or no team name filter)
		if( not filters.teamName or ( filters.teamName and string.match(string.lower(matchInfo.eTeamName), filters.teamName) ) ) then
			-- Check if enemies rating is above the minimum, but below maximum
			if( matchInfo.eRating >= filters.minRate and matchInfo.eRating <= filters.maxRate ) then
				-- Check if we should filter this zone
				if( filters[matchInfo.zone] ) then
					matchInfo.hidden = nil
				end
			end
		end
	end
end

-- Searching
local function searchMinRange(self)
	local filters = GUI.frame.filters
	local minRate = tonumber(self:GetText()) or 0
	
	if( minRate ~= filters.minRate ) then
		filters.minRate = minRate

		updateFilters()
		updateRecords()
	end
end

local function searchMaxRange(self)
	local filters = GUI.frame.filters
	local maxRate = tonumber(self:GetText()) or 0
	
	if( maxRate ~= filters.maxRate ) then
		filters.maxRate = maxRate

		updateFilters()
		updateRecords()
	end
end

local function searchName(self)
	local filters = GUI.frame.filters
	local text = string.lower(self:GetText() or "")
	if( text == "" or self.searchText) then
		text = nil
	end
	
	if( text ~= filters.teamName ) then
		filters.teamName = text

		updateFilters()
		updateRecords()
	end
end

local function searchZone(self)
	local filters = GUI.frame.filters
	local status = self:GetChecked()
	
	if( status ~= filters[self.type] ) then
		filters[self.type] = status
		
		updateFilters()
		updateRecords()
	end
end

local function searchFocusGained(self)
	if( self.searchText ) then
		self.searchText = nil
		self:SetText("")
		self:SetTextColor(1, 1, 1, 1)
	end
end

local function searchFocusLost(self)
	if( not self.searchText and string.trim(self:GetText()) == "" ) then
		self.searchText = true
		self:SetText(self.defaultText)
		self:SetTextColor(0.90, 0.90, 0.90, 0.80)
	end
end

local function resetSearch(self)
	self.searchText = true
	self:SetText(self.defaultText)
	self:SetTextColor(0.90, 0.90, 0.90, 0.80)
end

local function resetCheck(self)
	self:SetChecked(true)
end

-- Set bracket to show records from
local function setShownBracket(self)
	if( GUI.bracket ~= self.bracket ) then
		GUI.bracket = self.bracket
		GUI.frame.bracket = self.bracket
		
		updateCache()
		updateFilters()
		updateRecords()
	end
end


-- Create the team info display
local infoBackdrop = {	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true,
			edgeSize = 1,
			tileSize = 5,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}

local function OnEnter(self)
	if( self.tooltip ) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(self.tooltip)
		GameTooltip:Show()
	end
end

local function OnLeave(self)
	GameTooltip:Hide()
end

local function createTeamRows(frame, firstParent)
	local teamRows = {}
	for i=1, MAX_TEAM_MEMBERS do
		-- Container frame
		local row = CreateFrame("Frame", nil, frame)
		row:SetWidth(70)
		row:SetHeight(15)
		
		-- Race
		row.raceIcon = CreateFrame("Button", nil, row)
		row.raceIcon:SetHeight(ICON_SIZE)
		row.raceIcon:SetWidth(ICON_SIZE)
		row.raceIcon:SetScript("OnEnter", OnEnter)
		row.raceIcon:SetScript("OnLeave", OnLeave)
		row.raceIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		
		-- Talent spec
		row.specIcon = CreateFrame("Button", nil, row)
		row.specIcon:SetHeight(ICON_SIZE)
		row.specIcon:SetWidth(ICON_SIZE)
		row.specIcon:SetScript("OnEnter", OnEnter)
		row.specIcon:SetScript("OnLeave", OnLeave)
		row.specIcon:SetPoint("TOPLEFT", row.raceIcon, "TOPRIGHT", 5, 0)

		-- Char name
		row.name = CreateFrame("Button", nil, row)
		row.name:SetPushedTextOffset(0, 0)
		row.name:SetTextFontObject(GameFontHighlightSmall)
		row.name:SetHeight(15)
		row.name:SetWidth(55)
		row.name:SetScript("OnEnter", OnEnter)
		row.name:SetScript("OnLeave", OnLeave)
		row.name:SetPoint("TOPLEFT", row.specIcon, "TOPRIGHT", 4, 0)

		-- So we can do word wrapping
		row.name:SetText("*")
		row.name.fs = row.name:GetFontString()
		row.name.fs:SetPoint("LEFT", row.name, "LEFT", 0, 0)
				
		teamRows[i] = row
		
		if( i > 1 ) then
			row:SetPoint("TOPLEFT", teamRows[i - 1].name, "TOPRIGHT", 7, 0)
		else
			row:SetPoint("TOPLEFT", firstParent, "TOPLEFT", 0, -16)
		end
	end
	
	return teamRows
end

local function createTeamInfo(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(522)
	frame:SetHeight(75)
	frame:SetBackdrop(infoBackdrop)
	frame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	frame:SetBackdropBorderColor(0.65, 0.65, 0.65, 1.0)
	
	-- Match info
	frame.matchInfo = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.matchInfo:SetFont(GameFontHighlightSmall:GetFont(), FONT_SIZE)
	frame.matchInfo:SetPoint("TOPLEFT", frame, "TOPLEFT", 320, -3)

	frame.zoneText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.zoneText:SetFont(GameFontHighlightSmall:GetFont(), FONT_SIZE)
	frame.zoneText:SetPoint("TOPLEFT", frame, "TOPLEFT", 320, -40)

	-- Team stats
	frame.teamRecord = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.teamRecord:SetFont(GameFontHighlightSmall:GetFont(), FONT_SIZE)
	frame.teamRecord:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -40)
	
	-- Enemy team data
	frame.enemyTeam = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	frame.enemyTeam:SetFont(GameFontNormalSmall:GetFont(), FONT_SIZE)
	frame.enemyTeam:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -3)

	frame.enemyInfo = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	frame.enemyInfo:SetFont(GameFontNormalSmall:GetFont(), FONT_SIZE)
	frame.enemyInfo:SetPoint("TOPLEFT", frame, "TOPLEFT", 175, -3)
	
	frame.enemyRows = createTeamRows(frame, frame.enemyTeam)

	-- Player team data
	frame.playerTeam = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	frame.playerTeam:SetFont(GameFontNormalSmall:GetFont(), FONT_SIZE)
	frame.playerTeam:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -40)

	frame.playerInfo = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	frame.playerInfo:SetFont(GameFontNormalSmall:GetFont(), FONT_SIZE)
	frame.playerInfo:SetPoint("TOPLEFT", frame, "TOPLEFT", 175, -40)

	frame.playerRows = createTeamRows(frame, frame.playerTeam)
	
	return frame
end

-- Main container frame, we should probably wrap this in another frame so we can actually center it
function GUI:CreateFrame()
	if( self.frame ) then
		return
	end
				
	local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = false,
			edgeSize = 1,
			tileSize = 5,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}

	-- Create the main window
	self.frame = CreateFrame("Frame", "ArenaHistorianFrame", UIParent)
	self.frame.bracket = 2
	self.frame:Hide()
	self.frame:SetScript("OnShow", function()
		updateCache()
		updateFilters()
		updateRecords()
	end)

	self.frame:SetHeight(440)
	self.frame:SetWidth(550)
	self.frame:SetClampedToScreen(true)
	self.frame:SetMovable(true)
	self.frame:EnableKeyboard(false)
	self.frame:SetBackdrop(backdrop)
	self.frame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	self.frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.frame:SetPoint("CENTER", UIParent, "CENTER", 75, 0)

	self.frame.filters = {["BEA"] = true, ["NA"] = true, ["RoL"] = true, minRate = 0, maxRate = 3000}

	table.insert(UISpecialFrames, "ArenaHistorianFrame")
	
	-- Scroll frame
	self.frame.scroll = CreateFrame("ScrollFrame", "ArenaHistorianFrameScroll", self.frame, "FauxScrollFrameTemplate")
	self.frame.scroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 26, -24)
	self.frame.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -26, 4)
	self.frame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(75, updateRecords) end)

	-- Close button
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", 4, 4)
	button:SetScript("OnClick", function()
		HideUIPanel(GUI.frame)
	end)
	
	-- Now the title text
	self.frameTitle = self.frame:CreateFontString(nil, "ARTWORK")
	self.frameTitle:SetFont(GameFontNormalSmall:GetFont(), 16)
	self.frameTitle:SetPoint("CENTER", self.frame, "TOP", 0, -12)
	self.frameTitle:SetText(L["Arena Historian"])
	
	self.frameMover = CreateFrame("Button", nil, self.frame)
	self.frameMover:SetPoint("TOPLEFT", self.frameTitle, "TOPLEFT", -2, 0)
	self.frameMover:SetWidth(150)
	self.frameMover:SetHeight(20)
	self.frameMover:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			local parent = self:GetParent()
			local scale = parent:GetEffectiveScale()

			self.isMoving = nil
			parent:StopMovingOrSizing()

			ArenaHistorian.db.profile.position = {x = parent:GetLeft() * scale, y = parent:GetTop() * scale}
		end
	end)

	self.frameMover:SetScript("OnMouseDown", function(self, mouse)
		local parent = self:GetParent()

		-- Start moving!
		if( parent:IsMovable() and mouse == "LeftButton" ) then
			self.isMoving = true
			parent:StartMoving()

		-- Reset position
		elseif( mouse == "RightButton" ) then
			parent:ClearAllPoints()
			parent:SetPoint("CENTER", UIParent, "CENTER", 75, 0)

			ArenaHistorian.db.profile.position = nil
		end
	end)
	
	-- Create the tab frame
	self.tabFrame = CreateFrame("Frame", nil, self.frame)
	self.tabFrame:SetHeight(440)
	self.tabFrame:SetWidth(130)
	self.tabFrame:SetBackdrop(backdrop)
	self.tabFrame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	self.tabFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.tabFrame:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -8, 0)
		
	-- Record stat and such
	-- Total records
	local totalRecordsText = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	totalRecordsText:SetText(L["Total records"])
	totalRecordsText:SetPoint("TOPLEFT", self.tabFrame, "TOPLEFT", 3, -80)

	local text = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetText(0)
	text:SetPoint("TOPLEFT", totalRecordsText, "TOPRIGHT", 12, 0)
	
	self.tabFrame.totalRecords = text

	-- Total visible
	local totalVisibleText = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	totalVisibleText:SetText(L["Total visible"])
	totalVisibleText:SetPoint("TOPLEFT", totalRecordsText, "TOPLEFT", 0, -14)

	local text = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetText(0)
	text:SetPoint("TOPLEFT", self.tabFrame.totalRecords, "TOPLEFT", 0, -14)

	self.tabFrame.totalVisible = text
	
	-- Browsing
	local browsingText = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	browsingText:SetText(L["Browsing"])
	browsingText:SetPoint("TOPLEFT", totalVisibleText, "TOPLEFT", 0, -14)

	local text = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetText(0)
	text:SetPoint("TOPLEFT", self.tabFrame.totalVisible, "TOPLEFT", 0, -14)

	self.tabFrame.browsing = text
	
	-- MAP STATS
	-- Blade's Edge Arena
	local text = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetText(L["Blade's Edge Arena"])
	text:SetPoint("TOPLEFT", browsingText, "TOPLEFT", 0, -30)

	local BEA = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	BEA:SetPoint("TOPLEFT", text, "TOPLEFT", 0, -12)
	
	self.tabFrame.BEA = BEA

	-- Nagrand Arena
	local text = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetText(L["Nagrand Arena"])
	text:SetPoint("TOPLEFT", BEA, "TOPLEFT", 0, -16)

	local NA = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	NA:SetPoint("TOPLEFT", text, "TOPLEFT", 0, -12)
	
	self.tabFrame.NA = NA

	-- Ruins of Lordaeron
	local text = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetText(L["Ruins of Lordaeron"])
	text:SetPoint("TOPLEFT", NA, "TOPLEFT", 0, -16)

	local RoL = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	RoL:SetPoint("TOPLEFT", text, "TOPLEFT", 0, -12)
	
	self.tabFrame.RoL = RoL

	-- Now create our filters for the tab frame
	-- TEAM NAME SEARCH
	local search = CreateFrame("EditBox", "AHTeamNameSearch", self.tabFrame, "InputBoxTemplate")
	search:SetHeight(19)
	search:SetWidth(122)
	search:SetAutoFocus(false)
	search:ClearAllPoints()
	search:SetPoint("CENTER", self.tabFrame, "BOTTOM", 2, 11)

	search.searchText = true
	search.defaultText = L["Search"]
	search:SetText(L["Search"])
	search:SetTextColor(0.90, 0.90, 0.90, 0.80)
	search:SetScript("OnTextChanged", searchName)
	search:SetScript("OnEditFocusGained", searchFocusGained)
	search:SetScript("OnEditFocusLost", searchFocusLost)
	search:SetScript("OnHide", resetSearch)
	
	self.tabFrame.search = search

	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Enemy team name"])
	label:SetPoint("TOPLEFT", search, "TOPLEFT", -2, 12)
	
	-- MIN RATING
	local minRating = CreateFrame("EditBox", "AHTeamMinRating", self.tabFrame, "InputBoxTemplate")
	minRating:SetHeight(19)
	minRating:SetWidth(50)
	minRating:SetAutoFocus(false)
	minRating:SetNumeric(true)
	minRating:ClearAllPoints()
	minRating:SetPoint("CENTER", self.tabFrame, "BOTTOM", -33, 50)
	
	minRating.searchText = true
	minRating.defaultText = 0
	minRating:SetText(0)
	minRating:SetTextColor(0.90, 0.90, 0.90, 0.80)
	minRating:SetScript("OnTextChanged", searchMinRange)
	minRating:SetScript("OnEditFocusGained", searchFocusGained)
	minRating:SetScript("OnEditFocusLost", searchFocusLost)
	minRating:SetScript("OnHide", resetSearch)
	
	self.tabFrame.minRating = minRating

	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Min rate"])
	label:SetPoint("TOPLEFT", minRating, "TOPLEFT", -3, 12)
	
	-- MAX RATING
	local maxRating = CreateFrame("EditBox", "AHTeamMaxRating", self.tabFrame, "InputBoxTemplate")
	maxRating:SetHeight(19)
	maxRating:SetWidth(50)
	maxRating:SetAutoFocus(false)
	maxRating:SetNumeric(true)
	maxRating:ClearAllPoints()
	maxRating:SetPoint("CENTER", self.tabFrame, "BOTTOM", 38, 50)
	
	maxRating.searchText = true
	maxRating.defaultText = 3000
	maxRating:SetText(3000)
	maxRating:SetTextColor(0.90, 0.90, 0.90, 0.80)
	maxRating:SetScript("OnTextChanged", searchMaxRange)
	maxRating:SetScript("OnEditFocusGained", searchFocusGained)
	maxRating:SetScript("OnEditFocusLost", searchFocusLost)
	maxRating:SetScript("OnHide", resetSearch)
	
	self.tabFrame.maxRating = maxRating

	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Max rate"])
	label:SetPoint("TOPLEFT", maxRating, "TOPLEFT", -3, 12)
	
	-- ZONE FILTERS
	local filter = CreateFrame("CheckButton", nil, self.tabFrame, "OptionsCheckButtonTemplate")
	filter:SetHeight(18)
	filter:SetWidth(18)
	filter:SetChecked(true)
	filter.type = "BEA"
	filter:SetScript("OnClick", searchZone)
	filter:SetScript("OnHide", resetCheck)
	filter:SetPoint("CENTER", self.tabFrame, "BOTTOM", -55, 120)
	
	filter.text = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	filter.text:SetText(L["Blade's Edge Arena"])
	filter.text:SetPoint("TOPLEFT", filter, "TOPRIGHT", -1, -3)
	
	self.tabFrame.BEAFilter = filter

	local filter = CreateFrame("CheckButton", nil, self.tabFrame, "OptionsCheckButtonTemplate")
	filter:SetHeight(18)
	filter:SetWidth(18)
	filter:SetChecked(true)
	filter.type = "NA"
	filter:SetScript("OnClick", searchZone)
	filter:SetScript("OnHide", resetCheck)
	filter:SetPoint("TOPLEFT", self.tabFrame.BEAFilter, "TOPLEFT", 0, -15)
	
	filter.text = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	filter.text:SetText(L["Nagrand Arena"])
	filter.text:SetPoint("TOPLEFT", filter, "TOPRIGHT", -1, -3)
	
	self.tabFrame.NAFilter = filter

	local filter = CreateFrame("CheckButton", nil, self.tabFrame, "OptionsCheckButtonTemplate")
	filter:SetHeight(18)
	filter:SetWidth(18)
	filter:SetChecked(true)
	filter.type = "RoL"
	filter:SetScript("OnClick", searchZone)
	filter:SetScript("OnHide", resetCheck)
	filter:SetPoint("TOPLEFT", self.tabFrame.NAFilter, "TOPLEFT", 0, -15)
	
	filter.text = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	filter.text:SetText(L["Ruins of Lordaeron"])
	filter.text:SetPoint("TOPLEFT", filter, "TOPRIGHT", -1, -3)
	
	self.tabFrame.RoLFilter = filter

	-- Create the display buttons
	local tab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	tab:SetTextFontObject(GameFontHighlightSmall)
	tab:SetHighlightFontObject(GameFontHighlightSmall)
	tab:SetScript("OnClick", setShownBracket)
	tab:SetWidth(122)
	tab:SetHeight(13)
	tab:SetText(L["Show 2vs2"])
	tab:SetPoint("CENTER", self.tabFrame, "TOP", 0, -15)
	tab.bracket = 2

	local tab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	tab:SetTextFontObject(GameFontHighlightSmall)
	tab:SetHighlightFontObject(GameFontHighlightSmall)
	tab:SetScript("OnClick", setShownBracket)
	tab:SetWidth(122)
	tab:SetHeight(13)
	tab:SetText(L["Show 3vs3"])
	tab:SetPoint("CENTER", self.tabFrame, "TOP", 0, -30)
	tab.bracket = 3

	local tab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	tab:SetTextFontObject(GameFontHighlightSmall)
	tab:SetHighlightFontObject(GameFontHighlightSmall)
	tab:SetScript("OnClick", setShownBracket)
	tab:SetWidth(122)
	tab:SetHeight(13)
	tab:SetText(L["Show 5vs5"])
	tab:SetPoint("CENTER", self.tabFrame, "TOP", 0, -45)
	tab.bracket = 5
	
	-- Create the actual team displays
	self.rows = {}
	for i=1, MAX_TEAMS_SHOWN do
		self.rows[i] = createTeamInfo(self.frame)
		
		if( i > 1 ) then
			self.rows[i]:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -8)
		else
			self.rows[i]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -25)
		end
	end
	
	-- Set position
	if( ArenaHistorian.db.profile.position ) then
		local scale = self.frame:GetEffectiveScale()

		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", ArenaHistorian.db.profile.position.x / scale, ArenaHistorian.db.profile.position.y / scale)
	end
end