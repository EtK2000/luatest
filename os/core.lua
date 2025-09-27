-- disable terminate
local pullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

local perm = 0 -- permission level (0: not logged in, 1: guest, 2: user, 3: super)
local displayName
local hiddenFiles = { 'startup' } -- files hidden by OS
local hiddenFolders = { 'osData' } -- folders hidden by OS, child folders AREN'T hidden (for access to osDir['bin'] and osDir['cfg'])
local native = {}
local loading = true

function os.isLoading()
	return loading
end

local maxUsername, maxPassword = 10, 10

-- paths
-- 1 ***** User's Renamed File, Named To Be Hidden
local userStartup = '1userStartupURFNTOBH' -- the name given to the renamed 'startup'
local usersFile = 'osData/crd' -- the file containing the users' credentials, is would be awesome to encode this

----------------------
-- load native junk --
----------------------

os.loadAPI('osData/native')

osDir = os.readOnly({
	['bin'] = 'osData/bin', -- the os src dir
	['cfg'] = 'osData/cfg', -- the config dir
	['init'] = 'osData/init.d', -- the init dir
	['tmp'] = 'osData/tmp' -- the tmp dir
})

----------------------
--   shell  setup   --
----------------------

function os.completeDir(shell, nIndex, sText, tPreviousText)
    if nIndex == 1 then
        return fs.complete(sText, shell.dir(), false, true)
    end
end

for i, v in ipairs(fs.list(osDir['init'])) do
	print('running ' .. v)
	shell.run('osData/init.d/' .. v)
end

os.pause()

shell.run(osDir['bin'] .. '/cmd', 'nil')
shell.setPath(shell.path() .. ':/' .. osDir['bin'])
shell.setAlias('cls', 'clear')
shell.setAlias('shell', 'cmd')
shell.setAlias('del', 'delete')
shell.setAlias('ren', 'rename')

local repoPrefix = 'https://raw.githubusercontent.com/EtK2000/Alb-no-OS/master/'
local URL = os.readOnly({
	['core'] = repoPrefix .. 'core', -- the startup file
	['modules'] = repoPrefix .. 'modules', -- the modules index
	['version'] = repoPrefix .. 'version' -- the current version
})

-- structures
local periph = {}
periph.__index = periph

function periph.get(self)
	return self.p
end

function periph.getType(self)
	return self.t
end

local function NewPeripheral(type, peripheral)
    local obj = { t = type, p = peripheral }
    return setmetatable( obj, periph )
end

-- cache
local w, h = term.getSize()
local sides = { 'back', 'bottom', 'front', 'left', 'right', 'top' }
local peri = {}

-- config
local config = {
	['animate'] = true, -- do animations? (only available on colored computers)
	['desktop'] = colors.yellow, -- desktop color (only available on colored computers)
	['require_pass'] = true, -- request password for admin actions? (if logged in as admin)
	['update'] = true -- check for updates?
}

function os.getConfig(K)
	if type(K) ~= 'string' then
		error('Expected string', 2)
	end
	return config[K]
end

function os.setConfig(K, V)
	if perm < 3 then
		error('Access denied!', 2)
	elseif type(K) ~= 'string' then
		error('Config keys are strings!', 2)
	end
	if string.lower(K) == 'animate' then
		if type(V) == 'boolean' then
			config['animate'] = V
		else
			error('Animate is a boolean!', 2)
		end
	elseif string.lower(K) == 'desktop' then
		if type(V) == 'number' then
			config['desktop'] = V
		else
			error('Color is a number!', 2)
		end
	elseif string.lower(K) == 'require_pass' then
		if type(V) == 'boolean' then
			config['require_pass'] = V
		else
			error('Require_pass is a boolean!', 2)
		end
	elseif string.lower(K) == 'update' then
		if type(V) == 'boolean' then
			config['update'] = V
		else
			error('Update is a boolean!', 2)
		end
	end
	-- you only get here if no errors accord
	local file = native.open(osDir['cfg'] .. '/cfg', 'w')
	for k,v in pairs(config) do
		file.write(k .. '=' .. tostring(v) .. '\n')
	end
	file.close()
end

----------------------
-- Auth's functions --
----------------------

-- auth is verified as:
-- USERNAME
-- PASSWORD
-- AUTH_LEVEL
local function doAuth(username, password)
	local file = native.open(usersFile, 'r')
	local line = file.readLine() -- read USERNAME
	while line ~= nil do
		if string.lower(username) == string.lower(line) then -- validate USERNAME
			if password == file.readLine() then -- validate PASSWORD
				local res = file.readLine() -- return PERM_LEVEL
				file.close()
				displayName = line
				return line .. res -- {USERNAME}{AUTH_LEVEL}
			end
		else
			file.readLine() -- skip PASSWORD
		end
		file.readLine() -- skip PERM_LEVEL
		line = file.readLine() -- continue to next USERNAME
	end
	file.close()
	return 0
end

-- NOTE: returns the completed, result, can cause errors if opening OS files then os.trying to modify not as OS
-- NEVER RUN THIS WITHIN parallel.waitForAny WITH OTHER FINITE FUNCTIONS!!! IT MAY CAUSE PERMISSION LEAKS 
local function doAsOS(func, ...)
	local p = perm
	perm = 4
	local ok, res = os.try(func, ...)
	perm = p
	return ok, res
end

local asAdmin = false -- did we already ask for escalation within a parent function?
function os.doAsAdmin(func, ...)
	local ok, res
	if asAdmin then
		ok, res = os.try(func, ...)
	elseif perm == 3 then
		if config['require_pass'] then
			for i=1, 3 do -- do login, and if you fail thrice error
				write('Password: ')
				if doAuth(username, read('*')) == 0 then
					if i == 3 then
						error('Auth failed!', 2)
					end
				else
					break
				end
			end
		end
		asAdmin = true
		ok, res = os.try(func, ...)
		asAdmin = false
	else
		-- make the user login with an admin (temporarily)
		local p = perm
		for i=1, 3 do -- do login, and if you fail thrice error
			write('Username: ')
			local u = read()
			write('Password: ')
			if doAuth(u, read('*')) < 3 then
				if i == 3 then
					error('Auth failed!', 2)
				end
			else
				break
			end
		end
		asAdmin = true
		ok, res = os.try(func, ...)
		asAdmin = false
		perm = p
	end
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
	local file = native.open(usersFile, fs.exists(usersFile) and 'a' or 'w')
	file.writeLine(username)
	file.writeLine(password)
	file.writeLine(tostring(perm_level))
	file.close()
end

local function isHidden(path)
	for i=1, #hiddenFiles do
		if string.lower(path) == string.lower(hiddenFiles[i]) then
			return true
		end
	end
	for i=1, #hiddenFolders do
		if string.lower(path) == string.lower(hiddenFolders[i]) then
			return true
		elseif string.starts(string.lower(path), string.lower(hiddenFolders[i]) .. '/') and not string.find(string.lower(path), '/', string.len(hiddenFolders[i]) + 3) and not native.isDir(path) then
			return true
		end
	end
	return false
end

local function removeHiddenFromList(list)
	for i=#list, 1, -1  do
		for j=1, #hiddenFiles do
			if type(list[i]) == 'string' then
				if string.lower(list[i]) == string.lower(hiddenFiles[j]) then
					table.remove(list, i)
				end
			end
		end
		for j=1, #hiddenFolders do
			if type(list[i]) == 'string' then
				if string.lower(list[i]) == string.lower(hiddenFolders[j]) then
					table.remove(list, i)
				end
			end
		end
	end
end

-----------------------
-- change functions --
-----------------------

native.find = fs.find
local function oFind(path)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return {}
	end
	local list = native.find(path)
	removeHiddenFromList(list)
	for i=1, #list do
		if list[i] == userStartup then
			list[i] = 'startup'
		end
	end
	return list
end
fs.find = oFind

native.list = fs.list
local function oList(path)
	if not fs.isDir(path) then
		term.writeColored('Directory doesn't exist!\n', colors.red)
		return {}
	end
	local list = native.list(path)
	removeHiddenFromList(list)
	for i=1, #list do
		if list[i] == userStartup then
			list[i] = 'startup'
		end
	end
	return list
end
fs.list = oList
 
native.exists = fs.exists
local function oExists(path)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	end
	return native.exists(path)
end
fs.exists = oExists
 
native.ioOpen = io.open
local function oIoOpen(path, mode)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	elseif string.starts(string.lower(path), string.lower(osDir['cfg']) .. '/') or string.starts(string.lower(path), string.lower(osDir['tmp']) .. '/') then 
		if perm < 3 then
			error('Access Denied!', 2)
		end
	elseif (mode == 'a' or mode == 'w') and fs.isReadOnly(path) then
		term.writeColored('Cannot open a read-only file for writing!\n', colors.red)
		return
	end
	return native.ioOpen(path)
end
io.open = oIoOpen
 
native.makeDir = fs.makeDir
local function oMakeDir(path)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	end
	return native.makeDir(path)
end
fs.makeDir = oMakeDir
 
native.delete = fs.delete
local function oDelete(path)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	elseif string.starts(string.lower(path), string.lower(osDir['tmp']) .. '/') then 
		if perm < 3 then
			error('Access Denied!', 2)
		end
	elseif fs.isReadOnly(path) and shell.getRunningProgram() ~= (osDir['bin'] .. '/apt-get') then -- a little hack to allow apt-get to update system files
		term.writeColored('Cannot delete read-only files!\n', colors.red)
		return
	end
	native.delete(path)
end
fs.delete = oDelete
 
native.open = fs.open
local function oOpen(path, mode)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	elseif string.starts(string.lower(path), string.lower(osDir['cfg']) .. '/') or string.starts(string.lower(path), string.lower(osDir['tmp']) .. '/') then
		if perm < 3 then
			error('Access Denied!', 2)
		end
	elseif (mode == 'a' or mode == 'w') and fs.isReadOnly(path) then
		term.writeColored('Cannot open a read-only file for writing!\n', colors.red)
		return
	end
	return native.open(path, mode)
end
fs.open = oOpen
 
 -- moves the specified file replacing any existing one
function fs.replace(from, to)
	if shell.getRunningProgram() == (osDir['bin'] .. '/apt-get') then -- a little hack to allow apt-get to update system files
		if native.exists(to) then
			native.delete(to)
		end
		native.move(from, to)
	else
		if fs.exists(to) then
			fs.delete(to)
		end
		fs.move(from, to)
	end
 end
 
native.isReadOnly = fs.isReadOnly
local function oIsReadOnly(path)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	elseif string.starts(string.lower(path), osDir['tmp'] .. '/') then
		return (not perm == 4)
	else
		for i=1, #hiddenFolders do
			if string.starts(string.lower(path), string.lower(hiddenFolders[i]) .. '/') then
				return true
			end
		end
	end
	return native.isReadOnly(path)
end
fs.isReadOnly = oIsReadOnly
 
native.getSize = fs.getSize
local function oGetSize(path)
	if string.lower(path) == 'startup' then
		path = userStartup
	end
	if isHidden(path) == true then
		return
	end
	return native.getSize(path)
end
fs.getSize = oGetSize
 
native.move = fs.move
local function oMove(fromPath, toPath)
	if string.lower(fromPath) == 'startup' then
		fromPath = userStartup
	end
	if string.lower(toPath) == 'startup' then
		toPath = userStartup
	end
	if isHidden(fromPath) == true or isHidden(toPath) == true then
		return
	end
	return native.move(fromPath, toPath)
end
fs.move = oMove
 
native.copy = fs.copy
local function oCopy(fromPath, toPath)
	if string.lower(fromPath) == 'startup' then
		fromPath = userStartup
	end
	if string.lower(toPath) == 'startup' then
		toPath = userStartup
	end
	if isHidden(fromPath) == true or isHidden(toPath) == true then
		return
	end
	return native.copy(fromPath, toPath)
end
fs.copy = oCopy

native.isDir = fs.isDir
local function oIsDir(path)
	if isHidden(path) == true then
		return false
	end
	return native.isDir(path)
end
fs.isDir = oIsDir

function os.getName()
	return 'Albyno'
end

function os.getVersion()
	return 0.11
end

function os.version()
	return os.getName() .. ' ' .. tostring(os.getVersion())
end

----------------------
-- define functions --
----------------------

local function catchTerminate()
	os.pullEventRaw('terminate')
end

local function cacheHardware()
	for i=1, #sides do
		if peripheral.isPresent(sides[i]) then
			print('found a ', peripheral.getType(sides[i]), ' at ', sides[i])
			peri[sides[i]] = NewPeripheral(peripheral.getType(sides[i]), peripheral.wrap(sides[i]))
			print('-- ', peri[sides[i]]:getType())
		end
	end
end

-- windows
local startMenuOpen = false

local function closeStartMenu()
	if not startMenuOpen or not config['animate'] then
		startMenuOpen = false
		return
	end
	local c = term.getBackgroundColor()
	term.setBackgroundColor(config['desktop'])
	for i=math.max(math.ceil(h / 2), 8), (h - 1) do
		term.setCursorPos(1, i)
		for j=1, math.floor(w / 3) do
			write(' ')
		end
		sleep(0.025)
	end
	term.setBackgroundColor(c)
	startMenuOpen = false
end

local function drawStartMenu(opening)
	if not startMenuOpen and not opening then
		return
	end
	local lastColor = term.getBackgroundColor()
	term.setBackgroundColor(colors.blue)
	for i=(h - 1), math.max(math.ceil(h / 2), 8), -1 do
		term.setCursorPos(1, i)
		for j=1, math.floor(w / 3) do
			if i == (h - 1) and j == math.floor(w / 3) then -- logout (bottom row)
				local fg = term.getTextColor()
				term.setBackgroundColor(colors.red)
				term.setTextColor(colors.black)
				write('x')
				term.setBackgroundColor(colors.blue)
				term.setTextColor(fg)
			elseif i == (h - 4) and j > (math.floor(w / 3) - 8) and shell.resolveProgram('explorer') then
				term.writeColored(string.sub('computer', j - math.floor(w / 3) - 1, j - math.floor(w / 3) - 1), colors.black, colors.blue)
			elseif i == (h - 3) and j > (math.floor(w / 3) - 3) then
				term.writeColored(string.sub('cmd', j - math.floor(w / 3) - 1, j - math.floor(w / 3) - 1), colors.black, colors.blue)
			elseif i == math.max(math.ceil(h / 2), 8) then -- username (top row)
				if j <= string.len(username) then
					term.writeColored(string.sub(username, j, j), colors.gray, colors.lightBlue)
				else
					term.writeColored(' ', colors.gray, colors.lightBlue)
				end
			else
				write(' ')
			end
		end
		if opening ~= nil and opening and config['animate'] then
			sleep(0.025)
		end
	end
	term.setBackgroundColor(lastColor)
	startMenuOpen = true
end

local function toggleStartMenu()
	if startMenuOpen then
		closeStartMenu()
	else
		drawStartMenu(true)
	end
end

-- input

local run = ''

local function call()
	if run ~= '' then
		os.clear()
		local r = run -- don't run twice
		run = ''
		shell.run(r)
	end
end

local err = ''
local function callWrapper()
	local ok, val = os.try(call)
	if not ok then
		err = val
	end
end

local doLogin -- needs to be defined here for user switching

local function acceptKeyboardInput()
	local event, scancode = pullEvent('key')
	-- buttons: { left, right, mid }, pocket computer is 26x20
	if scancode == 219 or scancode == 220 or scancode == 56 then
		toggleStartMenu()
	end
end

local function acceptMouseInput()
	local event, button, xPos, yPos = pullEvent('mouse_click')
	-- buttons: { left, right, mid }, pocket computer is 26x20
	if yPos == h and xPos < 4 then
		toggleStartMenu()
	elseif startMenuOpen then
		if yPos == (h - 1) and xPos == math.floor(w / 3) then -- clicked the shutdown
			if button == 1 then
				os.shutdown()
			elseif button == 2 then
				os.reboot()
			else
				doLogin() -- logout
			end
		elseif yPos == (h - 3) and xPos > (math.floor(w / 3) - 3) and xPos <= (math.floor(w / 3)) then
			run = 'cmd'
		elseif shell.resolveProgram('explorer') and yPos == (h - 4) and xPos > (math.floor(w / 3) - 8) and xPos <= (math.floor(w / 3)) then
			run = 'explorer'
		end
	else
		print('Mouse button clicked: ', button, ' => Click Position X: ', xPos, ' => Click Position Y: ', yPos)
	end
end

----------------------
-- Main entry point --
----------------------
os.clear() -- start clean
loading = false

-- load the config
if fs.exists(osDir['cfg'] .. '/cfg') then -- before native replaces default
	doAsOS(function()
			for line in io.lines(osDir['cfg'] .. '/cfg') do
				for k,v in pairs(config) do
					if string.starts(line, k .. '=') then
						config[k] = os.castToTypeOf(string.sub(line, string.len(k) + 2, string.len(line)), v)
					end
				end
			end
		end)
end

-- load hardware into cache
-- cacheHardware() this is a WIP function

-- make sure the sources file exist (apt-get)
if not native.exists(osDir['cfg'] .. '/sources') then
	local file = native.open(osDir['cfg'] .. '/sources', 'w')
	file.write(URL['modules'] .. '\n')
	file.close()
end

-- make the user login TODO: fix logout issues
function doLogin()
	if native.os then -- a different user is logged in
		os = native.os
		perm = 0
	end
	if not native.exists(usersFile) then -- no users, create one
		term.writeColored('Please create an account', colors.green)
		sleep(2)
		perm = 3 -- allow user creation
		createUser(3) -- create an admin
		perm = 0
	end
	while perm == 0 do -- while not loggedin, os.try to login
		os.clear()
		term.writeColored('Please login\n', colors.green)
		write('Username: ')
		username = io.read()
		write('Password: ')
		local password = read('*')
		perm = doAuth(username, password)
		if perm ~= 0 then
			username = string.sub(perm, 1, string.len(perm) - 1)
			perm = tonumber(string.sub(perm, string.len(perm) - 1, string.len(perm)))
			term.writeColored('Login successful!\n', colors.green)
			os.getPermLevel = function()
					return perm
				end
			os.getUsername = function()
					return username
				end
		else
			term.writeColored('Login failure!', colors.red)
		end
		sleep(1)
	end
	os.clear()
	-- we have finished initializing, finalize everything!
	native.os = os
	os = os.readOnly(os)
end
doLogin()

if config['update'] and perm == 3 then
	-- check for updates
	term.writeColored('Checking for updates...', colors.cyan)
	local downloaded
	parallel.waitForAny(
		function()
			local res
			downloaded, res = doAsOS(http.download, URL['version'], osDir['tmp'] .. '/ver')
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
			term.writeColored('canceled', colors.red)
			downloaded = false
		end,
		function()
			os.loading(colors.blue)
		end
	)
	write('\n') -- just to make it look better
	if downloaded then
		local file = native.open(osDir['tmp'] .. '/ver', 'r') -- basically doAsOS
		local version = file.readLine() -- only one line
		file.close()
		native.delete(osDir['tmp'] .. '/ver') -- delete the temporary file
		if tonumber(version) > os.getVersion() then
			term.writeColored('A new version (' .. version .. ') is available!\n', colors.yellow)
			term.writeColored('Update [Y/n]? ', colors.cyan)
			local c = term.getTextColor()
			term.setTextColor(colors.orange)
			local a = term.YN()
			term.setTextColor(c)
			if a then
				local us = userStartup
				userStartup = 'startup' -- allow overriding the startup file
				doAsOS(http.download, URL['core'], 'startup')
				userStartup = us
			end
		else
			term.writeColored('You are up to date!\n', colors.green)
		end
	end
	os.pause()
	os.clear()
end

-- run the user's startup
if native.exists(userStartup) then
	parallel.waitForAny(function()
			shell.run(userStartup)
		end,
		catchTerminate)
end

-- show the desktop
while true do
	term.setCursorBlink(false) -- fix issues sometimes caused by CTRL+T
	local lastBG, lastFG = term.getBackgroundColor(), term.getTextColor()
	term.setBackgroundColor(config['desktop'])
	os.clear()
	term.writeColored(err, colors.red)
	err = ''
	
	-- draw the start button
	term.setBackgroundColor(colors.green)
	
	-- draw start button
	term.setCursorPos(1, h)
	term.writeColored('menu', colors.white)
	drawStartMenu()
	
	-- draw taskbar
	term.setBackgroundColor(colors.cyan)
	for i=5, w do
		term.setCursorPos(i, h)
		write(' ')
	end
	
	term.setBackgroundColor(lastBG)
	term.setTextColor(lastFG)
	term.setCursorPos(1, 1)
	
	-- do the update
	parallel.waitForAny(catchTerminate, acceptMouseInput, acceptKeyboardInput) -- wait for input
	parallel.waitForAny(catchTerminate, callWrapper) -- run the requested program (if any) until termination
end

-- allow terminate from other programs (needed?)
os.pullEvent = pullEvent