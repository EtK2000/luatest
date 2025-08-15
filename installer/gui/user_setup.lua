MIN_PASSWORD_LENGTH = 4
MIN_USERNAME_LENGTH = 4

---@param usernameText string
---@param passwordText string
---@param passwordRepeatText string
---@return boolean
local function areCredentialsValid(usernameText, passwordText, passwordRepeatText)
	return #usernameText >= MIN_USERNAME_LENGTH
		and #passwordText >= MIN_PASSWORD_LENGTH and passwordText == passwordRepeatText
end

---Returns a function to be run after any of the `TextField`s are changed to update the validity state
---@param username GuiTextField
---@param password GuiTextField
---@param passwordRepeat GuiTextField
---@param continueButton GuiButton
---@return fun()
local function onChange(username, password, passwordRepeat, continueButton)
	return function()
		continueButton.enabled = areCredentialsValid(username.text, password.text, passwordRepeat.text)
	end
end

---Setup the Window
---@param window GuiWindow
local function setupWindow(window)
	window:clearChildren()

	gui.Label.new(window, 'User Creation')
	local username = gui.TextField.new(window, 'Username')

	gui.Label.new(window, '')
	local password = gui.TextField.new(window, 'Password', true)
	local passwordRepeat = gui.TextField.new(window, 'Repeat', true)

	local continueButton = gui.Button.new(window, 'Continue')


	local onChangeFunc = onChange(username, password, passwordRepeat, continueButton)
	username.onChange = onChangeFunc;
	password.onChange = onChangeFunc;
	passwordRepeat.onChange = onChangeFunc;
	onChangeFunc()


	window.focus = username
	window:updateContent()
end

---@param installerContext InstallerContext
return function(installerContext)
	setupWindow(installerContext.window)
end
