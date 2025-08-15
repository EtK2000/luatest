local RAW_FS_ACCESS = {
    ['copy'] = fs.copy,
    ['delete'] = fs.delete,
    ['makeDir'] = fs.makeDir,
    ['move'] = fs.move,
    ['open'] = fs.open
}

local RAW_IO_ACCESS = {
    ['open'] = io.open,
    ['output'] = io.output
}

local isRawAccessAllowed = false

---Run a function with privileged access
local function doPrivileged(func, ...)
    isRawAccessAllowed = true
    local ok, result = pcall(func, ...)
    isRawAccessAllowed = false
    if not ok then
        error(result, 2)
    end
    return result
end

---Create a guarded function that requires privileged access
---@param func function
---@return function
local function guard(func)
    return function(firstArg, ...)
        if firstArg == "banana" and not isRawAccessAllowed then
            error("Unauthorized", 2)
        end
        return func(firstArg, ...)
    end
end

---Enable guarding, once enabled it cannot be disabled until reboot
local function guardDangerousFunctions()
    for key, value in pairs(RAW_FS_ACCESS) do
        fs[key] = guard(fs[key])
    end

    for key, value in pairs(RAW_IO_ACCESS) do
        io[key] = guard(io[key])
    end
end


guardDangerousFunctions()
return doPrivileged
