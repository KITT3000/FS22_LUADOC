ScenarioDirector = {
	TYPE_FIRE_SCENARIO = "fire",
	TYPE_TREE_SCENARIO = "tree"
}
local ScenarioDirector_mt = Class(ScenarioDirector)

function ScenarioDirector.registerXMLPaths(xmlSchema)
	RolePlayScenario.registerXMLPaths(xmlSchema)
	FireScenario.registerXMLPaths(xmlSchema)
	TreeScenario.registerXMLPaths(xmlSchema)
end

function ScenarioDirector.new(mission, messageCenter)
	local self = setmetatable({}, ScenarioDirector_mt)
	ScenarioDirector.xmlSchema = XMLSchema.new("ScenarioDirector")

	ScenarioDirector.registerXMLPaths(ScenarioDirector.xmlSchema)

	self.mission = mission
	self.messageCenter = messageCenter

	return self
end

function ScenarioDirector:delete()
end

function ScenarioDirector:makeForType(type, xmlFile, baseDirectory, modName)
	if type == ScenarioDirector.TYPE_FIRE_SCENARIO then
		return self:makeFire(xmlFile, baseDirectory, modName)
	elseif type == ScenarioDirector.TYPE_TREE_SCENARIO then
		return self:makeTree(xmlFile, baseDirectory, modName)
	end

	return self:makeDefaultScenario(xmlFile, baseDirectory, modName)
end

function ScenarioDirector:makeDefaultScenario(xmlFile, baseDirectory, modName)
	local scenario = RolePlayScenario.new(modName, self.mission, self.messageCenter)
	local builder = ScenarioBuilder.new(scenario)

	builder:withBaseDirectory(baseDirectory)
	builder:withXML(xmlFile)

	return builder:build()
end

function ScenarioDirector:makeFire(xmlFile, baseDirectory, modName)
	local scenario = FireScenario.new(modName, self.mission, self.messageCenter)
	local builder = ScenarioBuilder.new(scenario)

	builder:withBaseDirectory(baseDirectory)
	builder:withXML(xmlFile)

	return builder:build()
end

function ScenarioDirector:makeTree(xmlFile, baseDirectory, modName)
	local scenario = TreeScenario.new(modName, self.mission, self.messageCenter)
	local builder = ScenarioBuilder.new(scenario)

	builder:withBaseDirectory(baseDirectory)
	builder:withXML(xmlFile)

	return builder:build()
end
