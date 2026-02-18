---Setup the Window
---@param installerContext InstallerContext
local function setupWindow(installerContext)
	local window = installerContext.window
	window:clearChildren()

	gui.Label.new(window, 'Installation complete!')

	local continueButton = gui.Button.new(window, 'Reboot')
	continueButton.onClick = os.reboot


	window.focus = window.children[1]
	window:updateContent()
end

---@param installerContext InstallerContext
return function(installerContext)
	setupWindow(installerContext)
end
