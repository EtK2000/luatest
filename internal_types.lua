---@meta
---This file is for types that are used internally in Albyno

-----------------------
--- Context Classes ---
-----------------------


---@class BootstrapContext
---@field public crypto Crypto The crypto lib downloaded from `cryptoLibraryUrl`
---@field public osPath string The path were the OS should be located
---@field public redownload boolean
---@field public repoPrefix string


---@class (exact) InstallerContext : BootstrapContext
---@field public cryptoLibraryUrl string The URL from which to download the crypto lib
---@field public defaultModules string[]
---@field public forceRedownloadFilePath string
---@field public installType InstallType
---@field public log fun(str: string, color?: ccTweaked.colors.color)
---@field public moduleDir string
---@field public redownload boolean Whether or not everything should be redownloaded
---@field public repoPrefix string
---@field public version {['installer']: InstallerVersionCatalog, ['latest']: InstallerVersionCatalog}
---@field public window GuiWindow


-------------------
--- Gui Classes ---
-------------------


---@class (exact) Gui
---@field public Button GuiButton
---@field public Checkbox GuiCheckbox
---@field public Label GuiLabel
---@field public TextField GuiTextField
---@field public Window GuiWindow
---@field public defaultStyle WindowStyle


---@class (exact) GuiButton : GuiWindowComponent
---@field private __index GuiButton
---@field public draw fun(self: GuiButton)
---@field public new fun(parent: GuiWindow, text: string, onClick?: fun()): GuiButton
---@field public text string


---@class (exact) GuiCheckbox : GuiWindowComponent
---@field private __index GuiCheckbox
---@field public checked boolean
---@field public draw fun(self: GuiCheckbox)
---@field public drawFocus fun(self: GuiCheckbox)
---@field public new fun(parent: GuiWindow, text: string, checked?: boolean): GuiCheckbox
---@field public onChange? fun() A handler to be run after `self.checked` changes
---@field public onKey fun(self: GuiCheckbox, key: integer)
---@field public text string


---@class (exact) GuiLabel : GuiWindowComponent
---@field private __index GuiLabel
---@field public draw fun(self: GuiLabel)
---@field public new fun(parent: GuiWindow, text: string): GuiLabel
---@field public text string


---@class (exact) GuiTextField : GuiWindowComponent
---@field private __index GuiTextField
---@field private displayText string
---@field public draw fun(self: GuiTextField)
---@field public drawFocus fun(self: GuiTextField)
---@field public new fun(parent: GuiWindow, placeholder?: string, secret?: boolean): GuiTextField
---@field public onChar fun(self: GuiTextField, char: string)
---@field public onChange? fun() A handler to be run after `self.text` changes
---@field public onKey fun(self: GuiTextField, key: integer)
---@field public maxCharacters integer
---@field public placeholder? string
---@field public text string
---@field public secret? true


---@class (exact) GuiWindow
---@field private __index GuiWindow
---@field private h integer
---@field private drawScrollIndicators fun(self: GuiWindow) Draw up/down arrow indicators when content is scrollable
---@field private getMaxScroll fun(self: GuiWindow): integer Get the maximum scroll offset
---@field private handleClickEvents fun(self: GuiWindow): fun() Wrapper for handling click events, returns the actual handler of `self:handleClickEventsInner`
---@field private handleClickEventsInner fun(self: GuiWindow) Handle click events inner function
---@field private handleTerminateEvents fun(self: GuiWindow): fun() Set `self.closeRequested = true` if a terminate was caught
---@field private isClickOnWindowX fun(self: GuiWindow, clickX: integer, clickY: integer): boolean Check if the given relative coords are where the 'X' button is
---@field private scrollOffset integer Number of rows scrolled down
---@field private scrollToFocus fun(self: GuiWindow) Adjust scroll offset to make the focused component visible
---@field private totalContentHeight integer Total virtual height of all content
---@field private visibleHeight integer Height of the content area
---@field private waitForCloseRequested fun(self: GuiWindow): fun() Return when/if close was requested
---@field private w integer
---@field private x integer
---@field private y integer
---@field public clearChildren fun(self: GuiWindow) Remove all children and redraw
---@field public children GuiWindowComponent[]
---@field public closeRequested boolean
---@field public eventLoop fun(self: GuiWindow) Run this window's event loop on the current thread
---@field public focus? GuiWindowComponent
---@field public hasX boolean
---@field public hwndContent Window
---@field public hwndTitlebar Window
---@field public new fun(title: string, x: integer, y: integer, w: integer, h: integer, style?: WindowStyle, hasX?: boolean): GuiWindow Create a new window with the given `style`
---@field public style WindowStyle
---@field public title string
---@field public updateContent fun(self: GuiWindow) Update and redraw the content in case it changed


---@class (exact) GuiWindowComponent
---@field private __index GuiWindowComponent
---@field protected h integer
---@field protected parent GuiWindow
---@field protected w integer
---@field protected x integer
---@field protected y integer
---@field draw fun(self: GuiWindowComponent)
---@field drawFocus? fun(self: GuiWindowComponent) Draw focus, run after all other components have been drawn
---@field enabled boolean
---@field onChar? fun(self: GuiWindowComponent, char: string) Handle a character being typed
---@field onClick? fun()
---@field onKey? fun(self: GuiWindowComponent, key: integer) Handle a key being pressed
---@field isFocusable fun(self: GuiWindowComponent): boolean
---@field isOver fun(self: GuiWindowComponent, x: integer, y: integer): boolean Checks whether or not a coordinate is over this component


---Note that any unset background field will default to `windowBackground`
---and any unset foreground field will default to `windowForeground`
---@class (exact) WindowStyle
---@field public buttonBackground? ccTweaked.colors.color
---@field public buttonForeground? ccTweaked.colors.color
---@field public buttonDisabledBackground? ccTweaked.colors.color
---@field public buttonDisabledForeground? ccTweaked.colors.color
---@field public checkboxBackground? ccTweaked.colors.color
---@field public checkboxBoxBackground? ccTweaked.colors.color
---@field public checkboxBoxDisabledBackground? ccTweaked.colors.color
---@field public checkboxBoxDisabledForeground? ccTweaked.colors.color
---@field public checkboxBoxForeground? ccTweaked.colors.color
---@field public checkboxDisabledBackground? ccTweaked.colors.color
---@field public checkboxDisabledForeground? ccTweaked.colors.color
---@field public checkboxForeground? ccTweaked.colors.color
---@field public labelBackground? ccTweaked.colors.color
---@field public labelForeground? ccTweaked.colors.color
---@field public textFieldBackground? ccTweaked.colors.color
---@field public textFieldForeground? ccTweaked.colors.color
---@field public textFieldDisabledBackground? ccTweaked.colors.color
---@field public textFieldDisabledForeground? ccTweaked.colors.color
---@field public textFieldPlaceholderForeground? ccTweaked.colors.color
---@field public titlebarBackground? ccTweaked.colors.color
---@field public titlebarForeground? ccTweaked.colors.color
---@field public titlebarXBackground? ccTweaked.colors.color
---@field public titlebarXForeground? ccTweaked.colors.color
---@field public windowBackground ccTweaked.colors.color
---@field public windowForeground ccTweaked.colors.color


-------------------------
--- Installer Classes ---
-------------------------


---@class (exact) InstallerVersionCatalog
---@field public core number


--------------------------
--- Repository Classes ---
--------------------------


---@class (exact) ModuleDefinition
---@field public dependencies? string[]
---@field public displayName? string
---@field public maxSupportedOsVersion? number
---@field public minSupportedOsVersion? number
---@field public name string
---@field public initFileUrl? string
---@field public isStandalone 0|1
---@field public isRequiredForRepository 0|1
---@field public version number


---@class (exact) Repo
---@field public loadRepo fun(repositoryUrl: string): Repository


---@class (exact) Repository
---@field public getModuleUrl fun(repository: Repository, mod: string): string
---@field public index RepositoryIndex
---@field public installModule fun(repository: Repository, mod: string, versionCatalogPath: string, installationPath: string)
---@field public uninstallModule fun(repository: Repository, mod: string, versionCatalogPath: string, installationPath: string)
---@field public url string


---@class (exact) RepositoryIndex
---@field public basepath string
---@field public moduleDefinitions {[string]: ModuleDefinition}


---------------------
--- Users Classes ---
---------------------


---@class users.User
---@field public authorize fun(password: string): boolean
---@field public name string
---@field public type users.UserType


---@class users.Localization
---@field public continue string
---@field public password string
---@field public title string
---@field public username string


-----------------------
--- Version Classes ---
-----------------------


---@class VersionCatalog
---@field public core number
---@field public modules {[string]: integer}

---@class Version
---@field public loadVersionCatalog fun(versionCatalogPath: string): VersionCatalog
---@field public saveVersionCatalog fun(versionCatalog: VersionCatalog, versionCatalogPath: string)
