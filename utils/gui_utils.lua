---@enum colors
---@enum colours


---@see https://tweaked.cc/module/term.html#ty:Redirect
---@class term.Redirect


---@see https://tweaked.cc/module/window.html
---@class Window
---@field blit fun(sText: string, sTextColor: string, sBackgroundColor: string)
---@field clear fun()
---@field clearLine fun()
---@field getBackgroundColor fun(): colors
---@field getBackgroundColour fun(): colours
---@field getCursorBlink fun(): boolean
---@field getCursorPos fun(): integer, integer
---@field getLine fun(y: integer): string, string, string
---@field getPosition fun(): integer, integer
---@field getTextColor fun(): colors
---@field getTextColour fun(): colours
---@field isColor fun(): boolean
---@field isColour fun(): boolean
---@field isVisible fun(): boolean
---@field reposition fun(new_x: integer, new_y: integer, new_width: integer?, new_height: integer?, new_parent: term.Redirect?)
---@field redraw fun()
---@field restoreCursor fun()
---@field scroll fun(n: integer)
---@field setBackgroundColor fun(color: colors)
---@field setBackgroundColour fun(colour: colours)
---@field setCursorBlink fun(blink: boolean)
---@field setCursorPos fun(x: integer, y: integer)
---@field setTextColor fun(color: colors)
---@field setTextColour fun(colour: colours)
---@field setVisible fun(visible: boolean)
---@field write fun(sText: string)


---@class GuiWindow
---@field private w integer
---@field private h integer
---@field private x integer
---@field private y integer
---@field addButton fun(window: GuiWindow, text: string, onClick: fun()): GuiWindowComponentButton
---@field addLabel fun(window: GuiWindow, text: string): GuiWindowComponentLabel
---@field children GuiWindowComponent[]
---@field closeRequested boolean
---@field eventLoop fun() run the event loop on the current thread
---@field hasX boolean
---@field hwndContent Window
---@field hwndTitlebar Window
---@field style WindowStyle
---@field title string
---@field updateContent fun(window: GuiWindow)


---@class GuiWindowComponent
---@field protected parent GuiWindow
---@field protected w integer
---@field protected h integer
---@field protected x integer
---@field protected y integer
---@field draw fun(component: GuiWindowComponent)


---@class GuiWindowComponentButton : GuiWindowComponent
---@field draw fun(component: GuiWindowComponentButton)
---@field onClick fun()
---@field text string


---@class GuiWindowComponentLabel : GuiWindowComponent
---@field draw fun(component: GuiWindowComponentLabel)
---@field text string


---Note that any unset background field will default to `windowBackground`
---and any unset foreground field will default to `windowForeground`
---@class WindowStyle
---@field buttonBackground colors?
---@field buttonForeground colors?
---@field buttonDisabledBackground colors?
---@field buttonDisabledForeground colors?
---@field labelBackground colors?
---@field labelForeground colors?
---@field textFieldBackground colors?
---@field textFieldForeground colors?
---@field titlebarBackground colors?
---@field titlebarForeground colors?
---@field titlebarXBackground colors?
---@field titlebarXForeground colors?
---@field windowBackground colors
---@field windowForeground colors

---@class Gui
---@field defaultStyle WindowStyle
_G.gui = {

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
		['textFieldForeground'] = nil,

		-- Titlebar
		['titlebarBackground'] = colors.blue,
		['titlebarForeground'] = colors.white,
		['titlebarXBackground'] = colors.red,
		['titlebarXForeground'] = colors.white,

		-- Window (also defaults if unset)
		['windowBackground'] = colors.white,
		['windowForeground'] = colors.black
	}
}


---@type term.Redirect
local nativeTerm = term.native() -- Don't allow anything to overwrite this


---Draw the `button`
---@param button GuiWindowComponentButton
local function drawButton(button)
	local parent = button.parent
	local contentArea = parent.hwndContent;
	local style = parent.style
	local x, y = contentArea.getCursorPos()

	-- Set the style
	local prevBackground = contentArea.getBackgroundColor()
	local prevForeground = contentArea.getTextColor()
	contentArea.setBackgroundColor(style.buttonBackground or style.windowBackground)
	contentArea.setTextColor(style.buttonForeground or style.windowForeground)

	-- Center the text
	local textLength = #button.text
	local textStartX = math.floor((parent.w - textLength + 1) / 2) -- +1 for edge padding
	contentArea.setCursorPos(textStartX, y)
	contentArea.write(' ' .. button.text .. ' ')

	-- Update the coords
	button.x = textStartX
	button.y = y + 1 -- titlebar
	button.w = textLength + 2
	button.h = 1

	-- Revert the style
	contentArea.setBackgroundColor(prevBackground)
	contentArea.setTextColor(prevForeground)

	-- Move to the next line, FIXME: shouldn't be done in here
	contentArea.setCursorPos(x, y + 2)
end


---Draw the `label`
---@param label GuiWindowComponentLabel
local function drawLabel(label)
	local parent = label.parent
	local contentArea = parent.hwndContent;
	local style = parent.style
	local x, y = contentArea.getCursorPos()

	-- Set the style
	local prevBackground = contentArea.getBackgroundColor()
	local prevForeground = contentArea.getTextColor()
	contentArea.setBackgroundColor(style.labelBackground or style.windowBackground)
	contentArea.setTextColor(style.labelForeground or style.windowForeground)

	-- Center the text
	local textLength = #label.text
	local textStartX = math.floor((parent.w - textLength + 1) / 2) -- +1 for edge padding
	contentArea.setCursorPos(textStartX, y)
	contentArea.write(' ' .. label.text .. ' ')

	-- Update the coords
	label.x = textStartX
	label.y = y + 1 -- titlebar
	label.w = textLength + 2
	label.h = 1

	-- Revert the style
	contentArea.setBackgroundColor(prevBackground)
	contentArea.setTextColor(prevForeground)

	-- Move to the next line, FIXME: shouldn't be done in here
	contentArea.setCursorPos(x, y + 2)
end


---Update the content of `window` in case it changed
---@param window GuiWindow
local function updateWindowContent(window)
	local style = window.style
	local windowBackground = style.windowBackground
	local windowForeground = style.windowForeground

	-- Setup titlebar - title
	local titlebar = window.hwndTitlebar
	titlebar.setBackgroundColor(style.titlebarBackground or windowBackground)
	titlebar.setTextColor(style.titlebarForeground or windowForeground)
	titlebar.setCursorPos(2, 1)
	titlebar.clearLine()
	titlebar.write(window.title)

	-- Setup titlebar - 'X' button
	if window.hasX then
		titlebar.setCursorPos(window.w - 3, 1)
		titlebar.setBackgroundColor(style.titlebarXBackground or windowBackground)
		titlebar.setTextColor(style.titlebarXForeground or windowForeground)
		titlebar.write(" X ")
	end

	-- Setup content
	local content = window.hwndContent
	content.setBackgroundColor(windowBackground)
	content.setTextColor(windowForeground)
	content.clear()
	content.setCursorPos(1, 2)

	-- Draw children, FIXME: use index to center vertically
	for index, child in ipairs(window.children) do
		child:draw()
	end
end

---Add a new `GuiWindowComponentButton` to `window`
---@param window GuiWindow
---@param text string
---@param onClick fun()
---@return GuiWindowComponentButton
local function addButton(window, text, onClick)
	---@type GuiWindowComponentButton
	local button = {
		['draw'] = drawButton,
		['onClick'] = onClick,
		['parent'] = window,
		['text'] = text
	}

	table.insert(window.children, button)
	window:updateContent()

	return button
end

---Add a new `GuiWindowComponentLabel` to `window`
---@param window GuiWindow
---@param text string
---@return GuiWindowComponentLabel
local function addLabel(window, text)
	---@type GuiWindowComponentLabel
	local label = {
		['draw'] = drawLabel,
		['parent'] = window,
		['text'] = text
	}

	table.insert(window.children, label)
	window:updateContent()

	return label
end


---Check if the given relative coords are where `window`s 'X' button is
---@param component GuiWindowComponent[]
---@param clickX integer
---@param clickY integer
---@return boolean
local function isClickOnWindowComponent(component, clickX, clickY)
	local endX = component.x + component.w - 1
	local endY = component.y + component.h - 1

	return clickX >= component.x and clickX <= endX
		and clickY >= component.y and clickY <= endY
end

---Check if the given relative coords are where `window`s 'X' button is
---@param window GuiWindow
---@param clickX integer
---@param clickY integer
---@return boolean
local function isClickOnWindowX(window, clickX, clickY)
	return window.hasX and clickY == 1 and clickX >= window.w - 3
end

---Handle click events
---@param window GuiWindow
---@return fun()
local function windowHandleClickEvents(window)
	return function()
		while not window.closeRequested do
			local event, btn, x, y = os.pullEvent("mouse_click")

			-- Ignore other events and non-left clicks
			if event == 'mouse_click' and btn == 1 then
				local relativeX, relativeY = x - window.x + 1, y - window.y + 1

				-- Check that it's in this window
				if relativeX >= 1 and relativeX <= window.w and relativeY >= 1 and relativeY <= window.h then
					-- Check the 'X' button
					if isClickOnWindowX(window, relativeX, relativeY) then
						window.closeRequested = true

						-- Check all children
					else
						for _, child in pairs(window.children) do
							-- Only one child can be clicked, and only click it if it listens for clicks
							if isClickOnWindowComponent(child, relativeX, relativeY) then
								if child.onClick then
									child.onClick()
								end
								break
							end
						end
					end
				end
			end
		end
	end
end

---Set `window.closeRequested = true` if a terminate was caught
---@param window GuiWindow
---@return fun()
local function windowHandleTerminateEvents(window)
	return function()
		os.waitForTerminate()
		window.closeRequested = true
	end
end

---Return when/if `window` was requested to be closed
---@param window GuiWindow
---@return fun()
local function windowWaitForCloseRequested(window)
	return function()
		while not window.closeRequested do
			coroutine.yield()
		end
	end
end

---Run `window`'s event loop on the current thread
---@param window GuiWindow
local function windowEventLoop(window)
	parallel.waitForAny(
		windowHandleClickEvents(window),
		windowHandleTerminateEvents(window),
		windowWaitForCloseRequested(window)
	)

	os.clear()
end


---Create a new window with the given `style`
---@param title string
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param style? WindowStyle
---@param hasX? boolean
---@return GuiWindow
function gui.createWindow(title, x, y, w, h, style, hasX)
	---@type GuiWindow
	local res = {
		['w'] = w,
		['h'] = h,
		['x'] = x,
		['y'] = y,
		['addButton'] = addButton,
		['addLabel'] = addLabel,
		['children'] = {},
		['closeRequested'] = false,
		['eventLoop'] = windowEventLoop,
		['hasX'] = hasX ~= false,
		['hwndContent'] = window.create(nativeTerm, x, y + 1, w, h - 1, true),
		['hwndTitlebar'] = window.create(nativeTerm, x, y, w, 1, true),
		['style'] = style or gui.defaultStyle,
		['title'] = title,
		['updateContent'] = updateWindowContent
	}
	res:updateContent()

	return res
end
