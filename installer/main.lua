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
	crypto = nil,
	cryptoLibraryUrl =
	'https://raw.githubusercontent.com/Egor-Skriptunoff/pure_lua_SHA/6adac177c16c3496899f69d220dfb20bc31c03df/sha2.lua',
	defaultModules = { 'add-apt-repository', 'apt-get', 'cmd', 'config', 'explorer', 'su', 'sudo' },
	forceRedownloadFilePath = getDiskPath() .. '.update',
	installType = InstallType.new,
	log = function(_, _) error('logger not setup', 2) end,
	moduleDir = '/osDir/mods/',
	osPath = '/osDir',
	redownload = false,
	repoPrefix = 'https://raw.githubusercontent.com/EtK2000/luatest/master/',
	version = {
		installer = {
			core = -1
		},
		latest = {
			core = -1
		}
	},
	---@type GuiWindow
	window = nil
}


----------------------
--       Setup      --
----------------------


-- paths
-- 1 ***** User's Renamed File, Named To Be Hidden
local userStartup = '1userStartupURFNTOBH' -- the name given to the renamed 'startup'


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
	doPrivileged(fs.delete, installerContext.osPath)
elseif installerContext.version.installer.core > os.getVersion() then
	installerContext.installType = InstallType.update
else
	installerContext.installType = InstallType.reinstall
	doPrivileged(fs.delete, installerContext.osPath)
end


-- Download and run `os_downloader`
-- FIXME: see if this should be done after UI is setup before showing buttons
local wasOsDownloaded = loadAndExecute(installerContext, 'installer/os_downloader')(
	installerContext,
	getDiskPath() .. 'os/'
)
if not wasOsDownloaded then
	return
end


----------------------
-- define functions --
----------------------


local function downloadDefaultModules()
	local repository = repo.loadRepo(installerContext.repoPrefix)

	for _, module in pairs(installerContext.defaultModules) do
		installerContext.log('Downloading module "' .. module .. '"...')

		local ok, errorMessage = os.try(
			http.download,
			repository:getModuleUrl(module),
			installerContext.moduleDir .. module
		)
		if not ok then
			error(errorMessage)
		end
	end
end


local function doUserCreationOrLogin()
	local windowInstaller = installerContext.window
	windowInstaller:clearChildren()

	doPrivileged(downloadDefaultModules)

	-- Download the crypto util
	installerContext.log('Downloading crypto lib...')
	doPrivileged(
		http.download,
		installerContext.cryptoLibraryUrl,
		installerContext.osPath .. '/crypto'
	)
	installerContext.crypto = require(installerContext.osPath .. '/crypto')

	-- Prompt user to create a user if needed
	local needsUserCreation = installerContext.installType == InstallType.new or not users.hasUsers()
	if needsUserCreation then
		installerContext.log('Preparing user creation...')
	else
		installerContext.log('Users already exist, prompting for login...')
	end

	-- Download and run `user`
	loadAndExecute(installerContext, 'installer/gui/user', true)(
		installerContext,
		doPrivileged,
		needsUserCreation,
		function()
			installerContext.log('Logged in as ' .. users.currentUser().name)

			-- Download and run `optional_modules`
			loadAndExecute(installerContext, 'installer/gui/optional_modules')(
				installerContext,
				doPrivileged,
				function()
					-- download the startup,
					-- FIXME: copy old startup file if not a previous version of Albyno
					local ok, errorMessage = os.try(
						http.download,
						installerContext.repoPrefix .. 'os/core.lua',
						'/startup'
					)
					if not ok then
						error(errorMessage)
					end

					-- Download and run `success`
					loadAndExecute(installerContext, 'installer/gui/success', true)(
						installerContext
					)
				end
			)
		end
	)
end


----------------------
-- Main entry point --
----------------------


-- Download and run `gui`
loadAndExecute(installerContext, 'installer/gui/gui_main')(installerContext, doUserCreationOrLogin)

-- Allow the window to listen for events
installerContext.window:eventLoop()
if installerContext.window.closeRequested then
	os.clear()
	term.writeColored('Operation canceled!\n', colors.red)
	return
end
