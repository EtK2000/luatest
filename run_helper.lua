---This file is a helper to for `run.sh` when testing Albyno via CraftOS 2 (https://github.com/MCJack123/craftos2)

local env = setmetatable({}, { __index = _ENV })
local httpLatency = true


--region patch http
-------------------

local rawHttpGet = http.get

---@param url string The URL to make the request to
---@param headers? table<ccTweaked.http.HTTP_REQUEST_HEADERS, string> The [request headers](https://developer.mozilla.org/en-US/docs/Glossary/Request_header)
---@param binary? boolean If the request should be a binary request. If true, the body will not be UTF-8 encoded and the response will not be decoded
---@return ccTweaked.http.Response|ccTweaked.http.BinaryResponse|nil response The HTTP response object. `nil` when the request fails
---@return string message Why the request failed
---@return nil|ccTweaked.http.Response|ccTweaked.http.BinaryResponse failedResponse The response object for the failed request, if available
env.http.get = function(url, headers, binary)
	-- only proxy requests that would hit this repo
	local prefix = 'https://raw.githubusercontent.com/EtK2000'
	if string.sub(url, 1, string.len(prefix)) ~= prefix then
		return rawHttpGet(url, headers, binary)
	end

	-- strip prefix in format of https://raw.githubusercontent.com/EtK2000/Alb-no-OS/master/
	local path = url:match('^https?://[^/]+/[^/]+/[^/]+/[^/]+(/.*)$')
	local mappedPath = '/http' .. path

	if not fs.exists(mappedPath) or fs.isDir(mappedPath) then
		-- CC:Tweaked style: nil, message, failedResponse(optional)
		return nil, ('Not found: ' .. mappedPath), nil
	end

	local file = fs.open(mappedPath, 'r')
	if not file then
		return nil, ('Cannot open: ' .. mappedPath), nil
	end
	local body = file.readAll()
	file.close()

	-- add some latency to simulate network latency
	if httpLatency then
		sleep(0.25)
	end

	-- return a fake HTTP response object
	return {
		readAll = function() return body end,
		readLine = function()
			local line
			body, line = body:match('([^\n]*)\n?(.*)')
			return line
		end,
		close = function() end,
		getResponseCode = function() return 200 end,
		getResponseHeaders = function() return {} end,
	}, '', nil
end

-- endregion


--region patch shell
--------------------

env.shell.getRunningProgram = function()
	return 'disk/startup.lua'
end

--endregion


-- run the startup script
env.package.path = '/disk/?.lua;/disk/?;' .. package.path
assert(loadfile('disk/startup.lua', 't', env))()
