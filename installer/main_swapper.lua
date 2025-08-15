---This file is here to delete the running `main` then reboot
---If `fs.move` is called on the running program execution continues from the wrong location
---This file is needed to get around that


---Returns `<disk name>/`
---@return string
local function getDiskPath()
	local p = shell.getRunningProgram()
	p = string.sub(p, 1, string.find(p, '/'))
	return p
end

---@type string
local installerMainPath = getDiskPath() .. 'startup.lua'


-- Delete the update request
fs.delete(getDiskPath() .. '.update')

-- Replace `main`
fs.delete(installerMainPath)
fs.move(installerMainPath .. '_new', installerMainPath)

-- Delete this file so `startup.lua` is run
fs.delete(shell.getRunningProgram())

-- Let the new `main` run
os.reboot()

-- Ensure execution doesn't get further
while true do end
