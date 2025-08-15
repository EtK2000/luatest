---@class VersionCatalog
---@field public core number
---@field public modules {[string]: integer}

---@class Version
---@field loadVersionCatalog fun(versionCatalogPath: string): VersionCatalog
---@field saveVersionCatalog fun(versionCatalog: VersionCatalog, versionCatalogPath: string)
version = {}


---Load a `VersionCatalog` from `versionCatalogPath`
---@param versionCatalogPath string
---@return VersionCatalog?
function version.loadVersionCatalog(versionCatalogPath)
	local file = fs.open(versionCatalogPath, 'r')

	if file then
		local content = file.readLine()

		-- It should be a single line
		if content then
			return textutils.unserialise(content) --[[@as VersionCatalog]]
		end

		---@diagnostic disable-next-line: missing-return
	end
end

---Save a `versionCatalog` to `versionCatalogPath`
---@param versionCatalog VersionCatalog
---@param versionCatalogPath string
function version.save(versionCatalog, versionCatalogPath)
	local file = fs.open(versionCatalogPath, 'w')
	if not file then
		error('Failed to save version catalog', 2)
	end
	file.write(textutils.serialise(versionCatalog, { compact = true }))
	file.close()
end

-- Lock this util package
_G.version = table.readOnly(version)
