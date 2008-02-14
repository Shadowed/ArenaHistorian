local Config = ArenaHistorian:NewModule("Config")
local L = ArenaHistLocals

local OptionHouse
local HouseAuthority
local OHObj

function Config:OnInitialize()
	-- Random things
	SLASH_ARENAHISTORIAN1 = "/arenahistory"
	SLASH_ARENAHISTORIAN2 = "/arenahistorian"
	SLASH_ARENAHISTORIAN3 = "/arenahist"
	SLASH_ARENAHISTORIAN4 = "/ah"
	SlashCmdList["ARENAHISTORIAN"] = function(msg)
		msg = string.lower(msg or "")
		
		if( msg == "history" ) then
			ArenaHistorian.modules.GUI:CreateFrame()
			ArenaHistorian.modules.GUI.frame:Show()
		elseif( msg == "config" ) then
			OptionHouse:Open("Arena Historian")
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["ArenaHistorian slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - history - Shows the arena history panel"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - config - Opens the OptionHouse configuration panel"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration."])
		end
	end
	
	-- Register with OptionHouse
	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
	
	OHObj = OptionHouse:RegisterAddOn("Arena Historian", nil, "Mayen", "r" .. max(tonumber(string.match("$Revision$", "(%d+)")) or 1, ArenaHistorian.revision))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
end


-- GUI
function Config:Set(var, value)
	ArenaHistorian.db.profile[var] = value
end

function Config:Get(var)
	return ArenaHistorian.db.profile[var]
end

function Config:Reload()
	ArenaHistorian:Reload()
end

function Config:CreateUI()
	local currentDate = date("%c", time())

	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ order = 1, group = L["General"], text = L["Enable maximum records"], help = L["Enables only storing the last X entered records."], type = "check", var = "enableMax"},
		{ order = 2, group = L["General"], text = L["Maximum saved records"], help = L["How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones."], type = "input", numeric = true, default = 5, width = 30, var = "maxRecords"},

		{ order = 3, group = L["General"], text = L["Enable week records"], help = L["Enables removing records that are over X weeks old."], type = "check", var = "enableWeek"},
		{ order = 4, group = L["General"], text = L["How many weeks to save records"], help = string.format(L["Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s"], currentDate), type = "input", numeric = true, default = 5, width = 30, var = "maxWeeks"},
	}

	return HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = self})	
end