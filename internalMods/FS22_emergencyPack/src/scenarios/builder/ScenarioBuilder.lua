ScenarioBuilder = {}
local ScenarioBuilder_mt = Class(ScenarioBuilder)

function ScenarioBuilder.new(scenario)
	local self = {
		scenario = scenario
	}

	return setmetatable(self, ScenarioBuilder_mt)
end

function ScenarioBuilder:delete()
	self.scenario:delete()
end

function ScenarioBuilder:withBaseDirectory(directory)
	self.scenario:setBaseDirectory(directory)

	return self
end

function ScenarioBuilder:withXML(xmlFile)
	self.scenario:loadFromXML(xmlFile, "scenario")

	return self
end

function ScenarioBuilder:build()
	return self.scenario
end
