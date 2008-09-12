--zhTW Localization
--中文化 by 龐克 @ 狂熱之刃

if(GetLocale()=="zhTW") then
	ArenaHistLocals = {
		["Arena Historian"] = "Arena Historian",
		
		["%dvs%d History"] = "%dvs%d 紀錄",
		["Stats"] = "組合",
		
		["%d Rating (%d Points)"] = "%d 階級 (%d 分)",
		
		["Run Time: %s"] = "歷時: %s",
		["Record: %s/%s"] = "紀錄: %s/%s",
		["Zone: %s"] = "地區: %s",
		["%s\nDamage (|cffffffff%s|r)\nHealing (|cffffffff%s|r)"] = "%s\n傷害 (|cffffffff%s|r)\n治療 (|cffffffff%s|r)",
		["%s - %s\nDamage (|cffffffff%s|r)\nHealing (|cffffffff%s|r)"] = "%s - %s\n傷害 (|cffffffff%s|r)\n治療 (|cffffffff%s|r)",
		["Date: %s"] = "日期: %s",
		["%s:%s (%.1f%%) (%s)"] = "%s:%s (%.1f%%) (%s)",
		
		["Unknown"] = "未知",
		["Arena Preparation"] = "競技場準備",
		["Enemy team name"] = "隊名",
		["Enemy player name"] = "人名",
		["Search"] = "搜尋...",
		["Min rate"] = "Min 階級",
		["Max rate"] = "Max 階級",
		
		["Talents"] = "天賦",
		["Classes"] = "職業",
		["Reset filters"] = "重置過濾",
		
		["%s's shown"] = "%s 出場",
		["%s's hidden"] = "%s 沒出場",
		
		["OK"] = "OK",
		
		["Male"] = "Male",
		["Female"] = "Female",
		
		["Hold ALT and click the button to delete this arena record."] = "按住 ALT 點 X 刪除這筆紀錄.",
		
		["The Arena battle has begun!"] = "The Arena battle has begun!",
		
		["Strict"] = "過濾",
		["Only show teams with all the selected classes in them."] = "只顯示出場的職業組合.",
		
		["Show loses"] = "顯示 敗場",
		["Show wins"] = "顯示 勝場",
		["Show draws"] = "顯示 平手",
		
		-- Syncing
		["Deny"] = "拒絕",
		["%s has requested missing data for %dvs%d, sync data?"] = "%s 要求遺失的 %dvs%d 資料,要傳送嗎?",
		["Data Syncing"] = "資料同步",
		["Sync"] = "同步",
		
		["Waiting for sync to be sent"] = "等待資料傳送",
		
		["Timed out, no data received"] = "時間結束,沒有接收資料",
		["Timeout: %d seconds"] = "剩餘時間: %d 秒",
		["Timeout: ----"] = "剩餘時間: ----",
		
		["No new games to sync"] = "沒有新場次可同步",
		["Player '%s' is not online"] = "玩家 '%s' 不在線上",
		["Invalid data entered"] = "輸入錯誤的資料",
		["Request sent, waiting for approval"] = "傳送要求,等待許可",
		["Cannot send sync, player isn't on your team"] = "無法同步,玩家不在競技場隊伍",
		["Request accepted, waiting for game list"] = "要求被接受, 等待場次清單",
		["Request accepted, sending game list"] = "接受要求, 傳送場次清單",
		["Request denied"] = "要求被拒絕",
		["Request denied, you are not on the same team"] = "要求被拒絕,你不在相同的競技場隊伍",
		["Finished! %d new games received"] = "完成! %d 收到新場次",
		["Finished! %d new games sent"] = "完成! %d 傳送新場次",
		["Sent %d of %d"] = "傳送 %d 的 %d",
		["Receiving %d of %d"] = "接收 %d 的 %d",
		["Waiting for data, %d total games to sync"] = "等待資料中, %d 場次可同步",
		
		-- This is a simple race -> token map, we don't do gendor checks here
		["TOKENS"] = {
		["HUMAN_FEMALE"] = "人類",
		["DWARF_FEMALE"] = "矮人",
		["GNOME_FEMALE"] = "地精",
		["NIGHTELF_FEMALE"] = "夜精靈",
		["SCOURGE_FEMALE"] = "不死族",
		["TROLL_FEMALE"] = "食人妖",
		["ORC_FEMALE"] = "獸人",
		["BLOODELF_FEMALE"] = "血精靈",
		["TAUREN_FEMALE"] = "牛頭人",
		["DRAENEI_FEMALE"] = "德萊尼",
		},
		
		-- Zone -> abbreviation
		["BEA"] = "BEA",
		["NA"] = "NA",
		["RoL"] = "RoL",
		
		-- Arenas
		["Blade's Edge Arena"] = "劍刃競技場",
		["Nagrand Arena"] = "納葛蘭競技場",
		["Ruins of Lordaeron"] = "羅德隆廢墟",
		
		-- Token -> Text
		["HUMAN_FEMALE"] = "女 人類",
		["HUMAN_MALE"] = "男 人類",
		
		["DWARF_FEMALE"] = "女 矮人",
		["DWARF_MALE"] = "男 矮人",
		
		["NIGHTELF_FEMALE"] = "女 夜精靈",
		["NIGHTELF_MALE"] = "男 夜精靈",
		
		["TROLL_FEMALE"] = "女 食人妖",
		["TROLL_MALE"] = "男 食人妖",
		
		["BLOODELF_FEMALE"] = "女 血精靈",
		["BLOODELF_MALE"] = "男 血精靈",
		
		["DRAENEI_FEMALE"] = "女 德萊尼",
		["DRAENEI_MALE"] = "男 德萊尼",
		
		["GNOME_FEMALE"] = "女 地精",
		["GNOME_MALE"] = "男 地精",
		
		["SCOURGE_FEMALE"] = "女 不死族",
		["SCOURGE_MALE"] = "男 不死族",
		
		["ORC_FEMALE"] = "女 獸人",
		["ORC_MALE"] = "男 獸人",
		
		["TAUREN_FEMALE"] = "女 牛頭人",
		["TAUREN_MALE"] = "男 牛頭人",
		
		["WARRIOR"] = "戰士",
		["DRUID"] = "德魯伊",
		["PALADIN"] = "聖騎士",
		["SHAMAN"] = "薩滿",
		["WARLOCK"] = "術士",
		["PRIEST"] = "牧師",
		["MAGE"] = "法師",
		["HUNTER"] = "獵人",
		["ROGUE"] = "盜賊",
		
		-- Tree names
		["Elemental"] = "元素",
		["Enhancement"] = "增強",
		["Restoration"] = "恢復",
		["Arcane"] = "密法",
		["Fire"] = "火焰",
		["Frost"] = "冰霜",
		["Affliction"] = "痛苦",
		["Demonology"] = "惡魔",
		["Destruction"] = "毀滅",
		["Balance"] = "平衡",
		["Feral"] = "野性戰鬥",
		["Restoration"] = "恢復",
		["Arms"] = "武器",
		["Fury"] = "狂怒",
		["Protection"] = "防禦",
		["Assassination"] = "刺殺",
		["Combat"] = "戰鬥",
		["Subtlety"] = "敏銳",
		["Holy"] = "神聖",
		["Protection"] = "防護",
		["Retribution"] = "懲戒",
		["Beast Mastery"] = "野獸控制",
		["Marksmanship"] = "射擊",
		["Survival"] = "生存",
		["Discipline"] = "誡律",
		["Holy"] = "神聖",
		["Shadow"] = "暗影",
		
		
		-- Config
		["ArenaHistorian slash commands"] = "ArenaHistorian 指令",
		[" - history - Shows the arena history panel"] = " /ah history - 顯示競技場記錄介面",
		[" - config - Opens the OptionHouse configuration panel"] = " /ah config - 開啟 OptionHouse 設定介面",
		[" - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration."] = " /ah clean - 移除所有與設定不符資料.",
		[" - sync - Shows the arena history sync frame"] = " /ah sync - 顯示競技場記錄之同步介面",
		
		["General"] = "基本",
		["Enable talent guessing"] = "啟用 天賦猜測",
		["Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea."] = "收集敵隊施法紀錄情報,然後猜測大致天賦.",
		
		["Enable maximum records"] = "啟用 最多數量紀錄",
		
		["Enables only storing the last X entered records."] = "啟用 只儲存最後 X筆 輸入的技能紀錄.",
		
		["Maximum saved records"] = "最大存檔紀錄",
		["How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones."] = "一個括弧內儲存多少紀錄, 舉例假如你設定10,每個括弧內只會保留最後10場, 舊場次會被新的覆蓋.",
		
		["Enable week records"] = "啟用 週紀錄",
		["Enables removing records that are over X weeks old."] = "啟用 移除 X週 以前的舊紀錄.",
		["How many weeks to save records"] = "保存多少週的紀錄",
		["Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s"] = "被刪除之前的每週資料, 這是每週競技那天保存的資料.\nTime: %s",
		
		["Enter the talent points spent in each tree for %s from %s."] = "輸入每個天賦樹所花的天賦點數 從 %s 到 %s.",
		
		["Data retention"] = "資料保留",
		["Allows you to set how long data should be saved before being removed."] = "讓你設定資料在移除前能夠保留多久.",
	}
end						