---Checks if `tbl` contains `element`
---@param tbl table
---@param element any
---@return boolean
function table.contains(tbl, element)
	for k, v in pairs(tbl) do
		if v == element then
			return true
		end
	end
	return false
end

---Get the size of `tbl`
---@param tbl table
---@return integer
function table.size(tbl)
	local res = 0
	for k, v in pairs(tbl) do
		res = res + 1
	end
	return res
end
