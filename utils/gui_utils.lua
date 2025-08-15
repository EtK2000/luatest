---@type term.Redirect
local nativeTerm = term.native() -- Don't allow anything to overwrite this


----------------------
--- Base Component ---
----------------------


---@class GuiWindowComponent
local GuiWindowComponent = {}
GuiWindowComponent.__index = GuiWindowComponent


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

	-- Center the text, FIXME: align text to left and have predetirmined width
	local textStartX = math.ceil((parent.w - width) / 2)
	contentArea.setCursorPos(textStartX, y)
	contentArea.write(' ' .. textToRender .. ' ')

	-- Update the coords
	self.x = textStartX
	self.y = y + 1 -- titlebar
	self.w = width
	self.h = 1

	-- Write the remaining characters
	for _ = #textToRender + 2, width do
		contentArea.write(' ')
	end
	-- Keep the width even
	if width % 2 == 1 then
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
	-- FIXME: based off cursor pos
	-- FIXME: support max leng

	if #self.text < self.maxCharacters then
		self.displayText = (self.displayText or '') .. (self.secret and '*' or char)
		self.text = (self.text or '') .. char

		if self.onChange then
			self.onChange()
		end

		-- LOW: maybe only redraw this component?
		self.parent:updateContent()
	end
end

function GuiTextField.onKey(self, key)
	-- FIXME: support moving cursor and editing at cursor pos
	-- FIXME: process delete, enter, tab, and arrow keys

	if key == keys.backspace then
		-- FIXME: support deleting at cursor pos
		if self.text and #self.text > 0 then
			self.displayText = string.sub(self.displayText, 1, -2)
			self.text = string.sub(self.text, 1, -2)

			if self.onChange then
				self.onChange()
			end
		end
	end

	-- LOW: maybe only redraw this component?
	self.parent:updateContent()
end

--------------
--- Window ---
--------------


---@class GuiWindow
local GuiWindow = {}
GuiWindow.__index = GuiWindow


function GuiWindow.clearChildren(self)
	self.children = {}
	self:updateContent()
end

function GuiWindow.eventLoop(self)
	parallel.waitForAny(
		self:handleClickEvents(),
		self:handleTerminateEvents(),
		self:waitForCloseRequested()
	)

	os.clear()
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

										-- For now, only support focusing TextFields
										if child.__index == GuiTextField then
											self.focus = child
											someThingChanged = true
										end

										if child.onClick then
											-- FIXME: support clicking to change cursor pos in text fields
											child.onClick()
											someThingChanged = true
										end

										-- Only redraw if something external might've happened
										if someThingChanged then
											self:updateContent()
										end
									end
									break
								end
							end
						end
					end
				end

				-- Process key events if the focus can recieve it
			elseif event == 'key' then
				if self.focus then
					if self.focus.onKey then
						self.focus:onKey(btn_or_key)
					end
				end
			end
			-- FIXME: support pasting
		end
	end
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
	self.style = style or gui.defaultStyle
	self.title = title
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
	content.setCursorPos(1, 2)

	-- Draw children, FIXME: use index to center vertically
	for index, child in ipairs(self.children) do
		child:draw()
	end

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
