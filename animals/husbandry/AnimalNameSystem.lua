AnimalNameSystem = {}
local AnimalNameSystem_mt = Class(AnimalNameSystem)

function AnimalNameSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or AnimalNameSystem_mt)
	self.mission = mission
	self.names = {}

	return self
end

function AnimalNameSystem:delete()
end

function AnimalNameSystem:loadMapData(xmlFile, missionInfo)
	local filename = getXMLString(xmlFile, "map.animals.names#filename")

	if filename == nil or filename == "" then
		Logging.xmlInfo(xmlFile, "No animals names xml given at 'map.animals.names#filename'")

		return false
	end

	filename = Utils.getFilename(filename, self.mission.baseDirectory)
	local xmlFileNames = XMLFile.load("animalNames", filename)

	if xmlFileNames ~= nil then
		xmlFileNames:iterate("animalNames.name", function (_, key)
			local name = xmlFileNames:getString(key .. "#value")

			if name == nil then
				Logging.xmlError(xmlFileNames, "Missing name for '%s'", key)

				return false
			end

			name = g_i18n:convertText(name, missionInfo.customEnvironment)

			table.insert(self.names, name)
		end)
		xmlFileNames:delete()

		return #self.names > 0
	end

	return false
end

function AnimalNameSystem:getRandomName()
	local numNames = #self.names

	if numNames == 0 then
		return ""
	end

	local index = math.random(1, numNames)

	return self.names[index]
end
