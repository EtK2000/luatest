---Map from `RepositoryIndex` field to `ModuleDefinition` field
local mapRepoIndexToModuleDefField = {
	['$alone'] = 'isStandalone',
	['$dep'] = 'dependencies',
	['$disp'] = 'displayName',
	['$max'] = 'maxSupportedOsVersion',
	['$min'] = 'minSupportedOsVersion',
	['$name'] = 'name',
	['$req'] = 'isRequiredForRepository',
	['$run'] = 'initFileUrl',
	['$ver'] = 'version'
}


---Get the url to download `mod` from `repository`, TODO: cache?
---@param repository Repository
---@param mod string
---@return string
local function getModuleUrl(repository, mod)
	local moduleDefinition = repository.index.moduleDefinitions[mod]
	local res = repository.index.basepath

	if not moduleDefinition then
		error('Module cannot be found in the repository', 2)
	end

	for formatField, moduleField in pairs(mapRepoIndexToModuleDefField) do
		res = string.gsub(res, '%' .. formatField, moduleDefinition[moduleField])
	end

	return res
end


---Process the repository index
---@param repoIndexContent string
---@return RepositoryIndex
local function loadRepoIndex(repoIndexContent)
	---@type string?, string?
	local basepath, format

	---@type string[]
	local rawModuleLines = {}

	-- Process all lines for keywords
	for line in string.gmatch(repoIndexContent, '[^\r\n]+') do
		-- Skip comments
		if not string.starts(line, '#') then
			-- Check if it's a keyword
			if string.starts(line, '[basepath]=') then
				basepath = string.match(line, '=(.+)$')
			elseif string.starts(line, '[format]=') then
				format = string.match(line, '=(.+)$')

				-- Otherwise, it's a module definition
			else
				table.insert(rawModuleLines, line)
			end
		end
	end

	if not basepath or not format then
		error('Invalid repository.index', 3)
	end

	-- Validate `format` (this is rudimentary)
	local formatChunks = string.explode(format, ',')
	if not formatChunks or #formatChunks < 2 then
		error('Invalid repository format', 3)
	end

	-- Map from index fields to definition fields
	---@type string
	local fields = {}
	for i, formatField in ipairs(formatChunks) do
		fields[i] = mapRepoIndexToModuleDefField[formatField]
	end

	-- Now use `format` to process `rawModuleLines`
	---@type ModuleDefinition[]
	local moduleDefinitions = {}
	for _, line in pairs(rawModuleLines) do
		---@type ModuleDefinition
		local currentModuleDefinition = {
			['isStandalone'] = 1,
			['dependencies'] = {},
			['displayName'] = nil,
			['maxSupportedOsVersion'] = -1,
			['minSupportedOsVersion'] = -1,
			['name'] = '',
			['isRequiredForRepository'] = 0,
			['initFileUrl'] = nil,
			['version'] = -1
		}

		local moduleFieldValues = string.explode(line, ',')

		if not moduleFieldValues then
			error('Invalid module definition: ' .. line, 3)
		end

		for j, moduleFieldValue in ipairs(moduleFieldValues) do
			local field = fields[j]

			-- Dependencies need to be converted to an array
			if field == 'dependencies' then
				currentModuleDefinition[field] = string.explode(moduleFieldValue, ';') or {}
			else
				currentModuleDefinition[field] = os.castToTypeOf(moduleFieldValue, currentModuleDefinition[field])
			end
		end

		-- Validate the definition we just built
		local modName = currentModuleDefinition['name']
		if #modName == 0 then
			error('Invalid module definition: ' .. line, 3)
		end
		if moduleDefinitions[modName] then
			error('Module redefinition: ' .. modName, 3)
		end

		-- Add the definition we just built
		moduleDefinitions[modName] = table.readOnly(currentModuleDefinition)
	end

	---@type RepositoryIndex
	local res = {
		['basepath'] = basepath,
		['moduleDefinitions'] = moduleDefinitions
	}
	return table.readOnly(res)
end


---@param repository Repository
---@param mod string
---@param versionCatalogPath string
---@param installationPath string
---FIXME: deal with access when needing to update system module or versionCatalog
local function moduleInstall(repository, mod, versionCatalogPath, installationPath)
	local versionCatalog = version.loadVersionCatalog(versionCatalogPath)

	if not versionCatalog then
		error('Cannot access version catalog', 2)
	end

	http.download(repository:getModuleUrl(mod), installationPath .. mod)

	versionCatalog.modules[mod] = repository.index.moduleDefinitions[mod].version
	version.save(versionCatalog, versionCatalogPath)
end


---@param repository Repository
---@param mod string
---@param versionCatalogPath string
---@param installationPath string
---FIXME: deal with access when needing to update system module or versionCatalog
local function moduleUninstall(repository, mod, versionCatalogPath, installationPath)
	local versionCatalog = version.loadVersionCatalog(versionCatalogPath)

	if not versionCatalog then
		error('Cannot access version catalog', 2)
	elseif not versionCatalog.modules[mod] then
		error('Module not installed', 2)
	end

	fs.delete(installationPath .. mod)

	versionCatalog.modules[mod] = nil
	version.save(versionCatalog, versionCatalogPath)
end


---@param repositoryUrl string
---@return Repository
local function loadRepo(repositoryUrl)
	local repoIndex = loadRepoIndex(http.download(repositoryUrl .. 'repository.index'))

	---@type Repository
	local res = {
		['getModuleUrl'] = getModuleUrl,
		['index'] = repoIndex,
		['installModule'] = moduleInstall,
		['uninstallModule'] = moduleUninstall,
		['url'] = repositoryUrl
	}
	return table.readOnly(res)
end


-- Lock this util package
---@type Repo
_G.repo = table.readOnly({
	['loadRepo'] = loadRepo
})
