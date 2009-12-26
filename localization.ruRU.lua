if( GetLocale() ~= "ruRU" ) then
	return
end


ArenaHistLocals = setmetatable({
	["Arena Historian"] = "Arena Historian",
	["Unknown"] = "Неизвестно",
	
	["%dvs%d History"] = "История %dна%d",
	["Stats"] = "Стат.",
	
	["%d Rating (%d Points)"] = "%d Рейтинг (%d Очков)",
	["%d TR (%d MMR)"] = "%d TR (%d MMR)",
	["%d Points"] = "%d Очков",
	
	["Run Time: %s"] = "Время: %s",
	["Record: %s/%s"] = "Record: %s/%s",
	["Zone: %s"] = "Зона: %s",
	["%s\nDamage (|cffffffff%s|r)\nHealing (|cffffffff%s|r)"] = "%s\nУрон (|cffffffff%s|r)\nИсцеление (|cffffffff%s|r)",
	["%s - %s\nDamage (|cffffffff%s|r)\nHealing (|cffffffff%s|r)"] = "%s - %s\nУрон (|cffffffff%s|r)\nИсцеление (|cffffffff%s|r)",
	["Date: %s"] = "Дата: %s",
	["%s:%s (%.1f%%) (%s)"] = "%s:%s (%.1f%%) (%s)",
	
	["Unknown"] = "Неизвестно",
	["Arena Preparation"] = "Арена - подготовка",
	["Enemy team name"] = "Вражеская команда",
	["Enemy player name"] = "Вражеский игрок",
	["Search"] = "Поиск...",
	["Min rate"] = "Мин. рейт",
	["Max rate"] = "Макс. рейт",
	
	["Talents"] = "Таланты",
	["Classes"] = "Классы",
	["Reset filters"] = "Сброс фильтра",
	
	["%s's shown"] = "Показывать |3-1(%s)",
	["%s's hidden"] = "Скрывать |3-1(%s)",
	
	["OK"] = "OK",
	
	["Male"] = "Муж.",
	["Female"] = "Жен.",
	
	["Hold ALT and click the button to delete this arena record."] = "Чтобы удалить записи этой арены, удерживайте ALT и нажмите кнопку.",

	["The Arena battle has begun!"] = "Битва на Арене началась!",
	
	["Strict"] = "Полный",
	["Only show teams with all the selected classes in them."] = "Показывать только те команды, в которых присутствуют все выбранные классы.",
	
	["Lose"] = "Lose",
	["Win"] = "Win",
	["Draw"] = "Ничья",
	
	-- Syncing
	["Deny"] = "Отвергать",
	["%s has requested missing data for %dvs%d, sync data?"] = "%s запросил недостающии данные из %dна%d, синхронизировать данные?",
	["Data Syncing"] = "Синхр. данных",
	["Sync"] = "Синхр",
	
	["Waiting for sync to be sent"] = "Waiting for sync to be sent",

	["Timed out, no data received"] = "Время ожидание истекло, данных неполучено",
	["Timeout: %d seconds"] = "Простой: %d |4секунда:секунды:секунд;",
	["Timeout: ----"] = "Простой: ----",
	
	["No new games to sync"] = "Нет новых игр для синхр",
	["Player '%s' is not online"] = "Игрок '%s' вышел из игры",
	["Invalid data entered"] = "Invalid data entered",
	["Request sent, waiting for approval"] = "запрос выслан, ожидается утверждение",
	["Cannot send sync, player isn't on your team"] = "Немогу выполнить синхр, игрок не в вашей команде",
	["Request accepted, waiting for game list"] = "Запрос принят, ожидание списка игр",
	["Request accepted, sending game list"] = "Запрос принят, высылается список игр",
	["Request denied"] = "Запрос отвергнут",
	["Request denied, you are not on the same team"] = "Запрос отвергнут, вы в разных командах",
	["Finished! %d new games received"] = "Готово! Получено %d новых игр",
	["Finished! %d new games sent"] = "Готово! Высланно %d новых игр",
	["Sent %d of %d"] = "Высылается %d - %d",
	["Receiving %d of %d"] = "Получение %d - %d",
	["Waiting for data, %d total games to sync"] = "Ожидание данных, всего %d игр для синхр",

	-- This is a simple race -> token map, we don't do gendor checks here
	["TOKENS"] = {
		["HUMAN_FEMALE"] = "Человек",
		["DWARF_FEMALE"] = "Дворф",
		["GNOME_FEMALE"] = "Гном",
		["NIGHTELF_FEMALE"] = "Ночной эльф",
		["SCOURGE_FEMALE"] = "Нежить",
		["TROLL_FEMALE"] = "Тролль",
		["ORC_FEMALE"] = "Орк",
		["BLOODELF_FEMALE"] = "Эльф крови",
		["TAUREN_FEMALE"] = "Таурен",
		["DRAENEI_FEMALE"] = "Дреней",
		
	},
	
	-- Zone -> abbreviation
	["BEA"] = "АОСТ",
	["NA"] = "АНАГ",
	["RoL"] = "РЛОР",
	["DA"] = "АДАЛ",
	["RoV"] = "АДОБ",
	
	-- Arenas
	["Blade's Edge Arena"] = "Арена Острогорья",
	["Nagrand Arena"] = "Арена Награнда",
	["Ruins of Lordaeron"] = "Руины Лордерона",
	["The Ring of Valor"] = "Арена Доблести",
	["Dalaran Arena"] = "Арена Даларана",
	
	-- Token -> Text
	["HUMAN_FEMALE"] = "Человек жен.",
	["HUMAN_MALE"] = "Человек муж.",
	
	["DWARF_FEMALE"] = "Дворф Жен.",
	["DWARF_MALE"] = "Дворф муж.",
	
	["NIGHTELF_FEMALE"] = "Ночной эльф жен.",
	["NIGHTELF_MALE"] = "Ночной эльф муж.",
	
	["TROLL_FEMALE"] = "Тролль жен.",
	["TROLL_MALE"] = "Тролль муж.",
	
	["BLOODELF_FEMALE"] = "Эльф крови жен.",
	["BLOODELF_MALE"] = "Эльф крови муж.",

	["DRAENEI_FEMALE"] = "Дреней жен.",
	["DRAENEI_MALE"] = "Дреней муж.",

	["GNOME_FEMALE"] = "Гном жен.",
	["GNOME_MALE"] = "Гном муж.",

	["SCOURGE_FEMALE"] = "Нежить жен.",
	["SCOURGE_MALE"] = "Нежить муж.",

	["ORC_FEMALE"] = "Орк жен.",
	["ORC_MALE"] = "Орк муж.",

	["TAUREN_FEMALE"] = "Таурен жен.",
	["TAUREN_MALE"] = "Таурен муж.",
	
	["WARRIOR"] = "Воин",
	["DRUID"] = "Друид",
	["PALADIN"] = "Паладин",
	["SHAMAN"] = "Шаман",
	["WARLOCK"] = "Чернокнижник",
	["PRIEST"] = "Жрец",
	["MAGE"] = "Маг",
	["HUNTER"] = "Охотник",
	["ROGUE"] = "Разбойник",
	["DEATHKNIGHT"] = "Рыцарь смерти",
	
	-- Tree names
	["Elemental"] = "Укрощение стихии",
	["Enhancement"] = "Совершенствование",
	["Restoration"] = "Исцеление",
	["Arcane"] = "Тайная магия",
	["Fire"] = "Огонь",
	["Frost"] = "Лед",
	["Affliction"] = "Колдовство",
	["Demonology"] = "Демонология",
	["Destruction"] = "Разрушение",
	["Balance"] = "Баланс",
	["Feral"] = "Сила зверя",
	["Restoration"] = "Исцеление",
	["Arms"] = "Оружие",
	["Fury"] = "Неистовство",
	["Protection"] = "Защита",
	["Assassination"] = "Ликвидация",
	["Combat"] = "Бой",
	["Subtlety"] = "Скрытность",
	["Holy"] = "Свет",
	["Protection"] = "Защита",
	["Retribution"] = "Возмездие",
	["Beast Mastery"] = "Чувство зверя",
	["Marksmanship"] = "Стрельба",
	["Survival"] = "Выживание",
	["Discipline"] = "Послушание",
	["Holy"] = "Свет",
	["Shadow"] = "Тьма",
	["Frost"] = "Лед",
	["Blood"] = "Кровь",
	["Unholy"] = "Нечестивость",
	
	
	-- Config
	["ArenaHistorian slash commands"] = "Команды ArenaHistorian",
	[" - history - Shows the arena history panel"] = " - history - Открывает окно истории",
	[" - config - Opens the OptionHouse configuration panel"] = " - config - Открывает окно настроек OptionHouse",
	[" - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration."] = " - clean - Forces a history check to be ran, will remove anything that doesn't match the options set in the configuration.",
	[" - sync - Shows the arena history sync frame"] = " - sync - Открывает окно синхронизации истории арены",
	
	["General"] = "Основное",
	["Enable talent guessing"] = "Включить расчет талантов",
	["Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea."] = "Запоминает что применяет враг на арене во время сражения, а затем пытается определить их таланты, пологаясь на применённые заклинания, это не на 100% точно, но дает примерное представление спецификации талантов.",
	
	["Enable maximum records"] = "Включить лимит макс. записей",

	["Enables only storing the last X entered records."] = "Включает хранение только последних X записей.",
	
	["Maximum saved records"] = "Макс. сохраняемых записей",
	["How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones."] = "Сколько записей сохранять в каждой категории, например, если вы установите значение 10, это значит, вы будете хранить записи только за последние 10 матчей в каждой категории, устаревшие записи будут затираться оп мере поступления новых.",
	
	["Enable week records"] = "Включить запись по неделе",
	["Enables removing records that are over X weeks old."] = "Включает удаление записей которые старше Х недель.",
	["How many weeks to save records"] = "Сколько недель сохранять записи",
	["Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s"] = "Количество недель хранения данных. По истечению которых, они будут удалены. Начало недели начинается со дня сохранения записи.\nВремя: %s",
	
	["Enter the talent points spent in each tree for %s from %s."] = "Enter the talent points spent in each tree for %s from %s.",
	
	["Data retention"] = "Хранение данных",
	["Allows you to set how long data should be saved before being removed."] = "Позволяет установить, как долго будут храниться данные до их удаления.",
}, {__index = ArenaHistLocals})
