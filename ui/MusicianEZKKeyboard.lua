--- Live simplified keyboard window
-- @module MusicianEZK.Keyboard

MusicianEZK.Keyboard = LibStub("AceAddon-3.0"):NewAddon("MusicianEZK.Keyboard", "AceEvent-3.0")

local MODULE_NAME = "EasyKeyboard"
Musician.AddModule(MODULE_NAME)

local LAYER = Musician.KEYBOARD_LAYER

local KEY_SIZE = 60

local transpose = 0
local octave = 4
local instrument = 0
local noteShift = { 0, 0, 0, 0, 0, 0, 0, 0 }
local mode = "Ionian"
local noteButtons = {}

local mouseKeysDown = {}
local keyboardKeysDown = {}
local currentMouseKey = nil -- Current virtual keyboard button active by the mouse

--- Get the note that corresponds to provided key index
-- @param keyIndex (number)
-- @returns note (number) MIDI note number
local function getNoteAt(keyIndex)
	if keyIndex < 1 or keyIndex > 8 then return nil end
	return 12 + octave * 12 + transpose + MusicianEZK.MODES[mode][keyIndex] + noteShift[keyIndex]
end

--- Set keyboard keys (notes, color etc)
--
local function setKeys()
	local instrumentName = Musician.Sampler.GetInstrumentName(instrument)
	-- Base key color
	local rB, gB, bB = unpack(Musician.INSTRUMENTS[instrumentName].color)
	local isPercussion = instrument >= 128

	wipe(noteButtons)

	for keyIndex = 1, 10 do
		local r, g, b = rB, gB, bB
		local button = MusicianEZKKeyboard.ezKeyButtons[keyIndex]

		if keyIndex <= 8 then
			local noteKey = getNoteAt(keyIndex)
			noteButtons[noteKey] = button

			-- Ket key and note names
			local noteName = ""

			if noteKey >= Musician.MIN_KEY and noteKey <= Musician.MAX_KEY then
				noteName = Musician.Sampler.NoteName(noteKey)
				-- Black or white key
				if string.match(noteName, "[%#b]") then
					r = rB / 4
					g = gB / 4
					b = bB / 4
				end

				button.background:SetColorTexture(r, g, b, 1)
				button:Enable()
				button:SetAlpha(1)

				if isPercussion then
					button.tooltipText = Musician.Msg.MIDI_PERCUSSION_NAMES[noteKey]
				else
					button.tooltipText = nil
				end
			else
				button.background:SetColorTexture(0, 0, 0, 0)
				button:Disable()
				button:SetAlpha(.25)
				button.tooltipText = nil
			end

			if noteShift[keyIndex] ~= 0 then
				noteName = noteName .. "*"
			end

			button.subText:SetText(noteName)
			button.Text:SetTextColor(1, 1, 1, 1)
			button.subText:SetTextColor(1, 1, 1, 1)
		else
			button.background:SetColorTexture(1, 0, 0, 1)
			button.Text:SetTextColor(1, 1, 0, 1)
			button.subText:SetTextColor(1, 1, 0, 1)
			button.background:SetColorTexture(1, 0, 0, 1)
			button:Enable()
			button:SetAlpha(1)
			button.subText:SetText(keyIndex == 10 and MusicianEZK.Msg.OCTAVE_UP or MusicianEZK.Msg.OCTAVE_DOWN)
		end
	end
end

--- Init controls
local function initControls()
	local varNamePrefix = "MusicianEZKKeyboard"

	-- Instrument selector
	local instrumentSelector = _G[varNamePrefix .. "Instrument"]
	instrumentSelector.OnChange = function(i)
		Musician.Live.AllNotesOff(Musician.KEYBOARD_LAYER.UPPER)
		instrument = i
		setKeys()
	end

	instrumentSelector.SetValue(instrument)
	instrumentSelector.tooltipText = MusicianEZK.Msg.SELECT_INSTRUMENT

	-- Mode selector
	local modeSelector = _G[varNamePrefix .. "Mode"]
	local modes = { "Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian" }

	modeSelector.SetValue = function(value)
		for index, modeKey in pairs(modes) do
			if value == modeKey then
				modeSelector.SetIndex(index)
				return
			end
		end
	end

	modeSelector.SetIndex = function(index)
		modeSelector.index = index
		local modeKey = modes[index]
		Musician.Live.AllNotesOff(Musician.KEYBOARD_LAYER.UPPER)
		MSA_DropDownMenu_SetText(modeSelector, Musician.Msg.KEYBOARD_LAYOUTS[modeKey])
		mode = modeKey
		setKeys()
	end

	modeSelector.OnClick = function(self, arg1)
		modeSelector.SetValue(arg1)
	end

	modeSelector.GetItems = function()
		local info = MSA_DropDownMenu_CreateInfo()
		info.func = modeSelector.OnClick

		for index, modeKey in pairs(modes) do
			local label = Musician.Msg.KEYBOARD_LAYOUTS[modeKey]
			info.text = label
			info.arg1 = modeKey
			info.checked = modeSelector.index == index
			MSA_DropDownMenu_AddButton(info)
		end
	end

	MSA_DropDownMenu_Initialize(modeSelector, modeSelector.GetItems)
	modeSelector.SetValue(mode)

	-- Octave selector
	local octaveSelector = _G[varNamePrefix .. "Octave"]
	local octaveValues = { "+3", "+2", "+1", "0", "-1", "-2", "-3", "-4" }

	octaveSelector.SetValue = function(value)
		octaveSelector.SetIndex(8 - value)
	end

	octaveSelector.SetIndex = function(index)
		octaveSelector.index = index
		Musician.Live.AllNotesOff(Musician.KEYBOARD_LAYER.UPPER)
		octave = 8 - index
		MSA_DropDownMenu_SetText(octaveSelector, octaveValues[index])
		setKeys()
	end

	octaveSelector.OnClick = function(self, arg1)
		octaveSelector.SetIndex(arg1)
	end

	octaveSelector.GetItems = function()
		local info = MSA_DropDownMenu_CreateInfo()
		info.func = octaveSelector.OnClick

		for index, label in pairs(octaveValues) do
			info.text = label
			info.arg1 = index
			info.checked = octaveSelector.index == index
			MSA_DropDownMenu_AddButton(info)
		end
	end

	MSA_DropDownMenu_Initialize(octaveSelector, octaveSelector.GetItems)
	octaveSelector.SetValue(octave)

	-- Transpose selector
	local transposeSelector = _G[varNamePrefix .. "Transpose"]

	transposeSelector.SetValue = function(value)
		transposeSelector.SetIndex(value)
	end

	transposeSelector.SetIndex = function(index)
		transposeSelector.index = index
		Musician.Live.AllNotesOff(Musician.KEYBOARD_LAYER.UPPER)
		transpose = index
		MSA_DropDownMenu_SetText(transposeSelector, Musician.NOTE_NAMES[index])
		setKeys()
	end

	transposeSelector.OnClick = function(self, arg1)
		transposeSelector.SetIndex(arg1)
	end

	transposeSelector.GetItems = function()
		local info = MSA_DropDownMenu_CreateInfo()
		info.func = transposeSelector.OnClick

		for index = 0, 11, 1 do
			local label = Musician.NOTE_NAMES[index]
			info.text = label
			info.arg1 = index
			info.checked = transposeSelector.index == index
			MSA_DropDownMenu_AddButton(info)
		end
	end

	MSA_DropDownMenu_Initialize(transposeSelector, transposeSelector.GetItems)
	transposeSelector.SetValue(transpose)
end

--- Init keyboard
--
local function initKeyboard()
	local frame = MusicianEZKKeyboard
	local container = MusicianEZKKeyboard.ezKeys

	frame.ezKeyButtons = {}

	-- Create key buttons
	local previous = container
	for index, key in pairs(MusicianEZK.KEYS) do
		local button = CreateFrame('Button', 'MusicianEZKNoteButton' .. index, container, 'MusicianKeyboardKeyTemplate')
		button:SetPoint("LEFT", previous, previous == container and "LEFT" or "RIGHT")
		button:SetSize(KEY_SIZE, KEY_SIZE)
		button:SetText(key)
		button.glowColor:SetAlpha(0)
		button.glowColor:SetWidth(KEY_SIZE * 1.75)
		button.glowColor:SetHeight(KEY_SIZE * 1.75)
		previous = button
		button.key = key
		button.volumeMeter = Musician.VolumeMeter.create()
		frame.ezKeyButtons[index] = button
		-- Reference to existing methods is required by Musician.Keyboard.SetButtonState
		button.SuperOnMouseDown = button:GetScript('OnMouseDown')
		button.SuperOnMouseUp = button:GetScript('OnMouseUp')
		button:SetScript('OnMouseDown', MusicianEZK.Keyboard.OnVirtualKeyMouseDown)
		button:SetScript('OnMouseUp', MusicianEZK.Keyboard.OnVirtualKeyMouseUp)
		button:HookScript('OnEnter', MusicianEZK.Keyboard.OnVirtualKeyEnter)
		button:HookScript('OnLeave', MusicianEZK.Keyboard.OnVirtualKeyLeave)
		button:HookScript('OnUpdate', MusicianEZK.Keyboard.OnVirtualKeyUpdate)
		button:SetShown(true)
	end

	MusicianEZK.Keyboard:RegisterMessage(Musician.Events.LiveNoteOn, MusicianEZK.Keyboard.OnLiveNoteOn)
	MusicianEZK.Keyboard:RegisterMessage(Musician.Events.LiveNoteOff, MusicianEZK.Keyboard.OnLiveNoteOff)
end

--- OnFrame
-- @param event (string)
-- @param elapsed (boolean)
function MusicianEZK.Keyboard.OnFrame(event, elapsed)
	-- Key glow
	for _, button in pairs(MusicianEZKKeyboard.ezKeyButtons) do
		button.volumeMeter:AddElapsed(elapsed)
		button.glowColor:SetAlpha(button.volumeMeter:GetLevel() * 1)
	end
end

--- Initialize simplified keyboard
--
function MusicianEZK.Keyboard.Init()
	-- Set title
	MusicianEZKKeyboardTitle:SetText(MusicianEZK.Msg.EASY_KEYBOARD_TITLE)

	-- Instrument selector
	MusicianEZKKeyboard.instrumentLabel:SetText(Musician.Msg.HEADER_INSTRUMENT)
	MSA_DropDownMenu_SetWidth(MusicianEZKKeyboardInstrument, 165)

	-- Mode selector
	MusicianEZKKeyboard.modeLabel:SetText(MusicianEZK.Msg.HEADER_MODE)
	MSA_DropDownMenu_SetWidth(MusicianEZKKeyboardMode, 100)

	-- Octave selector
	MusicianEZKKeyboard.octaveLabel:SetText(MusicianEZK.Msg.HEADER_OCTAVE)
	MSA_DropDownMenu_SetWidth(MusicianEZKKeyboardOctave, 40)

	-- Transpose selector
	MusicianEZKKeyboard.transposeLabel:SetText(MusicianEZK.Msg.HEADER_TRANSPOSE)
	MSA_DropDownMenu_SetWidth(MusicianEZKKeyboardTranspose, 48)

	-- Init virtual keyboard
	initKeyboard()
	setKeys()

	-- Set scripts
	MusicianEZK.Keyboard:RegisterMessage(Musician.Events.Frame, MusicianEZK.Keyboard.OnFrame)
	MusicianEZKKeyboard:SetScript("OnKeyDown", MusicianEZK.Keyboard.OnPhysicalKeyDown)
	MusicianEZKKeyboard:SetScript("OnKeyUp", MusicianEZK.Keyboard.OnPhysicalKeyUp)

	-- Init controls
	initControls()

	-- Stop all notes and remove sustain when closing the window
	MusicianEZKKeyboard:HookScript("OnHide", function()
		MusicianEZK.Keyboard.ResetAllKeys()
		Musician.Live.SetSustain(false, Musician.KEYBOARD_LAYER.UPPER)
		Musician.Live.AllNotesOff(Musician.KEYBOARD_LAYER.UPPER)
	end)
end

--- OnPhysicalKeyDown
-- @param event (string)
-- @param keyValue (string)
function MusicianEZK.Keyboard.OnPhysicalKeyDown(event, keyValue)
	MusicianEZK.Keyboard.OnPhysicalKey(keyValue, true)
end

--- OnPhysicalKeyUp
-- @param event (string)
-- @param keyValue (string)
function MusicianEZK.Keyboard.OnPhysicalKeyUp(event, keyValue)
	MusicianEZK.Keyboard.OnPhysicalKey(keyValue, false)
end

--- Key up/down handler, from physical keyboard
-- @param keyValue (string)
-- @param down (boolean)
function MusicianEZK.Keyboard.OnPhysicalKey(keyValue, down)
	-- Escape key
	if down and keyValue == "ESCAPE" then
		-- Close special windows, if any
		for _, frameName in pairs(UISpecialFrames) do
			if _G[frameName] and _G[frameName]:IsShown() then
				securecall(CloseSpecialWindows)
				return true
			end
		end

		-- Hide main window
		MusicianKeyboard:MusicianEZKKeyboard()
		return true
	end

	-- Sustain (pedal)
	if keyValue == 'SPACE' and not IsModifierKeyDown() then
		MusicianEZK.Keyboard.SetSustain(down)
		return
	end

	-- Note on/note off
	if MusicianEZK.NOTE_KEYS[keyValue] ~= nil then
		MusicianEZK.Keyboard.OnKey(keyValue, down)
		return
	end

	-- Allow to use the simplified keyboard toggle binding to close it
	if down and GetBindingFromClick(keyValue) == "MUSICIANEZKTOGGLE" then
		MusicianEZKKeyboard:Toggle()
		return
	end

	-- Override standard Toggle UI to keep the keyboard visible on screen
	if down and GetBindingFromClick(keyValue) == "TOGGLEUI" and not InCombatLockdown() then
		ToggleFrame(UIParent)
		return true
	end
end

--- Key up/down handler, from virtual keyboard or physical key
-- @param keyValue (string)
-- @param down (boolean)
-- @param fromMouse (boolean) True when from virtual keyboard
function MusicianEZK.Keyboard.OnKey(keyValue, down, fromMouse)
	local keyIndex = MusicianEZK.NOTE_KEYS[keyValue]
	if keyIndex == nil then return end

	local button = MusicianEZKKeyboard.ezKeyButtons[keyIndex]
	if button == nil then return end

	local wasDown, wasUp
	if fromMouse then
		wasDown = not button.keyDown and button.mouseDown
		wasUp = not button.keyDown and not button.mouseDown
		button.mouseDown = down
	else
		wasDown = button.keyDown and not button.mouseDown
		wasUp = not button.keyDown and not button.mouseDown
		button.keyDown = down
	end

	if not down and wasDown or down and wasUp then
		MusicianEZK.Keyboard.SetVirtualKeyDown(keyIndex, down)
		MusicianEZK.Keyboard.SetNote(keyIndex, down)
	end
end

--- Virtual keyboard button mouse down handler
--
function MusicianEZK.Keyboard.OnVirtualKeyMouseDown()
	if currentMouseKey and IsMouseButtonDown() then
		MusicianEZK.Keyboard.OnKey(currentMouseKey, true, true)
	end
end

--- Virtual keyboard button mouse up handler
--
function MusicianEZK.Keyboard.OnVirtualKeyMouseUp()
	if currentMouseKey and not IsMouseButtonDown() then
		MusicianEZK.Keyboard.OnKey(currentMouseKey, false, true)
	end
end

--- Virtual keyboard button mouse enter handler
-- @param button (Button)
function MusicianEZK.Keyboard.OnVirtualKeyEnter(button)
	currentMouseKey = button.key
	if IsMouseButtonDown() then
		MusicianEZK.Keyboard.OnKey(button.key, true, true)
	end
end

--- Virtual keyboard button mouse leave handler
-- @param button (Button)
function MusicianEZK.Keyboard.OnVirtualKeyLeave(button)
	if currentMouseKey and IsMouseButtonDown() then
		MusicianEZK.Keyboard.OnKey(button.key, false, true)
	end
	currentMouseKey = nil
end

--- Virtual keyboard button on update
-- @param button (Button)
-- @param elapsed (number)
function MusicianEZK.Keyboard.OnVirtualKeyUpdate(button, elapsed)
	button.volumeMeter:AddElapsed(elapsed)
	local level = button.volumeMeter:GetLevel()
	button.glowColor:SetAlpha(level)
end

--- Reset all the keyboard keys
--
function MusicianEZK.Keyboard.ResetAllKeys()
	currentMouseKey = nil
	wipe(keyboardKeysDown)
	wipe(mouseKeysDown)
	for keyIndex, button in pairs(MusicianEZKKeyboard.ezKeyButtons) do
		MusicianEZK.Keyboard.SetVirtualKeyDown(keyIndex, false)
		-- Reset volume meter glow
		button.volumeMeter:Reset()
		button.glowColor:SetAlpha(0)
	end
end

--- Set note event
-- @param keyIndex (int) Easy keyboard key number
-- @param down (boolean)
function MusicianEZK.Keyboard.SetNote(keyIndex, down)
	-- Octave change
	if keyIndex == 9 and down and octave > 0 then
		MusicianEZKKeyboardOctave.SetValue(octave - 1)
	end

	if keyIndex == 10 and down and octave < 7 then
		MusicianEZKKeyboardOctave.SetValue(octave + 1)
	end

	-- Not a note
	if keyIndex < 1 or keyIndex > 8 then return end

	if IsShiftKeyDown() then
		-- Toggle note shift
		if down then
			MusicianEZK.Keyboard.ToggleShift(keyIndex)
		end
	else
		-- Play note

		-- Handle transposition
		local noteKey = getNoteAt(keyIndex)

		-- Send note event
		if down then
			Musician.Live.NoteOn(noteKey, LAYER.UPPER, instrument, false, MusicianEZK.Keyboard)
		else
			Musician.Live.NoteOff(noteKey, LAYER.UPPER, instrument)
		end
	end
end

--- Toggle note shift
-- @param keyIndex (int) Easy keyboard key number
function MusicianEZK.Keyboard.ToggleShift(keyIndex)
	if keyIndex >= 1 and keyIndex <= 8 then
		if noteShift[keyIndex] == 0 then
			-- Don't shift if the next note key will be the same
			if getNoteAt(keyIndex + 1) ~= getNoteAt(keyIndex) + 1 then
				noteShift[keyIndex] = 1
			end
		else
			-- Don't shift if the previous note key will be the same
			if getNoteAt(keyIndex - 1) ~= getNoteAt(keyIndex) - 1 then
				noteShift[keyIndex] = 0
			end
		end
		setKeys()
	end
end

--- Set key down on the virtual keyboard
-- @param keyIndex (int) Key index (0-9)
-- @param down (boolean)
function MusicianEZK.Keyboard.SetVirtualKeyDown(keyIndex, down)
	local button = MusicianEZKKeyboard.ezKeyButtons[keyIndex]
	Musician.Keyboard.SetButtonState(button, down)
end

--- OnLiveNoteOn
-- @param event (string)
-- @param key (number)
-- @param layer (number)
-- @param instrumentData (table)
-- @param isChordNote (boolean)
-- @param source (table)
function MusicianEZK.Keyboard.OnLiveNoteOn(event, key, layer, instrumentData, isChordNote, source)
	if source ~= MusicianEZK.Keyboard or instrumentData == nil then return end

	local button = noteButtons[key]
	if not button then
		return
	end

	-- Set glow color
	local r, g, b = unpack(Musician.INSTRUMENTS[Musician.Sampler.GetInstrumentName(instrumentData.midi)].color)
	local addedLuminance = .5
	r = min(1, r + addedLuminance)
	g = min(1, g + addedLuminance)
	b = min(1, b + addedLuminance)
	button.glowColor:SetColorTexture(r, g, b, 1)

	button.volumeMeter:NoteOn(instrumentData, key)
	button.volumeMeter.gain = isChordNote and .5 or 1 -- Make auto-chord notes dimmer
	button.volumeMeter.entropy = button.volumeMeter.entropy / 2
end

--- OnLiveNoteOff
-- @param event (string)
-- @param key (number)
-- @param layer (number)
-- @param isChordNote (boolean)
-- @param source (table)
function MusicianEZK.Keyboard.OnLiveNoteOff(event, key, layer, isChordNote, source)
	if source ~= MusicianEZK.Keyboard then return end

	local button = noteButtons[key]
	if not button then
		return
	end

	button.volumeMeter:NoteOff()
end

--- Set sustain
-- @param value (boolean)
function MusicianEZK.Keyboard.SetSustain(value)
	Musician.Live.SetSustain(value, LAYER.UPPER)
end

-- Widget templates
--

--- Simplified keyboard OnLoad
--
function MusicianEZKKeyboard_OnLoad(self)
	self:DisableEscape()
end

--- Piano key template OnLoad
--
function MusicianEZKPianoKeyTemplate_OnLoad(self)
	self.key = 0
	self.isFirst = false
	self.isLast = true
	self.down = false

	-- Keep the live keyboard visible when the UI is hidden

	UIParent:HookScript("OnHide", function()
		MusicianEZKKeyboard:SetParent(WorldFrame)
		MusicianEZKKeyboard:SetScale(UIParent:GetScale())
	end)
	UIParent:HookScript("OnShow", function()
		MusicianEZKKeyboard:SetParent(UIParent)
		MusicianEZKKeyboard:SetScale(1)
		MusicianEZKKeyboard:SetFrameStrata("DIALOG")
	end)
	self:SetScript("OnShow", function()
		if self:GetParent() == WorldFrame then
			self:SetScale(UIParent:GetScale())
		else
			self:SetScale(1)
		end
	end)
end
