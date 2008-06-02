Sync = ArenaHistorian:NewModule("Sync", "AceComm-3.0")

local L = ArenaHistLocals
local syncStatus = {type = "none", totalReceived = 0, totalSent = 0, totalGames = 0, lastUpdate = 0, timeout = 0}
local idTable = {}
local sendQueue = {}
local teamList = {}
local playerName
local notPlaying

function Sync:OnInitialize()
	playerName = UnitName("player")
	notPlaying = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.+)")
	
	self:RegisterComm("AHIST")
end

-- Create a list of teamIDs that we can use as a unique identify besides time
local function getTeamID(...)
	local id = ""
	for i=1, select("#", ...) do
		local name, _, _, _, healingDone, damageDone = string.split(",", (select(i, ...)))
		id = id .. name .. healingDone .. damageDone
	end

	return id
end

local function getTeamList(bracket)
	for k in pairs(teamList) do teamList[k] = nil end
	
	for id, data in pairs(ArenaHistoryData[bracket]) do
		local endTime, _, playerTeamName, _, enemyTeamName = string.split("::", id)
		endTime = tonumber(endTime)

		if( playerTeamName ~= "" and enemyTeamName ~= "" and endTime ) then
			local playerTeam, enemyTeam = select(2, string.split(";", data))
			local teamID = string.format("%s%s", getTeamID(string.split(":", playerTeam)), getTeamID(string.split(":", enemyTeam)))
			
			teamList[teamID] = string.format("%s@%s", id, data)
		end
	end
	
	return teamList
end

-- Make sure they are on our team before syncing with them
function Sync:IsOnTeam(name, bracket)
	if( not name or not bracket ) then
		return nil
	end	

	for i=1, MAX_ARENA_TEAMS do
		local teamSize = select(2, GetArenaTeam(i))
		if( teamSize == bracket ) then
			for j=1, GetNumArenaTeamMembers(i, true) do
				if( select(1, GetArenaTeamRosterInfo(i, j)) == name ) then
					return true
				end
			end
		end
	end
	
	return nil
end

-- We're sending a request to another player to send us his team data for the set bracket
function Sync:SendRequest(name, bracket)
	if( not self:IsOnTeam(name, bracket) ) then
		return
	end
	
	self:SendMessage(string.format("REQDATA: %d", bracket), name)
	

	syncStatus.totalReceived = 0

	syncStatus.totalSent = 0
	syncStatus.totalGames = 0
	syncStatus.requestFrom = name
	syncStatus.bracket = bracket
	syncStatus.denyReason = nil
	self:UpdateStatus("requested")
end

-- Reset it back to nothing happened
function Sync:ResetSync()
	syncStatus.totalReceived = 0
	syncStatus.totalSent = 0
	syncStatus.totalGames = 0
	syncStatus.requestFrom = nil
	syncStatus.bracket = nil
	syncStatus.denyReason = nil
	self:UpdateStatus("none")
end

-- We got a request from another player who wants our team data for the sent bracket
function Sync:RequestedData(sender, bracket)
	-- Not on our team, so deny it quickly
	if( not self:IsOnTeam(sender, bracket) ) then
		self:SendMessage("REQDENY: 1", sender)
		return

	end
	

	if( not StaticPopupDialogs["ARENAHIST_DATAREQUESTED"] ) then
		StaticPopupDialogs["ARENAHIST_DATAREQUESTED"] = {
			button1 = ACCEPT,
			button2 = L["Deny"],
			OnAccept = function(data)
				Sync:UpdateStatus("accept")
				Sync:SendMessage("REQACCEPT", data)
				
				Sync:CreateGUI()
				Sync.frame:Show()
			end,
			OnCancel = function(data)
				Sync:UpdateStatus("deny")
				Sync:SendMessage("REQDENY: 2", data)
			end,
			timeout = 30,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 1
		}
	end
	
	StaticPopupDialogs["ARENAHIST_DATAREQUESTED"].text = string.format(L["%s has requested missing data for %dvs%d, sync data?"], sender, bracket, bracket)

	local dialog = StaticPopup_Show("ARENAHIST_DATAREQUESTED")
	if( dialog ) then
		dialog.data = sender
	end
end

-- Our request for data was denied, either because we aren't on their team or the person we asked denied it
function Sync:RequestDenied(sender, reason)
	if( syncStatus.type ~= "requested" or not self:IsOnTeam(sender, syncStatus.bracket) ) then
		return

	end
	
	syncStatus.denyReason = tonumber(reason) or 2
	self:UpdateStatus("denied")
end

-- Our request was accepted, compiled a list of teamIDs for the bracket we asked for and send them off
function Sync:RequestAccepted(sender)
	if( syncStatus.type ~= "requested" or not self:IsOnTeam(sender, syncStatus.bracket) ) then
		return
	end	

	self:UpdateStatus("accepted")
	
	-- Reset table
	for i=#(idTable), 1, -1 do table.remove(idTable, i) end
	
	for id, data in pairs(getTeamList(syncStatus.bracket)) do
		table.insert(idTable, id)
	end
	
	self:SendMessage(string.format("IDHAVE: %d@%s", syncStatus.bracket, table.concat(idTable, "@")), sender)
end

-- We got a list of ids that the person already has, will now compile a list of everything we have, and remove what they already have then send it
function Sync:StartSending(sender, bracket, ...)
	bracket = tonumber(bracket)
	

	-- Got a sync for a bracket we aren't doing
	for k in pairs(sendQueue) do sendQueue[k] = nil end
	
	-- Queue up everything we have for this bracket
	for id, data in pairs(getTeamList(bracket)) do
		sendQueue[id] = data
	end
	
	-- Remove what we already have
	for i=1, select("#", ...) do
		sendQueue[select(i, ...)] = nil
	end
		
	-- How many do we have to send?
	local totalGames = 0
	for id in pairs(sendQueue) do
		totalGames = totalGames + 1
	end
	
	self:SendMessage(string.format("SENDING: %d@%d", bracket, totalGames), sender)
	
	syncStatus.totalGames = totalGames
	

	-- Start sending
	if( totalGames == 0 ) then
		self:UpdateStatus("nothing")
		return
	else
		self:UpdateStatus("sending")
	end
	
	for _, data in pairs(sendQueue) do
		self:SendMessage(string.format("DATA: %d@%s", bracket, data), sender)
	end
end

-- We have been told how many games to expect to get data-wise
function Sync:PrepareReceive(sender, bracket, games)
	bracket = tonumber(bracket)
	games = tonumber(games)
	

	-- Not waiting for data
	if( syncStatus.type ~= "accepted" or syncStatus.bracket ~= bracket ) then
		return
	end
	
	-- No games to send, so we're done
	if( games == 0 ) then
		self:UpdateStatus("nothing")
		return
	end
	
	syncStatus.totalGames = games
	syncStatus.waitForData = nil
	self:UpdateStatus("waiting")
end

-- We got game data
function Sync:GotData(sender, bracket, id, data)
	bracket = tonumber(bracket)

	-- No waiting for data or other issues
	if( ( syncStatus.type ~= "receiving" and syncStatus.type ~= "waiting" ) or syncStatus.bracket ~= bracket ) then
		return
	end
	
	syncStatus.totalReceived = syncStatus.totalReceived + 1
	self:UpdateStatus("receiving")
		
	-- Don't overwrite any data we have with synced data
	if( not ArenaHistoryData[bracket][id] ) then
		ArenaHistoryData[bracket][id] = data
	end
	
	-- Done, stop waiting for data
	if( syncStatus.totalReceived == syncStatus.totalGames ) then
		self:SendMessage("GOTALL", sender)
		self:UpdateStatus("done")
	
	-- Respond that we got this game
	else
		self:SendMessage(string.format("GOT: %d", syncStatus.totalReceived), sender)

	end
end

-- The requester got # and told us
function Sync:GotNumber(sender, sent)
	if( syncStatus.type ~= "sending" ) then
		return
	end
	
	syncStatus.totalSent = sent
	self:UpdateStatus("sending")
end

-- The requester got all the data
function Sync:SentAllData(sender)
	if( syncStatus.type ~= "sending" ) then
		return
	end
	
	self:UpdateStatus("sentall")
end

function Sync:SendMessage(msg, target, priority)
	self:SendCommMessage("AHIST", msg, "WHISPER", target)
end

function Sync:OnCommReceived(prefix, message, distribution, sender)
	if( prefix == "AHIST" and sender ~= playerName ) then
		local dataType, data = string.match(message, "([^:]+)%:(.+)")
		if( not dataType and not data ) then
			dataType = message
		end
		
		ChatFrame3:AddMessage(string.format("[%s] [%s]", sender, dataType))
		
		if( dataType == "REQDATA" ) then
			data = tonumber(data)
			if( data ) then
				self:RequestedData(sender, data)
			end
		elseif( dataType == "REQDENY" ) then
			data = tonumber(data)
			if( data )  then
				self:RequestDenied(sender, data)
			end
		elseif( dataType == "IDHAVE" ) then
			self:StartSending(sender, string.split("@", data))
		
		elseif( dataType == "SENDING" ) then
			self:PrepareReceive(sender, string.split("@", data))
		
		elseif( dataType == "DATA" ) then
			self:GotData(sender, string.split("@", data))
		
		elseif( dataType == "GOT" ) then
			data = tonumber(data)
			if( data ) then
				self:GotNumber(sender, data)
			end
		
		elseif( dataType == "GOTALL" ) then
			self:SentAllData(sender)
			
		elseif( dataType == "REQACCEPT" ) then
			self:RequestAccepted(sender)
		end
	end
end

-- GUI
local timeouts = {["requested"] = 30, ["none"] = 0, ["sentall"] = 0, ["done"] = 0}
function Sync:UpdateStatus(type)
	syncStatus.type = type
	syncStatus.lastUpdate = GetTime()
	syncStatus.timeout = timeouts[type] or 120

	self:UpdateGUI()
end

function Sync:UpdateGUI()
	if( not self.frame ) then
		return
	end

	local self = Sync
	if( syncStatus.type == "requested" ) then
		self.frame.statusText:SetText(L["Request sent, waiting for approval"])
	elseif( syncStatus.type == "accept" ) then
		self.frame.statusText:SetText(L["Request accepted, waiting for game list"])
	elseif( syncStatus.type == "deny" ) then
		self.frame.statusText:SetText(L["Request denied"])
	elseif( syncStatus.type == "accepted" ) then
		self.frame.statusText:SetText(L["Request accepted, sending game list"])
	elseif( syncStatus.type == "denied" ) then
		if( syncStatus.denyReason == 1 ) then
			self.frame.statusText:SetText(L["Request denied, you are not on the same team"])
		elseif( syncStatus.denyReason == 2 ) then
			self.frame.statusText:SetText(L["Request denied"])
		end
		
	elseif( syncStatus.type == "receiving" ) then
		self.frame.statusText:SetFormattedText(L["Receiving %d of %d"], syncStatus.totalReceived, syncStatus.totalGames)
	elseif( syncStatus.type == "waiting" ) then
		self.frame.statusText:SetFormattedText(L["Waiting for data, %d total games to sync"], syncStatus.totalGames)
	elseif( syncStatus.type == "sending" ) then
		self.frame.statusText:SetFormattedText(L["Sent %d of %d"], syncStatus.totalSent, syncStatus.totalGames)
	elseif( syncStatus.type == "done" ) then
		self.frame.statusText:SetFormattedText(L["Finished! %d new games received"], syncStatus.totalGames)	
	elseif( syncStatus.type == "sentall" ) then
		self.frame.statusText:SetFormattedText(L["Finished! %d new games sent"], syncStatus.totalGames)
	elseif( syncStatus.type == "nothing" ) then
		self.frame.statusText:SetText(L["No new games to sync"])

	else
		self.frame.statusText:SetText(L["Waiting for sync to be sent"])
	end
	
	-- If the sync is done, deny or denied enable it again
	if( syncStatus.type == "none" or syncStatus.type == "done" or syncStatus.type == "sentall" or syncStatus.type == "nothing" or syncStatus.type == "deny" or syncStatus.type == "denied" ) then
		Sync.frame.timeoutText:SetText(L["Timeout: ----"])
		syncStatus.timeout = 0
		
		UIDropDownMenu_EnableDropDown(AHSyncBracket)
		self.frame.send:Enable()
	else
		UIDropDownMenu_DisableDropDown(AHSyncBracket)
		self.frame.send:Disable()
	end
end

local function OnUpdate(self, elapsed)
	if( syncStatus.timeout <= 0 ) then
		return
	end	

	local time = GetTime()
	syncStatus.timeout = syncStatus.timeout - (time - syncStatus.lastUpdate)
	syncStatus.lastUpdate = time
	
	if( syncStatus.timeout <= 0 ) then
		Sync:ResetSync()
		
		syncStatus.timeout = 0
		self.timeoutText:SetText(L["Timed out, no data received"])
	else
		self.timeoutText:SetFormattedText(L["Timeout: %d seconds"], math.ceil(syncStatus.timeout))
	end
end

local function dropdownSelected()
	UIDropDownMenu_SetSelectedValue(AHSyncBracket, this.value)
end

local function initDropdown()
	UIDropDownMenu_AddButton({value = 2, text = "2vs2", arg1 = "bracket", func = dropdownSelected})
	UIDropDownMenu_AddButton({value = 3, text = "3vs3", arg1 = "bracket", func = dropdownSelected})
	UIDropDownMenu_AddButton({value = 5, text = "5vs5", arg1 = "bracket", func = dropdownSelected})
end

-- Send the sync off
local function sendSync(self)
	local name = Sync.frame.name:GetText()
	local bracket = UIDropDownMenu_GetSelectedValue(AHSyncBracket)
	
	if( not name or name == "" or not bracket ) then
		Sync.frame.statusText:SetText(L["Invalid data entered"])
		return
	end
	
	if( not Sync:IsOnTeam(name, bracket) ) then
		Sync.frame.statusText:SetText(L["Cannot send sync, player isn't on your team"])
		return
	end
	

	UIDropDownMenu_DisableDropDown(AHSyncBracket)
	self:Disable()

	Sync:SendRequest(name, bracket)
end

-- Make sure they aren't offline
local function checkOffline(message)
	local name = string.match(message,  notPlaying)
	if( name and name == Sync.frame.name:GetText() ) then
		Sync:UpdateStatus("none")
		Sync.frame.statusText:SetFormattedText(L["Player '%s' is not online"], name)
		Sync.frame.timeoutText:SetText(L["Timeout: ----"])
	end
end

function Sync:CreateGUI()
	local self = Sync
	if( self.frame ) then
		return
	end
	
	local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = false,
			edgeSize = 1,
			tileSize = 5,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}
	

	self.frame = CreateFrame("Frame", "ArenaHistorianSync", UIParent)
	self.frame.timeout = 0
	self.frame:SetScript("OnUpdate", OnUpdate)
	self.frame:SetHeight(92)
	self.frame:SetWidth(265)
	self.frame:SetClampedToScreen(true)
	self.frame:SetMovable(true)
	self.frame:EnableKeyboard(false)
	self.frame:SetBackdrop(backdrop)
	self.frame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	self.frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	self.frame:SetFrameStrata("DIALOG")
	self.frame:SetScript("OnShow", function(self)
		self.timeoutText:SetText(L["Timeout: ----"])
		self.statusText:SetText(L["Waiting for sync to be sent"])
		Sync:UpdateGUI()

		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", checkOffline)
	end)
	self.frame:SetScript("OnHide", function(self)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", checkOffline)
	end)
	self.frame:Hide()

	table.insert(UISpecialFrames, "ArenaHistorianSync")
	
	-- Close button
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", 4, 4)
	button:SetScript("OnClick", function()
		HideUIPanel(Sync.frame)
	end)
	
	-- Now the title text
	self.title = self.frame:CreateFontString(nil, "ARTWORK")
	self.title:SetFont(GameFontNormalSmall:GetFont(), 14)
	self.title:SetPoint("CENTER", self.frame, "TOP", 0, -10)
	self.title:SetText(L["Data Syncing"])
	
	self.mover = CreateFrame("Button", nil, self.frame)
	self.mover:SetPoint("TOPLEFT", self.title, "TOPLEFT", -2, 0)
	self.mover:SetWidth(150)
	self.mover:SetHeight(20)
	self.mover:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			self:GetParent():StopMovingOrSizing()
		end
	end)
	self.mover:SetScript("OnMouseDown", function(self)
		self.isMoving = true
		self:GetParent():StartMoving()
	end)

	self.frame.name = CreateFrame("EditBox", "AHSyncName", self.frame, "InputBoxTemplate")
	self.frame.name:SetHeight(20)
	self.frame.name:SetWidth(120)
	self.frame.name:SetAutoFocus(false)
	self.frame.name:ClearAllPoints()
	self.frame.name:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -30)

	self.frame.bracket = CreateFrame("Frame", "AHSyncBracket", self.frame, "UIDropDownMenuTemplate")
	self.frame.bracket:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 120, -26)
	self.frame.bracket:SetScript("OnShow", function(self)
		UIDropDownMenu_Initialize(AHSyncBracket, initDropdown)
		UIDropDownMenu_SetWidth(55, AHSyncBracket)
		UIDropDownMenu_SetSelectedValue(AHSyncBracket, 2)
	end)

	self.frame.send = CreateFrame("Button", nil, self.frame, "UIPanelButtonGrayTemplate")
	self.frame.send:SetText(L["Sync"])
	self.frame.send:SetHeight(25)
	self.frame.send:SetWidth(40)
	self.frame.send:SetScript("OnClick", sendSync)
	self.frame.send:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -27)
	
	-- Text
	self.frame.statusText = self.frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.statusText:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -60)
	
	self.frame.timeoutText = self.frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.timeoutText:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -80)
end