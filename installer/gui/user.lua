local MIN_PASSWORD_LENGTH = 4
local MIN_USERNAME_LENGTH = 4

---@type {[boolean]: users.Localization}
local LOCALIZATION = {
	[false] = {
		continue = 'Login',
		password = 'Password',
		title = 'Login',
		username = 'Username'
	},
	[true] = {
		continue = 'Create User',
		password = 'Password (4-10)',
		title = 'User Creation',
		username = 'Username (4-10)'
	}
}

---@type boolean
local _isUserCreation
---@type fun(func: fun(...: unknown), ...: unknown): unknown
local _doPrivileged

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
---@param passwordRepeat GuiTextField|false
---@param continueButton GuiButton
---@return fun()
local function onChange(username, password, passwordRepeat, continueButton)
	return function()
		continueButton.enabled = areCredentialsValid(
			username.text,
			password.text,
			(passwordRepeat and passwordRepeat.text) or password.text
		)
	end
end

---Returns a function to be run when the continue button is clicked
---@param installerContext InstallerContext
---@param username GuiTextField
---@param password GuiTextField
---@param onComplete fun()
---@return fun()
local function onContinueClicked(installerContext, username, password, onComplete)
	return function()
		if _isUserCreation then
			users.createUser(_doPrivileged, users.UserType.super, username.text, password.text)
		end

		if users.login(username.text, password.text) then
			if users.hasPerms(users.UserType.super) then
				onComplete()
			else
				installerContext.log('Please login as a super user', colors.red)
				password.text = ''
				username.text = ''
			end
		else
			installerContext.log('Incorrect username or password', colors.red)
		end
	end
end

---Setup the Window
---@param installerContext InstallerContext
---@param onComplete fun()
local function setupWindow(installerContext, onComplete)
	local window = installerContext.window
	window:clearChildren()

	local localization = LOCALIZATION[_isUserCreation]

	gui.Label.new(window, localization.title)
	local username = gui.TextField.new(window, localization.username)

	if _isUserCreation then
		gui.Label.new(window, '')
	end
	local password = gui.TextField.new(window, localization.password, true)
	local passwordRepeat = _isUserCreation and gui.TextField.new(window, 'Repeat         ', true)

	local continueButton = gui.Button.new(window, localization.continue)
	continueButton.onClick = onContinueClicked(installerContext, username, password, onComplete)


	local onChangeFunc = onChange(username, password, passwordRepeat, continueButton)
	username.onChange = onChangeFunc;
	password.onChange = onChangeFunc;
	onChangeFunc()

	if _isUserCreation then
		passwordRepeat.onChange = onChangeFunc;
	end


	window.focus = username
	window:updateContent()
end

---@param installerContext InstallerContext
---@param doPrivileged fun(func: fun(...: unknown), ...: unknown): unknown
---@param isUserCreation boolean
---@param onComplete fun()
return function(installerContext, doPrivileged, isUserCreation, onComplete)
	_isUserCreation = isUserCreation
	_doPrivileged = doPrivileged
	setupWindow(installerContext, onComplete)
end
