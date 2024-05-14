MusicianEZK = LibStub("AceAddon-3.0"):NewAddon("MusicianEZK", "AceEvent-3.0")

local MODULE_NAME = "EZK"
Musician.AddModule(MODULE_NAME)

local isInitialized = false

local MusicianGetCommands
local MusicianButtonGetMenu

--- OnEnable
--
function MusicianEZK:OnEnable()
	Musician.Utils.Debug(MODULE_NAME, 'MusicianEZK', 'OnInitialize')

	-- Init bindings names
	_G.BINDING_NAME_MUSICIANEZKTOGGLE = MusicianEZK.Msg.COMMAND_LIVE_KEYBOARD

	-- Incompatible Musician version
	if MusicianEZK.MUSICIAN_API_VERSION > (Musician.API_VERSION or 0) or
		MusicianDialogTemplateMixin.DisableEscape == nil
	then
		Musician.Utils.Error(MusicianEZK.Msg.ERROR_MUSICIAN_VERSION_TOO_OLD)
		Musician.Utils.PrintError(MusicianEZK.Msg.ERROR_MUSICIAN_VERSION_TOO_OLD)
		return
	elseif MusicianEZK.MUSICIAN_API_VERSION < Musician.API_VERSION then
		Musician.Utils.Error(MusicianEZK.Msg.ERROR_MUSICIAN_EZK_VERSION_TOO_OLD)
		Musician.Utils.PrintError(MusicianEZK.Msg.ERROR_MUSICIAN_EZK_VERSION_TOO_OLD)
		return
	end

	-- Initialize keyboard
	MusicianEZK.Keyboard.Init()

	-- Hook Musician functions
	MusicianButtonGetMenu = MusicianButton.GetMenu
	MusicianButton.GetMenu = MusicianEZK.GetMenu
	MusicianGetCommands = Musician.GetCommands
	Musician.GetCommands = MusicianEZK.GetCommands

	-- Initialization complete
	isInitialized = true
end

--- Indicates if the plugin is properly initialized
-- @return isInitialized (table)
function MusicianEZK.IsInitialized()
	return isInitialized
end

--- Initialize a locale and returns the initialized message table
-- @param languageCode (string) Short language code (ie 'en')
-- @param languageName (string) Locale name (ie "English")
-- @param localeCode (string) Long locale code (ie 'enUS')
-- @param[opt] ... (string) Additional locale codes
-- @return msg (table) Initialized message table
function MusicianEZK.InitLocale(languageCode, languageName, localeCode, ...)
	local localeCodes = { localeCode, ... }

	-- Set English (en) as base locale
	local baseLocale = languageCode == 'en' and MusicianEZK.LocaleBase or MusicianEZK.Locale.en

	-- Init table
	local msg = Musician.Utils.DeepCopy(baseLocale)
	MusicianEZK.Locale[languageCode] = msg
	msg.LOCALE_NAME = languageName
	msg.LOCALE_CODES = localeCodes

	-- Set English (en) as the current language by default
	if languageCode == 'en' then
		MusicianEZK.Msg = msg
	else
		-- Set localized messages
		for _, locale in pairs(localeCodes) do
			if GetLocale() == locale then
				MusicianEZK.Msg = msg
				break
			end
		end
	end

	return msg
end

--- Return main menu elements
-- @return menu (table)
function MusicianEZK.GetMenu()
	local menu = MusicianButtonGetMenu()

	-- Show easy keyboard
	for index, row in pairs(menu) do
		-- Insert after the standard "Show keyboard" option
		if row.text == Musician.Msg.MENU_SHOW_KEYBOARD then
			table.insert(menu, index + 1, {
				notCheckable = true,
				text = MusicianEZK.Msg.MENU_EASY_KEYBOARD,
				func = function()
					MusicianEZKKeyboard:Show()
				end
			})
		end
	end

	return menu
end

--- Get command definitions
-- @return commands (table)
function MusicianEZK.GetCommands()
	local commands = MusicianGetCommands()

	for index, command in pairs(commands) do
		if command.text == Musician.Msg.COMMAND_LIVE_KEYBOARD then
			table.insert(commands, index + 1, {
				command = { "ezk", "liveeasy", "easylive", "easykeyboard", "ezkeyboard" },
				text = MusicianEZK.Msg.COMMAND_LIVE_KEYBOARD,
				func = function()
					MusicianEZKKeyboard:Show()
				end
			})
			break
		end
	end

	return commands
end
