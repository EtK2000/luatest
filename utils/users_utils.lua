local context = _G.__bootstrap_context
local usersFile = context.osPath .. '/.passwd'

---@type users.User?
local currentUser

---@type table<string, users.User>
local allUsers = {}

---Construct a user object
---@param userType users.UserType
---@param name string
---@param salt string
---@param hashedPassword string
---@return users.User
local function newUser(userType, name, salt, hashedPassword)
	return table.readOnly({
		authorize = function(password)
			return type(password) == 'string' and context.crypto.sha256(salt .. password) == hashedPassword
		end,
		name = name,
		type = userType
	})
end


-- Load existing users from file
if fs.exists(usersFile) then
	local file = fs.open(usersFile, 'r')
	if not file then
		error('Could not open users file')
	end

	local name = file.readLine()
	while name ~= nil do
		local salt = file.readLine()
		local hashedPassword = file.readLine()
		local userType = tonumber(file.readLine())

		if not salt or not hashedPassword or not userType then
			file.close()
			error('Malformed users file')
		end

		allUsers[name] = newUser(userType, name, salt, hashedPassword)
		name = file.readLine()
	end

	file.close()
end


users = {
	---@enum users.UserType
	UserType = {
		os = 0,
		super = 1,
		user = 2,
		guest = 3
	}
}

---Create a new user, FIXME: require permissions (currently we use `doPrivileged` as a pseudo way of validating permissions)
---@param doPrivileged fun(...): unknown
---@param userType users.UserType
---@param username string
---@param password string
function users.createUser(doPrivileged, userType, username, password)
	-- save the user
	doPrivileged(function()
		fs.makeDir(string.sub(usersFile, 1, string.last(usersFile, '/') - 1))

		local file = fs.open(usersFile, fs.exists(usersFile) and 'a' or 'w')
		if not file then
			error('Could not open users file')
		end

		-- FIXME: deal with reusing usernames

		local salt = tostring(os.epoch('utc')) .. tostring(math.random(0, 99999))
		local hashedPassword = context.crypto.sha256(salt .. password)

		file.writeLine(username)
		file.writeLine(salt)
		file.writeLine(hashedPassword)
		file.writeLine(tostring(userType))
		file.close()

		allUsers[username] = newUser(userType, username, salt, hashedPassword)
	end)
end

---Get the current logged in user
---@return users.User?
function users.currentUser()
	return currentUser
end

---Checks if the specified user has the required access
---@param permissions users.UserType
---@param username? string
---@return boolean
function users.hasPerms(permissions, username)
	local user
	if username then
		user = allUsers[username]
	else
		user = currentUser
	end

	-- No user logged in or specified user not found
	if not user then
		return false
	end

	return user.type <= permissions
end

---Checks if at least 1 user exists
---@return boolean
function users.hasUsers()
	return next(allUsers) ~= nil
end

---Attempt to login as the specific user
---@param username string
---@param password string
---@return boolean
function users.login(username, password)
	-- Skip login if already logged in
	if currentUser and currentUser.name == username then
		return true
	end

	user = allUsers[username]
	if user and user.authorize(password) then
		currentUser = user
		return true
	end

	return false
end

---Logout the current user
function users.logout()
	currentUser = nil
end

-- Lock this util package
_G.users = table.readOnly(users)
