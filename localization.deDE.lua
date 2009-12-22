if( GetLocale() ~= "deDE" ) then
	return
end

ArenaHistLocals = setmetatable({
}, { __index = ArenaHistLocals})