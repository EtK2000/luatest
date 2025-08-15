--- This file effectively sets up ring-0 protection


---Permissions based off Linux 777
---@enum permission
local Permission = {
	execute = 1,
	write = 2,
	read = 4
}

---Dangerous functions under `fs` that only need their first argument tested,
---note that `fs.open` is handled separately
---@type {[string]: permission}
local DANGEROUS_FS_FUNCS_WITH_ONE_ARG_TO_VALIDATE = {
	['delete'] = Permission.write, --  delete(path)
	['makeDir'] = Permission.write, -- makeDir(path)
}

---Dangerous functions under `fs` that need their first two arguments tested
---@type {[string]: [permission, permission]}
local DANGEROUS_FS_FUNCS_WITH_TWO_ARGS_TO_VALIDATE = {
	['copy'] = { Permission.read, Permission.write }, --  copy(path, dest)
	['move'] = { Permission.write, Permission.write }, -- move(path, dest)
}

---Dangerous functions under `io` that only need their first argument tested
---@type {[string]: permission}
local DANGEROUS_IO_FUNCS_WITH_ONE_ARG_TO_VALIDATE = {
	['input'] = Permission.read, --  input([file])
	['lines'] = Permission.read, --  lines([filename, ...])
	['open'] = Permission.read, --   open(filename [, mode])
	['output'] = Permission.write -- output([file])
}


---@type boolean
local isRawAccessAllowed = false

---@type fun(path: string): { size: number, isDir: boolean, isReadOnly: boolean, created: number, modified: number }
local rawFsAttributes = fs.attributes

---@type fun(path: string): string
local rawFsCombine = fs.combine -- Don't allow anything to overwrite this

---@type fun(path: string): boolean
local rawFsIsReadOnly = fs.isReadOnly

---@type fun(path: string, mode?: string): table|[nil, string|nil]
local rawFsOpen = fs.open -- Don't allow anything to overwrite this

---@type fun(str: string, startsWith: string): boolean
local rawStringStartsWith = string.starts -- Don't allow anything to overwrite this


---Check if access to `path` requires privileged access
---@param path any
---@param permission permission
---@return boolean
local function checkIfAccessShouldBeDenied(path, permission)
	-- Only block access to paths
	if type(path) ~= 'string' then
		return false
	end

	-- FIXME: validate permission based off allowed access
	if permission == Permission.read then
		return false
	end

	-- Block access to OS directory, we use `fs.combine` to resolve path traversal
	return rawStringStartsWith(rawFsCombine(path), 'osData')
end


---Error out if unauthorized access is detected
---@param path any
---@param permission permission
local function checkForUnauthorizedAccess(path, permission)
	if checkIfAccessShouldBeDenied(path, permission) and not isRawAccessAllowed then
		error('Unauthorized', 3)
	end
end

---Run a function with privileged access
---@param func function
---@param ... unknown
---@return unknown
local function doPrivileged(func, ...)
	isRawAccessAllowed = true
	local ok, result = pcall(func, ...)
	isRawAccessAllowed = false
	if not ok then
		error(result, 2)
	end
	return result
end

---Unwrap the message from an `error` thrown within an `os.try`,
---then throw it
---@param message string
---@return any
local function errorUnwrap(message)
	-- Otherwise, error out the caller of this function
	-- `res` should be in the format of ".../os_utils:N: <Error>"
	local firstColon = message:find(':')
	message = message:sub(firstColon + 1) -- ':'

	local secondColon = message:find(':')
	message = message:sub(secondColon + 2) -- ': '

	-- We should now be left with the error
	error(message, 2)
end

---Create a guarded function that requires privileged access
---@param func function
---@param permission permission
---@return function
local function guardFirstArg(func, permission)
	return function(firstArg, ...)
		if not isRawAccessAllowed then
			checkForUnauthorizedAccess(firstArg, permission)
		end

		-- Return results or rethrow errors
		local ok, res = os.try(func, firstArg, ...)
		if ok then
			return res
		end
		return errorUnwrap(res)
	end
end

---Create a guarded function that requires privileged access
---@param func function
---@param permissions [permission, permission]
---@return function
local function guardFirstTwoArgs(func, permissions)
	return function(firstArg, secondArg, ...)
		if not isRawAccessAllowed then
			checkForUnauthorizedAccess(firstArg, permissions[1])
			checkForUnauthorizedAccess(secondArg, permissions[2])
		end

		-- Return results or rethrow errors
		local ok, res = os.try(func, firstArg, secondArg, ...)
		if ok then
			return res
		end
		return errorUnwrap(res)
	end
end

---Create a guarded wrapper for `fs.open` that requires privileged access depending on `mode`
---@param path string
---@param mode string
---@return table|[nil, string|nil]
local function guardedFsOpen(path, mode)
	local permission = Permission.write
	if mode == 'r' then
		permission = Permission.read
	end

	if not isRawAccessAllowed then
		checkForUnauthorizedAccess(path, permission)
	end

	-- Return the handle or rethrow the error
	local ok, res = os.try(rawFsOpen, path, mode)
	if ok then
		return res
	end
	return errorUnwrap(res)
end

---An overriden version of `fs.attributes` that returns read-only for OS files
---@param path string
---@return { size: number, isDir: boolean, isReadOnly: boolean, created: number, modified: number }
local function overridenFsAttributes(path)
	local rawResult = rawFsAttributes(path)

	if checkIfAccessShouldBeDenied(path, Permission.write) and not isRawAccessAllowed then
		rawResult['isReadOnly'] = true
	end
	return rawResult
end

---An overriden version of `fs.attributes` that returns read-only for OS files
---@param path string
---@return boolean
local function overridenFsIsReadOnly(path)
	if checkIfAccessShouldBeDenied(path, Permission.write) and not isRawAccessAllowed then
		return true
	end
	return rawFsIsReadOnly(path)
end


----------
-- Main --
----------

for key, value in pairs(DANGEROUS_FS_FUNCS_WITH_ONE_ARG_TO_VALIDATE) do
	fs[key] = guardFirstArg(fs[key], value)
end

for key, value in pairs(DANGEROUS_FS_FUNCS_WITH_TWO_ARGS_TO_VALIDATE) do
	fs[key] = guardFirstTwoArgs(fs[key], value)
end

for key, value in pairs(DANGEROUS_IO_FUNCS_WITH_ONE_ARG_TO_VALIDATE) do
	io[key] = guardFirstArg(io[key], value)
end

fs.attributes = overridenFsAttributes
fs.open = guardedFsOpen
fs.isReadOnly = overridenFsIsReadOnly


return doPrivileged
