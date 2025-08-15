---Downloads the content from the given URL,
---if `filepath` is specified, will write the output to it,
---otherwise, the content is returned
---@overload fun(url: string): string
---@overload fun(url: string, filepath: string)
function http.download(url, filepath)
	local req = http.get(url)
	if not req then
		error('Could not reach ' .. url, 2)
	end

	local content = req.readAll()
	if not content then
		error('Could not connect to ' .. url, 2)
	end

	if not filepath then
		return content
	end

	local file = fs.open(filepath, 'w')
	if not file then
		error('Could not open file ' .. filepath, 3)
	end

	file.write(content)
	file.close()
end
