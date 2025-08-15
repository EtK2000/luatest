-- Disable terminate
local pullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

-- Clear the terminal (`os.clear` doesn't exist yet)
term.clear()
term.setCursorPos(1, 1)

-- As of now, we only support colorful devices
if not term.isColor() then
	shell.run('clear')
	print('No color!\nSetup will now exit...')
	sleep(3)
	os.shutdown()
end

-- returns <disk name>/
local function getDiskPath()
	local p = shell.getRunningProgram()
	p = string.sub(p, 1, string.find(p, '/'))
	return p
end

local perm = 0 -- permission level (0: not logged in, 1: guest, 2: user, 3: super)
local displayName
local native = {}

local maxUsername, maxPassword = 10, 10

-- paths
-- 1 ***** User's Renamed File, Named To Be Hidden
local userStartup = '1userStartupURFNTOBH' -- the name given to the renamed 'startup'
local usersFile =
'osData/crd'                               -- the file containing the users' credentials, is would be awesome to encode this
local bin = 'osData/bin'
local cache = getDiskPath() .. 'cache'
local tmp = getDiskPath() .. 'tmp'
shell.setAlias('cls', 'clear')
shell.setAlias('del', 'delete')
shell.setAlias('ren', 'rename')
shell.setAlias('shell', 'cmd')

local REPO_PREFIX = 'https://raw.githubusercontent.com/EtK2000/luatest/master/'
local URL = {
	['core'] = REPO_PREFIX .. 'core.lua',   -- the startup file
	['modules'] = REPO_PREFIX .. 'modules', -- the modules index
	['version'] = REPO_PREFIX .. 'version.txt' -- the current version
}

-- cache
local w, h = term.getSize()
local hasOS = fs.exists('osData/.ver')

-- Download and load utils
local bootstrapUtilsPath = getDiskPath() .. 'utils/bootstrap.lua'
if not fs.exists(bootstrapUtilsPath) then
	print('Downloading utilities...')

	local bootstrapUtilsUrl = REPO_PREFIX .. 'utils/bootstrap.lua'
	local req = http.get(bootstrapUtilsUrl)
	if not req then
		error('Could not reach ' .. bootstrapUtilsUrl)
	end
	local content = req.readAll()
	if not content then
		error('Could not connect to ' .. bootstrapUtilsUrl)
	end

	local file = fs.open(bootstrapUtilsPath, 'w')
	file.write(content)
	file.close()
end
require('utils/bootstrap')
local doPrivileged = bootstrap(REPO_PREFIX, getDiskPath() .. 'utils/')
os.clear()

----------------------
-- Helper functions --
----------------------

local function catchTerminate()
	os.pullEventRaw('terminate')
end

----------------------
--  Auth functions  --
----------------------

-- auth is verified as:
-- USERNAME
-- PASSWORD
-- AUTH_LEVEL
local function doAuth(username, password)
	local file = native.open(usersFile, 'r')
	local line = file.readLine()                       -- read USERNAME
	while line ~= nil do
		if string.lower(username) == string.lower(line) then -- validate USERNAME
			if password == file.readLine() then        -- validate PASSWORD
				local res = file.readLine()            -- return PERM_LEVEL
				file.close()
				displayName = line
				return line .. res -- {USERNAME}{AUTH_LEVEL}
			end
		else
			file.readLine() -- skip PASSWORD
		end
		file.readLine()  -- skip PERM_LEVEL
		line = file.readLine() -- continue to next USERNAME
	end
	file.close()
	return 0
end

-- NOTE: returns the completed, result, can cause errors if opening OS files then trying to modify not as OS
-- NEVER RUN THIS WITHIN parallel.waitForAny WITH OTHER FINITE FUNCTIONS!!! IT MAY CAUSE PERMISSION LEAKS
local function doAsOS(func, ...)
	local p = perm
	perm = 4
	local ok, res = os.try(func, ...)
	perm = p
	return ok, res
end

local function hasPerms(perm_level)
	if perm_level < 1 or perm_level > 3 then
		throw('invalid perm_level, range is 1-3')
	end
	return perm >= perm_level
end

local function createUser(perm_level)
	if not hasPerms(3) then
		error('You are not permitted to create users')
	end
	if perm_level < 1 or perm_level > 3 then
		error('Invalid perm_level, range is 1-3')
	end

	local username
	local password

	while true do
		os.clear()
		write('Username: ')
		username = io.read()
		if username:len() <= maxUsername then
			write('Password: ')
			password = read('*')
			if password:len() <= maxPassword then
				write('Confirm:  ')
				if password == read('*') then
					break
				end
				term.writeColored('Passwords do not match!', colors.red)
			else
				term.writeColored('Passwords is too long! (max: ' .. maxPassword .. ')', colors.red)
			end
		else
			term.writeColored('Username is too long! (max: ' .. maxUsername .. ')', colors.red)
		end
		sleep(2)
	end
	os.clear()
	-- save the user
	fs.makeDir(string.sub(usersFile, 1, string.last(usersFile, '/') - 1))
	local file = fs.open(usersFile, fs.exists(usersFile) and 'a' or 'w')
	file.writeLine(username)
	file.writeLine(password)
	file.writeLine(tostring(perm_level))
	file.close()
end

-----------------------
-- backup  functions --
-----------------------
native.attributes = fs.attributes
native.copy = fs.copy
native.delete = fs.delete
native.isReadOnly = fs.isReadOnly
native.makeDir = fs.makeDir
native.move = fs.move
native.open = fs.open
native.ioLines = io.lines
native.ioOpen = io.open
native.ioOutput = io.output

----------------------
-- define functions --
----------------------

-- ordered pairs
function __genOrderedIndex(t)
	local orderedIndex = {}
	for key in pairs(t) do
		table.insert(orderedIndex, key)
	end
	table.sort(orderedIndex)
	return orderedIndex
end

function orderedNext(t, state)
	-- Equivalent of the next function, but returns the keys in the alphabetic
	-- order. We use a temporary ordered key table that is stored in the
	-- table being iterated.
	key = nil
	if state == nil then
		-- the first time, generate the index
		t.__orderedIndex = __genOrderedIndex(t)
		key = t.__orderedIndex[1]
	else
		-- fetch the next value
		for i = 1, table.getn(t.__orderedIndex) do
			if t.__orderedIndex[i] == state then
				key = t.__orderedIndex[i + 1]
			end
		end
	end

	if key then
		return key, t[key]
	end

	-- no more value to return, cleanup
	t.__orderedIndex = nil
	return
end

-- Equivalent of the pairs() function on tables. Allows to iterate in order
function orderedPairs(t)
	return orderedNext, t, nil
end

-- moves the specified file replacing any existing one
local function privilegedReplace(from, to)
	if shell.getRunningProgram() == getDiskPath() .. 'startup' or shell.getRunningProgram() == (bin .. '/apt-get') then -- a little hack to allow apt-get to update system files
		if native.exists(to) then
			native.delete(to)
		end
		native.move(from, to)
	else
		fs.replace(from, to)
	end
end

-- copies the specified file replacing any existing one
local function privilegedReplaceCopy(from, to)
	if shell.getRunningProgram() == getDiskPath() .. 'startup' then
		if native.exists(to) then
			native.delete(to)
		end
		native.copy(from, to)
	else
		if fs.exists(to) then
			fs.delete(to)
		end
		fs.copy(from, to)
	end
end

local downOS = false
local function downloadOS() -- download OS core
	downOS = true
	local downloaded
	parallel.waitForAny(
		function()
			local res
			downloaded, res = doAsOS(http.download, URL['version'], tmp .. '/ver')
			if not downloaded then
				res = string.sub(res, 8, string.len(res)) -- remove the 'pcall: '
				local f = string.sub(URL['version'], 1, 7) -- get the beginning of the URL
				res = string.sub(res, 1, string.find(res, f) - 1) -- remove the URL
				res = res .. 'update URL!'
				term.writeColored(res, colors.red)
			end
		end,
		function()
			catchTerminate()
			term.writeColored('cancelled', colors.red)
			downloaded = false
		end,
		function()
			os.loading(colors.blue)
		end)

	write('\n')                            -- just to make it look better
	local file = fs.open(tmp .. '/ver', 'r') -- basically doAsOS
	local version = tonumber(file.readLine()) -- only one line
	file.close()
	native.delete(tmp .. '/ver')
	if downloaded then
		if os.getVersion() == 0 then
			local ok, res = doAsOS(http.download, URL['core'], cache .. '/startup.lua') -- download the OS
			if not ok then
				term.writeColored('Failed to download OS!\n', colors.red)
				term.writeColored(res .. '\n', colors.red)
				native.delete(cache)
			else
				ok, res = doAsOS(http.download, URL['native'], cache .. '/native.lua') -- download the OS
				if not ok then
					term.writeColored('Failed to download OS!\n', colors.red)
					term.writeColored(res .. '\n', colors.red)
					native.delete(cache)
				else
					file = native.open(cache .. '/ver', 'w')
					file.write('[core]=' .. tostring(version))
					file.close()
				end
			end
		elseif version > os.getVersion() then
			term.writeColored('A new version (' .. version .. ') is available!\n', colors.yellow)
			term.writeColored('Update [Y/n]? ', colors.cyan)
			local c = term.getTextColor()
			term.setTextColor(colors.orange)
			local a = term.YN()
			term.setTextColor(c)
			if a then
				local ok, res = doAsOS(http.download, URL['core'], cache .. '/startup.lua') -- download the OS
				if not ok then
					term.writeColored('Failed to download OS!\n', colors.red)
					term.writeColored(res .. '\n', colors.red)
				end
			end
		else
			term.writeColored('OS is up to date!\n', colors.green)
		end
	end
	downOS = false
end

local moduleNames, modules = { 'add-apt-repository', 'apt-get', 'cmd', 'config', 'explorer', 'su', 'sudo' }, {}
local function downloadModule(moduleName)
	local url = modules['|base']:gsub('%$name', moduleName)
	local downloaded
	parallel.waitForAny(
		function()
			local res
			downloaded, res = doAsOS(http.download, url, cache .. '/' .. moduleName)
			if not downloaded then
				res = string.sub(res, 8, string.len(res)) -- remove the 'pcall: '
				local f = string.sub(url, 1, 7)       -- get the beginning of the URL
				res = string.sub(res, 1, string.find(res, f) - 1) -- remove the URL
				res = res .. 'update URL!' .. url .. '\n'
				term.writeColored(res, colors.red)
			else
				local arr = {}
				local found = false
				local p = perm
				perm = 4 -- doAsOS for io.lines
				for line in io.lines(cache .. '/ver') do
					if string.starts(line, '[' .. moduleName .. ']=') then
						table.insert(arr, '[' .. moduleName .. ']=' .. modules[moduleName]['ver']);
						found = true
					else
						table.insert(arr, line);
					end
				end
				perm = p
				if not found then -- newly installed
					table.insert(arr, '[' .. moduleName .. ']=' .. modules[moduleName]['ver']);
				end

				file = native.open(cache .. '/ver', 'w')
				for k, v in pairs(arr) do
					file.writeLine(v)
				end
				file.close()
			end
		end,
		function()
			catchTerminate()
			term.writeColored('cancelled', colors.red)
			downloaded = false
		end,
		function()
			os.loading(colors.blue)
		end)
end

local function removeModule(moduleName)
	local arr = {}
	local p = perm
	native.delete(cache .. '/' .. moduleName)
	perm = 4 -- doAsOS for io.lines
	for line in io.lines(cache .. '/ver') do
		if not string.starts(line, '[' .. moduleName .. ']=') then
			table.insert(arr, line);
		end
	end
	perm = p

	file = native.open(cache .. '/ver', 'w')
	for k, v in pairs(arr) do
		file.writeLine(v)
	end
	file.close()
end

local function getModules()
	local downloaded
	parallel.waitForAny(
		function()
			local res
			downloaded, res = os.try(http.download, URL['modules'], tmp .. '/mod')
			if not downloaded then
				res = string.sub(res, 8, string.len(res)) -- remove the 'pcall: '
				local f = string.sub(URL['modules'], 1, 7) -- get the beginning of the URL
				res = string.sub(res, 1, string.find(res, f) - 1) -- remove the URL
				res = res .. 'update URL!'
				term.writeColored(res, colors.red)
			end
		end,
		function()
			catchTerminate()
			term.writeColored('cancelled', colors.red)
			downloaded = false
		end,
		function()
			os.loading(colors.blue)
		end)

	-- apt-get update
	local file = fs.open(tmp .. '/_m', 'w')
	local fine, base, form = true
	for line in io.lines(tmp .. '/mod') do
		if not string.starts(line, '#') then -- ignore comments
			if fine then
				if string.starts(line, '[basepath]=') then
					base = string.sub(line, 12, string.len(line))
					file.write(base .. '\n')
				elseif string.starts(line, '[format]=') then
					form = string.explode(string.sub(line, 10, string.len(line)), ',')
					for i = 1, #form do
						if not fine or not string.starts(form[i], '$') then
							fine = false
						else
							form[i] = string.sub(form[i], 2, string.len(form[i]))
						end
					end
				else
					if base and form then
						local mod = string.explode(line, ',')
						for i = #mod, 1, -1 do
							mod[form[i]] = mod[i]
							table.remove(mod, i)
						end
						if table.contains(moduleNames, mod['name']) then
							file.write('\t' .. mod['name'] .. '\n')
							for k, v in pairs(mod) do
								if k ~= 'name' then
									file.write('\t\t' .. k .. '=' .. v .. '\n')
								end
							end
						end
					else
						fine = false
					end
				end
			end
		end
	end
	file.close()
	fs.delete(tmp .. '/mod')

	local repo, curM = {}
	for line in io.lines(tmp .. '/_m') do
		if string.starts(line, '\t\t') then
			local v = string.explode(string.sub(line, 3, string.len(line)), '=') -- should only produce string[2]
			repo[curM][v[1]] = v[2]
		elseif string.starts(line, '\t') then                           -- found a module definition
			curM = string.sub(line, 2, string.len(line))
			repo[curM] = {}
		else
			repo['|base'] = string.sub(line, 1, string.len(line))
		end
	end
	modules = repo
	for k, v in pairs(repo) do
		if v['req'] == '1' and not fs.exists(cache .. '/' .. k) then
			os.clear()
			downloadModule(k)
		end
	end
	os.clear()
end

function os.getVersion()
	if not native.exists(cache .. '/ver') then
		if downOS then
			return 0
		end
		downloadOS()
	end
	local r
	while not r do
		local p = perm
		perm = 4 -- doAsOS for io.lines
		for line in io.lines(cache .. '/ver') do
			if string.starts(line, '[core]=') then
				r = tonumber(string.sub(line, 8, string.len(line)))
			end
		end
		perm = p
		if not r then -- corrupted data, re-download the OS core
			downloadOS()
		end
	end
	return r
end

function os.version()
	return os.getName() .. ' ' .. os.getVersion() .. ' setup'
end

function doLogin()
	if not native.exists(usersFile) then -- no users, create one
		term.writeColored('Please create an account', colors.green)
		sleep(2)
		perm = 3 -- allow user creation
		createUser(3) -- create an admin
		perm = 0
	else
		while perm < 3 do -- while not loggedin, try to login
			os.clear()
			term.writeColored('A user exists, Please login!\n', colors.green)
			write('Username: ')
			username = io.read()
			write('Password: ')
			local password = read('*')
			perm = doAuth(username, password)
			if perm ~= 0 then
				username = string.sub(perm, 1, string.len(perm) - 1)
				perm = tonumber(string.sub(perm, string.len(perm) - 1, string.len(perm)))
				if perm == 3 then
					term.writeColored('Login successful!\n', colors.green)
					os.getPermLevel = function()
						return perm
					end
					os.getUsername = function()
						return username
					end
				else
					term.writeColored('Admin required!\n', colors.red)
				end
			else
				term.writeColored('Login failure!\n', colors.red)
			end
			sleep(1)
		end
	end
	os.clear()
end

function configure()
	getModules()
	local vers = {}
	for k, v in pairs(moduleNames) do
		vers[v] = false
	end

	local p = perm
	perm = 4 -- doAsOS for io.lines
	for line in io.lines(cache .. '/ver') do
		for k, v in pairs(vers) do
			if not v and string.starts(line, '[' .. k .. ']=') and fs.exists(cache .. '/' .. k) then
				vers[k] = tonumber(string.sub(line, 4 + string.len(k), string.len(line)))
			end
		end
	end
	perm = p

	lastColor = term.getBackgroundColor()
	term.setCursorPos(1, 1)
	term.writeColored('core', colors.green)
	term.writeCentered('' .. os.getVersion())
	term.setCursorPos(w - 9, 1)
	term.setBackgroundColor(colors.blue)
	write('redownload')
	term.setBackgroundColor(lastColor)
	term.setCursorPos(1, 2)
	term.writeColored('modules:', colors.cyan)
	for i, v in ipairs(moduleNames) do
		term.setCursorPos(4, 2 + i)
		term.writeColored(v, vers[v] and colors.green or colors.red)
		if vers[v] then
			term.writeCentered(vers[v])
		end
		term.setBackgroundColor(vers[v] and (modules[v]['req'] == '1' and colors.blue or colors.red) or colors.green)
		term.setCursorPos(w - 9, 2 + i)
		write(vers[v] and (modules[v]['req'] == '1' and 'redownload' or '  remove  ') or ' download ')
		term.setBackgroundColor(lastColor)
	end
	term.setCursorPos(w, h)
	term.writeColored('x', colors.red)

	-- wait for input
	parallel.waitForAny(
		function()
			local event, button, xPos, yPos = pullEvent('mouse_click')
			while yPos ~= h or xPos ~= w do
				-- do some calculations
				if yPos == 1 and xPos >= w - 9 then
					os.clear()
					downloadOS()
					sleep(2)
					os.clear()
					configure()
					break
				elseif yPos > 2 and yPos <= 2 + table.size(vers) and xPos >= w - 9 then
					local i, m = 1
					for k, v in orderedPairs(vers) do
						if i == (yPos - 2) then
							m = k
						end
						i = i + 1
					end
					os.clear()
					if not vers[m] or modules[m]['req'] == '1' then
						write('downloading...')
						downloadModule(m)
					else
						removeModule(m)
					end
					os.clear()
					configure()
					break
				end
				event, button, xPos, yPos = pullEvent('mouse_click')
			end
		end)
end

----------------------
-- Main entry point --
----------------------
term.setTextColor(colors.white)

-- no OS cached, download is required
while not fs.exists(cache) do
	term.writeColored('No OS found on disk!\n', colors.red)
	term.writeColored('Downloading...', colors.orange)
	downloadOS()
	getModules()
end

-- show UI
local ok, res = os.try(
	function()
		while true do
			os.clear()
			if w > 22 then
				local width = math.floor(w / 2 - 2)
				local lastColor = term.getBackgroundColor()
				for i = 1, 10 do
					term.setBackgroundColor(colors.red)
					term.setCursorPos(3, math.ceil(h / 2 - 6 + i))
					for j = 1, width do
						if i == 5 and j >= math.ceil(width / 2 - 3) and j < math.ceil(width / 2 - 3) + 7 then
							write(string.sub('Install', j - 2 - width / 2 - 3, j - 2 - width / 2 - 3))
						else
							write(' ')
						end
					end
					term.setCursorPos(width + 4, math.ceil(h / 2 - 6 + i))
					for j = 1, width do
						if i == 1 or i == 10 or j == 1 or j == width then
							term.setBackgroundColor(colors.blue)
						else
							term.setBackgroundColor(colors.cyan)
						end
						if i == 5 and j >= math.ceil(width / 2 - 4) and j < math.ceil(width / 2 - 3) + 8 then
							write(string.sub('Configure', j - 2 - width / 2 - 4, j - 2 - width / 2 - 4))
						else
							write(' ')
						end
					end
				end
				if fs.exists(cache .. '/cmd') then
					term.setCursorPos(1, h)
					term.setBackgroundColor(colors.brown)
					write('cmd')
				end
				term.setBackgroundColor(lastColor)
				term.setCursorPos(w, h)
				lastColor = term.getTextColor()
				term.setTextColor(colors.red)
				write('x')
				term.setTextColor(lastColor)

				-- wait for input
				parallel.waitForAny(
					function()
						local event, button, xPos, yPos = pullEvent('mouse_click')
						if yPos > math.ceil(h / 2 - 6) and yPos <= (math.ceil(h / 2 - 6) + 10) then
							if xPos > 2 and xPos <= (2 + width) then -- Install clicked
								os.clear()
								term.writeColored('Install [Y/n]? ', colors.orange)
								if term.YN() then
									doLogin()
									local done = false
									parallel.waitForAny(
										function()
											os.spinner(colors.cyan, function() return done end)
										end,
										function()
											if not hasOS and fs.exists('startup') --[[ and not fs.exists(userStartup) ]] then
												fs.move('startup', userStartup)
											end

											-- install required packages
											fs.replaceCopy(cache .. '/startup', 'startup')
											fs.replaceCopy(cache .. '/native', 'osData/native')
											fs.replaceCopy(cache .. '/add-apt-repository',
												'osData/bin/add-apt-repository')
											fs.replaceCopy(cache .. '/apt-get', 'osData/bin/apt-get')
											fs.replaceCopy(cache .. '/cmd', 'osData/bin/cmd')
											fs.replaceCopy(cache .. '/config', 'osData/bin/config')

											-- install optional packages
											if fs.exists(cache .. '/explorer') then
												fs.replaceCopy(cache .. '/explorer', 'osData/bin/explorer')
											end
											if fs.exists(cache .. '/su') then
												fs.replaceCopy(cache .. '/su', 'osData/bin/su')
											end
											if fs.exists(cache .. '/sudo') then
												fs.replaceCopy(cache .. '/sudo', 'osData/bin/sudo')
											end

											-- write current version
											file = native.open('osData/.ver', 'w')
											file.write(os.getVersion())
											file.close()

											-- set the versions of the installed packages in the progs
											file = native.open('osData/cfg/progs', 'w')
											-- get the module path
											for line in io.lines(tmp .. '/_m') do
												if not string.starts(line, '#') and not string.starts(line, '\t') then
													file.write(line .. '\n')
													break
												end
											end
											-- get the installed programs
											for line in io.lines(cache .. '/ver') do
												if not string.starts(line, '[core]') then
													local i = string.find(line, '%]')
													file.write('\t' .. string.sub(line, 1, i - 1) .. '\n')
													file.write('\t\t' .. string.sub(line, i + 1) .. '\n')
													break
												end
											end
											file.close()

											hasOS = true
											done = true
										end)
								else
									term.writeColored('Cancelled...\n', colors.red)
								end
								sleep(1)
							elseif xPos > (3 + width) and xPos < (w - 1) then
								os.clear()
								configure()
							end
						elseif yPos == h and xPos < 4 and fs.exists(cache .. '/cmd') then
							os.clear()
							parallel.waitForAny(catchTerminate,
								function()
									shell.run(cache .. '/cmd')
									-- TODO: fix cmd crashing after entering command
								end)
							term.setCursorBlink(false)
						elseif yPos == h and xPos == w then
							os.queueEvent('terminate')
						end
					end)
			else
			end
		end
	end)
if not ok then
	if res == 'Terminated' then
		os.clear()
		term.writeColored('Bye bye!\n', colors.yellow)
	else
		term.writeColored(res .. '\n', colors.red)
	end
	os.pause()
	os.shutdown()
end
