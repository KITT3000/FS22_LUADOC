RolePlayVehicle = {
	MOD_NAME = g_currentModName,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Drivable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("RolePlayVehicle")
		schema:register(XMLValueType.STRING, "vehicle.emergencyVehicle#categories", "The vehicle categories it supports")
		schema:setXMLSpecializationType()
	end
}

function RolePlayVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsUsedByScenario", RolePlayVehicle.setIsUsedByScenario)
	SpecializationUtil.registerFunction(vehicleType, "isUsedByScenario", RolePlayVehicle.isUsedByScenario)
	SpecializationUtil.registerFunction(vehicleType, "hasRolePlayCategories", RolePlayVehicle.hasRolePlayCategories)
	SpecializationUtil.registerFunction(vehicleType, "getRolePlayCategories", RolePlayVehicle.getRolePlayCategories)
end

function RolePlayVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", RolePlayVehicle.getIsVehicleControlledByPlayer)
end

function RolePlayVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RolePlayVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", RolePlayVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RolePlayVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", RolePlayVehicle)
end

function RolePlayVehicle:onLoad(savegame)
	self.spec_rolePlayVehicle = self[("spec_%s.rolePlayVehicle"):format(RolePlayVehicle.MOD_NAME)]
	local spec = self.spec_rolePlayVehicle
	spec.isUsed = false
	spec.rolePlay = g_currentMission.rolePlay
	local categories = self.xmlFile:getValue("vehicle.emergencyVehicle#categories")
	spec.rolePlayCategories = string.split(categories, " ")
	spec.hasRolePlayCategories = #spec.rolePlayCategories ~= 0

	spec.rolePlay:addVehicle(self)
end

function RolePlayVehicle:getRolePlayCategories()
	local spec = self.spec_rolePlayVehicle

	return spec.rolePlayCategories
end

function RolePlayVehicle:hasRolePlayCategories()
	local spec = self.spec_rolePlayVehicle

	return spec.hasRolePlayCategories
end

function RolePlayVehicle:onDelete()
	local spec = self.spec_rolePlayVehicle

	spec.rolePlay:removeVehicle(self)
end

function RolePlayVehicle:onUpdate(dt)
	local spec = self.spec_rolePlayVehicle

	if self.isClient then
		local actionEvent = spec.actionEvents[InputAction.RP_TOGGLE]

		if actionEvent ~= nil then
			local isMultiplayer = g_currentMission.missionDynamicInfo.isMultiplayer

			if not isMultiplayer then
				local isScenarioRunning = self:isUsedByScenario() or spec.rolePlay:getRunningScenarioForFarm(self:getOwnerFarmId()) ~= nil
				local text = isScenarioRunning and "action_stopScenario" or "action_startScenario"

				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(text))
			end
		end
	end
end

function RolePlayVehicle:setIsUsedByScenario(isUsed)
	self.spec_rolePlayVehicle.isUsed = isUsed
end

function RolePlayVehicle:isUsedByScenario()
	return self.spec_rolePlayVehicle.isUsed
end

function RolePlayVehicle:getIsVehicleControlledByPlayer(superFunc)
	return superFunc(self)
end

function RolePlayVehicle:actionEventToggleScenario(actionName, inputValue, callbackState, isAnalog)
	local isMultiplayer = g_currentMission.missionDynamicInfo.isMultiplayer

	if isMultiplayer then
		return
	end

	local farmId = self:getOwnerFarmId()

	g_messageCenter:publish(ScenarioMessageType.SCENARIO_TOGGLE, farmId, "none")
end

function RolePlayVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_rolePlayVehicle

		self:clearActionEventsTable(spec.actionEvents)

		if self:getIsActiveForInput(true, true) then
			local binding = g_inputBinding
			local isMultiplayer = g_currentMission.missionDynamicInfo.isMultiplayer
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.RP_TOGGLE, self, RolePlayVehicle.actionEventToggleScenario, false, true, false, true, nil)
			local isScenarioRunning = self:isUsedByScenario() or spec.rolePlay:getRunningScenarioForFarm(self:getOwnerFarmId()) ~= nil
			local text = isScenarioRunning and "action_stopScenario" or "action_startScenario"

			binding:setActionEventText(actionEventId, g_i18n:getText(text))
			binding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			binding:setActionEventTextVisibility(actionEventId, not isMultiplayer)
			binding:setActionEventActive(actionEventId, not isMultiplayer)
		end
	end
end
