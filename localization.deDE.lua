if( GetLocale() ~= "deDE" ) then
	return
end

ArenaHistLocal = setmetatable({
}, { __index = ArenaHistLocal })