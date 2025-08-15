---@type boolean
local didDownloadFail = false

---@type boolean
local wasCancelRequested = false


---Downloads the `core.lua` file from the remote URL
---@param baseUrl string
---@param installerDir string
---@param installerContext InstallerContext
---@return boolean
local function downloadOsCore(baseUrl, installerDir, installerContext)
	local corePath = installerDir .. '/core'
	local coreUrl = baseUrl .. '/os/core.lua'

	if installerContext.redownload or not fs.exists(corePath) then
		local ok, res = os.try(http.download, coreUrl, corePath)
		if not ok then
			didDownloadFail = true
			error(res, 2)
		end

		return ok
	end

	return true
end

---Sets `latestVersion` from the remote URL
---@param installerContext InstallerContext
---@return boolean
local function fetchLatestVersion(installerContext)
	local versionUrl = installerContext.repoPrefix .. '/version.txt'

	local ok, res = os.try(http.download, versionUrl)

	-- If success, write the version to the installer's catalog file
	if ok then
		installerContext.version.latest.core = tonumber(res) --[[@as integer]]
		return true
	end

	didDownloadFail = true
	error(res, 2)
end

---Sets `installerVersion` from the local file if available,
---otherwise copies `latestVersion` (yes, this isn't foolproof)
---@param installerContext InstallerContext
---@param installerDir string
local function getInstallerVersion(installerContext, installerDir)
	local installerVersionFile = installerDir .. 'version.txt'

	if not installerContext.redownload then
		local file = fs.open(installerVersionFile, 'r')

		-- Load the version from `installerVersionFile` if it exists and is deserializable
		if file then
			local content = file.readLine()

			-- It should be a single line
			if content then
				local versionCatalog = textutils.unserialise(content)

				-- If it can be deserialized and we have a version for core, we're done
				if versionCatalog and versionCatalog.core then
					installerContext.version.installer.core = versionCatalog.core
					return
				end

				-- Otherwise, fall-through to recreating the version catalog
			end
		end
	end

	-- Otherwise, write `latestVersion` to it
	local file = fs.open(installerVersionFile, 'w')
	if not file then
		error('Failed to save installer version catalog', 2)
	end
	file.write(textutils.serialise({ ['core'] = installerContext.version.latest.core }, { compact = true }))
	file.close()

	installerContext.version.installer.core = installerContext.version.latest.core;
end

---Returns a downloader for the given `baseUrl`
---@param installerContext InstallerContext
---@param installerDir string
---@return fun()
local function getOsDownloader(installerContext, installerDir)
	return function()
		if downloadOsCore(installerContext.repoPrefix, installerDir, installerContext)
			and fetchLatestVersion(installerContext)
		then
			getInstallerVersion(installerContext, installerDir)
		end
	end
end

---Wait for user to cancel the operation
local function letUserCancel()
	os.waitForTerminate()
	term.writeColored('\nOperation canceled!\n', colors.red)
	term.setTextColor(colors.white) -- in case we interrupted a Y/N
	wasCancelRequested = true
end

---Show a blue loading animation to the user
local function showLoading()
	os.loading(colors.blue)
end


---Download the OS, returns `true` if succeeded, otherwise `false`
---@param installerContext InstallerContext
---@param installerDir string
---@return boolean
return function(installerContext, installerDir)
	parallel.waitForAny(
		getOsDownloader(installerContext, installerDir),
		letUserCancel,
		showLoading
	)

	if didDownloadFail or wasCancelRequested then
		return false
	end

	os.clear()
	return true
end
