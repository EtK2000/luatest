---@type boolean
local isTerminationCaught = false
local rawOsPullEvent = os.pullEvent
local rawOsPullEventRaw = os.pullEventRaw

---@type string
local osName = 'Alb' .. string.char(255) .. 'no'

---Attempts to cast `val` to the type of `typeOf`
---@generic T
---@param val any
---@param typeOf T
---@return T
function os.castToTypeOf(val, typeOf)
	local t, f = type(typeOf), type(val)
	if t == f or val == nil or typeOf == nil then
		return val
	elseif t == 'number' then
		return tonumber(val)
	elseif t == 'string' then
		return tostring(val)
	elseif t == 'boolean' and f == 'string' then
		return string.asBoolean(val)
	else
		error('Could not cast from ' .. type(val) .. ' to ' .. t, 2)
	end
end

---Prevents `terminate` event from terminating the current process
function os.catchTerminate()
	if isTerminationCaught then
		error('Termination is already caught', 2)
	end
	isTerminationCaught = true
	os.pullEvent = rawOsPullEventRaw
end

-- term.clear() already exists
function os.clear()
	term.clear()
	term.setCursorPos(1, 1)
end

---Get the name of the current OS
---@return string
function os.getName()
	return osName
end

---Get the name of the current OS, or -1 if not installed
---@return integer
function os.getVersion()
	local file = fs.open('osData/version.txt', 'r')
	if not file then
		return -1
	end

	local version = tonumber(file.readLine())
	file.close()

	return version or -1
end

function os.loading(color, func) -- func is a function that returns a boolean (that is all), true means stop
	local anim = { '|', '/', '-', '\\' }
	local i = 1;
	local x, y = term.getCursorPos()
	while (func ~= nil and not func()) or true do
		local x1, y1 = term.getCursorPos()
		term.setCursorPos(x, y)

		if color then
			term.writeColored(anim[i], color ~= nil and color or term.getTextColor())
		else
			term.write(anim[i])
		end

		if x1 ~= x and y1 ~= y then
			term.setCursorPos(x1, y1)
		end
		i = i + 1
		if i > 4 then
			i = 1
		end
		sleep(0.1)
	end
end

function os.pause()
	write('Press any key to continue')
	os.pullEvent('key')
end

function os.spinner(color, func)
	local anim = { {
		'   O      ',
		' O      O ',
		'O        O',
		'O        O',
		' O      O ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O        ',
		'O        O',
		'O        O',
		' O      O ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O      O ',
		'O         ',
		'O        O',
		' O      O ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O      O ',
		'O        O',
		'O         ',
		' O      O ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O      O ',
		'O        O',
		'O        O',
		' O        ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O      O ',
		'O        O',
		'O        O',
		' O      O ',
		'   O      '
	}, {
		'   O  O   ',
		' O      O ',
		'O        O',
		'O        O',
		' O      O ',
		'      O   '
	}, {
		'   O  O   ',
		' O      O ',
		'O        O',
		'O        O',
		'        O ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O      O ',
		'O        O',
		'         O',
		' O      O ',
		'   O  O   '
	}, {
		'   O  O   ',
		' O      O ',
		'         O',
		'O        O',
		' O      O ',
		'   O  O   '
	}, {
		'   O  O   ',
		'        O ',
		'O        O',
		'O        O',
		' O      O ',
		'   O  O   '
	}, {
		'      O   ',
		' O      O ',
		'O        O',
		'O        O',
		' O      O ',
		'   O  O   '
	} }
	local frame = 1
	local sw, sh = string.len(anim[1][1]), #anim[1]
	local w, h = term.getSize()
	while true do
		for i = 1, sh do
			term.setCursorPos(math.ceil(w / 2 - sw / 2), math.ceil(h / 2) - sh / 2 + i - 1)
			term.writeColored(anim[frame][i], color ~= nil and color or term.getTextColor())
		end
		frame = frame + 1
		if frame > #anim then
			frame = 1
		end
		sleep(0.075)
	end
end

function os.try(func, ...)
	return pcall(func, ...)
end

---Allows `terminate` event from terminating the current process
function os.uncatchTerminate()
	if not isTerminationCaught then
		error("Termination isn't caught", 2)
	end
	os.pullEvent = rawOsPullEvent
	isTerminationCaught = false
end

---Return the os name and version
---@param installerContext? InstallerContext
function os.version(installerContext)
	if installerContext then
		return os.getName() .. ' ' .. installerContext.version.installer.core .. ' setup'
	end
	return os.getName() .. ' ' .. os.getVersion()
end

---Wait for a `terminate` event
function os.waitForTerminate()
	if not isTerminationCaught then
		error("Termination isn't caught", 2)
	end
	rawOsPullEventRaw('terminate')
end
