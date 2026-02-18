local nativeTerm = term.native() -- Don't allow anything to overwrite this


----------------------
--- Base Component ---
----------------------


---@class GuiWindowComponent
local GuiWindowComponent = {}
GuiWindowComponent.__index = GuiWindowComponent


function GuiWindowComponent.isFocusable(self)
	return false
end

function GuiWindowComponent.isOver(self, x, y)
	local endX = self.x + self.w - 1
	local endY = self.y + self.h - 1

	return x >= self.x and x <= endX
		and y >= self.y and y <= endY
end

--------------
--- Button ---
--------------


---@class GuiButton: GuiWindowComponent
local GuiButton = setmetatable({}, { __index = GuiWindowComponent })
GuiButton.__index = GuiButton


function GuiButton.draw(self)
	local parent = self.parent
	local contentArea = parent.hwndContent;
	local style = parent.style
	local x, y = contentArea.getCursorPos()

	-- Set the style
	local prevBackground = contentArea.getBackgroundColor()
	local prevForeground = contentArea.getTextColor()
	contentArea.setBackgroundColor(
		(not self.enabled and style.buttonDisabledBackground)
		or style.buttonBackground or style.windowBackground
	)
	contentArea.setTextColor(
		(not self.enabled and style.buttonDisabledForeground)
		or style.buttonForeground or style.windowForeground
	)

	-- Center the text
	local textLength = #self.text
	local textStartX = math.floor((parent.w - textLength + 1) / 2) -- +1 for edge padding
	contentArea.setCursorPos(textStartX, y)
	contentArea.write(' ' .. self.text .. ' ')

	-- Update the coords
	self.x = textStartX
	self.y = y + 1 -- titlebar
	self.w = textLength + 2
	self.h = 1

	-- Revert the style
	contentArea.setBackgroundColor(prevBackground)
	contentArea.setTextColor(prevForeground)

	-- Move to the next line, FIXME: shouldn't be done in here
	contentArea.setCursorPos(x, y + 2)
end

---@param parent GuiWindow
---@param text string
---@param onClick? fun()
function GuiButton.new(parent, text, onClick)
	local self = setmetatable({}, GuiButton)
	self.enabled = true
	self.onClick = onClick
	self.parent = parent
	self.text = text

	table.insert(parent.children, self)
	parent:updateContent()

	return self
end

----------------
--- Checkbox ---
----------------


---@class GuiCheckbox: GuiWindowComponent
local GuiCheckbox = setmetatable({}, { __index = GuiWindowComponent })
GuiCheckbox.__index = GuiCheckbox


function GuiCheckbox.draw(self)
	local parent = self.parent
	local contentArea = parent.hwndContent
	local style = parent.style
	local x, y = contentArea.getCursorPos()

	local prevBackground = contentArea.getBackgroundColor()
	local prevForeground = contentArea.getTextColor()

	-- Total width: 2 (box) + 1 (space) + text length
	local totalWidth = #self.text + 3

	-- Center
	local startX = math.floor((parent.w - totalWidth + 1) / 2)
	contentArea.setCursorPos(startX, y)

	-- Draw the box
	contentArea.setBackgroundColor(
		(not self.enabled and style.checkboxBoxDisabledBackground)
		or style.checkboxBoxBackground or style.windowBackground
	)
	contentArea.setTextColor(
		(not self.enabled and style.checkboxBoxDisabledForeground)
		or style.checkboxBoxForeground or style.windowForeground
	)
	contentArea.write(self.checked and '\136\132' or '  ')

	-- Draw the label
	contentArea.setBackgroundColor(style.checkboxBackground or style.windowBackground)
	contentArea.setTextColor(
		(not self.enabled and style.checkboxDisabledForeground)
		or style.checkboxForeground or style.windowForeground
	)
	contentArea.write(' ' .. self.text)

	-- Update the coords
	self.x = startX
	self.y = y + 1 -- titlebar
	self.w = totalWidth
	self.h = 1

	-- Revert the style
	contentArea.setBackgroundColor(prevBackground)
	contentArea.setTextColor(prevForeground)

	-- Move to the next line, FIXME: shouldn't be done in here
	contentArea.setCursorPos(x, y + 2)
end

function GuiCheckbox.drawFocus(self)
	local contentArea = self.parent.hwndContent
	local style = self.parent.style

	contentArea.setCursorBlink(true)
	contentArea.setCursorPos(
		self.x + 1, -- padding
		self.y - 1 -- titlebar
	)
	contentArea.setTextColor(
		style.checkboxBoxForeground or style.windowForeground
	)
end

function GuiCheckbox.isFocusable(self)
	return self.enabled
end

function GuiCheckbox.onKey(self, key)
	if key == keys.space then
		self.onClick()
		self.parent:updateContent()
	end
end

---@param parent GuiWindow
---@param text string
---@param checked? boolean
function GuiCheckbox.new(parent, text, checked)
	local self = setmetatable({}, GuiCheckbox)
	self.checked = checked or false
	self.enabled = true
	self.onClick = function()
		self.checked = not self.checked
		if self.onChange then
			self.onChange()
		end
	end
	self.parent = parent
	self.text = text

	table.insert(parent.children, self)
	parent:updateContent()

	return self
end

-------------
--- Label ---
-------------


---@class GuiLabel: GuiWindowComponent
local GuiLabel = setmetatable({}, { __index = GuiWindowComponent })
GuiLabel.__index = GuiLabel


function GuiLabel.draw(self)
	local parent = self.parent
	local contentArea = parent.hwndContent;
	local style = parent.style
	local x, y = contentArea.getCursorPos()

	-- Set the style
	local prevBackground = contentArea.getBackgroundColor()
	local prevForeground = contentArea.getTextColor()
	contentArea.setBackgroundColor(style.labelBackground or style.windowBackground)
	contentArea.setTextColor(style.labelForeground or style.windowForeground)

	-- Center the text
	local textLength = #self.text
	local textStartX = math.floor((parent.w - textLength + 1) / 2) -- +1 for edge padding
	contentArea.setCursorPos(textStartX, y)
	contentArea.write(' ' .. self.text .. ' ')

	-- Update the coords
	self.x = textStartX
	self.y = y + 1 -- titlebar
	self.w = textLength + 2
	self.h = 1

	-- Revert the style
	contentArea.setBackgroundColor(prevBackground)
	contentArea.setTextColor(prevForeground)

	-- Move to the next line, FIXME: shouldn't be done in here
	contentArea.setCursorPos(x, y + 2)
end

---@param parent GuiWindow
---@param text string
function GuiLabel.new(parent, text)
	local self = setmetatable({}, GuiLabel)
	self.enabled = true
	self.parent = parent
	self.text = text

	table.insert(parent.children, self)
	parent:updateContent()

	return self
end

-----------------
--- TextField ---
-----------------


---@class GuiTextField: GuiWindowComponent
local GuiTextField = setmetatable({}, { __index = GuiWindowComponent })
GuiTextField.__index = GuiTextField

function GuiTextField.draw(self)
	local parent = self.parent
	local contentArea = parent.hwndContent;
	local style = parent.style
	local x, y = contentArea.getCursorPos()

	-- Set the style
	local prevBackground = contentArea.getBackgroundColor()
	local prevForeground = contentArea.getTextColor()
	contentArea.setBackgroundColor(
		(not self.enabled and style.textFieldDisabledBackground)
		or style.textFieldBackground or style.windowBackground
	)
	contentArea.setTextColor(
		(not self.enabled and style.textFieldDisabledForeground)
		or (#self.displayText == 0 and style.textFieldPlaceholderForeground)
		or style.textFieldForeground or style.windowForeground
	)

	-- FIXME: support text scroll if too long
	local textToRender = #self.displayText > 0 and self.displayText or self.placeholder or ''
	local width = math.max(#self.displayText, #self.placeholder, self.maxCharacters) + 2 -- padding

	-- Align text to left
	local textStartX = math.ceil((parent.w - width) / 2)
	contentArea.setCursorPos(textStartX, y)
	contentArea.write(' ' .. textToRender .. ' ')

	-- Update the coords
	self.x = textStartX
	self.y = y + 1 -- titlebar
	self.w = width
	self.h = 1

	-- Write the remaining characters (+3 because it's inclusive)
	for _ = #textToRender + 3, width do
		contentArea.write(' ')
	end

	-- Revert the style
	contentArea.setBackgroundColor(prevBackground)
	contentArea.setTextColor(prevForeground)

	-- Move to the next line, FIXME: shouldn't be done in here
	contentArea.setCursorPos(x, y + 2)

	-- FIXME: support showing cursor if focused
end

function GuiTextField.drawFocus(self)
	local contentArea = self.parent.hwndContent;
	local style = self.parent.style

	contentArea.setCursorBlink(true)
	contentArea.setCursorPos(
		self.x + #self.text + 1, -- padding
		self.y - 1         -- titlebar
	)
	contentArea.setTextColor(style.textFieldForeground or style.windowForeground)
end

function GuiTextField.isFocusable(self)
	return self.enabled
end

function GuiTextField.new(parent, placeholder, secret)
	local self = setmetatable({}, GuiTextField)
	self.displayText = ''
	self.enabled = true
	self.maxCharacters = 10
	self.parent = parent
	self.placeholder = placeholder
	self.secret = secret
	self.text = ''

	table.insert(parent.children, self)
	parent:updateContent()

	return self
end

function GuiTextField.onChar(self, char)
	if #self.text < self.maxCharacters then
		local contentArea = self.parent.hwndContent
		local cursorX = contentArea.getCursorPos()
		local textPos = cursorX - self.x - 1

		self.text = string.sub(self.text, 1, textPos) .. char .. string.sub(self.text, textPos + 1)
		self.displayText = string.sub(self.displayText, 1, textPos) ..
			(self.secret and '*' or char) .. string.sub(self.displayText, textPos + 1)

		if self.onChange then
			self.onChange()
		end

		-- LOW: maybe only redraw this component?
		self.parent:updateContent()
		contentArea.setCursorPos(self.x + textPos + 2, self.y - 1)
	end
end

function GuiTextField.onKey(self, key)
	local contentArea = self.parent.hwndContent
	local cursorX = contentArea.getCursorPos()
	local textPos = cursorX - self.x - 1

	if key == keys.backspace then
		if textPos > 0 then
			self.text = string.sub(self.text, 1, textPos - 1) .. string.sub(self.text, textPos + 1)
			self.displayText = string.sub(self.displayText, 1, textPos - 1) .. string.sub(self.displayText, textPos + 1)
			textPos = textPos - 1

			if self.onChange then
				self.onChange()
			end
		end
	elseif key == keys.delete then
		if textPos < #self.text then
			self.text = string.sub(self.text, 1, textPos) .. string.sub(self.text, textPos + 2)
			self.displayText = string.sub(self.displayText, 1, textPos) .. string.sub(self.displayText, textPos + 2)

			if self.onChange then
				self.onChange()
			end
		end
	elseif key == keys.left then
		if textPos > 0 then
			textPos = textPos - 1
		end
	elseif key == keys.right then
		if textPos < #self.text then
			textPos = textPos + 1
		end
	end

	-- LOW: maybe only redraw this component?
	self.parent:updateContent()
	contentArea.setCursorPos(self.x + textPos + 1, self.y - 1)
end

--------------
--- Window ---
--------------


---@class GuiWindow
local GuiWindow = {}
GuiWindow.__index = GuiWindow


function GuiWindow.clearChildren(self)
	self.children = {}
	self.scrollOffset = 0
	self:updateContent()
end

function GuiWindow.drawScrollIndicators(self)
	local content = self.hwndContent
	local maxScroll = self:getMaxScroll()

	local prevBg = content.getBackgroundColor()
	local prevFg = content.getTextColor()
	content.setBackgroundColor(self.style.windowBackground)
	content.setTextColor(self.style.windowForeground)

	local arrowX = math.floor(self.w / 2)

	if self.scrollOffset > 0 then
		content.setCursorPos(arrowX, 1)
		content.write('\24')
	end

	if self.scrollOffset < maxScroll then
		content.setCursorPos(arrowX, self.visibleHeight)
		content.write('\25')
	end

	content.setBackgroundColor(prevBg)
	content.setTextColor(prevFg)
end

function GuiWindow.eventLoop(self)
	parallel.waitForAny(
		self:handleClickEvents(),
		self:handleTerminateEvents(),
		self:waitForCloseRequested()
	)

	os.clear()
end

function GuiWindow.getMaxScroll(self)
	return math.max(0, self.totalContentHeight - self.visibleHeight - 1)
end

function GuiWindow.handleClickEvents(self)
	return function()
		while not self.closeRequested do
			local event, btn_or_key, x, y = os.pullEvent()

			-- Process character events if the focus can recieve it
			if event == 'char' then
				if self.focus then
					if self.focus.onChar then
						self.focus:onChar(btn_or_key)
					end
				end

				-- Process mouse left clicks
			elseif event == 'mouse_click' then
				if btn_or_key == 1 then
					local relativeX, relativeY = x - self.x + 1, y - self.y + 1

					-- Check that it's in this self
					if relativeX >= 1 and relativeX <= self.w and relativeY >= 1 and relativeY <= self.h then
						-- Check the 'X' button
						if self:isClickOnWindowX(relativeX, relativeY) then
							self.closeRequested = true

							-- Check all children
						else
							for _, child in pairs(self.children) do
								-- Only one child can be clicked, and only click it if it listens for clicks
								if child:isOver(relativeX, relativeY) then
									if child.enabled then
										local someThingChanged = false

										-- Focus if the component supports it
										if child:isFocusable() then
											self.focus = child
											someThingChanged = true
										end

										if child.onClick then
											child.onClick()
											someThingChanged = true
										end

										-- Only redraw if something external might've happened
										if someThingChanged then
											self:updateContent()
										end

										-- Position cursor at click location for text fields
										-- (must be after call to `self:updateContent`)
										if getmetatable(child) == GuiTextField then
											local textPos = math.min(math.max(relativeX - child.x - 1, 0), #child.text)
											self.hwndContent.setCursorPos(child.x + textPos + 1, child.y - 1)
										end
									end
									break
								end
							end
						end
					end
				end

				-- Process scroll events
			elseif event == 'mouse_scroll' then
				local direction = btn_or_key
				local relativeX, relativeY = x - self.x + 1, y - self.y + 1

				if relativeX >= 1 and relativeX <= self.w and relativeY >= 1 and relativeY <= self.h then
					local newOffset = math.max(0, math.min(self.scrollOffset + direction, self:getMaxScroll()))
					if newOffset ~= self.scrollOffset then
						self.scrollOffset = newOffset
						self:updateContent()
					end
				end

				-- Process key events if the focus can recieve it
			elseif event == 'key' then
				if btn_or_key == keys.tab then
					-- Find the index of the current focus
					local startIndex = nil
					for i, child in ipairs(self.children) do
						if child == self.focus then
							startIndex = i
							break
						end
					end

					-- Focus the next TextField
					if startIndex then
						local count = #self.children
						for offset = 1, count - 1 do
							local i = (startIndex - 1 + offset) % count + 1
							local child = self.children[i]
							if child:isFocusable() then
								self.focus = child
								self:updateContent()
								self:scrollToFocus()
								break
							end
						end
					end
				elseif btn_or_key == keys.enter and self.focus then
					-- Find the index of the current focus
					local startIndex = nil
					for i, child in ipairs(self.children) do
						if child == self.focus then
							startIndex = i
							break
						end
					end

					-- Toggle checkbox if focused
					if getmetatable(self.focus) == GuiCheckbox and self.focus.enabled then
						self.focus.onClick()
						self:updateContent()
					end

					-- Act on the next non-label child if applicable
					if startIndex then
						for i = startIndex + 1, #self.children do
							local next = self.children[i]
							if next:isFocusable() then
								self.focus = next
								self:updateContent()
								self:scrollToFocus()
								break
							elseif getmetatable(next) == GuiButton and next.enabled and next.onClick then
								next.onClick()
								self:updateContent()
								break
							elseif getmetatable(next) ~= GuiLabel then
								break
							end
						end
					end
				elseif (btn_or_key == keys.up or btn_or_key == keys.down) and not self.focus then
					local direction = (btn_or_key == keys.up) and -1 or 1
					local newOffset = math.max(0, math.min(self.scrollOffset + direction, self:getMaxScroll()))
					if newOffset ~= self.scrollOffset then
						self.scrollOffset = newOffset
						self:updateContent()
					end
				elseif self.focus then
					if self.focus.onKey then
						self.focus:onKey(btn_or_key)
					end
				end
			end
			-- FIXME: support pasting
		end
	end
end

function GuiWindow.scrollToFocus(self)
	local child = self.focus
	if not child then return end

	local minVisible = 2   -- topmost visible content row (window-relative)
	local maxVisible = self.h -- bottommost visible row (window-relative)

	-- Include padding: one row above and one row below the component
	local topWithPadding = child.y - 1
	local bottomWithPadding = child.y + child.h

	if topWithPadding >= minVisible and bottomWithPadding <= maxVisible then
		return -- fully visible with padding
	end

	-- Convert to virtual (scroll-independent) coordinates
	local virtualTop = (topWithPadding - 1) + self.scrollOffset
	local virtualBottom = (bottomWithPadding - 1) + self.scrollOffset

	if topWithPadding < minVisible then
		-- Top padding is above visible area, scroll up to reveal it
		self.scrollOffset = virtualTop - (minVisible - 1)
	else
		-- Bottom padding is below visible area, scroll down to reveal it
		self.scrollOffset = virtualBottom - (maxVisible - 1)

		-- If this pushed top padding off-screen, prioritize showing top
		if virtualTop - self.scrollOffset + 1 < minVisible then
			self.scrollOffset = virtualTop - (minVisible - 1)
		end
	end

	self.scrollOffset = math.max(0, math.min(self.scrollOffset, self:getMaxScroll()))
	self:updateContent()
end

function GuiWindow.handleTerminateEvents(self)
	return function()
		os.waitForTerminate()
		self.closeRequested = true
	end
end

function GuiWindow.isClickOnWindowX(self, clickX, clickY)
	return self.hasX and clickY == 1 and clickX >= self.w - 3
end

function GuiWindow.new(title, x, y, w, h, style, hasX)
	local self = setmetatable({}, GuiWindow)
	self.children = {}
	self.closeRequested = false
	self.h = h
	self.hasX = hasX ~= false
	self.hwndContent = window.create(nativeTerm, x, y + 1, w, h - 1, true)
	self.hwndTitlebar = window.create(nativeTerm, x, y, w, 1, true)
	self.scrollOffset = 0
	self.style = style or gui.defaultStyle
	self.title = title
	self.totalContentHeight = 0
	self.visibleHeight = h - 1
	self.w = w
	self.x = x
	self.y = y

	self:updateContent()
	return self
end

function GuiWindow.updateContent(self)
	local style = self.style
	local windowBackground = style.windowBackground
	local windowForeground = style.windowForeground

	-- Setup titlebar - title
	local titlebar = self.hwndTitlebar
	titlebar.setBackgroundColor(style.titlebarBackground or windowBackground)
	titlebar.setTextColor(style.titlebarForeground or windowForeground)
	titlebar.setCursorPos(2, 1)
	titlebar.clearLine()
	titlebar.write(self.title)

	-- Setup titlebar - 'X' button
	if self.hasX then
		titlebar.setCursorPos(self.w - 3, 1)
		titlebar.setBackgroundColor(style.titlebarXBackground or windowBackground)
		titlebar.setTextColor(style.titlebarXForeground or windowForeground)
		titlebar.write(' X ')
	end

	-- Setup content
	local content = self.hwndContent
	content.setBackgroundColor(windowBackground)
	content.setTextColor(windowForeground)
	content.clear()
	content.setCursorPos(1, 2 - self.scrollOffset)

	-- Draw children, FIXME: use index to center vertically
	for _, child in ipairs(self.children) do
		child:draw()
	end

	-- Compute total content height for scroll bounds
	local _, finalCursorY = content.getCursorPos()
	self.totalContentHeight = finalCursorY + self.scrollOffset

	-- Draw scroll indicators
	self:drawScrollIndicators()

	-- Draw the focused component, LOW: might be better to find a way to do this in the first pass
	if self.focus and self.focus.drawFocus then
		self.focus:drawFocus()
	end
end

function GuiWindow.waitForCloseRequested(self)
	return function()
		while not self.closeRequested do
			coroutine.yield()
		end
	end
end

---@type Gui
_G.gui = table.readOnly({

	---------------
	--- Classes ---
	---------------
	['Button'] = GuiButton,
	['Checkbox'] = GuiCheckbox,
	['Label'] = GuiLabel,
	['TextField'] = GuiTextField,
	['Window'] = GuiWindow,


	--------------
	--- Fields ---
	--------------

	['defaultStyle'] = {
		-- Button
		['buttonBackground'] = colors.blue,
		['buttonForeground'] = colors.white,
		['buttonDisabledBackground'] = colors.lightGray,
		['buttonDisabledForeground'] = colors.gray,

		-- Checkbox
		['checkboxBackground'] = nil,
		['checkboxBoxBackground'] = colors.gray,
		['checkboxBoxDisabledBackground'] = colors.lightGray,
		['checkboxBoxDisabledForeground'] = colors.gray,
		['checkboxBoxForeground'] = colors.lime,
		['checkboxDisabledBackground'] = colors.lightGray,
		['checkboxDisabledForeground'] = colors.gray,
		['checkboxForeground'] = nil,

		-- Label
		['labelBackground'] = nil,
		['labelForeground'] = nil,

		-- TextField
		['textFieldBackground'] = colors.black,
		['textFieldForeground'] = colors.white,
		['textFieldDisabledBackground'] = colors.gray,
		['textFieldDisabledForeground'] = colors.lightGray,
		['textFieldPlaceholderForeground'] = colors.lightGray,

		-- Titlebar
		['titlebarBackground'] = colors.blue,
		['titlebarForeground'] = colors.white,
		['titlebarXBackground'] = colors.red,
		['titlebarXForeground'] = colors.white,

		-- Window (also defaults if unset)
		['windowBackground'] = colors.white,
		['windowForeground'] = colors.black
	}
})
