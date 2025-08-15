---Checks if `t` contains `element`
---@param t table
---@param element any
---@return boolean
function table.contains(t, element)
	for _, v in pairs(t) do
		if v == element then
			return true
		end
	end
	return false
end

---Return a deep copy of `t`
---@generic T : table
---@param t T
---@return T
function table.deepCopy(t)
	local res = {}
	for k, v in pairs(t) do
		if type(v) == 'table' then
			res[k] = v:deepCopy(v)
		else
			res[k] = v
		end
	end
	return res
end

---Return a frozen version of `t`
---@generic T : table
---@param t T
---@return T
function table.readOnly(t)
	local proxy = {}
	local mt = {
		__index = t,
		__newindex = function(_, _, _)
			error('Attempt to update a read-only table', 2)
		end
	}
	setmetatable(proxy, mt)
	return proxy
end

---Equivalent to `next()`, but returns the keys in the alphabetic order.<br>
---We use a temporary ordered key table that is stored in the table being iterated.
---@generic K, V
---@param t { [K]: V }
---@param state? K
---@return K?, V?
local function orderedNext(t, state)
	---@type string?
	local key = nil

	if state == nil then
		-- the first time, generate the index
		local keys = {}
		for k in pairs(t) do
			table.insert(keys, k)
		end
		table.sort(keys)
		t.__orderedIndex = keys

		key = t.__orderedIndex[1]
	else
		-- fetch the next value
		for i = 1, #t.__orderedIndex do
			if t.__orderedIndex[i] == state then
				key = t.__orderedIndex[i + 1]
			end
		end
	end

	if key then
		return key, t[key]
	end

	-- No more values to return, cleanup
	t.__orderedIndex = nil
end

---Similar to `pairs()`, but iterates in order by keys sorted
---@generic K, V
---@param t { [K]: V }
---@return fun(t: { [K]: V }, state?: K), table, nil
function table.orderedPairs(t)
	return orderedNext, t, nil
end

---Return a shallow copy of `t`
---@generic T : table
---@param t T
---@return T
function table.shallowCopy(t)
	local res = {}
	for k, v in pairs(t) do
		res[k] = v
	end
	return res
end

---Get the size of `t`
---@param t table
---@return integer
function table.size(t)
	local res = 0
	for _, _ in pairs(t) do
		res = res + 1
	end
	return res
end
