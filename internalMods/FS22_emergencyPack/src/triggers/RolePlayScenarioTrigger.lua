RolePlayScenarioTrigger = {}
local rolePlayScenarioTrigger_mt = Class(RolePlayScenarioTrigger)

function RolePlayScenarioTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Trigger node")
end

function RolePlayScenarioTrigger.new(isServer, isClient, customMt)
	local self = {}

	setmetatable(self, customMt or rolePlayScenarioTrigger_mt)

	self.isServer = isServer
	self.isClient = isClient
	self.isEnabled = true
	self.activatable = RolePlayScenarioTriggerActivatable.new(self)

	g_messageCenter:subscribe(ScenarioMessageType.SCENARIO_TOGGLE, RolePlayScenarioTrigger.onStartStopScenario, self)

	return self
end

function RolePlayScenarioTrigger:loadFromXML(components, xmlFile, baseKey, i3dMappings)
	local triggerNode = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings)

	if triggerNode == nil then
		Logging.xmlError(xmlFile, "Missing triggerNode defined in '%s'", baseKey)

		return false
	end

	if self.isClient then
		self.triggerId = triggerNode

		addTrigger(triggerNode, "triggerCallback", self)
	end

	return true
end

function RolePlayScenarioTrigger:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)

		self.triggerId = nil
	end

	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

function RolePlayScenarioTrigger.deleteUnfinalized(components, xmlFile, baseKey, i3dMappings)
	local triggerNode = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings)

	if triggerNode ~= nil then
		removeTrigger(triggerNode)
	end
end

function RolePlayScenarioTrigger:getOwnerFarmId()
	if self.owningPlaceable == nil then
		return 0
	end

	return self.owningPlaceable:getOwnerFarmId()
end

function RolePlayScenarioTrigger:onStartStopScenario(start)
	self.activatable:updateActivatable()
end

function RolePlayScenarioTrigger:toggleScenario()
	local farmId = self:getOwnerFarmId()

	g_messageCenter:publish(ScenarioMessageType.SCENARIO_TOGGLE, farmId, "none", true)
end

function RolePlayScenarioTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end

		self.activatable:updateActivatable()
	end
end

RolePlayScenarioTriggerActivatable = {}
local rolePlayScenarioTriggerActivatable_mt = Class(RolePlayScenarioTriggerActivatable)

function RolePlayScenarioTriggerActivatable.new(rolePlayScenarioTrigger)
	local self = setmetatable({}, rolePlayScenarioTriggerActivatable_mt)
	self.rolePlayScenarioTrigger = rolePlayScenarioTrigger
	self.activateText = g_i18n:getText("action_startScenario", self.customEnvironment)

	return self
end

function RolePlayScenarioTriggerActivatable:getIsActivatable()
	if g_currentMission.rolePlay == nil then
		return false
	end

	return self.rolePlayScenarioTrigger.isEnabled and g_currentMission.controlPlayer and g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
end

function RolePlayScenarioTriggerActivatable:updateActivatable()
	if g_currentMission.rolePlay == nil then
		return
	end

	local isScenarioPlaying = g_currentMission.rolePlay:getRunningScenarioForFarm(self.rolePlayScenarioTrigger:getOwnerFarmId()) ~= nil
	self.activateText = g_i18n:getText(isScenarioPlaying and "action_stopScenario" or "action_startScenario", self.customEnvironment)
end

function RolePlayScenarioTriggerActivatable:run()
	self.rolePlayScenarioTrigger:toggleScenario()
	self:updateActivatable()
end
