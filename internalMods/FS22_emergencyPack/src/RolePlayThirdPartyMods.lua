RolePlayThirdPartyMods = {}
local RolePlayThirdPartyMods_mt = Class(RolePlayThirdPartyMods)

function RolePlayThirdPartyMods.new(modManager, modDirectory, mission)
	local self = setmetatable({}, RolePlayThirdPartyMods_mt)
	self.modManager = modManager
	self.modDirectory = modDirectory
	self.mission = mission
	self.minAPIVersion = 1
	self.maxAPIVersion = 1
	self.mods = {}
	self.scenarioDirectories = {}

	return self
end

function RolePlayThirdPartyMods:delete()
end

function RolePlayThirdPartyMods:load()
	local mods = self.modManager:getActiveMods()

	for _, mod in ipairs(mods) do
		local xmlFile = XMLFile.load("ModDesc", mod.modFile)

		if xmlFile then
			self:loadMod(mod, xmlFile)
			xmlFile:delete()
		end
	end
end

function RolePlayThirdPartyMods:loadMod(mod, xmlFile)
	local version = xmlFile:getInt("modDesc.emergencyPack#version")

	if version == nil then
		return
	end

	if self.maxAPIVersion < version or version < self.minAPIVersion then
		Logging.warning("Mod '" .. mod.title .. "' is not compatible with the current version of Emergency Pack. Skipping.")

		return
	end

	local modInfo = {
		mod = mod
	}
	local scenarioDirectory = xmlFile:getString("modDesc.emergencyPack.scenarioDirectory")

	if scenarioDirectory ~= nil then
		modInfo.scenarioDirectory = Utils.getFilename(scenarioDirectory, mod.modDir)

		self:addScenarioDirectory(modInfo.scenarioDirectory, mod.modDir)
	end

	table.insert(self.mods, modInfo)
end

function RolePlayThirdPartyMods:getMods()
	return self.mods
end

function RolePlayThirdPartyMods:addScenarioDirectory(path, modDir)
	table.insert(self.scenarioDirectories, {
		path = path,
		modDir = modDir
	})
end

function RolePlayThirdPartyMods:getScenarioDirectories()
	return self.scenarioDirectories
end

function RolePlayThirdPartyMods:getScenarioPaths(filename)
	local paths = {}

	if self.mission.missionInfo.map ~= nil then
		local path = Utils.getFilename("emergencyPack" .. filename, self.mission.missionInfo.baseDirectory)

		if fileExists(path) then
			table.insert(paths, {
				file = path,
				modDir = self.mission.missionInfo.baseDirectory
			})
		end
	end

	for _, dir in ipairs(self.scenarioDirectories) do
		local path = Utils.getFilename(filename, dir.path)

		if fileExists(path) then
			table.insert(paths, {
				file = path,
				modDir = dir.modDir
			})
		end
	end

	return paths
end
