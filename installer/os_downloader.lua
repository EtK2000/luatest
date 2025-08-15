---@type boolean
local didDownloadFail = false

---@type boolean
local wasCancelRequested = false


---Downloads the `core.lua` file from the remote URL
---@param baseUrl string
---@param installerDir string
---@param installerConfig InstallerConfig
---@return boolean
local function downloadOsCore(baseUrl, installerDir, installerConfig)
	local corePath = installerDir .. '/core'
	local coreUrl = baseUrl .. '/os/core.lua'

	if installerConfig.redownload or not fs.exists(corePath) then
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
---@param installerConfig InstallerConfig
---@return boolean
local function fetchLatestVersion(installerConfig)
	local versionUrl = installerConfig.repoPrefix .. '/version.txt'

	local ok, res = os.try(http.download, versionUrl)

	-- If success, write the version to the installer's catalog file
	if ok then
		installerConfig.version.latest.core = tonumber(res) --[[@as integer]]
		return true
	end

	didDownloadFail = true
	error(res, 2)
end

---Sets `installerVersion` from the local file if available,
---otherwise copies `latestVersion` (yes, this isn't foolproof)
---@param installerConfig InstallerConfig
---@param installerDir string
local function getInstallerVersion(installerConfig, installerDir)
	local installerVersionFile = installerDir .. 'version.txt'

	if not installerConfig.redownload then
		local file = fs.open(installerVersionFile, 'r')

		-- Load the version from `installerVersionFile` if it exists and is deserializable
		if file then
			local content = file.readLine()

			-- It should be a single line
			if content then
				local versionCatalog = textutils.unserialise(content)

				-- If it can be deserialized and we have a version for core, we're done
				if versionCatalog and versionCatalog.core then
					installerConfig.version.installer.core = versionCatalog.core
					return
				end

				-- Otherwise, fall-through to recreating the version catalog
			end
		end
	end

	-- Otherwise, write `latestVersion` to it
	file = fs.open(installerVersionFile, 'w')
	if not file then
		error('Failed to save installer version catalog', 2)
	end
	file.write(textutils.serialise({ ['core'] = installerConfig.version.latest.core }, { compact = true }))
	file.close()

	installerConfig.version.installer.core = installerConfig.version.latest.core;
end

---Returns a downloader for the given `baseUrl`
---@param installerConfig InstallerConfig
---@param installerDir string
---@return fun()
local function getOsDownloader(installerConfig, installerDir)
	return function()
		if downloadOsCore(installerConfig.repoPrefix, installerDir, installerConfig)
			and fetchLatestVersion(installerConfig)
		then
			getInstallerVersion(installerConfig, installerDir)
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
---@param installerConfig InstallerConfig
---@param installerDir string
---@return boolean
return function(installerConfig, installerDir)
	parallel.waitForAny(
		getOsDownloader(installerConfig, installerDir),
		letUserCancel,
		showLoading
	)

	if didDownloadFail or wasCancelRequested then
		return false
	end

	os.clear()
	return true
end
