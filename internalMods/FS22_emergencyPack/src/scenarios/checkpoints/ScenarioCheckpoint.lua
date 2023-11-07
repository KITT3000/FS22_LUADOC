ScenarioCheckpoint = {}
local ScenarioCheckpoint_mt = Class(ScenarioCheckpoint)

function ScenarioCheckpoint.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#hint", "The hint text or i18n key")
	schema:register(XMLValueType.STRING, basePath .. "#actionClass", "The checkpoint classname")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "start")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "complete")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effects")
	ScenarioAction.registerXMLPaths(schema, basePath .. ".action")
end

function ScenarioCheckpoint.new(scenario, customMt)
	local self = setmetatable({}, customMt or ScenarioCheckpoint_mt)
	self.isServer = scenario.isServer
	self.isClient = scenario.isClient
	self.scenario = scenario
	self.isActive = false
	self.objectReferences = ObjectReferences.new()

	return self
end

function ScenarioCheckpoint:setId(id)
	self.id = id
end

function ScenarioCheckpoint:delete()
	g_soundManager:deleteSamples(self.samples)
	g_effectManager:deleteEffects(self.effects)

	if self:hasAction() then
		self.action:delete()
	end
end

function ScenarioCheckpoint:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isActive)

	if self:hasAction() then
		self.action:writeStream(streamId, connection)
	end
end

function ScenarioCheckpoint:readStream(streamId, connection)
	local isActive = streamReadBool(streamId)

	self:setIsActive(isActive)

	if self:hasAction() then
		self.action:readStream(streamId, connection)
	end
end

function ScenarioCheckpoint:writeUpdateStream(streamId, connection, dirtyMask)
	if self:hasAction() then
		self.action:writeUpdateStream(streamId, connection, dirtyMask)
	end
end

function ScenarioCheckpoint:readUpdateStream(streamId, timestamp, connection)
	if self:hasAction() then
		self.action:readUpdateStream(streamId, timestamp, connection)
	end
end

function ScenarioCheckpoint:update(dt)
	if self:hasAction() then
		self.action:onUpdate(dt)
	end
end

function ScenarioCheckpoint:start()
	assert(self.id ~= nil)
	g_messageCenter:subscribe(ScenarioMessageType.SCENARIO_CHECKPOINT_ACTION_CHANGED, self.onActionChanged, self)
	self:setIsActive(true)

	if self:hasAction() then
		self.action:onStart()
	end
end

function ScenarioCheckpoint:complete()
	assert(self.id ~= nil)
	g_messageCenter:unsubscribeAll(self)
	self:setIsActive(false)

	if self:hasAction() then
		self.action:onComplete()
	end
end

function ScenarioCheckpoint:setActionCompleted(isCompleted)
	if self.action ~= nil and self.action:isCompleted() ~= isCompleted then
		if self.isServer then
			g_messageCenter:publish(ScenarioMessageType.SCENARIO_CHECKPOINT_ACTION_CHANGED, self.id, isCompleted)
		else
			g_client:getServerConnection():sendEvent(ScenarioCheckPointActionEvent.new(self.id, isCompleted))
		end
	end
end

function ScenarioCheckpoint:onActionChanged(checkpointId, isCompleted)
	if checkpointId ~= self.id then
		return
	end

	local action = self.action

	if action ~= nil then
		action:setIsCompleted(isCompleted)
	end
end

function ScenarioCheckpoint:isCompleted()
	if self:hasAction() and self.action:canBeCompleted() and self.action:isCompleted() then
		return true
	end

	return false
end

function ScenarioCheckpoint:setIsActive(isActive)
	if isActive then
		if self.scenario:canShowHints() and self.hintText ~= nil then
			self.scenario.mission.hud:showInGameMessage(g_i18n:getText("info_hint_title"), self.hintText, -1)
		end

		g_soundManager:playSample(self.samples.start)
		g_soundManager:playSample(self.samples.start2d)
		g_effectManager:startEffects(self.effects)
	else
		g_soundManager:playSample(self.samples.complete)
		g_soundManager:playSample(self.samples.complete2d)
		g_effectManager:stopEffects(self.effects)
	end

	self.isActive = isActive

	if self:hasAction() then
		self.action:setIsActive(isActive)
	end
end

function ScenarioCheckpoint:hasAction()
	return self.action ~= nil
end

function ScenarioCheckpoint:getFarmId()
	return self.scenario.farmId
end

function ScenarioCheckpoint:getScenario()
	return self.scenario
end

function ScenarioCheckpoint:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	local hintText = xmlFile:getValue(baseKey .. "#hint")

	if hintText ~= nil then
		self.hintText = g_i18n:getText(hintText, self.scenario.customEnvironment)
	end

	local actionClassName = xmlFile:getValue(baseKey .. "#actionClass")

	if actionClassName ~= nil then
		self.action = self:loadAction(xmlFile, baseKey .. ".action", actionClassName, baseDirectory, rootNode)
	end

	self:loadObjectReferences(xmlFile, baseKey)

	self.samples = {
		start = g_soundManager:loadSampleFromXML(xmlFile, baseKey .. ".sounds", "start", baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil),
		start2d = g_soundManager:loadSample2DFromXML(xmlFile.handle, baseKey .. ".sounds", "start2d", baseDirectory, 1, AudioGroup.ENVIRONMENT),
		complete = g_soundManager:loadSampleFromXML(xmlFile, baseKey .. ".sounds", "complete", baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil),
		complete2d = g_soundManager:loadSample2DFromXML(xmlFile.handle, baseKey .. ".sounds", "complete2d", baseDirectory, 1, AudioGroup.ENVIRONMENT)
	}
	self.effects = g_effectManager:loadEffect(xmlFile, baseKey .. ".effects", rootNode, self, nil)

	return true
end

function ScenarioCheckpoint:loadAction(xmlFile, baseKey, actionClassName, baseDirectory, rootNode)
	local class = ClassExtension.getClassObject(actionClassName)

	if class == nil then
		Logging.xmlError(xmlFile, "Action class '%s' not defined", actionClassName)

		return nil
	end

	local action = class.new(self)

	if action:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode) then
		return action
	end

	return nil
end

function ScenarioCheckpoint:loadObjectReferences(xmlFile, baseKey)
	self.objectReferences:loadFromXML(xmlFile, baseKey)
end

function ScenarioCheckpoint:resolveObjectReferences(objectsById)
	self.objectReferences:resolve(objectsById)
end

function ScenarioCheckpoint:getObjectReferenceById(id)
	return self.objectReferences:getById(id)
end

function ScenarioCheckpoint:getObjectReferences()
	return self.objectReferences:getAll()
end

function ScenarioCheckpoint:getObjectReferencePhysics(node)
	return self.objectReferences:getPhysicsObjects(node)
end

function ScenarioCheckpoint:isInRangeOfNode(node)
	return self.scenario:isInRangeOfNode(node)
end
