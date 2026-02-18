---@type Repository
local repository

---@type {[string]: GuiCheckbox}
local moduleCheckboxes = {}

---@type fun(func: fun(...: unknown), ...: unknown): unknown
local _doPrivileged


---Installs all modules selected by the user
---@param installerContext InstallerContext
local function installSelectedModules(installerContext)
	for module, checkbox in pairs(moduleCheckboxes) do
		if checkbox.checked then
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
end

---Returns a function to be run after any of the `TextField`s are changed to update the validity state
---@param installerContext InstallerContext
---@param onComplete fun()
---@return fun()
local function onContinueClicked(installerContext, onComplete)
	return function()
		_doPrivileged(installSelectedModules, installerContext)
		onComplete()
	end
end

---Setup the Checkboxes for each optional module
---@param installerContext InstallerContext
local function setupCheckboxes(installerContext)
	local installedModules = {}
	for _, k in pairs(installerContext.defaultModules) do
		installedModules[k] = true
	end

	---@type string[]
	local sortedModules = {}
	for module in pairs(repository.index.moduleDefinitions) do
		sortedModules[#sortedModules + 1] = module
	end
	table.sort(sortedModules)

	for _, module in pairs(sortedModules) do
		if not installedModules[module] then
			moduleCheckboxes[module] = gui.Checkbox.new(
				installerContext.window,
				module
			)
		end
	end
end

---Setup the Window
---@param installerContext InstallerContext
---@param onComplete fun()
local function setupWindow(installerContext, onComplete)
	local window = installerContext.window
	window:clearChildren()

	setupCheckboxes(installerContext)

	local continueButton = gui.Button.new(window, 'Install') -- FIXME: change if nothing selected and back if selected
	continueButton.onClick = onContinueClicked(installerContext, onComplete)


	window.focus = window.children[1]
	window:updateContent()
end

---@param installerContext InstallerContext
---@param doPrivileged fun(func: fun(...: unknown), ...: unknown): unknown
---@param onComplete fun()
return function(installerContext, doPrivileged, onComplete)
	_doPrivileged = doPrivileged
	repository = repo.loadRepo(installerContext.repoPrefix)

	setupWindow(installerContext, onComplete)
end
