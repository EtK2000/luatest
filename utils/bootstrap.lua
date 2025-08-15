-- Note that `http_utils`, `os_utils`, and `permission_utils`  are downloaded separately
local UTILS_FILES_TO_DOWNLOAD_NORMALLY = {
	'fs',
	'gui',
	'string',
	'table',
	'term',

	-- These need to be after `table`
	'colors',
	'repo',
	'version'
}


---@type fun(...: unknown): unknown
local doPrivileged


---Get the local destination path for `moduleName`
---@param utilsDir string
---@param moduleName string
---@return string
local function getModuleLocalPath(utilsDir, moduleName)
	return utilsDir .. moduleName .. '_utils'
end

---Get the URL for downloading `moduleName`
---@param installerContext InstallerContext
---@param moduleName string
---@return string
local function getModuleRemoteUrl(installerContext, moduleName)
	return installerContext.repoPrefix .. 'utils/' .. moduleName .. '_utils.lua'
end

---Download `http_utils` and load it
---@param installerContext InstallerContext
---@param utilsDir string
local function downloadAndInjectHttpUtils(installerContext, utilsDir)
	local httpUtilsPath = getModuleLocalPath(utilsDir, 'http')

	-- Download if needed or requested
	if installerContext.redownload or not fs.exists(httpUtilsPath) then
		local httpUtilsUrl = getModuleRemoteUrl(installerContext, 'http')
		local req = http.get(httpUtilsUrl)
		if not req then
			error('Could not reach ' .. httpUtilsUrl, 3)
		end
		local content = req.readAll()
		if not content then
			error('Could not connect to ' .. httpUtilsUrl, 3)
		end

		local file = fs.open(httpUtilsPath, 'w')
		if not file then
			error('Could not open file ' .. httpUtilsPath, 3)
		end

		file.write(content)
		file.close()
	end

	-- Load
	os.loadAPI(httpUtilsPath)
end

---Download `os_utils` and load it, note that this depends on `http_utils` being loaded
---@param installerContext InstallerContext
---@param utilsDir string
local function downloadAndInjectOsUtils(installerContext, utilsDir)
	local osUtilsPath = getModuleLocalPath(utilsDir, 'os')

	-- Download if needed or requested
	if installerContext.redownload or not fs.exists(osUtilsPath) then
		local ok, errorMessage = pcall(
			http.download,
			getModuleRemoteUrl(installerContext, 'os'),
			osUtilsPath
		)
		if not ok then
			error(errorMessage, 3)
		end
	end

	-- Load
	os.loadAPI(osUtilsPath)
end

---Download `permission_utils`, load it, and set `doPrivileged`,
---note this depends on `http_utils` and `os_utils` being loaded
---@param installerContext InstallerContext
---@param utilsDir string
local function downloadAndInjectPermissionUtils(installerContext, utilsDir)
	local permissionUtilsPath = getModuleLocalPath(utilsDir, 'permission')

	if installerContext.redownload or not fs.exists(permissionUtilsPath) then
		local ok, errorMessage = os.try(
			http.download,
			getModuleRemoteUrl(installerContext, 'permission'),
			permissionUtilsPath
		)
		if not ok then
			error(errorMessage, 2)
		end
	end

	doPrivileged = require('utils/permission_utils')
end

---Returns a function that will download remaining utils and load them,
---note it depends on `http_utils` and `os_utils` being loaded
---@param installerContext InstallerContext
---@param utilsDir string
---@return fun()
local function downloadAndInjectRemainingUtils(installerContext, utilsDir)
	return function()
		-- We can now call http.download for the remaining files
		for _, moduleName in ipairs(UTILS_FILES_TO_DOWNLOAD_NORMALLY) do
			local modulePath = getModuleLocalPath(utilsDir, moduleName)
			if installerContext.redownload or not fs.exists(modulePath) then
				local ok, errorMessage = os.try(
					http.download,
					getModuleRemoteUrl(installerContext, moduleName),
					getModuleLocalPath(utilsDir, moduleName)
				)
				if not ok then
					error(errorMessage, 2)
				end
			end

			os.loadAPI(modulePath)
		end

		-- Download `permission_utils` last and return its `doPrivileged`
		downloadAndInjectPermissionUtils(installerContext, utilsDir)
	end
end

---Wait for user to cancel the operation
local function letUserCancel()
	os.waitForTerminate()
	error('Operation was canceled')
end


---Download all utils files from a specific URL into the specified directory,
---returns `permission_utils.doPrivileged` for privileged access,
---not that `os.catchTerminate()` is called internally
---@param installerContext InstallerContext
---@param utilsDir string
---@return fun(func: function, ...: unknown): unknown
return function(installerContext, utilsDir)
	-- Create the utils directory if needed
	if not fs.exists(utilsDir) then
		fs.makeDir(utilsDir)
	end

	-- First, we would like to pull http_utils.lua so we can call `http.download` for the rest
	downloadAndInjectHttpUtils(installerContext, utilsDir)

	-- Now download os_utils.lua for `os.try`
	downloadAndInjectOsUtils(installerContext, utilsDir)

	-- Download everything else with a nicer loading
	os.clear()
	os.catchTerminate()
	parallel.waitForAny(
		downloadAndInjectRemainingUtils(installerContext, utilsDir),
		letUserCancel,
		os.loading
	)

	return doPrivileged

	-- FIXME: if we fail anywhere, unload all loadAPI calls?
end
