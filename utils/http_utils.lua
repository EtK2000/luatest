---Downloads the content from the given URL into the supplied filepath
---@param url string
---@param filepath string
function http.download(url, filepath)
    local req = http.get(url)
    if not req then
        error('Could not reach ' .. url, 2)
    end

    local content = req.readAll()
    if not content then
        error('Could not connect to ' .. url, 2)
    end

    local file = fs.open(filepath, 'w')
    file.write(content)
    file.close()
end
