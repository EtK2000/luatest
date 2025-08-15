-- Note that `http_utils`, `os_utils`, and `permission_utils`  are downloaded separately
local UTILS_FILES_TO_DOWNLOAD_NORMALLY = {
    'colors',
    'fs',
    'string',
    'table',
    'term'
}

-- Get the local destination path for `moduleName`
---@param utilsDir string
---@param moduleName string
---@return string
local function getModuleLocalPath(utilsDir, moduleName)
    return utilsDir .. moduleName .. '_utils'
end

-- Get the URL for downloading `moduleName`
---@param baseUrl string
---@param moduleName string
---@return string
local function getModuleRemoteUrl(baseUrl, moduleName)
    return baseUrl .. 'utils/' .. moduleName .. '_utils.lua'
end

---Download `http_utils` and load it
---@param baseUrl string
---@param utilsDir string
---@param redownload boolean|nil
local function downloadAndInjectHttpUtils(baseUrl, utilsDir, redownload)
    local httpUtilsPath = getModuleLocalPath(utilsDir, 'http')

    -- Download if needed or requested
    if redownload or not fs.exists(httpUtilsPath) then
        local httpUtilsUrl = getModuleRemoteUrl(baseUrl, 'http')
        local req = http.get(httpUtilsUrl)
        if not req then
            error('Could not reach ' .. httpUtilsUrl, 3)
        end
        local content = req.readAll()
        if not content then
            error('Could not connect to ' .. httpUtilsUrl, 3)
        end

        local file = fs.open(httpUtilsPath, 'w')
        file.write(content)
        file.close()
    end

    -- Load
    os.loadAPI(httpUtilsPath)
end

---Download `os_utils` and load it, note that this depends on `http_utils` being loaded
---@param baseUrl string
---@param utilsDir string
---@param redownload boolean|nil
local function downloadAndInjectOsUtils(baseUrl, utilsDir, redownload)
    local osUtilsPath = getModuleLocalPath(utilsDir, 'os')

    -- Download if needed or requested
    if redownload or not fs.exists(osUtilsPath) then
        local ok, errorMessage = pcall(
            http.download,
            getModuleRemoteUrl(baseUrl, 'os'),
            osUtilsPath
        )
        if not ok then
            error(errorMessage, 3)
        end
    end

    -- Load
    os.loadAPI(osUtilsPath)
end


---Download all utils files from a specific URL into the specified directory,
---returns `permission_utils.doPrivileged` for privileged access
---@param baseUrl string
---@param utilsDir string
---@param redownload boolean?
---@return table
function bootstrap(baseUrl, utilsDir, redownload)
    -- Create the utils directory if needed
    if not fs.exists(utilsDir) then
        fs.makeDir(utilsDir)
    end

    -- First, we would like to pull http_utils.lua so we can call `http.download` for the rest
    downloadAndInjectHttpUtils(baseUrl, utilsDir, redownload)

    -- Now download os_utils.lua for `os.try`
    downloadAndInjectOsUtils(baseUrl, utilsDir, redownload)

    -- We can now call http.download for the remaining files
    for index, moduleName in ipairs(UTILS_FILES_TO_DOWNLOAD_NORMALLY) do
        local modulePath = getModuleLocalPath(utilsDir, moduleName)
        if not fs.exists(modulePath) then
            ok, errorMessage = os.try(
                http.download,
                getModuleRemoteUrl(baseUrl, moduleName),
                getModuleLocalPath(utilsDir, moduleName)
            )
            if not ok then
                error(errorMessage, 2)
            end
        end

        os.loadAPI(modulePath)
    end

    -- Download `permission_utils` last and return it
    local modulePath = getModuleLocalPath(utilsDir, 'permission')
    if not fs.exists(modulePath) then
        ok, errorMessage = os.try(
            http.download,
            getModuleRemoteUrl(baseUrl, 'permission'),
            getModuleLocalPath(utilsDir, 'permission')
        )
        if not ok then
            error(errorMessage, 2)
        end
    end

    return require('utils/permission_utils')

    -- FIXME: if we fail anywhere, unload all loadAPI calls?
end
