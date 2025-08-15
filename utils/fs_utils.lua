---Move `from` to `to` replacing an existing file if needed
---@param from string
---@param to string
function fs.replace(from, to)
	if fs.exists(to) then
		fs.delete(to)
	end
	fs.move(from, to)
end

---Copy `from` to `to` replacing an existing file if needed
---@param from string
---@param to string
function fs.replaceCopy(from, to)
	if fs.exists(to) then
		fs.delete(to)
	end
	fs.copy(from, to)
end
