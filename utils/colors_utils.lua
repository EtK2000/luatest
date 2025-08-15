local colorNumberMap = table.readOnly({
	['0'] = colors.white,
	['1'] = colors.orange,
	['2'] = colors.magenta,
	['3'] = colors.lightBlue,
	['4'] = colors.yellow,
	['5'] = colors.lime,
	['6'] = colors.pink,
	['7'] = colors.gray,
	['8'] = colors.lightGray,
	['9'] = colors.cyan,
	['a'] = colors.purple,
	['b'] = colors.blue,
	['c'] = colors.brown,
	['d'] = colors.green,
	['e'] = colors.red,
	['f'] = colors.black
})

local colorWordMap = table.readOnly({
	['white'] = colors.white,
	['orange'] = colors.orange,
	['magenta'] = colors.magenta,
	['lightBlue'] = colors.lightBlue,
	['yellow'] = colors.yellow,
	['lime'] = colors.lime,
	['pink'] = colors.pink,
	['gray'] = colors.gray,
	['lightGray'] = colors.lightGray,
	['cyan'] = colors.cyan,
	['purple'] = colors.purple,
	['blue'] = colors.blue,
	['brown'] = colors.brown,
	['green'] = colors.green,
	['red'] = colors.red,
	['black'] = colors.black
})

---Converts the supplied `str` into a color if possible
---@param str string
---@return integer
function colors.asColor(str)
	local s = string.lower(str)
	local res = colorNumberMap[s]
	if res == nil then
		res = colorWordMap[s]
		if res == nil then
			error('Invalid color: ' .. str, 2)
		end
	end
	return res
end
