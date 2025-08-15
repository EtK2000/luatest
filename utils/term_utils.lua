local currentBackgroundColor = colors.black
local currentForegroundColor = colors.white
local setBackgroundColorRaw = term.setBackgroundColor
local setTextColorRaw = term.setTextColor

---Returns the current background color
---@return integer
function term.getBackgroundColor()
	return currentBackgroundColor
end

---Returns the current text color
---@return integer
function term.getTextColor()
	return currentForegroundColor
end

---Sets the current background color
---@param col integer
function term.setBackgroundColor(col)
	setBackgroundColorRaw(col)
	currentBackgroundColor = col
end

---Sets the current text color
---@param col integer
function term.setTextColor(col)
	setTextColorRaw(col)
	currentForegroundColor = col
end

---Writes `text` to the center of the screen
---@param text string
---@param fgc? integer
---@param bgc? integer
function term.writeCentered(text, fgc, bgc)
	local _, y = term.getCursorPos()
	local w, _ = term.getSize()
	local bg = term.getBackgroundColor()
	local fg = term.getTextColor()
	if bgc ~= nil then
		term.setBackgroundColor(bgc)
	end
	if fgc ~= nil then
		term.setBackgroundColor(fgc)
	end
	term.setCursorPos((w - string.len(text) - 1) / 2, y) -- -1 to align text on left side
	write(text)
	if bgc ~= nil then
		term.setBackgroundColor(bg)
	end
	if fgc ~= nil then
		term.setBackgroundColor(fg)
	end
end

---Writes `text` to the screen with the supplied foreground and background colors
---@param text string
---@param fgc integer
---@param bgc? integer
function term.writeColored(text, fgc, bgc)
	if term.isColor() then
		local bg = term.getBackgroundColor()
		local fg = term.getTextColor()
		if bgc ~= nil then
			term.setBackgroundColor(bgc)
		end
		term.setTextColor(fgc)
		write(text)
		if bgc ~= nil then
			term.setBackgroundColor(bg)
		end
		term.setTextColor(fg)
	else
		write(text)
	end
end

---Prompts the user for yes or no
---@return boolean
function term.yesNo()
	while true do
		local x, y = term.getCursorPos()
		local r = read()
		local ok, rAsBoolean = os.try(string.asBoolean, r)
		if ok then
			return rAsBoolean
		end
		term.setCursorPos(x, y)
		for _ = 1, string.len(r) do
			write(' ')
		end
		term.setCursorPos(x, y)
	end
end
