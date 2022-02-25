ImeSimulator = {
	LAST_STRING = "",
	IS_CLOSED = false,
	IS_CANCELED = false
}

addConsoleCommand("gsImeSetLastString", "Sets the last IME string", "consoleCommandImeSimulatorSetLastString", ImeSimulator)
addConsoleCommand("gsImeClose", "Close IME with success", "consoleCommandImeSimulatorClose", ImeSimulator)
addConsoleCommand("gsImeCancel", "Close IME with cancel", "consoleCommandImeSimulatorCancel", ImeSimulator)

function ImeSimulator:consoleCommandImeSimulatorSetLastString(text)
	ImeSimulator.LAST_STRING = text

	return "Set last IME string: " .. text
end

function ImeSimulator:consoleCommandImeSimulatorClose()
	ImeSimulator.IS_CLOSED = true
	ImeSimulator.IS_CANCELED = false

	return "Closed IME"
end

function ImeSimulator:consoleCommandImeSimulatorCancel()
	ImeSimulator.IS_CLOSED = true
	ImeSimulator.IS_CANCELED = true

	return "Cancled IME"
end

function imeIsSupported()
	Logging.devInfo("Reporting IME as available")

	return true
end

function imeAbort()
	Logging.devInfo("IME aborted")
end

function imeOpen(text, title, description, placeholder, keyboardType, maxCharacters)
	if title == nil then
		Logging.devError("IME title must be set")
	end

	if description == nil then
		Logging.devError("IME description must be set")
	end

	if placeholder == nil then
		Logging.devError("IME placeholder must be set")
	end

	Logging.devInfo("Opened IME with text='%s'; title='%s'; description='%s'; placeholder='%s'; keyboardType='%s'; maxCharacters='%s'", text, title, description, placeholder, keyboardType, maxCharacters)

	ImeSimulator.LAST_STRING = text

	return true
end

function imeIsComplete()
	return ImeSimulator.IS_CLOSED, ImeSimulator.IS_CANCELED
end

function imeGetLastString()
	return ImeSimulator.LAST_STRING
end

local oldUpdate = update

function update(dt)
	oldUpdate(dt)

	ImeSimulator.IS_CLOSED = false
	ImeSimulator.IS_CANCELED = false
end
