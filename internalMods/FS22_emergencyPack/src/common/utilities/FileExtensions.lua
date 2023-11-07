FileExtensions = {}
local modPrefix = "$emergencyPackDir"
local modPrefixLength = modPrefix:len() + 2

function FileExtensions.getFilename(filename, superFunc, baseDir)
	if filename == nil or not filename then
		printCallstack()

		return nil
	end

	if filename:find(modPrefix) then
		return g_currentMission.rolePlay.modDirectory .. filename:sub(modPrefixLength), false
	end

	return superFunc(filename, baseDir)
end
