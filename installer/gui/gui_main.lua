local CONSOLE_HEIGHT = 5

local nativeTerm = term.native()

---@type integer, integer
local w, h = nativeTerm.getSize()


local consoleStyle = table.shallowCopy(gui.defaultStyle)
consoleStyle.titlebarBackground = colors.gray
consoleStyle.windowBackground = colors.black
consoleStyle.windowForeground = colors.white
local windowConsole = gui.Window.new(
	'Console',
	1, h - CONSOLE_HEIGHT + 1,
	w, CONSOLE_HEIGHT,
	consoleStyle,
	false
)

---Write `str` to the console and scroll if needed
---@param str string
---@param color? colors
local function log(str, color)
	local console = windowConsole.hwndContent
	console.setCursorPos(1, CONSOLE_HEIGHT - 1)
	console.scroll(1)
	console.setTextColor(color or consoleStyle.windowForeground)
	console.write(str)
end

---Attempt to make the installer update next boot
---@param installerContext InstallerContext
---@return fun()
local function updateInstaller(installerContext)
	return function()
		local file = fs.open(installerContext.forceRedownloadFilePath, 'w')
		if file then
			file.close()
			os.reboot()

			-- Ensure execution doesn't get further
			while true do end
		else
			installerContext.log('Failed to trigger update', colors.red)
		end
	end
end

---Create the main content window
---@param installerContext InstallerContext
---@return GuiWindow
local function createInstallerWindow(installerContext)
	local windowInstaller = gui.Window.new(
		os.getName() .. ' Installer v' .. installerContext.version.installer.core,
		1, 1,
		w, h - CONSOLE_HEIGHT
	)

	-- Set install button text based off assumed install type
	gui.Button.new(windowInstaller, installerContext.installType .. ' ' .. os.getName())

	if installerContext.version.latest.core > installerContext.version.installer.core then
		gui.Button.new(
			windowInstaller,
			'Update Installer to v' .. installerContext.version.latest.core,
			updateInstaller(installerContext)
		)
	end

	return windowInstaller
end


---@param installerContext InstallerContext
return function(installerContext)
	installerContext.log = log
	installerContext.window = createInstallerWindow(installerContext)
end
