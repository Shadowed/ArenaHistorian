ArenaHistLocals = {
	["Arena Historian"] = "Arena Historian",
	["Show 2vs2"] = "Show 2vs2",
	["Show 3vs3"] = "Show 3vs3",
	["Show 5vs5"] = "Show 5vs5",
	
	["%d Rating (%d Points)"] = "%d Rating (%d Points)",
	
	["Run Time: %s"] = "Run Time: %s",
	["Record: %s/%s"] = "Record: %s/%s",
	["Zone: %s"] = "Zone: %s",
	["%s - Damage (%d) / Healing (%d)"] = "%s - Damage (%d) / Healing (%d)",
	
	["Unknown"] = "Unknown",
	["Arena Preparation"] = "Arena Preparation",
	["Enemy team name"] = "Enemy team name",
	["Enemy player name"] = "Enemy player name",
	["Search"] = "Search...",
	["Min rate"] = "Min rate",
	["Max rate"] = "Max rate",
	
	["Total records"] = "Total records",
	["Total visible"] = "Total visible",
	["Browsing"] = "Browsing",
	["OK"] = "OK",
	
	["Male"] = "Male",
	["Female"] = "Female",
	
	["Hold ALT and click the button to delete this arena record."] = "Hold ALT and click the button to delete this arena record.",

	["The Arena battle has begun!"] = "The Arena battle has begun!",
	
	-- Syncing
	["Deny"] = "Deny",
	["%s has requested missing data for %dvs%d, sync data?"] = "%s has requested missing data for %dvs%d, sync data?",
	["Data Syncing"] = "Data Syncing",
	["Sync"] = "Sync",
	

	["Waiting for sync to be sent"] = "Waiting for sync to be sent",

	["Timed out, no data received"] = "Timed out, no data received",
	["Timeout: %d seconds"] = "Timeout: %d seconds",
	["Timeout: ----"] = "Timeout: ----",
	
	["No new games to sync"] = "No new games to sync",
	["Player '%s' is not online"] = "Player '%s' is not online",
	["Invalid data entered"] = "Invalid data entered",
	["Request sent, waiting for approval"] = "Request sent, waiting for approval",
	["Cannot send sync, player isn't on your team"] = "Cannot send sync, player isn't on your team",
	["Request accepted, waiting for game list"] = "Request accepted, waiting for game list",
	["Request accepted, sending game list"] = "Request accepted, sending game list",
	["Request denied"] = "Request denied",
	["Request denied, you are not on the same team"] = "Request denied, you are not on the same team",
	["Finished! %d new games received"] = "Finished! %d new games received",
	["Finished! %d new games sent"] = "Finished! %d new games sent",
	["Sent %d of %d"] = "Sent %d of %d",
	["Receiving %d of %d"] = "Receiving %d of %d",
	["Waiting for data, %d total games to sync"] = "Waiting for data, %d total games to sync",

	-- This is a simple race -> token map, we don't do gendor checks here
	["TOKENS"] = {
		["HUMAN_FEMALE"] = "Human",
		["DWARF_FEMALE"] = "Dwarf",
		["GNOME_FEMALE"] = "Gnome",
		["NIGHTELF_FEMALE"] = "Night Elf",
		["SCOURGE_FEMALE"] = "Undead",
		["TROLL_FEMALE"] = "Troll",
		["ORC_FEMALE"] = "Orc",
		["BLOODELF_FEMALE"] = "Bloof Elf",
		["TAUREN_FEMALE"] = "Tauren",
		["DRAENEI_FEMALE"] = "Draenei",
	},
	
	-- Zone -> abbreviation
	["BEA"] = "BEA",
	["NA"] = "NA",
	["RoL"] = "RoL",
	
	-- Arenas
	["Blade's Edge Arena"] = "Blade's Edge Arena",
	["Nagrand Arena"] = "Nagrand Arena",
	["Ruins of Lordaeron"] = "Ruins of Lordaeron",
	
	-- Token -> Text
	["HUMAN_FEMALE"] = "Female Human",
	["HUMAN_MALE"] = "Male Human",
	
	["DWARF_FEMALE"] = "Female Dwarf",
	["DWARF_MALE"] = "Male Dwarf",
	
	["NIGHTELF_FEMALE"] = "Female Night Elf",
	["NIGHTELF_MALE"] = "Male Night Elf",
	
	["TROLL_FEMALE"] = "Female Troll",
	["TROLL_MALE"] = "Male Troll",
	
	["BLOODELF_FEMALE"] = "Female Bloof Elf",
	["BLOODELF_MALE"] = "Male Bloof Elf",

	["DRAENEI_FEMALE"] = "Female Draenei",
	["DRAENEI_MALE"] = "Male Draenei",

	["GNOME_FEMALE"] = "Female Gnome",
	["GNOME_MALE"] = "Male Gnome",

	["SCOURGE_FEMALE"] = "Female Undead",
	["SCOURGE_MALE"] = "Male Undead",

	["ORC_FEMALE"] = "Female Orc",
	["ORC_MALE"] = "Male Orc",

	["TAUREN_FEMALE"] = "Female Tauren",
	["TAUREN_MALE"] = "Male Tauren",
	
	["WARRIOR"] = "Warrior",
	["DRUID"] = "Druid",
	["PALADIN"] = "Paladin",
	["SHAMAN"] = "Shaman",
	["WARLOCK"] = "Warlock",
	["PRIEST"] = "Priest",
	["MAGE"] = "Mage",
	["HUNTER"] = "Hunter",
	["ROGUE"] = "Rogue",
	
	-- Config
	["ArenaHistorian slash commands"] = "ArenaHistorian slash commands",
	[" - history - Shows the arena history panel"] = " - history - Shows the arena history panel",
	[" - config - Opens the OptionHouse configuration panel"] = " - config - Opens the OptionHouse configuration panel",
	[" - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration."] = " - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration.",
	[" - sync - Shows the arena history sync frame"] = " - sync - Shows the arena history sync frame",
	
	["General"] = "General",
	["Enable talent guessing"] = "Enable talent guessing",
	["Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea."] = "Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea.",
	
	["Enable maximum records"] = "Enable maximum records",

	["Enables only storing the last X entered records."] = "Enables only storing the last X entered records.",
	
	["Maximum saved records"] = "Maximum saved records",
	["How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones."] = "How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones.",
	
	["Enable week records"] = "Enable week records",
	["Enables removing records that are over X weeks old."] = "Enables removing records that are over X weeks old.",
	["How many weeks to save records"] = "How many weeks to save records",
	["Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s"] = "Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s",
	
	["Enter the talent points spent in each tree for %s from %s."] = "Enter the talent points spent in each tree for %s from %s.",
	
	["Data retention"] = "Data retention",
	["Allows you to set how long data should be saved before being removed."] = "Allows you to set how long data should be saved before being removed.",
}