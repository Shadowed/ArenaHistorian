local GUI = ArenaHistorian:NewModule("GUI")

local L = ArenaHistLocals
local arenaData = {[2] = {}, [3] = {}, [5] = {}}
local arenaStats = {[2] = {}, [3] = {}, [5] = {}}
local arenaMap = {[2] = {}, [3] = {}, [5] = {}}
local arenaTeamStats = {[2] = {}, [3] = {}, [5] = {}}
local alreadyParsed = {}
local alreadyParsedStat = {}
local talentPopup, racePopup

local MAX_TEAMS_SHOWN = 5
local MAX_TEAM_MEMBERS = 5
local DEEP_THRESHOLD = 30
local FONT_SIZE = 10
local ICON_SIZE = 16


-- Stolen out of GlueXML
local RACE_ICONS = {
	["HUMAN_MALE"] = {0, 0.125, 0, 0.25}, ["DWARF_MALE"] = {0.125, 0.25, 0, 0.25}, ["GNOME_MALE"] = {0.25, 0.375, 0, 0.25}, ["NIGHTELF_MALE"] = {0.375, 0.5, 0, 0.25},
	["TAUREN_MALE"] = {0, 0.125, 0.25, 0.5}, ["SCOURGE_MALE"] = {0.125, 0.25, 0.25, 0.5}, ["TROLL_MALE"] = {0.25, 0.375, 0.25, 0.5}, ["ORC_MALE"] = {0.375, 0.5, 0.25, 0.5},
	["HUMAN_FEMALE"] = {0, 0.125, 0.5, 0.75}, ["DWARF_FEMALE"] = {0.125, 0.25, 0.5, 0.75}, ["GNOME_FEMALE"] = {0.25, 0.375, 0.5, 0.75}, ["NIGHTELF_FEMALE"] = {0.375, 0.5, 0.5, 0.75},
	["TAUREN_FEMALE"] = {0, 0.125, 0.75, 1.0}, ["SCOURGE_FEMALE"] = {0.125, 0.25, 0.75, 1.0}, ["TROLL_FEMALE"] = {0.25, 0.375, 0.75, 1.0}, ["ORC_FEMALE"] = {0.375, 0.5, 0.75, 1.0},
	["BLOODELF_MALE"] = {0.5, 0.625, 0.25, 0.5}, ["BLOODELF_FEMALE"] = {0.5, 0.625, 0.75, 1.0},  ["DRAENEI_MALE"] = {0.5, 0.625, 0, 0.25}, ["DRAENEI_FEMALE"] = {0.5, 0.625, 0.5, 0.75}, 
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

function GUI:GetSpecName(class, spec, isGuess, isCustom)
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

local talentPopup
local racePopup

-- Popup request window for talents
local function setTalentData(self)
	local parent = self:GetParent()
	local talents = string.format("%d/%d/%d", tonumber(parent.pointOne:GetNumber()) or 0, tonumber(parent.pointTwo:GetNumber()) or 0, tonumber(parent.pointThree:GetNumber()) or 0)
	
	if( ArenaHistoryCustomData[parent.id] ) then
		local _, race = string.split(":", ArenaHistoryCustomData[parent.id])
		ArenaHistoryCustomData[parent.id] = string.format("%s:%s", talents, race)
	else
		ArenaHistoryCustomData[parent.id] = string.format("%s:", talents)
	end
	
	talentPopup:Hide()
	GUI:RefreshView()
end

local function popupTalentRequest(frame, bracket, teamName, name)
	local popup = talentPopup
	if( not popup ) then
		popup = CreateFrame("Frame", nil, GUI.frame)

		popup:SetBackdrop(GameTooltip:GetBackdrop())
		popup:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
		popup:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
		popup:SetScale(1.0)
		popup:SetWidth(125)
		popup:SetHeight(35)
		popup:SetClampedToScreen(true)
		popup:SetToplevel(true)
		popup:SetFrameStrata("DIALOG")
		popup:SetScript("OnHide", function(self) self.currentFrame = nil end)
		popup:Hide()
		
		popup.pointOne = CreateFrame("EditBox", "AHHistoryPopupOne", popup, "InputBoxTemplate")
		popup.pointOne:SetHeight(20)
		popup.pointOne:SetWidth(20)
		popup.pointOne:SetNumeric(true)
		popup.pointOne:SetAutoFocus(false)
		popup.pointOne:SetScript("OnEnterPressed", setTalentData)
		popup.pointOne:SetScript("OnTabPressed", function() popup.pointTwo:SetFocus(); end)
		popup.pointOne:ClearAllPoints()
		popup.pointOne:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -8)

		popup.pointTwo = CreateFrame("EditBox", "AHHistoryPopupTwo", popup, "InputBoxTemplate")
		popup.pointTwo:SetHeight(20)
		popup.pointTwo:SetWidth(20)
		popup.pointTwo:SetNumeric(true)
		popup.pointTwo:SetAutoFocus(false)
		popup.pointTwo:SetScript("OnEnterPressed", setTalentData)
		popup.pointTwo:SetScript("OnTabPressed", function() popup.pointThree:SetFocus(); end)
		popup.pointTwo:ClearAllPoints()
		popup.pointTwo:SetPoint("TOPLEFT", popup.pointOne, "TOPRIGHT", 6, 0)

		popup.pointThree = CreateFrame("EditBox", "AHHistoryPopupThree", popup, "InputBoxTemplate")
		popup.pointThree:SetHeight(20)
		popup.pointThree:SetWidth(20)
		popup.pointThree:SetNumeric(true)
		popup.pointThree:SetAutoFocus(false)
		popup.pointThree:SetScript("OnEnterPressed", setTalentData)
		popup.pointThree:SetScript("OnTabPressed", function() popup.pointOne:SetFocus(); end)
		popup.pointThree:ClearAllPoints()
		popup.pointThree:SetPoint("TOPLEFT", popup.pointTwo, "TOPRIGHT", 6, 0)
		
		popup.confirmSave = CreateFrame("Button", nil, popup, "UIPanelButtonGrayTemplate")
		popup.confirmSave:SetText(L["OK"])
		popup.confirmSave:SetHeight(20)
		popup.confirmSave:SetWidth(25)
		popup.confirmSave:SetScript("OnClick", setTalentData)
		popup.confirmSave:SetPoint("TOPLEFT", popup.pointThree, "TOPRIGHT", 6, 0)
		
		talentPopup = popup
	end
	
	-- Hide it if it's visible still
	if( popup.currentFrame == frame ) then
		popup:Hide()
		
		-- Reshow the old tooltip
		GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(frame.tooltip)
		GameTooltip:Show()
		return

	-- We switched icons, so retoggle
	elseif( popup:IsVisible() and popup.currentFrame ~= frame ) then
		popup:Hide()
	end
	
	-- Hide the race frame if it's viewable
	if( racePopup and racePopup:IsVisible() ) then
		racePopup:Hide()
	end
	
	-- Setup!
	popup.id = bracket .. teamName .. name
	popup.teamName = teamName
	popup.name = name
	popup.bracket = bracket
	popup.currentFrame = frame
	popup:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
	popup:Show()
	popup.pointOne:SetFocus()
	
	GameTooltip:Hide()

	-- Annnd set other things
	local one, two, three, talent
	if( ArenaHistoryCustomData[popup.id] ) then
		talent = string.split(":", ArenaHistoryCustomData[popup.id])
	else
		talent = frame.spec
	end

	if( talent and talent ~= "" ) then
		one, two, three = string.split("/", talent)
	end

	popup.pointOne:SetNumber(tonumber(one) or 0)
	popup.pointTwo:SetNumber(tonumber(two) or 0)
	popup.pointThree:SetNumber(tonumber(three) or 0)
end

-- Popup request window for race/sex
local function dropdownSelected()
	if( this.arg1 == "sex" ) then
		UIDropDownMenu_SetSelectedValue(AHCustomSexDropdown, this.value)
	elseif( this.arg1 == "race" ) then
		UIDropDownMenu_SetSelectedValue(AHCustomRaceDropdown, this.value)
	end
	
	-- Compile the token
	local sex = UIDropDownMenu_GetSelectedValue(AHCustomSexDropdown)
	local race = UIDropDownMenu_GetSelectedValue(AHCustomRaceDropdown)
	local raceToken = string.format("%s_%s", race, sex)
	
	-- Now save
	local parent = racePopup
	local race = ""
	
	if( ArenaHistoryCustomData[parent.id] ) then
		local talents, _ = string.split(":", ArenaHistoryCustomData[parent.id])
		ArenaHistoryCustomData[parent.id] = string.format("%s:%s", talents, raceToken)
	else
		ArenaHistoryCustomData[parent.id] = string.format(":%s", race)
	end

	GUI:RefreshView()
end

local function initSexDropdown()
	UIDropDownMenu_AddButton({value = "MALE", text = L["Male"], arg1 = "sex", func = dropdownSelected})
	UIDropDownMenu_AddButton({value = "FEMALE", text = L["Female"], arg1 = "sex", func = dropdownSelected})
end

local function initRaceDropdown()
	for token, text in pairs(L["TOKENS"]) do
		local race = string.split("_", token)
		UIDropDownMenu_AddButton({value = race, text = text, arg1 = "race", func = dropdownSelected})
	end
end

local function popupRaceRequest(frame, bracket, teamName, name)
	local popup = racePopup
	if( not popup ) then
		popup = CreateFrame("Frame", nil, GUI.frame)
		popup:SetBackdrop(GameTooltip:GetBackdrop())
		popup:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
		popup:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
		popup:SetScale(1.0)
		popup:SetWidth(260)
		popup:SetHeight(35)
		popup:SetClampedToScreen(true)
		popup:SetToplevel(true)
		popup:SetFrameStrata("DIALOG")
		popup:SetScript("OnHide", function(self) self.currentFrame = nil end)
		popup:Hide()

		popup.sex = CreateFrame("Frame", "AHCustomSexDropdown", popup, "UIDropDownMenuTemplate")
		popup.sex:SetPoint("TOPLEFT", popup, "TOPLEFT", -10, -4)
		popup.sex:SetScript("OnShow", function(self)
			UIDropDownMenu_Initialize(AHCustomSexDropdown, initSexDropdown)
			UIDropDownMenu_SetWidth(70, AHCustomSexDropdown)
			UIDropDownMenu_SetSelectedValue(AHCustomSexDropdown, self.sex)
		end)
		
		popup.race = CreateFrame("Frame", "AHCustomRaceDropdown", popup, "UIDropDownMenuTemplate")
		popup.race:SetPoint("TOPLEFT", popup, "TOPLEFT", 85, -4)
		popup.race:SetScript("OnShow", function(self)
			UIDropDownMenu_Initialize(AHCustomRaceDropdown, initRaceDropdown)
			UIDropDownMenu_SetWidth(100, AHCustomRaceDropdown)
			UIDropDownMenu_SetSelectedValue(AHCustomRaceDropdown, self.race)
		end)
		
		popup.confirmSave = CreateFrame("Button", nil, popup, "UIPanelButtonGrayTemplate")
		popup.confirmSave:SetText(L["OK"])
		popup.confirmSave:SetHeight(20)
		popup.confirmSave:SetWidth(25)
		popup.confirmSave:SetScript("OnClick", function() racePopup:Hide() end)
		popup.confirmSave:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -10, -8)

		racePopup = popup
	end
	
	-- Hide it if it's visible still
	if( popup.currentFrame == frame ) then
		popup:Hide()
		
		-- Reshow the old tooltip
		GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(frame.tooltip)
		GameTooltip:Show()
		return
	

	-- We switched from one icon to another, so retoggle
	elseif( popup:IsVisible() and popup.currentFrame ~= frame ) then
		popup:Hide()
	end

	-- Hide the talent frame if it's viewable
	if( talentPopup and talentPopup:IsVisible() ) then
		talentPopup:Hide()
	end

	popup.id = bracket .. teamName .. name

	-- Annnd set other things
	local sex = "FEMALE"
	local race = "BLOODELF"
	if( ArenaHistoryCustomData[popup.id] ) then
		local _, raceToken = string.split(":", ArenaHistoryCustomData[popup.id])
		if( not raceToken or raceToken == "" ) then
			raceToken = frame.race
		end
	else
		raceToken = frame.race
	end

	if( raceToken and raceToken ~= "" ) then
		race, sex = string.split("_", raceToken)
	end
	
	-- Setup!
	popup.id = bracket .. teamName .. name
	popup.teamName = teamName
	popup.name = name
	popup.bracket = bracket
	popup.currentFrame = frame
	popup.sex.sex = sex
	popup.race.race = race
	popup:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
	popup:Show()
	
	GameTooltip:Hide()
end

local function OnClick(self)
	if( self.type == "talent" ) then
		popupTalentRequest(self, self.bracket, self.teamName, self.name)
	elseif( self.type == "race" ) then
		popupRaceRequest(self, self.bracket, self.teamName, self.name)
	end
end

-- Parse the team data into a table for handy access
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

local function sortClassSpecs(a, b)
	return a < b
end

local function parseTeamData(...)
	local teamData = {}
	
	for i=1, select("#", ...) do
		local name, spec, classToken, race, healingDone, damageDone, guessTalents = string.split(",", (select(i, ...)))
		
		local row = {
			name = name,
			race = race,
			classToken = classToken,
			guessTalents = (guessTalents == "true"),
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

-- Win/lose stats per makeup
local classData = {}
function updateStatCache()
	local self = GUI
	local history = arenaData[self.frame.bracket]
	local mapStats = arenaTeamStats[self.frame.bracket]
	
	for id, data in pairs(history) do
		if( not alreadyParsedStat[self.frame.bracket .. data.recordID] ) then
			alreadyParsedStat[self.frame.bracket .. data.recordID] = true
			
			for i=#(classData), 1, -1 do table.remove(classData, i) end
			
			for _, playerData in pairs(data.enemyTeam) do
				local playerTalents = playerData.spec or ""
				
				-- Load custom talent data (if any)
				local id = GUI.frame.bracket .. data.eTeamName .. playerData.name
				if( ArenaHistoryCustomData[id] ) then
					local talents = string.split(":", ArenaHistoryCustomData[id])

					if( talents ~= "" ) then
						playerTalents = talents
					end

				end
				
				local icon = self:GetSpecName(playerData.classToken, playerTalents)
				table.insert(classData, string.format("%s:%s", icon, playerData.classToken))
			end
			
			table.sort(classData, sortClassSpecs)
			
			local teamID = table.concat(classData, ";")
			
			if( not mapStats[teamID] ) then
				mapStats[teamID] = { win = 0, lose = 0, gameLength = 0 }
			end
			
			mapStats[teamID].gameLength = mapStats[teamID].gameLength + data.runTime
			if( data.won ) then
				mapStats[teamID].win = mapStats[teamID].win + 1
			else
				mapStats[teamID].lose = mapStats[teamID].lose + 1
			end
		end
	end
end

-- Updates our data cache
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
			
			if( playerTeamName ~= "" and enemyTeamName ~= "" and endTime ) then
				local matchData, playerTeam, enemyTeam = string.split(";", data)
				local arenaZone, _, runTime, playerWon, pRating, pChange, eRating, eChange, eServer, pServer = string.split(":", matchData)
				
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
				
				if( playerWon == "true" or playerWon == "1" ) then
					stats[teamID].won = stats[teamID].won + 1
					mapStats[arenaZone].won = mapStats[arenaZone].won + 1
				elseif( playerWon == "nil" or playerWon == "-1" ) then
					stats[teamID].lost = stats[teamID].lost + 1
					mapStats[arenaZone].lost = mapStats[arenaZone].lost + 1
				end

				-- Match information
				local matchTbl = {
					zone = arenaZone,
					time = tonumber(endTime) or 0,
					runTime = tonumber(runTime) or 0,
					won = (playerWon == "true" or playerWon == "1"),
					draw = (playerWon == "0"),
					teamID = teamID,
					recordID = id,
					
					pTeamName = playerTeamName,
					pServer = pServer ~= "" and pServer or nil,
					pRating = tonumber(pRating) or 0,
					pChange = tonumber(pChange) or 0,
					
					eTeamName = enemyTeamName,
					eServer = eServer ~= "" and eSever or nil,
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
	
	-- Update win per class
	updateStatCache()
end

local function setupTeamInfo(nameLimit, fsLimit, teamRows, teamData, teamName, teamID)
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
			
			-- Check if we should override our saved data with custom data
			local id = GUI.frame.bracket .. teamName .. data.name
			local isCustom
			if( ArenaHistoryCustomData[id] ) then
				local talents, race = string.split(":", ArenaHistoryCustomData[id])
				
				if( talents ~= "" ) then
					data.spec = talents
					isCustom = true
				end
				
				if( race ~= "" ) then
					data.race = race
				end
			end
			
			-- Custom data
			row.specIcon.bracket = GUI.frame.bracket
			row.specIcon.teamName = teamName
			row.specIcon.name = data.name
			
			row.raceIcon.bracket = GUI.frame.bracket
			row.raceIcon.teamName = teamName
			row.raceIcon.name = data.name
			
			-- Spec icon
			if( data.spec and data.spec ~= "" ) then
				local icon, tooltip = GUI:GetSpecName(data.classToken, data.spec, data.guessTalents, isCustom)
				row.specIcon.tooltip = tooltip
				row.specIcon.classToken = data.classToken
				row.specIcon.spec = data.spec
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
				row.raceIcon.race = data.race
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

local function updateStatPage()
	local self = GUI
	local history = arenaData[self.frame.bracket]
	local statHistory = arenaTeamStats[self.frame.bracket]
	
	local test = self.statFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	test:SetPoint("CENTER", self.statFrame, "CENTER", 0, 0)
	test:SetText("FOO BAR")
	
	self.statFrame:Show()
	self.statFrame.scroll:Show()
end

-- HISTORY PAGE WITH GAMES PLAYED
local function updateHistoryPage()
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

				-- Delete ID
				row.deleteButton.id = matchInfo.recordID				
				
				-- Row number
				row.rowInfo:SetFormattedText("[%d]", (#(history) + 1) - id)
				row.rowInfo.tooltip = string.format(L["Date: %s"], date("%B %Y, %A %d, %I:%M %p", matchInfo.time))

				-- Match info
				row.matchInfo:SetFormattedText(L["Run Time: %s"], SecondsToTime(matchInfo.runTime / 1000))
				row.zoneText:SetText(zone or L["Unknown"])

				-- Team stats
				row.teamRecord:SetFormattedText(L["Record: %s/%s"], GREEN_FONT_COLOR_CODE .. arenaStats[matchInfo.teamID].won .. FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE .. arenaStats[matchInfo.teamID].lost .. FONT_COLOR_CODE_CLOSE)

				-- Enemy team display
				row.enemyTeam:SetText(matchInfo.eTeamName)
				row.enemyInfo:SetFormattedText(L["%d Rating (%d Points)"], matchInfo.eRating, matchInfo.eChange)

				setupTeamInfo(nameLimit, fsLimit, row.enemyRows, matchInfo.enemyTeam, matchInfo.eTeamName, matchInfo.teamID)

				-- Player team display
				row.playerTeam:SetText(matchInfo.pTeamName)
				row.playerInfo:SetFormattedText(L["%d Rating (%d Points)"], matchInfo.pRating, matchInfo.pChange)

				setupTeamInfo(nameLimit, fsLimit, row.playerRows, matchInfo.playerTeam, matchInfo.pTeamName, matchInfo.teamID)

				-- Green border if we won, red if we lost, yellow if draw
				if( matchInfo.draw ) then
					row:SetBackdropBorderColor(0.85, 0.71, 0.26, 1.0)
				elseif( matchInfo.won ) then
					row:SetBackdropBorderColor(0.0, 1.0, 0.0, 1.0)
				else
					row:SetBackdropBorderColor(1.0, 0.0, 0.0, 1.0)
				end
			end
		end

	end

	-- Hide unused
	for i=usedRows + 1, MAX_TEAMS_SHOWN do
		self.rows[i]:Hide()
	end

	-- Show scroll
	self.frame.scroll:Show()
end

local function updatePage()
	local self = GUI
	if( self.frame.type == "history" ) then
		updateHistoryPage()
	elseif( self.frame.type == "stats" ) then
		updateStatPage()
	end

	-- Now set map stats
	self.tabFrame.RoL:SetText("---------")
	self.tabFrame.BEA:SetText("---------")
	self.tabFrame.NA:SetText("---------")
	
	for key, data in pairs(arenaMap[self.frame.bracket]) do
		self.tabFrame[key]:SetFormattedText("%.1f%% - %s:%s (%.1f%%)", data.played / #(arenaData[self.frame.bracket]) * 100, GREEN_FONT_COLOR_CODE .. data.won .. FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE .. data.lost .. FONT_COLOR_CODE_CLOSE, data.won / ( data.won + data.lost ) * 100)
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
					-- See if we need to search the team members
					if( filters.playerName or filters.searchClasses ) then
						for _, data in pairs(matchInfo.enemyTeam) do
							-- Check name
							if( not filters.playerName or ( filters.playerName and string.match(string.lower(data.name), filters.playerName) ) ) then
								-- Check class
								if( not filters.searchClasses or ( filters.searchClasses and not filters.classes[data.classToken] ) ) then
									matchInfo.hidden = nil
								end
							end
						end
					else
						matchInfo.hidden = nil
					end
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
		updatePage()
	end
end

local function searchMaxRange(self)
	local filters = GUI.frame.filters
	local maxRate = tonumber(self:GetText()) or 0
	
	if( maxRate ~= filters.maxRate ) then
		filters.maxRate = maxRate

		updateFilters()
		updatePage()
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
		updatePage()
	end
end

local function updateClassButton(self)
	local filters = GUI.frame.filters

	-- Fade out the button if we aren't searching them
	SetDesaturation(self:GetNormalTexture(), filters.classes[self.type])
	
	-- Update tooltip!
	if( not filters.classes[self.type] ) then
		self.tooltip = string.format(L["%s's shown"], L[self.type])
	else
		self.tooltip = string.format(L["%s's hidden"], L[self.type])
	end
	
	GameTooltip:SetText(self.tooltip)

	-- If we have any class disabled, then set it as needing to search them
	filters.searchClasses = false
	for _, flag in pairs(filters.classes) do
		if( flag ) then
			filters.searchClasses = true
		end
	end
end

local function searchClasses(self)
	local filters = GUI.frame.filters
	filters.classes[self.type] = not filters.classes[self.type]
	
	updateClassButton(self)
	
	-- Annd finally update filters
	updateFilters()
	updatePage()
end

local function resetClass(self)
	GUI.frame.filters.classes[self.type] = false
	updateClassButton(self)
end

local function searchEnemyName(self)
	local filters = GUI.frame.filters
	local text = string.lower(self:GetText() or "")
	if( text == "" or self.searchText) then
		text = nil
	end
	
	if( text ~= filters.playerName ) then
		filters.playerName = text

		updateFilters()
		updatePage()
	end
end

local function searchZone(self)
	local filters = GUI.frame.filters
	local status = self:GetChecked()
	
	if( status ~= filters[self.type] ) then
		filters[self.type] = status
		
		updateFilters()
		updatePage()
	end
end

local function searchEnemyTalents()
	local filters = GUI.frame.filters
	local talent = string.format("%d/%d/%d", tonumber(GUI.tabFrame.pointOne:GetText()) or 0, tonumber(GUI.tabFrame.pointTwo:GetText()) or 0, tonumber(GUI.tabFrame.pointThree:GetText()) or 0)
	if( talent ~= filters.talent ) then
		filters.talent = talent

		updateFilters()
		updatePage()
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

local function resetFilters()
	for _, row in pairs(GUI.tabFrame.filters) do
		if( row.reset ) then
			row.reset(row)	
		else
			resetSearch(row)
		end
	end
end

local function resetCheck(self)
	self:SetChecked(true)
end

local function updateButtonHighlight()
	for _, button in pairs(GUI.tabFrame.browseButtons) do
		if( button.type == GUI.frame.type and button.bracket == GUI.frame.bracket ) then
			button:LockHighlight()
		else
			button:UnlockHighlight()
		end
	end
end

-- Set bracket to show records from
local function setShownPage(self)
	if( GUI.frame.type ~= self.type or GUI.frame.bracket ~= self.bracket ) then
		-- Hide everything
		if( GUI.frame.type ~= self.type ) then
			GUI.statFrame.scroll:Hide()
			GUI.frame.scroll:Hide()
			
			for _, row in pairs(GUI.rows) do
				row:Hide()
			end
		end
		
		GUI.frame.type = self.type
		GUI.frame.bracket = self.bracket
		
		ArenaHistorian.db.profile.lastBracket = self.bracket
		ArenaHistorian.db.profile.lastType = self.type
		
		updateButtonHighlight()
		updateCache()
		updateFilters()
		updatePage()
	end
end

-- Move this down here for when we modify stuff
function GUI:RefreshView()
	updateCache()
	updateFilters()
	updatePage()
end

-- Delete something
local function deleteRecord(self)
	if( IsAltKeyDown() ) then
		ArenaHistoryData[GUI.frame.bracket][self.id] = nil

		-- Check and remove the history record
		for i=#(arenaData[GUI.frame.bracket]), 1, -1 do
			local row = arenaData[GUI.frame.bracket][i]
			if( row.recordID == self.id ) then
				table.remove(arenaData[GUI.frame.bracket], i)
			end
		end

		-- Update
		updatePage()
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
		row:Hide()
		
		-- Race
		row.raceIcon = CreateFrame("Button", nil, row)
		row.raceIcon:SetHeight(ICON_SIZE)
		row.raceIcon:SetWidth(ICON_SIZE)
		row.raceIcon:SetScript("OnEnter", OnEnter)
		row.raceIcon:SetScript("OnLeave", OnLeave)
		row.raceIcon:SetScript("OnDoubleClick", OnClick)
		row.raceIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		row.raceIcon.type = "race"
		
		-- Talent spec
		row.specIcon = CreateFrame("Button", nil, row)
		row.specIcon:SetHeight(ICON_SIZE)
		row.specIcon:SetWidth(ICON_SIZE)
		row.specIcon:SetScript("OnEnter", OnEnter)
		row.specIcon:SetScript("OnLeave", OnLeave)
		row.specIcon:SetScript("OnDoubleClick", OnClick)
		row.specIcon:SetPoint("TOPLEFT", row.raceIcon, "TOPRIGHT", 5, 0)
		row.specIcon.type = "talent"

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
	frame:Hide()
	
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
		
	-- Deletion
	frame.deleteButton = CreateFrame("Button", nil, frame)
	frame.deleteButton:SetTextFontObject(GameFontNormalSmall)
	frame.deleteButton:SetTextColor(1, 1, 1)
	frame.deleteButton:SetPushedTextOffset(0,0)
	frame.deleteButton:SetHeight(18)
	frame.deleteButton:SetWidth(18)
	frame.deleteButton:SetFormattedText("[%s%s%s]", RED_FONT_COLOR_CODE, "X", FONT_COLOR_CODE_CLOSE)
	frame.deleteButton:SetScript("OnClick", deleteRecord)
	frame.deleteButton:SetScript("OnEnter", OnEnter)
	frame.deleteButton:SetScript("OnLeave", OnLeave)
	frame.deleteButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, 0)
	frame.deleteButton.tooltip = L["Hold ALT and click the button to delete this arena record."]

	-- Row info
	frame.rowInfo = CreateFrame("Button", nil, frame)
	frame.rowInfo:SetTextFontObject(GameFontNormalSmall)
	frame.rowInfo:SetTextColor(1, 1, 1)
	frame.rowInfo:SetPushedTextOffset(0,0)
	frame.rowInfo:SetHeight(18)
	frame.rowInfo:SetWidth(18)
	frame.rowInfo:SetScript("OnEnter", OnEnter)
	frame.rowInfo:SetScript("OnLeave", OnLeave)
	frame.rowInfo:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -27, 0)

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
	self.frame.bracket = ArenaHistorian.db.profile.lastBracket
	self.frame.type = ArenaHistorian.db.profile.lastType
	self.frame:Hide()
	self.frame:SetScript("OnShow", function()
		resetFilters()
		updateButtonHighlight()
		updateCache()
		updateFilters()
		updatePage()
	end)
	self.frame:SetScript("OnHide", function()
		if( talentPopup ) then
			talentPopup:Hide()
		end
		
		if( racePopup ) then
			racePopup:Hide()
		end
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

	self.frame.filters = {["BEA"] = true, ["NA"] = true, ["RoL"] = true, classes = {}, minRate = 0, maxRate = 0}

	table.insert(UISpecialFrames, "ArenaHistorianFrame")
	
	-- Scroll frame
	self.frame.scroll = CreateFrame("ScrollFrame", "ArenaHistorianFrameScroll", self.frame, "FauxScrollFrameTemplate")
	self.frame.scroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 26, -24)
	self.frame.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -26, 4)
	self.frame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(75, updatePage) end)
	
	-- Stat frame
	local scroll = CreateFrame("ScrollFrame", "ArenaHistorianFrameStatScroll", self.frame, "UIPanelScrollFrameTemplate")
	
	self.statFrame = CreateFrame("Frame", nil, self.frame)
	self.statFrame:SetWidth(1)
	self.statFrame:SetHeight(1)
	self.statFrame:SetParent(scroll)

	self.statFrame.scroll = scroll
	self.statFrame.scroll:SetScrollChild(self.statFrame)
	
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
	self.tabFrame:SetWidth(140)
	self.tabFrame:SetBackdrop(backdrop)
	self.tabFrame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	self.tabFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.tabFrame:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -8, 0)
	
	self.tabFrame.filters = {}
	
	-- MAP STATS
	local FILTER_TEXT_X = 1
	local FILTER_TEXT_Y = -17
	
	-- Blade's Edge Arena
	local filter = CreateFrame("CheckButton", nil, self.tabFrame, "OptionsCheckButtonTemplate")
	filter:SetHeight(18)
	filter:SetWidth(18)
	filter:SetChecked(true)
	filter.type = "BEA"
	filter:SetScript("OnClick", searchZone)
	filter:SetScript("OnHide", resetCheck)
	filter:SetPoint("TOPLEFT", self.tabFrame, "TOPLEFT", 1, -100)
	
	filter.text = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	filter.text:SetText(L["Blade's Edge Arena"])
	filter.text:SetPoint("TOPLEFT", filter, "TOPRIGHT", -1, -3)
	
	self.tabFrame.BEAFilter = filter
	
	local BEA = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	BEA:SetPoint("TOPLEFT", filter, "TOPLEFT", FILTER_TEXT_X, FILTER_TEXT_Y)
	
	self.tabFrame.BEA = BEA

	-- Nagrand Arena
	local filter = CreateFrame("CheckButton", nil, self.tabFrame, "OptionsCheckButtonTemplate")
	filter:SetHeight(18)
	filter:SetWidth(18)
	filter:SetChecked(true)
	filter.type = "NA"
	filter:SetScript("OnClick", searchZone)
	filter:SetScript("OnHide", resetCheck)
	filter:SetPoint("TOPLEFT", self.tabFrame.BEA, "TOPLEFT", -FILTER_TEXT_X, -15)
	
	filter.text = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	filter.text:SetText(L["Nagrand Arena"])
	filter.text:SetPoint("TOPLEFT", filter, "TOPRIGHT", -1, -3)
	
	self.tabFrame.NAFilter = filter

	local NA = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	NA:SetPoint("TOPLEFT", filter, "TOPLEFT", FILTER_TEXT_X, FILTER_TEXT_Y)
	
	self.tabFrame.NA = NA

	-- Ruins of Lordaeron
	local filter = CreateFrame("CheckButton", nil, self.tabFrame, "OptionsCheckButtonTemplate")
	filter:SetHeight(18)
	filter:SetWidth(18)
	filter:SetChecked(true)
	filter.type = "RoL"
	filter:SetScript("OnClick", searchZone)
	filter:SetScript("OnHide", resetCheck)
	filter:SetPoint("TOPLEFT", self.tabFrame.NA, "TOPLEFT", -FILTER_TEXT_X, -16)
	
	filter.text = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	filter.text:SetText(L["Ruins of Lordaeron"])
	filter.text:SetPoint("TOPLEFT", filter, "TOPRIGHT", -1, -3)
	
	self.tabFrame.RoLFilter = filter

	local RoL = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	RoL:SetPoint("TOPLEFT", filter, "TOPLEFT", FILTER_TEXT_X, FILTER_TEXT_Y)
	
	self.tabFrame.RoL = RoL

	-- Now create our filters for the tab frame
	-- CLASS FILTERS
	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Classes"])
	label:SetPoint("CENTER", self.tabFrame, "BOTTOM", -48, 175)
	
	local buttons = {}
	local id = 0
	local lastColumn = 1
	
	for classToken, coords in pairs(CLASS_BUTTONS) do
		id = id + 1

		local button = CreateFrame("Button", nil, self.tabFrame)
		button:SetHeight(24)
		button:SetWidth(24)
		button:SetScript("OnClick", searchClasses)
		button:SetScript("OnHide", resetClass)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetNormalTexture("Interface\\WorldStateFrame\\Icons-Classes")
		button:GetNormalTexture():SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		
		button.reset = resetClass
		button.type = classToken
		button.tooltip = string.format(L["%s's shown"], L[classToken])
		
		if( id == 1 ) then
			button:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
		elseif( id % 6 == 0 ) then
			button:SetPoint("TOPLEFT", buttons[lastColumn], "BOTTOMLEFT", 0, -2)
			lastColumn = id
		else
			button:SetPoint("TOPLEFT", buttons[id - 1], "TOPRIGHT", 0, 0)
		end
		
		table.insert(buttons, button)
		table.insert(self.tabFrame.filters, button)
		
		self.frame.filters.classes[classToken] = false
	end

	-- TALENT FILTER
	--[[
	-- One
	local pointOne = CreateFrame("EditBox", "ArenaHistorianTalentOne", self.tabFrame, "InputBoxTemplate")
	pointOne:SetHeight(20)
	pointOne:SetWidth(20)
	pointOne:SetNumeric(true)
	pointOne:SetAutoFocus(false)
	pointOne:SetScript("OnTextChanged", searchEnemyTalents)
	pointOne:SetScript("OnTabPressed", function() GUI.tabFrame.pointTwo:SetFocus(); end)
	pointOne:SetScript("OnEditFocusGained", searchFocusGained)
	pointOne:SetScript("OnEditFocusLost", searchFocusLost)
	pointOne:ClearAllPoints()
	pointOne:SetPoint("CENTER", self.tabFrame, "BOTTOM", -53, 120)
	pointOne.defaultText = 0

	self.tabFrame.pointOne = pointOne
	table.insert(self.tabFrame.filters, pointOne)
	
	-- Two
	local pointTwo = CreateFrame("EditBox", "ArenaHistorianTalentTwo", self.tabFrame, "InputBoxTemplate")
	pointTwo:SetHeight(20)
	pointTwo:SetWidth(20)
	pointTwo:SetNumeric(true)
	pointTwo:SetAutoFocus(false)
	pointTwo:SetScript("OnTextChanged", searchEnemyTalents)
	pointTwo:SetScript("OnTabPressed", function() GUI.tabFrame.pointThree:SetFocus(); end)
	pointTwo:SetScript("OnEditFocusGained", searchFocusGained)
	pointTwo:SetScript("OnEditFocusLost", searchFocusLost)
	pointTwo:ClearAllPoints()
	pointTwo:SetPoint("TOPLEFT", pointOne, "TOPRIGHT", 6, 0)
	pointTwo.defaultText = 0
	
	self.tabFrame.pointTwo = pointTwo
	table.insert(self.tabFrame.filters, pointTwo)
	
	-- Three
	pointThree = CreateFrame("EditBox", "ArenaHistorianTalentThree", self.tabFrame, "InputBoxTemplate")
	pointThree:SetHeight(20)
	pointThree:SetWidth(20)
	pointThree:SetNumeric(true)
	pointThree:SetAutoFocus(false)
	pointThree:SetScript("OnTextChanged", searchEnemyTalents)
	pointThree:SetScript("OnTabPressed", function() GUI.tabFrame.pointOne:SetFocus(); end)
	pointThree:SetScript("OnEditFocusGained", searchFocusGained)
	pointThree:SetScript("OnEditFocusLost", searchFocusLost)
	pointThree:ClearAllPoints()
	pointThree:SetPoint("TOPLEFT", pointTwo, "TOPRIGHT", 6, 0)
	pointThree.defaultText = 0
	
	self.tabFrame.pointThree = pointThree
	table.insert(self.tabFrame.filters, pointThree)
	
	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Talents"])
	label:SetPoint("TOPLEFT", pointOne, "TOPLEFT", -3, 12)
	]]

	-- TEAM NAME SEARCH
	local search = CreateFrame("EditBox", "AHTeamNameSearch", self.tabFrame, "InputBoxTemplate")
	search:SetHeight(19)
	search:SetWidth(132)
	search:SetAutoFocus(false)
	search:ClearAllPoints()
	search:SetPoint("CENTER", self.tabFrame, "BOTTOM", 2, 11)

	search.defaultText = L["Search"]
	search:SetScript("OnTextChanged", searchName)
	search:SetScript("OnEditFocusGained", searchFocusGained)
	search:SetScript("OnEditFocusLost", searchFocusLost)
	
	self.tabFrame.search = search
	table.insert(self.tabFrame.filters, search)

	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Enemy team name"])
	label:SetPoint("TOPLEFT", search, "TOPLEFT", -2, 12)

	-- ENEMY NAME SEARCH
	local search = CreateFrame("EditBox", "AHNameEnemySearch", self.tabFrame, "InputBoxTemplate")
	search:SetHeight(19)
	search:SetWidth(132)
	search:SetAutoFocus(false)
	search:ClearAllPoints()
	search:SetPoint("CENTER", self.tabFrame, "BOTTOM", 2, 47)

	search.defaultText = L["Search"]
	search:SetScript("OnTextChanged", searchEnemyName)
	search:SetScript("OnEditFocusGained", searchFocusGained)
	search:SetScript("OnEditFocusLost", searchFocusLost)
	
	self.tabFrame.enemyName = search
	table.insert(self.tabFrame.filters, search)
	
	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Enemy player name"])
	label:SetPoint("TOPLEFT", search, "TOPLEFT", -2, 12)
	
	-- MIN RATING
	local RATING_Y = 82
	
	local minRating = CreateFrame("EditBox", "AHTeamMinRating", self.tabFrame, "InputBoxTemplate")
	minRating:SetHeight(19)
	minRating:SetWidth(50)
	minRating:SetAutoFocus(false)
	minRating:SetNumeric(true)
	minRating:ClearAllPoints()
	minRating:SetPoint("CENTER", self.tabFrame, "BOTTOM", -38, RATING_Y)
	
	minRating.defaultText = 0
	minRating:SetScript("OnTextChanged", searchMinRange)
	minRating:SetScript("OnEditFocusGained", searchFocusGained)
	minRating:SetScript("OnEditFocusLost", searchFocusLost)

	self.tabFrame.minRating = minRating
	table.insert(self.tabFrame.filters, minRating)

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
	maxRating:SetPoint("CENTER", self.tabFrame, "BOTTOM", 42, RATING_Y)
	
	maxRating.defaultText = 3000
	maxRating:SetScript("OnTextChanged", searchMaxRange)
	maxRating:SetScript("OnEditFocusGained", searchFocusGained)
	maxRating:SetScript("OnEditFocusLost", searchFocusLost)
	
	self.tabFrame.maxRating = maxRating
	table.insert(self.tabFrame.filters, maxRating)

	local label = self.tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetText(L["Max rate"])
	label:SetPoint("TOPLEFT", maxRating, "TOPLEFT", -3, 12)
	
	-- Create the display buttons
	self.tabFrame.browseButtons = {}
	
	-- 2 VS 2 Buttons
	local histTab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	histTab:SetTextFontObject(GameFontHighlightSmall)
	histTab:SetHighlightFontObject(GameFontHighlightSmall)
	histTab:SetScript("OnClick", setShownPage)
	histTab:SetWidth(90)
	histTab:SetHeight(14)
	histTab:SetFormattedText(L["%dvs%d History"], 2, 2)
	histTab:SetPoint("TOPLEFT", self.tabFrame, "TOPLEFT", 1, -4)
	histTab.bracket = 2
	histTab.type = "history"
	
	self.tabFrame.historyTwo = histTab
	table.insert(self.tabFrame.browseButtons, histTab)

	--[[
	local tab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	tab:SetTextFontObject(GameFontHighlightSmall)
	tab:SetHighlightFontObject(GameFontHighlightSmall)
	tab:SetScript("OnClick", setShownPage)
	tab:SetWidth(45)
	tab:SetHeight(14)
	tab:SetText(L["Stats"])
	tab:SetPoint("TOPLEFT", histTab, "TOPRIGHT", 0, 0)
	tab.bracket = 2
	tab.type = "stats"
	
	table.insert(self.tabFrame.browseButtons, tab)
	]]
	
	-- 3 VS 3 Buttons
	local histTab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	histTab:SetTextFontObject(GameFontHighlightSmall)
	histTab:SetHighlightFontObject(GameFontHighlightSmall)
	histTab:SetScript("OnClick", setShownPage)
	histTab:SetWidth(90)
	histTab:SetHeight(14)
	histTab:SetFormattedText(L["%dvs%d History"], 3, 3)
	histTab:SetPoint("TOPLEFT", self.tabFrame.historyTwo, "BOTTOMLEFT", 0, -2)
	histTab.bracket = 3
	histTab.type = "history"
	
	self.tabFrame.historyThree = histTab
	table.insert(self.tabFrame.browseButtons, histTab)

	--[[
	local tab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	tab:SetTextFontObject(GameFontHighlightSmall)
	tab:SetHighlightFontObject(GameFontHighlightSmall)
	tab:SetScript("OnClick", setShownPage)
	tab:SetWidth(45)
	tab:SetHeight(14)
	tab:SetText(L["Stats"])
	tab:SetPoint("TOPLEFT", histTab, "TOPRIGHT", 0, 0)
	tab.bracket = 3
	tab.type = "stats"

	table.insert(self.tabFrame.browseButtons, tab)
	]]

	-- 5 VS 5 Buttons
	local histTab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	histTab:SetTextFontObject(GameFontHighlightSmall)
	histTab:SetHighlightFontObject(GameFontHighlightSmall)
	histTab:SetScript("OnClick", setShownPage)
	histTab:SetWidth(90)
	histTab:SetHeight(14)
	histTab:SetFormattedText(L["%dvs%d History"], 5, 5)
	histTab:SetPoint("TOPLEFT", self.tabFrame.historyThree, "BOTTOMLEFT", 0, -2)
	histTab.bracket = 5
	histTab.type = "history"
	
	self.tabFrame.historyFive = histTab
	table.insert(self.tabFrame.browseButtons, histTab)

	--[[
	local tab = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	tab:SetTextFontObject(GameFontHighlightSmall)
	tab:SetHighlightFontObject(GameFontHighlightSmall)
	tab:SetScript("OnClick", setShownPage)
	tab:SetWidth(45)
	tab:SetHeight(14)
	tab:SetText(L["Stats"])
	tab:SetPoint("TOPLEFT", histTab, "TOPRIGHT", 0, 0)
	tab.bracket = 5
	tab.type = "stats"
	
	table.insert(self.tabFrame.browseButtons, tab)
	]]
	
	-- Reset button
	local reset = CreateFrame("Button", nil, self.tabFrame, "UIPanelButtonGrayTemplate")
	reset:SetTextFontObject(GameFontHighlightSmall)
	reset:SetHighlightFontObject(GameFontHighlightSmall)
	reset:SetScript("OnClick", function() resetFilters(); updateFilters(); updatePage(); end)
	reset:SetWidth(90)
	reset:SetHeight(14)
	reset:SetText(L["Reset filters"])
	reset:SetPoint("TOPLEFT", self.tabFrame.historyFive, "BOTTOMLEFT", 0, -6)
	
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