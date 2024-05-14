max_line_length = false

exclude_files = {
}

ignore = {
	-- Ignore global writes/accesses/mutations on anything prefixed with "Musician".
	-- This is the standard prefix for all of our global frame names and mixins.
	"11./^Musician",

	-- Ignore unused self. This would popup for Mixins and Objects
	"212/self",

	-- Ignore unused event. This would popup for event handlers
	"212/event",

	-- Ignore Live play handler variables.
	"212/isChordNote",
	"212/layer",
}

globals = {
	"Musician",
	"MusicianEZK",

	-- Globals

	-- AddOn Overrides
}

read_globals = {
	-- Libraries
	"LibStub",

	"MSA_DropDownMenu_SetText",
	"MSA_DropDownMenu_CreateInfo",
	"MSA_DropDownMenu_AddButton",
	"MSA_DropDownMenu_Initialize",
	"MSA_DropDownMenu_EnableDropDown",
	"MSA_DropDownMenu_DisableDropDown",
	"MSA_DropDownMenu_SetWidth",

	-- 3rd party add-ons
}

std = "lua51+wow"

stds.wow = {
	-- Globals that we mutate.
	globals = {
	},

	-- Globals that we access.
	read_globals = {
		-- Lua function aliases and extensions
		"tAppendAll",
		"floor",
		"ceil",
		"min",
		"max",
		"wipe",

		-- Global Functions
		C_Timer = {
			fields = {
				"After",
			}
		},

		"hooksecurefunc",
		"securecall",
		"CreateFrame",
		"GetLocale",
		"PlaySound",
		"IsInGroup",
		"IsMouseButtonDown",
		"IsModifierKeyDown",
		"GameTooltip_SetTitle",
		"GetBindingFromClick",
		"InCombatLockdown",
		"ToggleFrame",
		"UISpecialFrames",
		"CloseSpecialWindows",
		"IsShiftKeyDown",

		-- Global Mixins and UI Objects
		GameTooltip = {
			fields = {
				"SetOwner",
				"Hide"
			}
		},

		"GameFontHighlight",
		"GameFontDisable",
		"UIParent",
		"WorldFrame",

		-- Global Constants
		"SOUNDKIT",
	},
}
