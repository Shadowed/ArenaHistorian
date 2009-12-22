local Config = ArenaHistorian:NewModule("Config")
local L = ArenaHistLocals

local optionFrame, options

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
			InterfaceOptionsFrame_OpenToCategory(optionFrame)
		elseif( msg == "sync" ) then
			ArenaHistorian.modules.Sync.CreateGUI()
			ArenaHistorian.modules.Sync.frame:Show()
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["ArenaHistorian slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - history - Shows the arena history panel"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - config - Opens the OptionHouse configuration panel"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - sync - Shows the arena history sync frame"])
		end
	end
	

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ArenaHistorian", self.CreateUI)
	optionFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ArenaHistorian")
end

function Config:CreateUI()
	if( options ) then
		return options
	end

	local self = ArenaHistorian
	local get = function(info)
		return self.db.profile[info[#(info)]]
	end
	local set = function(info, value)
		self.db.profile[info[#(info)]] = value
	end
	local setNumber = function(info, value)
		self.db.profile[info[#(info)]] = tonumber(value)
	end
	local disabled = function(info)
		if( info[#(info)] == "maxRecords" ) then
			return not self.db.profile.enableMax
		elseif( info[#(info)] == "maxWeeks" ) then
			return not self.db.profile.enableWeek
		end
	end

	local options = {
		name = "Arena Historian",
		type = "group",
		get = get,
		set = set,
		handler = self,
		args = {
			--[[
			enableGuess = {
				order = 1,
				type = "toggle",
				name = L["Enable talent guessing"],
				desc = L["Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea."],
				width = "full",
			},
			]]
			retention = {
				order = 2,
				type = "group",
				name = L["Data retention"],
				desc = L["Allows you to set how long data should be saved before being removed."],
				dialogInline = true,
				args = {
					enableMax = {
						order = 1,
						type = "toggle",
						name = L["Enable maximum records"],
						desc = L["Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea."],
						width = "full",
					},
					maxRecords = {
						order = 2,
						type = "range",
						name = L["Maximum saved records"],
						desc = L["How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones."],
						min = 1, max = 1000, step = 1,
						set = setNumber,
						disabled = disabled,
						width = "full",
					},
					enableWeek = {
						order = 3,
						type = "toggle",
						name = L["Enable week records"],
						width = "full",
					},
					maxWeeks = {
						order = 4,
						type = "range",
						name = L["How many weeks to save records"],
						desc = string.format(L["Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s"], date("%c")),
						min = 1, max = 52, step = 1,
						set = setNumber,
						disabled = disabled,
						width = "full",
					},
				},
			},
		},
	}

	return options
end