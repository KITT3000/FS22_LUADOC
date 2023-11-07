FireScenario = {}
local FireScenario_mt = Class(FireScenario, RolePlayScenario)

function FireScenario.registerXMLPaths(xmlSchema)
	FireObject.registerXMLPaths(xmlSchema, "scenario.fireObjects.fireObject(?)")
end

function FireScenario.new(customEnvironment, mission, messageCenter)
	return FireScenario:superClass().new(customEnvironment, mission, messageCenter, FireScenario_mt)
end

function FireScenario:delete()
	if self.fire ~= nil then
		self.fire:delete()
	end

	FireScenario:superClass().delete(self)
end

function FireScenario:onPlayerJoinWriteStream(streamId, connection)
	FireScenario:superClass().onPlayerJoinWriteStream(self, streamId, connection)
	self.fire:onPlayerJoinWriteStream(streamId, connection)
end

function FireScenario:writeStream(streamId, connection)
	FireScenario:superClass().writeStream(self, streamId, connection)
	self.fire:writeStream(streamId, connection)
end

function FireScenario:onPlayerJoinReadStream(streamId, connection)
	FireScenario:superClass().onPlayerJoinReadStream(self, streamId, connection)
	self.fire:onPlayerJoinReadStream(streamId, connection)
end

function FireScenario:readStream(streamId, connection)
	FireScenario:superClass().readStream(self, streamId, connection)
	self.fire:readStream(streamId, connection)
end

function FireScenario:onTargetPositionDetermined(x, y, z)
	FireScenario:superClass().onTargetPositionDetermined(self, x, y, z)
	self.fire:setRootNode(self.rootNode)
	self.fire:reset()

	if self.isServer and self.startStrategy:isa(StartStrategyField) then
		local fieldId = self.startStrategy:getActiveField()

		self.fire:init(fieldId)
	end
end

function FireScenario:isComplete()
	if self.targetPosition == nil then
		return false
	end

	if self.fire ~= nil and self.fire:hasActiveFires() then
		return false
	end

	return true
end

function FireScenario:onUpdate(dt)
	self.fire:update(dt)

	if self.isServer and self.scenarioCheckPoint ~= nil and self.scenarioCheckPoint:hasAction() and self.scenarioCheckPoint.action:isa(ScenarioHandToolAction) then
		local totalCheckPointsSteps = self.initialCheckPointsSteps + self.fire:getAmountOfActiveFires()
		local checkpointsStepsCompleted = self.checkpointsStepsCompleted + 1
		local completedOfActive = self.fire:getCompletedAmount()
		local progress = (checkpointsStepsCompleted + completedOfActive) / totalCheckPointsSteps

		if RolePlayScenario.PROGRESS_PRECISION < math.abs(self.progress - progress) then
			self:setProgress(progress)
			g_server:broadcastEvent(ScenarioCheckPointProgressEvent.new(self.scenarioCheckPoint.id, progress), false)
		end
	end

	FireScenario:superClass().onUpdate(self, dt)
end

function FireScenario:loadFromXML(xmlFile, baseKey)
	FireScenario:superClass().loadFromXML(self, xmlFile, baseKey)

	self.fire = AdaptiveFire.new(self.isServer, self.isClient, self.baseDirectory)

	self.fire:loadFromXML(xmlFile, baseKey)
end

function FireScenario:updateAffectedArea()
	local fieldId = self.startStrategy:getActiveField()
	local field = g_fieldManager:getFieldByIndex(fieldId)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local witheredState = fruitDesc.witheredState
	local fruitModifier, fruitPreparingModifier = g_fieldManager:getFruitModifier(fruitDesc)
	local state = witheredState

	if state == fruitDesc.preparedGrowthState then
		fruitModifier = fruitPreparingModifier
		state = 1
	end

	local x0, z0, x1, z1, x2, z2 = self.startStrategy:getParallelogramOfField(field)

	fruitModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	fruitModifier:executeSet(state)
end
