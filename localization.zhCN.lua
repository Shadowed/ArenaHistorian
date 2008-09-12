-- Localized by Chris

if(GetLocale()=="zhCN") then
	ArenaHistLocals = {
		["Arena Historian"] = "竞技场史学家",
		
		["%dvs%d History"] = "%dvs%d 历史",
	  ["Stats"] = "统计",
	
    ["%d Rating (%d Points)"] = "等级 %d (%d点)",

		["Run Time: %s"] = "进行时间：%s",
		["Record: %s/%s"] = "记录数：%s/%s",
		["Zone: %s"] = "场地：%s",
		["%s\nDamage (|cffffffff%s|r)\nHealing (|cffffffff%s|r)"] = "%s\n伤害 (|cffffffff%s|r)\n治疗 (|cffffffff%s|r)",
	  ["%s - %s\nDamage (|cffffffff%s|r)\nHealing (|cffffffff%s|r)"] = "%s - %s\n伤害 (|cffffffff%s|r)\n治疗 (|cffffffff%s|r)",
	  ["Date: %s"] = "日期: %s",
	  ["%s:%s (%.1f%%) (%s)"] = "%s:%s (%.1f%%) (%s)",

		["Unknown"] = "未知",
		["Arena Preparation"] = "竞技场准备",
		["Enemy team name"] = "敌队名称",
		["Enemy player name"] = "敌人名称",
		["Search"] = "搜索……",
		["Min rate"] = "最小等级",
		["Max rate"] = "最大等级",
		
		["Talents"] = "天赋",
  	["Classes"] = "职业",
	  ["Reset filters"] = "重置过滤器",
	
		["%s's shown"] = "%s的显示",
	  ["%s's hidden"] = "%s的隐藏",
	
	  ["OK"] = "确定",
	  
		["Male"] = "男",
		["Female"] = "女",

		["Hold ALT and click the button to delete this arena record."] = "按住Alt键并点击按钮删除这条记录。",
		
		["The Arena battle has begun!"] = "竞技场的战斗开始了!",
		
		["Strict"] = "精确",
	  ["Only show teams with all the selected classes in them."] = "只显示包含有所选职业的战队.",
	
		["Show loses"] = "显示败局",
	  ["Show wins"] = "显示胜局",
	  ["Show draws"] = "显示平局",
		
	-- Syncing
	  ["Deny"] = "拒绝",
  	["%s has requested missing data for %dvs%d, sync data?"] = "%s 正在申请 %dvs%d 的遗漏数据, 是否同步?",
	  ["Data Syncing"] = "数据同步中",
  	["Sync"] = "同步",
	
  	["Waiting for sync to be sent"] = "等待发送同步数据",
	
  	["Timed out, no data received"] = "超时,未接收到数据",
	  ["Timeout: %d seconds"] = "超时: %d 秒",
	  ["Timeout: ----"] = "超时: ----", 
	  
	  ["No new games to sync"] = "没有新比赛同步",
	  ["Player '%s' is not online"] = "玩家 '%s' 不在线",
	  ["Invalid data entered"] = "输入了无效的数据",
	  ["Request sent, waiting for approval"] = "请求已发送, 等待通过",
	  ["Cannot send sync, player isn't on your team"] = "无法同步, 玩家不在你的战队",
	  ["Request accepted, waiting for game list"] = "请求已接受, 等待游戏列表",
  	["Request accepted, sending game list"] = "请求已接受, 发送游戏列表",
	  ["Request denied"] = "请求被拒绝",
  	["Request denied, you are not on the same team"] = "请求被拒绝, 你不在同一战队",
  	["Finished! %d new games received"] = "完成! 接收到 %d 比赛",
  	["Finished! %d new games sent"] = "完成! 发送 %d 比赛",
  	["Sent %d of %d"] = "发送 %d 的 %d",
	  ["Receiving %d of %d"] = "接收 %d 的 %d",
	  ["Waiting for data, %d total games to sync"] = "等待数据, 共同步 %d 场比赛",

	-- This is a simple race -> token map, we don't do vendor checks here
		["TOKENS"] = {
			["HUMAN_FEMALE"] = "人类",
			["DWARF_FEMALE"] = "矮人",
			["GNOME_FEMALE"] = "侏儒",
			["NIGHTELF_FEMALE"] = "暗夜精灵",
			["SCOURGE_FEMALE"] = "亡灵",
			["TROLL_FEMALE"] = "巨魔",
			["ORC_FEMALE"] = "兽人",
			["BLOODELF_FEMALE"] = "血精灵",
			["TAUREN_FEMALE"] = "牛头人",
			["DRAENEI_FEMALE"] = "德莱尼",
		},

		-- Zone -> abbreviation
		["BEA"] = "刀锋山",
		["NA"] = "纳格兰",
		["RoL"] = "洛丹伦",

		-- Arenas
		["Blade's Edge Arena"] = "刀锋山竞技场",
		["Nagrand Arena"] = "纳格兰竞技场",
		["Ruins of Lordaeron"] = "洛丹伦废墟",

		-- Token -> Text
		["HUMAN_FEMALE"] = "人类女性",
		["HUMAN_MALE"] = "人类男性",

		["DWARF_FEMALE"] = "矮人女性",
		["DWARF_MALE"] = "矮人男性",

		["NIGHTELF_FEMALE"] = "暗夜精灵女性",
		["NIGHTELF_MALE"] = "暗夜精灵男性",

		["TROLL_FEMALE"] = "巨魔女性",
		["TROLL_MALE"] = "巨魔男性",

		["BLOODELF_FEMALE"] = "血精灵女性",
		["BLOODELF_MALE"] = "血精灵男性",

		["DRAENEI_FEMALE"] = "德莱尼女性",
		["DRAENEI_MALE"] = "德莱尼男性",

		["GNOME_FEMALE"] = "侏儒女性",
		["GNOME_MALE"] = "侏儒男性",

		["SCOURGE_FEMALE"] = "亡灵女性",
		["SCOURGE_MALE"] = "亡灵男性",

		["ORC_FEMALE"] = "兽人女性",
		["ORC_MALE"] = "兽人男性",

		["TAUREN_FEMALE"] = "牛头人女性",
		["TAUREN_MALE"] = "牛头人男性",

		["WARRIOR"] = "战士",
		["DRUID"] = "德鲁伊",
		["PALADIN"] = "圣骑士",
		["SHAMAN"] = "萨满祭司",
		["WARLOCK"] = "术士",
		["PRIEST"] = "牧师",
		["MAGE"] = "法师",
		["HUNTER"] = "猎人",
		["ROGUE"] = "潜行者",

  	-- Tree names
  	["Elemental"] = "元素",
	  ["Enhancement"] = "增强",
   	["Restoration"] = "恢复",
	  ["Arcane"] = "奥术",
  	["Fire"] = "火焰",
	  ["Frost"] = "冰霜",
	  ["Affliction"] = "痛苦",
  	["Demonology"] = "恶魔",
  	["Destruction"] = "毁灭",
	  ["Balance"] = "平衡",
  	["Feral"] = "野性",
   	["Restoration"] = "恢复",
	  ["Arms"] = "武器",
  	["Fury"] = "狂怒",
  	["Protection"] = "防护",
	  ["Assassination"] = "刺杀",
  	["Combat"] = "战斗",
	  ["Subtlety"] = "敏锐",
	  ["Holy"] = "神圣",
	  ["Protection"] = "防护",
	  ["Retribution"] = "惩戒",
	  ["Beast Mastery"] = "兽王",
  	["Marksmanship"] = "射击",
	  ["Survival"] = "生存",
	  ["Discipline"] = "戒律",
	  ["Holy"] = "神圣",
  	["Shadow"] = "暗影",
	
	
	-- Config
		["ArenaHistorian slash commands"] = "竞技场史学家控制台命令",
		[" - history - Shows the arena history panel"] = " - history - 显示竞技场历史面板",
		[" - config - Opens the OptionHouse configuration panel"] = " - config - 开启OptionHouse控制面板",
		[" - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration."] = " - clean - 强制运行一次检查，将移除所有不符合选项设置的记录。",
		[" - sync - Shows the arena history sync frame"] = " - sync - 显示竞技场史学家同步框体",

		["General"] = "基础选项",
		["Enable talent guessing"] = "启用天赋猜测",
		["Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea."] = "存储敌人在竞技场内使用的法术, 以此猜测他们的天赋, 不是 100% 准确但给了我们个初步的想法.",
		
		["Enable maximum records"] = "启用最大记录",

		["Enables only storing the last X entered records."] = "只保存最后的X条记录。",

		["Maximum saved records"] = "最大保存数量",
		["How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones."] = "你所要保存的记录条目数，举例来说假如你设置为10，那么你将只会保存最新的10条记录，旧记录会被新记录覆盖掉。",

		["Enable week records"] = "启用按星期记录",
		["Enables removing records that are over X weeks old."] = "移除超过X星期的记录。",
		["How many weeks to save records"] = "所要保存的星期数",
		["Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s"] = "在数据被删除前所保存的星期数，从记录被记录时开始算起.\n时间：%s",

		["Enter the talent points spent in each tree for %s from %s."] = "给%2$s的%1$s输入每个天赋树所分配的天赋点。",

	  ["Data retention"] = "保留数据",
	  ["Allows you to set how long data should be saved before being removed."] = "设置数据被移除前所保存的时间.",
	}
end
