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


----------------------
-- Helper functions --
----------------------


---Returns `/<disk name>/`, absolute path fixes some issues
---@return string
local function getDiskPath()
	local p = shell.getRunningProgram()
	p = string.sub(p, 1, string.find(p, '/'))
	return '/' .. p
end

---Downloads the requested file if needed then executes it,
---note that this can only be run after bootstrapping
---@param installerContext InstallerContext
---@param pathWithoutExtension string
---@param force? true
---@return unknown
local function loadAndExecute(installerContext, pathWithoutExtension, force)
	local osDownloaderPath = getDiskPath() .. pathWithoutExtension
	if force or installerContext.redownload or not fs.exists(osDownloaderPath) then
		http.download(installerContext.repoPrefix .. pathWithoutExtension .. '.lua', osDownloaderPath)
	end

	local res, _ = require(pathWithoutExtension)
	return res
end


-------------------
-- Configuration --
-------------------


---@enum InstallType
InstallType = {
	new = 'Install',
	reinstall = 'Reinstall',
	update = 'Update'
}

---@type InstallerContext
local installerContext = {
	---@type Crypto
	['crypto'] = nil,
	['cryptoLibraryUrl'] =
	'https://raw.githubusercontent.com/Egor-Skriptunoff/pure_lua_SHA/6adac177c16c3496899f69d220dfb20bc31c03df/sha2.lua',
	['forceRedownloadFilePath'] = getDiskPath() .. '.update',
	['installType'] = InstallType.new,
	['log'] = function(_, _) error('logger not setup', 2) end,
	['osPath'] = '/osDir',
	['redownload'] = false,
	['repoPrefix'] = 'https://raw.githubusercontent.com/EtK2000/luatest/master/',
	['version'] = {
		['installer'] = {
			['core'] = -1
		},
		['latest'] = {
			['core'] = -1
		}
	},
	---@type GuiWindow
	['window'] = nil
}


----------------------
--       Setup      --
----------------------


local perm = 0 -- permission level (0: not logged in, 1: guest, 2: user, 3: super)
local displayName

local maxUsername, maxPassword = 10, 10

-- paths
-- 1 ***** User's Renamed File, Named To Be Hidden
local userStartup = '1userStartupURFNTOBH' -- the name given to the renamed 'startup'
local usersFile =
'osData/crd'                               -- the file containing the users' credentials, is would be awesome to encode this
local bin = 'osData/bin'
shell.setAlias('cls', 'clear')
shell.setAlias('del', 'delete')
shell.setAlias('ren', 'rename')
shell.setAlias('shell', 'cmd')


-- cache
local w, h = term.getSize()


-- Check if force redownload has been set
local file = fs.open(installerContext.forceRedownloadFilePath, 'r')
if file then
	file.close()

	-- If so, enable redownload
	installerContext.redownload = true

	-- And delete everything JIC
	fs.delete(getDiskPath() .. 'installer')
	fs.delete(getDiskPath() .. 'os')
	fs.delete(getDiskPath() .. 'utils')

	-- Note that this file is handled separately lower down
end

-- Download and load utils
local bootstrapUtilsPath = getDiskPath() .. 'utils/bootstrap'
if installerContext.redownload or not fs.exists(bootstrapUtilsPath) then
	print('Downloading utilities...')

	local bootstrapUtilsUrl = installerContext.repoPrefix .. 'utils/bootstrap.lua'
	local req = http.get(bootstrapUtilsUrl)
	if not req then
		error('Could not reach ' .. bootstrapUtilsUrl)
	end
	local content = req.readAll()
	if not content then
		error('Could not connect to ' .. bootstrapUtilsUrl)
	end

	local file = fs.open(bootstrapUtilsPath, 'w')
	if not file then
		error('Could not open file ' .. bootstrapUtilsPath)
	end
	file.write(content)
	file.close()
end

---@type fun(func: fun(...: unknown), ...: unknown): unknown
local doPrivileged = require('utils/bootstrap')(installerContext, getDiskPath() .. 'utils/')
os.clear()

-- Redownload this file, then reboot into `main_swapper`
if installerContext.redownload then
	-- Download the new `main`
	local ok, errorMessage = os.try(
		http.download,
		installerContext.repoPrefix .. 'installer/main.lua',
		shell.getRunningProgram() .. '_new'
	)
	if not ok then
		error(errorMessage)
	end

	-- Download the swapper so execution doesn't jump after `fs.move`
	local ok, errorMessage = os.try(
		http.download,
		installerContext.repoPrefix .. 'installer/main_swapper.lua',
		getDiskPath() .. 'startup'
	)
	if not ok then
		error(errorMessage)
	end

	-- Reboot so `startup` is executed instead of `startup.lua` and swapper runs
	os.reboot()

	-- Ensure execution doesn't get further
	while true do end
end

-- Update the install type
if os.getVersion() == -1 then
	installerContext.installType = InstallType.new
elseif installerContext.version.installer.core > os.getVersion() then
	installerContext.installType = InstallType.update
else
	installerContext.installType = InstallType.reinstall
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
		error('invalid perm_level, range is 1-3', 2)
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


----------------------
-- define functions --
----------------------


-- moves the specified file replacing any existing one
local function privilegedReplace(from, to)
	if shell.getRunningProgram() == (bin .. '/apt-get') then -- a little hack to allow apt-get to update system files
	end
end

-- Download and run `os_downloader`
-- FIXME: see if this should be done after UI is setup before showing buttons
local wasOsDownloaded = loadAndExecute(installerContext, 'installer/os_downloader')
	(installerContext, getDiskPath() .. 'os/')
if not wasOsDownloaded then
	return
end

-- Download and run `gui`
loadAndExecute(installerContext, 'installer/gui/gui_main')(installerContext)
local windowInstaller = installerContext.window

-- Set the `onClick` to continue installation
windowInstaller.children[1].onClick = function()
	windowInstaller:clearChildren()

	-- Download and run `module_downloader`
	installerContext.log('Downloading "module_downloader"...')
	loadAndExecute(installerContext, 'installer/module_downloader', true)(installerContext, getDiskPath() .. 'os/mods/')

	-- Download the crypto util
	installerContext.log('Downloading crypto lib...')
	http.download(installerContext.cryptoLibraryUrl, installerContext.osPath .. '/crypto')
	installerContext.crypto = require(installerContext.osPath .. '/crypto')

	-- Prompt user to create a user on new install
	if installerContext.installType == InstallType.new then
		installerContext.log('Preparing user creation...')
		-- FIXME: change `false` to `true`
		loadAndExecute(installerContext, 'installer/gui/user_setup', false)(installerContext, getDiskPath() .. 'os/mods/')
	else
		installerContext.log('Skipping user creation...')
	end
end

-- Allow the window to listen for events
windowInstaller:eventLoop()
if windowInstaller.closeRequested then
	os.clear()
	term.writeColored('Operation canceled!\n', colors.red)
	return
end


local function doLogin()
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
			local username = io.read()
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

local function configure()
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

	local lastColor = term.getBackgroundColor()
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
					for k, v in table.orderedPairs(vers) do
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
									term.writeColored('Canceled...\n', colors.red)
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
