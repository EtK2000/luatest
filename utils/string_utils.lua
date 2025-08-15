---Attempts to conver `str` to a `boolean`
---@param str string
---@return boolean
function string.asBoolean(str)
	local s = string.lower(str)
	if s == 'yes' or s == 'y' or s == 'true' or s == 't' or str == '1' then
		return true
	elseif s == 'no' or s == 'n' or s == 'false' or s == 'f' or str == '0' then
		return false
	else
		error('Invalid boolean', 2)
	end
end

---Checks if `str` ends with `endsWith`
---@param str string
---@param endsWith string
---@return boolean
function string.ends(str, endsWith)
	return string.sub(str, string.len(str) - string.len(endsWith) + 1) == endsWith
end

---Attempts to split `str` at the supplied character(s) `div`
---@param str string
---@param div string
---@return string[]|false
function string.explode(str, div)
	if div == '' then
		return false
	end
	local pos, res = 0, {}
	-- for each divider found
	for st, sp in function() return string.find(str, div, pos, true) end do
		res[#res + 1] = string.sub(str, pos, st - 1) -- Attach chars left of current divider
		pos = sp + 1                           -- Jump past current divider
	end
	res[#res + 1] = string.sub(str, pos)       -- Attach chars right of last divider
	return res
end

---Find the index of the last occurrence of `needle` in `str`
---@param str string
---@param needle string
---@return integer|nil
function string.last(str, needle)
	local i = str:match('.*' .. needle .. '()')
	if i == nil then
		return nil
	else
		return i - 1
	end
end

---Checks if `str` starts with `startsWith`
---@param str string
---@param startsWith string
---@return boolean
function string.starts(str, startsWith)
	return string.sub(str, 1, string.len(startsWith)) == startsWith
end
