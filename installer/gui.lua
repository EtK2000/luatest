local CONSOLE_HEIGHT = 5

---@class GuiObject
---@field log fun(str: string)
---@field shouldInstallationContinue boolean
---@field windowInstaller GuiWindow

local nativeTerm = term.native()

---@type integer, integer
local w, h = nativeTerm.getSize()

---@type boolean
local shouldInstallationContinue = true


local consoleStyle = table.shallowCopy(gui.defaultStyle)
consoleStyle.titlebarBackground = colors.gray
consoleStyle.windowBackground = colors.black
consoleStyle.windowForeground = colors.white
local windowConsole = gui.createWindow(
	"Console",
	1, h - CONSOLE_HEIGHT + 1,
	w, CONSOLE_HEIGHT,
	consoleStyle,
	false
)

---Write `str` to the console and scroll if needed
---@param str string
---@param color colors?
local function log(str, color)
	local console = windowConsole.hwndContent
	console.setCursorPos(1, CONSOLE_HEIGHT - 1)
	console.scroll(1)
	console.setTextColor(color or consoleStyle.windowForeground)
	console.write(str)
end

---Start the installation process, FIXME: this is a placeholder
---@param installerConfig InstallerConfig
---@windowInstaller GuiWindow
---@return fun()
local function startInstallation(installerConfig, windowInstaller)
	return function()
		windowInstaller.closeRequested = true
	end
end

---Attempt to make the installer update next boot
---@param installerConfig InstallerConfig
---@return fun()
local function updateInstaller(installerConfig)
	return function()
		local file = fs.open(installerConfig.forceRedownloadFilePath, 'w')
		if file then
			file.close()
			os.reboot()

			-- Ensure execution doesn't get further
			while true do end
		else
			log('Failed to trigger update', colors.red)
		end
	end
end

---Create the main content window
---@param installerConfig InstallerConfig
---@return GuiWindow
local function createInstallerWindow(installerConfig)
	--	gui.defaultStyle.buttonBackground = colors.cyan
	--gui.defaultStyle.buttonForeground = colors.black
	local windowInstaller = gui.createWindow(
		os.getName() .. " Installer v" .. installerConfig.version.installer.core,
		1, 1,
		w, h - CONSOLE_HEIGHT
	)

	-- Change install button text based off computer state
	if os.getVersion() == -1 then
		windowInstaller:addButton('Install ' .. os.getName(), startInstallation(installerConfig, windowInstaller))
	elseif installerConfig.version.installer.core > os.getVersion() then
		windowInstaller:addButton('Update ' .. os.getName(), startInstallation(installerConfig, windowInstaller))
	else
		windowInstaller:addButton('Reinstall ' .. os.getName(), startInstallation(installerConfig, windowInstaller))
	end

	if installerConfig.version.latest.core > installerConfig.version.installer.core then
		windowInstaller:addButton(
			'Update Installer to v' .. installerConfig.version.latest.core,
			updateInstaller(installerConfig)
		)
	end

	return windowInstaller
end


---@param installerConfig InstallerConfig
---@return GuiObject
return function(installerConfig)
	local windowInstaller = createInstallerWindow(installerConfig)

	windowInstaller:eventLoop()

	if windowInstaller.closeRequested then
		os.clear()
		term.writeColored('Operation canceled!\n', colors.red)
		shouldInstallationContinue = false
	end

	return {
		['log'] = log,
		['shouldInstallationContinue'] = shouldInstallationContinue,
		['windowInstaller'] = windowInstaller
	}
end
