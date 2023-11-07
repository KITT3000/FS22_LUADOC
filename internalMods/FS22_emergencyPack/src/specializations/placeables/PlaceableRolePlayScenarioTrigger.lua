PlaceableRolePlayScenarioTrigger = {
	MOD_NAME = g_currentModName,
	registerXMLPaths = function (schema, basePath)
		schema:setXMLSpecializationType("RolePlayScenarioTrigger")
		RolePlayScenarioTrigger.registerXMLPaths(schema, basePath .. ".rolePlayScenario.trigger")
		schema:setXMLSpecializationType()
	end,
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEventListeners = function (placeableType)
		SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableRolePlayScenarioTrigger)
		SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableRolePlayScenarioTrigger)
	end
}

function PlaceableRolePlayScenarioTrigger:onLoad(savegame)
	self.spec_rolePlayScenarioTrigger = self[("spec_%s.rolePlayScenarioTrigger"):format(PlaceableRolePlayScenarioTrigger.MOD_NAME)]
	local spec = self.spec_rolePlayScenarioTrigger
	spec.scenarioTrigger = RolePlayScenarioTrigger.new(self.isServer, self.isClient)

	spec.scenarioTrigger:loadFromXML(self.components, self.xmlFile, "placeable.rolePlayScenario.trigger", self.i3dMappings)

	spec.scenarioTrigger.owningPlaceable = self
end

function PlaceableRolePlayScenarioTrigger:onDelete()
	local spec = self.spec_rolePlayScnearioTrigger

	if spec ~= nil and spec.scenarioTrigger ~= nil then
		spec.scenarioTrigger:delete()
	elseif self.xmlFile ~= nil then
		RolePlayScenarioTrigger.deleteUnfinalized(self.components, self.xmlFile, "placeable.rolePlayScenario.trigger", self.i3dMappings)
	end
end
