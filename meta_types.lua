---@meta
---This file is only to supply ComputerCraft builtin types to IntelliSense
---in order to remove the "Undefined global `xxx`" warning message

---------------
--- Classes ---
---------------


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


---------------
--- Globals ---
---------------


---@enum colors
colors = {
	white     = 00000000000000001,
	orange    = 00000000000000010,
	magenta   = 00000000000000100,
	lightBlue = 00000000000001000,
	yellow    = 00000000000010000,
	lime      = 00000000000100000,
	pink      = 00000000001000000,
	gray      = 00000000010000000,
	lightGray = 00000000100000000,
	cyan      = 00000001000000000,
	purple    = 00000010000000000,
	blue      = 00000100000000000,
	brown     = 00001000000000000,
	green     = 00010000000000000,
	red       = 00100000000000000,
	black     = 01000000000000000
}
---@enum colours
colours = colors
fs = {}
http = {}
os = {
	['reboot'] = function() end
}
parallel = {}
shell = {}
term = {}
textutils = {}
window = {}


-----------------
--- Functions ---
-----------------


---Reads user input from the terminal.<br>
---This automatically handles arrow keys, pasting, character replacement, history scrollback, auto-completion, and default values.
---@param replaceChar string? A character to replace each typed character with. This can be used for hiding passwords, for example.
---@param history table? A table holding history items that can be scrolled back to with the up/down arrow keys.<br>The oldest item is at index 1, while the newest item is at the highest index.
---@param completeFn fun(partial: string):string[]|nil? A function to be used for completion.<br>This function should take the partial text typed so far, and returns a list of possible completion options.
---@param default string? Default text which should already be entered into the prompt.
---@return string string The text typed in.
function read(replaceChar, history, completeFn, default)
end

---Pauses execution for the specified number of seconds.<br>
---As it waits for a fixed amount of world ticks, time will automatically be rounded up to the nearest multiple of 0.05 seconds.<br>
---If you are using coroutines or the parallel API, it will only pause execution of the current thread, not the whole program.
---@see os.startTimer
---@param time number The number of seconds to sleep for, rounded up to the nearest multiple of 0.05.
function sleep(time)
end

---Writes a line of text to the screen without a newline at the end, wrapping text if necessary.
---@see print
---@param text string
---@return integer integer The number of lines written
function write(text)
end
