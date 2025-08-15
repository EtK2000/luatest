---@type string[]
local defaultModules = { 'add-apt-repository', 'apt-get', 'cmd', 'config', 'explorer', 'su', 'sudo' }


---@param installerContext InstallerContext
---@param moduleDir string
return function(installerContext, moduleDir)
	---@type Repository
	local repository = repo.loadRepo(installerContext.repoPrefix)


	for _, module in pairs(defaultModules) do
		installerContext.log('Downloading module "' .. module .. '"...')

		local ok, errorMessage = os.try(
			http.download,
			repository:getModuleUrl(module),
			moduleDir .. module
		)
		if not ok then
			error(errorMessage)
		end
	end
end
