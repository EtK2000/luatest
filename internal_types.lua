---@meta
---This file is for types that are used internally in Albyno

-----------------------
--- Context Classes ---
-----------------------


---@class BootstrapContext
---@field redownload boolean
---@field repoPrefix string


---@class (exact) InstallerContext : BootstrapContext
---@field public crypto Crypto The crypto lib downloaded from `cryptoLibraryUrl`
---@field public cryptoLibraryUrl string The URL from which to download the crypto lib
---@field public forceRedownloadFilePath string
---@field public installType InstallType
---@field public log fun(str: string, color: colors?)
---@field public osPath string The path were the OS should be located
---@field public redownload boolean Whether or not everything should be redownloaded
---@field public repoPrefix string
---@field public version {['installer']: InstallerVersionCatalog, ['latest']: InstallerVersionCatalog}
---@field public window GuiWindow


-------------------
--- Gui Classes ---
-------------------


---@class (exact) Gui
---@field Button GuiButton
---@field Label GuiLabel
---@field TextField GuiTextField
---@field Window GuiWindow
---@field defaultStyle WindowStyle


---@class (exact) GuiWindow
---@field private __index GuiWindow
---@field private isClickOnWindowX fun(self: GuiWindow, clickX: integer, clickY: integer): boolean Check if the given relative coords are where the 'X' button is
---@field private w integer
---@field private h integer
---@field private x integer
---@field private y integer
---@field clearChildren fun(self: GuiWindow) Remove all children and redraw
---@field children GuiWindowComponent[]
---@field closeRequested boolean
---@field eventLoop fun(self: GuiWindow) Run this window's event loop on the current thread
---@field focus GuiWindowComponent?
---@field handleClickEvents fun(self: GuiWindow): fun() Handle click events
---@field handleTerminateEvents fun(self: GuiWindow): fun() Set `self.closeRequested = true` if a terminate was caught
---@field hasX boolean
---@field hwndContent Window
---@field hwndTitlebar Window
---@field new fun(title: string, x: integer, y: integer, w: integer, h: integer, style: WindowStyle?, hasX: boolean?): GuiWindow Create a new window with the given `style`
---@field style WindowStyle
---@field title string
---@field updateContent fun(self: GuiWindow) Update and redraw the content in case it changed
---@field waitForCloseRequested fun(self: GuiWindow): fun() Return when/if close was requested


---@class (exact) GuiWindowComponent
---@field private __index GuiWindowComponent
---@field protected parent GuiWindow
---@field protected w integer
---@field protected h integer
---@field protected x integer
---@field protected y integer
---@field draw fun(self: GuiWindowComponent)
---@field drawFocus fun(self: GuiWindowComponent)? Draw focus, run after all other components have been drawn
---@field enabled boolean
---@field onChar fun(self: GuiWindowComponent, char: string)? Handle a character being typed
---@field onClick fun()?
---@field onKey fun(self: GuiWindowComponent, key: integer)? Handle a key being pressed
---@field isOver fun(self: GuiWindowComponent, x: integer, y: integer): boolean Checks whether or not a coordinate is over this component


---@class (exact) GuiButton : GuiWindowComponent
---@field private __index GuiButton
---@field draw fun(self: GuiButton)
---@field new fun(parent: GuiWindow, text: string, onClick: fun()?): GuiButton
---@field text string


---@class (exact) GuiLabel : GuiWindowComponent
---@field private __index GuiLabel
---@field draw fun(self: GuiLabel)
---@field new fun(parent: GuiWindow, text: string): GuiLabel
---@field text string


---@class (exact) GuiTextField : GuiWindowComponent
---@field private __index GuiTextField
---@field private displayText string
---@field draw fun(self: GuiTextField)
---@field drawFocus fun(self: GuiTextField)
---@field new fun(parent: GuiWindow, placeholder: string?, secret: boolean?): GuiTextField
---@field onChar fun(self: GuiTextField, char: string)
---@field onChange fun()? A handler to be run after `self.text` changes
---@field onKey fun(self: GuiTextField, key: integer)
---@field maxCharacters integer
---@field placeholder string?
---@field text string
---@field secret true?


---Note that any unset background field will default to `windowBackground`
---and any unset foreground field will default to `windowForeground`
---@class (exact) WindowStyle
---@field buttonBackground colors?
---@field buttonForeground colors?
---@field buttonDisabledBackground colors?
---@field buttonDisabledForeground colors?
---@field labelBackground colors?
---@field labelForeground colors?
---@field textFieldBackground colors?
---@field textFieldForeground colors?
---@field textFieldDisabledBackground colors?
---@field textFieldDisabledForeground colors?
---@field textFieldPlaceholderForeground colors?
---@field titlebarBackground colors?
---@field titlebarForeground colors?
---@field titlebarXBackground colors?
---@field titlebarXForeground colors?
---@field windowBackground colors
---@field windowForeground colors


-------------------------
--- Installer Classes ---
-------------------------


---@class (exact) InstallerVersionCatalog
---@field public core number


--------------------------
--- Repository Classes ---
--------------------------


---@class (exact) ModuleDefinition
---@field dependencies string[]?
---@field displayName string?
---@field maxSupportedOsVersion number?
---@field minSupportedOsVersion number?
---@field name string
---@field initFileUrl string?
---@field isStandalone 0|1
---@field isRequiredForRepository 0|1
---@field version number


---@class (exact) Repo
---@field loadRepo fun(repositoryUrl: string): Repository


---@class (exact) Repository
---@field getModuleUrl fun(repository: Repository, mod: string): string
---@field index RepositoryIndex
---@field installModule fun(repository: Repository, mod: string, versionCatalogPath: string, installationPath: string)
---@field uninstallModule fun(repository: Repository, mod: string, versionCatalogPath: string, installationPath: string)
---@field url string


---@class (exact) RepositoryIndex
---@field basepath string
---@field moduleDefinitions ModuleDefinition[]
