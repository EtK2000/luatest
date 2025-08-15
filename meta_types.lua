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
---@field reposition fun(new_x: integer, new_y: integer, new_width?: integer, new_height?: integer, new_parent?: term.Redirect)
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
keys = {
	['space'] = 32,
	['apostrophe'] = 39,
	['comma'] = 44,
	['minus'] = 45,
	['period'] = 46,
	['slash'] = 47,
	['zero'] = 48,
	['one'] = 49,
	['two'] = 50,
	['three'] = 51,
	['four'] = 52,
	['five'] = 53,
	['six'] = 54,
	['seven'] = 55,
	['eight'] = 56,
	['nine'] = 57,
	['semicolon'] = 59,
	['equals'] = 61,
	['a'] = 65,
	['b'] = 66,
	['c'] = 67,
	['d'] = 68,
	['e'] = 69,
	['f'] = 70,
	['g'] = 71,
	['h'] = 72,
	['i'] = 73,
	['j'] = 74,
	['k'] = 75,
	['l'] = 76,
	['m'] = 77,
	['n'] = 78,
	['o'] = 79,
	['p'] = 80,
	['q'] = 81,
	['r'] = 82,
	['s'] = 83,
	['t'] = 84,
	['u'] = 85,
	['v'] = 86,
	['w'] = 87,
	['x'] = 88,
	['y'] = 89,
	['z'] = 90,
	['leftBracket'] = 91,
	['backslash'] = 92,
	['rightBracket'] = 93,
	['grave'] = 96,
	['world1'] = 161,
	['world2'] = 162,
	['enter'] = 257,
	['tab'] = 258,
	['backspace'] = 259,
	['insert'] = 260,
	['delete'] = 261,
	['right'] = 262,
	['left'] = 263,
	['down'] = 264,
	['up'] = 265,
	['pageUp'] = 266,
	['pageDown'] = 267,
	['home'] = 268,
	['end'] = 269,
	['capsLock'] = 280,
	['scrollLock'] = 281,
	['numLock'] = 282,
	['printScreen'] = 283,
	['pause'] = 284,
	['f1'] = 290,
	['f2'] = 291,
	['f3'] = 292,
	['f4'] = 293,
	['f5'] = 294,
	['f6'] = 295,
	['f7'] = 296,
	['f8'] = 297,
	['f9'] = 298,
	['f10'] = 299,
	['f11'] = 300,
	['f12'] = 301,
	['f13'] = 302,
	['f14'] = 303,
	['f15'] = 304,
	['f16'] = 305,
	['f17'] = 306,
	['f18'] = 307,
	['f19'] = 308,
	['f20'] = 309,
	['f21'] = 310,
	['f22'] = 311,
	['f23'] = 312,
	['f24'] = 313,
	['f25'] = 314,
	['numPad0'] = 320,
	['numPad1'] = 321,
	['numPad2'] = 322,
	['numPad3'] = 323,
	['numPad4'] = 324,
	['numPad5'] = 325,
	['numPad6'] = 326,
	['numPad7'] = 327,
	['numPad8'] = 328,
	['numPad9'] = 329,
	['numPadDecimal'] = 330,
	['numPadDivide'] = 331,
	['numPadMultiply'] = 332,
	['numPadSubtract'] = 333,
	['numPadAdd'] = 334,
	['numPadEnter'] = 335,
	['numPadEqual'] = 336,
	['leftShift'] = 340,
	['leftCtrl'] = 341,
	['leftAlt'] = 342,
	['leftSuper'] = 343,
	['rightShift'] = 344,
	['rightCtrl'] = 345,
	['rightAlt'] = 346,
	['menu'] = 348,
}
os = {
	---Loads an API into the global table.
	---@param path string
	---@return boolean
	['loadAPI'] = function(path) end,

	---Waits for an event to occur (doesn't terminate when Ctrl-T is pressed).
	---@param targetEvent? string
	---@return string, any ...
	['pullEventRaw'] = function(targetEvent) end,

	---Reboots the computer.
	['reboot'] = function() end,

	---Powers off the computer.
	['shutdown'] = function() end
}
parallel = {}
peripheral = {
	---Call a method on the peripheral with the given name.
	---@param name string The name of the peripheral to invoke the method on.
	---@param method string The name of the method
	---@param ... unknown Additional arguments to pass to the method
	---@return unknown
	['call'] = function(name, method, ...) end,

	---Find all peripherals of a specific type, and return the wrapped peripherals.
	---@param ty string The type of peripheral to look for.
	---@param filter? fun(name: string, wrapped: table):boolean A filter function, which takes the peripheral's name and wrapped table and returns if it should be included in the result.
	---@return table ...
	['find'] = function(ty, filter) end,

	---Get all available methods for the peripheral with the given name.
	---@param name string The name of the peripheral to find.
	---@return string?...
	['getMethods'] = function(name) end,

	---Get the name of a peripheral wrapped with `peripheral.wrap`.
	---@param peripheral table The peripheral to get the name of.
	---@return string
	['getName'] = function(peripheral) end,

	---Provides a list of all peripherals available.
	---@return string ...
	['getNames'] = function() end,

	---Get the types of a named or wrapped peripheral.
	---@param peripheral string|table The name of the peripheral to find, or a wrapped peripheral instance.
	---@return string?...
	['getType'] = function(peripheral) end,

	---@param peripheral string|table The name of the peripheral or a wrapped peripheral instance.
	---@param peripheral_type string The type to check.
	---@return boolean?
	['hasType'] = function(peripheral, peripheral_type) end,

	---Determines if a peripheral is present with the given name.
	---@param name string The side or network name that you want to check.
	---@return boolean
	['isPresent'] = function(name) end,

	---Get a table containing all functions available on a peripheral.
	---@param name string The name of the peripheral to wrap.
	---@return table?
	['wrap'] = function(name) end
}
shell = {}
term = {}
textutils = {}
window = {}


-----------------
--- Functions ---
-----------------


---Reads user input from the terminal.<br>
---This automatically handles arrow keys, pasting, character replacement, history scrollback, auto-completion, and default values.
---@param replaceChar? string A character to replace each typed character with. This can be used for hiding passwords, for example.
---@param history? table A table holding history items that can be scrolled back to with the up/down arrow keys.<br>The oldest item is at index 1, while the newest item is at the highest index.
---@param completeFn? fun(partial: string):string[]|nil A function to be used for completion.<br>This function should take the partial text typed so far, and returns a list of possible completion options.
---@param default? string Default text which should already be entered into the prompt.
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
