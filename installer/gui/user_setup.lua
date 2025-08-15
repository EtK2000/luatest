---Setup the Window
---@param window GuiWindow
local function setupWindow(window)
	window:clearChildren()

	window:addLabel("User Creation")
	local username = window:addTextField("Username")
	local password = window:addTextField("Password")

	local continueButton = window:addButton("Continue")
	continueButton.enabled = false

	window.focus = username
	window:updateContent()
end

---@param installerContext InstallerContext
return function(installerContext)
	setupWindow(installerContext.window)
end
