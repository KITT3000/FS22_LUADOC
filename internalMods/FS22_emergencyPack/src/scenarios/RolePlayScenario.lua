RolePlayScenario = {
	REWARD_BASE_AMOUNT = 500,
	REWARD_BASE_TIME = 150000,
	REWARD_MAX_DIFFICULTY_CATEGORY = 3,
	REWARD_MAX_TEE_SIZE_CATEGORY = 6,
	MINIMAL_ENGAGEMENT_DISTANCE = 10,
	PROGRESS_PRECISION = 0.005
}
local RolePlayScenario_mt = Class(RolePlayScenario)

function RolePlayScenario.registerXMLPaths(xmlSchema)
	ScenarioCheckpoint.registerXMLPaths(xmlSchema, "scenario.checkpoints.checkpoint(?)")
	ScenarioNode.registerXMLPaths(xmlSchema, "scenario.objects.object(?)")
end

function RolePlayScenario.new(customEnvironment, mission, messageCenter, customMt)
	local self = setmetatable({}, customMt or RolePlayScenario_mt)
	self.customEnvironment = customEnvironment
	self.mission = mission
	self.messageCenter = messageCenter
	self.isServer = mission:getIsServer()
	self.isClient = mission:getIsClient()
	self.startStrategyDirector = StartStrategyDirector.new()
	self.baseDirectory = nil
	self.rootNode = 0
	self.objects = {}
	self.objectsById = {}
	self.checkpoints = {}
	self.showHints = mission.helpTriggersAreVisible
	self.engagementDistance = RolePlayScenario.MINIMAL_ENGAGEMENT_DISTANCE
	self.checkpointsStepsCompleted = 0
	self.initialCheckPointsSteps = 0
	self.totalCheckPointsSteps = 0
	self.time = 0

	self:loadHotspot()
	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_CHECKPOINT_CHANGED, self.startCompleteScenarioInternal, self)
	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_CHECKPOINT_PROGRESS, self.onScenarioProgressChanged, self)
	self.messageCenter:subscribe(ScenarioMessageType.OBJECT_PLACED, self.onObjectPlaced, self)
	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_POSITION_DETERMINED, self.onTargetPositionDetermined, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_TRIGGER], self.setShowHints, self)
	self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)

	return self
end

function RolePlayScenario:delete()
	self.messageCenter:unsubscribeAll(self)
	self.startStrategyDirector:delete()
	self.startStrategy:delete()
	self:deleteHotspot()
	self.mission.hud.gameInfoDisplay:setTutorialVisible(false)
	self.mission.aiSystem:removeObstacle(self.rootNode)

	for _, checkpoint in ipairs(self.checkpoints) do
		checkpoint:delete()
	end

	for _, object in ipairs(self.objects) do
		object:delete()
	end

	delete(self.rootNode)
end

function RolePlayScenario:writeStream(streamId, connection)
end

function RolePlayScenario:onPlayerJoinWriteStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.targetPosition ~= nil)

		if self.targetPosition ~= nil then
			local x, y, z = unpack(self.targetPosition)

			streamWriteFloat32(streamId, x)
			streamWriteFloat32(streamId, y)
			streamWriteFloat32(streamId, z)
		end

		for _, checkpoint in ipairs(self.checkpoints) do
			checkpoint:writeStream(streamId, connection)
		end

		streamWriteInt32(streamId, self.checkpointsStepsCompleted)
	end
end

function RolePlayScenario:readStream(streamId, connection)
end

function RolePlayScenario:onPlayerJoinReadStream(streamId, connection)
	if connection:getIsServer() then
		local hasTargetPosition = streamReadBool(streamId)

		if hasTargetPosition then
			local x = streamReadFloat32(streamId)
			local y = streamReadFloat32(streamId)
			local z = streamReadFloat32(streamId)

			self:onTargetPositionDetermined(x, y, z)
		end

		for _, checkpoint in ipairs(self.checkpoints) do
			checkpoint:readStream(streamId, connection)
		end

		self.checkpointsStepsCompleted = streamReadInt32(streamId)

		self:setProgress(self.checkpointsStepsCompleted / self.totalCheckPointsSteps)
		self:onPlayerFarmChanged(self.mission.player)
	end
end

function RolePlayScenario:setBaseDirectory(directory)
	self.baseDirectory = directory
end

function RolePlayScenario:setShowHints(showHints)
	self.showHints = showHints
end

function RolePlayScenario:canShowHints()
	return self.showHints and self:isPlayerOfScenario() and not g_gui:getIsGuiVisible()
end

function RolePlayScenario:isPlayerOfScenario()
	return self.mission.player.farmId == self.farmId
end

function RolePlayScenario:onPlayerFarmChanged(player)
	if self:isPlayerOfScenario() then
		local hasStarted = self.targetPosition ~= nil

		self:setProgressVisibility(hasStarted)
		self:updateMarker(hasStarted, self.targetPosition)
	else
		self:setProgressVisibility(false)
		self:updateMarker(false)
	end
end

function RolePlayScenario:canStart()
	local canBeUsed, reason = self.startStrategy:canBeUsed()

	if not canBeUsed then
		self.abortedReason = reason

		return false
	end

	return self.targetPosition ~= nil
end

function RolePlayScenario:beforeStart()
	if self.isServer then
		local canBeUsed = self.startStrategy:canBeUsed()

		if not canBeUsed then
			return
		end

		self.targetPosition = self.startStrategy:getPosition()

		if self.targetPosition == nil then
			return
		end

		self.scenarioCheckPointQueue = self:getCheckPointQueue()
		self.scenarioCheckPoint = self.scenarioCheckPointQueue:pop()
		local x, y, z = unpack(self.targetPosition)

		self:onTargetPositionDetermined(x, y, z)
		g_server:broadcastEvent(ScenarioTargetPositionEvent.new(x, y, z), false)
	end

	if self:isPlayerOfScenario() then
		self:setProgressVisibility(true)
	end

	self:setProgress(self.checkpointsStepsCompleted)
end

function RolePlayScenario:start()
	self:beforeStart()
	self:onStart()
	self:afterStart()
end

function RolePlayScenario:onStart()
	if self.isServer then
		self:startScenario(self.scenarioCheckPoint)
	end
end

function RolePlayScenario:afterStart()
end

function RolePlayScenario:onTargetPositionDetermined(x, y, z)
	self.targetPosition = {
		x,
		y,
		z
	}

	setWorldTranslation(self.rootNode, x, y, z)

	if self:isPlayerOfScenario() then
		self:updateMarker(true, self.targetPosition)
	end

	local offset = 0
	local size = 15

	if self.isServer then
		self.mission.aiSystem:addObstacle(self.rootNode, offset, offset, offset, size, size, size)
		self.mission.aiSystem:setObstacleIsPassable(self.rootNode, false)
	end

	self:updateObjectsPosition(x, y, z)
end

function RolePlayScenario:update(dt)
	self.time = self.time + dt

	self:onUpdate(dt)
end

function RolePlayScenario:onUpdate(dt)
	if self.scenarioCheckPointId ~= nil then
		local checkpoint = self:getCheckPointById(self.scenarioCheckPointId)

		checkpoint:update(dt)
	end

	if not self.isServer then
		return
	end

	if self.scenarioCheckPoint ~= nil and self.scenarioCheckPoint:isCompleted() then
		self:completeScenario(self.scenarioCheckPoint)

		local nextCheckPoint = self.scenarioCheckPointQueue:pop()

		if nextCheckPoint ~= nil then
			self:startScenario(nextCheckPoint)
		end

		self.scenarioCheckPoint = nextCheckPoint
	end
end

function RolePlayScenario:setProgressVisibility(isVisible)
	if isVisible and not self:isPlayerOfScenario() then
		isVisible = false
	end

	self.mission.hud.gameInfoDisplay:setTutorialVisible(isVisible)
end

function RolePlayScenario:setProgress(progress)
	self.progress = progress

	self.mission.hud.gameInfoDisplay:setTutorialProgress(progress)
end

function RolePlayScenario:isComplete()
	if self.targetPosition == nil then
		return false
	end

	if self.scenarioCheckPoint == nil then
		return true
	end

	return false
end

function RolePlayScenario:beforeComplete()
end

function RolePlayScenario:complete()
	self:beforeComplete()
	self:onComplete()
	self:afterComplete()
end

function RolePlayScenario:onComplete()
	if self.isServer then
		if self.scenarioCheckPoint ~= nil then
			self:completeScenario(self.scenarioCheckPoint)
		end

		self.mission.aiSystem:removeObstacle(self.rootNode)
	end
end

function RolePlayScenario:afterComplete()
	self:updateMarker(false, nil, true)
	self:setProgressVisibility(false)

	if self.isServer and self:isComplete() then
		local farmId = self.farmId

		self.mission:addMoney(self:getReward(), farmId, MoneyType.MISSIONS, true, true)
	end
end

function RolePlayScenario:reset()
	self:delete()
	self:start()
end

function RolePlayScenario:onScenarioProgressChanged(id, progress)
	self:setProgress(progress)
end

function RolePlayScenario:startCompleteScenarioInternal(id, isStart)
	if isStart then
		self:startScenarioInternal(id)
	else
		self:completeScenarioInternal(id)
	end
end

function RolePlayScenario:startScenario(scenario)
	self:startScenarioInternal(scenario.id)
	g_server:broadcastEvent(ScenarioCheckPointEvent.new(scenario.id, true), false)
end

function RolePlayScenario:startScenarioInternal(id)
	for _, object in ipairs(self.objects) do
		object:start()
	end

	local checkpoint = self:getCheckPointById(id)

	if checkpoint ~= nil then
		checkpoint:start()
	end

	self.scenarioCheckPointId = id
end

function RolePlayScenario:completeScenario(scenario)
	self:completeScenarioInternal(scenario.id)
	g_server:broadcastEvent(ScenarioCheckPointEvent.new(scenario.id, false), false)
end

function RolePlayScenario:completeScenarioInternal(id)
	local checkpoint = self:getCheckPointById(id)

	if checkpoint ~= nil then
		checkpoint:complete()

		self.checkpointsStepsCompleted = self.checkpointsStepsCompleted + 1

		self:setProgress(self.checkpointsStepsCompleted / self.totalCheckPointsSteps)
	end

	for _, object in ipairs(self.objects) do
		object:complete()
	end

	self.scenarioCheckPointId = nil
end

function RolePlayScenario:isRewarded()
	return true
end

function RolePlayScenario:calculateReward()
	local maxReward = RolePlayScenario.REWARD_BASE_AMOUNT * self.rewardDifficultyCategory * self.rewardTeeSizeCategory
	local timeFactor = math.max(0, self.rewardBaseDuration / self.time)

	return maxReward * timeFactor
end

function RolePlayScenario:getReward()
	local difficultyMultiplier = 1.3 - 0.1 * self.mission.missionInfo.economicDifficulty
	local reward = self:calculateReward()

	return reward * difficultyMultiplier
end

function RolePlayScenario:getAbortedReason()
	return self.abortedReason or "unknown"
end

function RolePlayScenario:hasCheckPoints()
	return #self.checkpoints ~= 0
end

function RolePlayScenario:getCheckPointById(id)
	return self.checkpoints[id]
end

function RolePlayScenario:getActiveCheckpoint()
	for _, checkpoint in ipairs(self.checkpoints) do
		if checkpoint.isActive then
			return checkpoint
		end
	end

	return nil
end

function RolePlayScenario:getCheckPointQueue()
	return Queue.new(table.copy(self.checkpoints))
end

function RolePlayScenario:isInRangeOfNode(node)
	if self.rootNode == nil then
		return false, 0
	end

	local distance = calcDistanceFrom(node, self.rootNode)

	return distance <= self.engagementDistance, distance
end

function RolePlayScenario:loadHotspot()
	self.mapHotspot = AITargetHotspot.new()

	self.mission:addMapHotspot(self.mapHotspot)
	self.mapHotspot:setVisible(false)
end

function RolePlayScenario:deleteHotspot()
	if self.mapHotspot ~= nil then
		self.mission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end
end

function RolePlayScenario:updateMarker(state, position, force)
	if state ~= self.mapMarkerState or force then
		local x = 0
		local y = 0
		local z = 0

		if state then
			x, y, z = unpack(position)
		end

		self.mapHotspot:setBlinking(state)
		self.mapHotspot:setPersistent(state)
		self.mapHotspot:setVisible(state)
		self.mapHotspot:setWorldPosition(x, z)
		self.mission:setMapTargetHotspot(state and self.mapHotspot or nil)

		self.mapMarkerState = state
	end
end

function RolePlayScenario:onObjectPlaced(scenarioId, id, filename, index, x, y, z, rotY)
	if scenarioId ~= self.id then
		return
	end

	local object = ScenarioObject.new(self.isServer, self.isClient)
	object.groupId = id

	object:loadFromI3DFileAtWorldPosition(filename, index, x, y, z, 0, rotY, 0, true)
	object:register(true)
	object:start()
	self:addObject(object)
end

function RolePlayScenario:updateObjectsPosition(x, y, z)
	for _, object in ipairs(self.objects) do
		if not object.positionIsControlled then
			object:setWorldPosition(x, y, z, true)
		end
	end
end

function RolePlayScenario:addObject(object)
	self.objectsById[object.groupId] = object

	table.insert(self.objects, object)
end

function RolePlayScenario:removeObject(object)
	self.objectsById[object.groupId] = nil

	table.removeElement(self.objects, object)
end

function RolePlayScenario:getObjects()
	return self.objects
end

function RolePlayScenario:getObjectsWithId(id)
	local objects = {}

	for _, object in ipairs(self.objects) do
		if object.groupId == id then
			table.insert(objects, object)
		end
	end

	return objects
end

function RolePlayScenario:getNumberOfObjectsWithId(id)
	local num = 0

	for _, object in ipairs(self.objects) do
		if object.groupId == id then
			num = num + 1
		end
	end

	return num
end

function RolePlayScenario:loadFromXML(xmlFile, baseKey)
	self.rootNode = createTransformGroup("RolePlayScenarioRoot")

	link(getRootNode(), self.rootNode)

	local descriptionKey = xmlFile:getString("scenario#description")
	self.description = g_i18n:getText(descriptionKey, self.customEnvironment)
	local postMessageKey = xmlFile:getString("scenario#postMessage")

	if postMessageKey ~= nil then
		self.postMessage = g_i18n:getText(postMessageKey, self.customEnvironment)
	end

	self.engagementDistance = xmlFile:getFloat("scenario#engagementDistance", RolePlayScenario.MINIMAL_ENGAGEMENT_DISTANCE)
	self.rewardDifficultyCategory = math.min(xmlFile:getInt("scenario#rewardDifficultyCategory", 1), RolePlayScenario.REWARD_MAX_DIFFICULTY_CATEGORY)
	self.rewardTeeSizeCategory = math.min(xmlFile:getInt("scenario#rewardTeeSizeCategory", 1), RolePlayScenario.REWARD_MAX_TEE_SIZE_CATEGORY)
	self.rewardBaseDuration = RolePlayScenario.REWARD_BASE_TIME * self.rewardDifficultyCategory * self.rewardTeeSizeCategory
	self.startStrategyType = xmlFile:getString("scenario#startStrategy", StartStrategyDirector.TYPE_FIELD)
	self.startStrategy = self.startStrategyDirector:makeForType(self.startStrategyType)
	self.size = {
		width = xmlFile:getInt("scenario#width", 10),
		height = xmlFile:getInt("scenario#height", 10),
		length = xmlFile:getInt("scenario#length", 10)
	}

	self:loadObjectsFromXML(xmlFile, baseKey)
	self:loadCheckPointsFromXML(xmlFile, baseKey)
end

function RolePlayScenario:loadObjectsFromXML(xmlFile, baseKey)
	local function loadObjectByClass(key, class)
		local object = class.new(self.isServer, self.isClient)

		if object:loadFromXML(xmlFile, key, self.baseDirectory, self.rootNode) then
			self:addObject(object)
		else
			object:delete()
		end
	end

	xmlFile:iterate(baseKey .. ".objects.object", function (_, key)
		local className = xmlFile:getString(key .. "#objectClass", "ScenarioEffectObject")
		local class = ClassExtension.getClassObject(className)

		if class == nil then
			Logging.xmlError(xmlFile, "Object class '%s' not defined", className)

			return nil
		end

		local numberOfTimesToCopy = xmlFile:getInt(key .. "#numberOfTimesToCopy", 0)

		if numberOfTimesToCopy ~= 0 then
			for _ = 1, numberOfTimesToCopy do
				loadObjectByClass(key, class)
			end
		else
			loadObjectByClass(key, class)
		end
	end)
end

function RolePlayScenario:loadCheckPointsFromXML(xmlFile, baseKey)
	xmlFile:iterate(baseKey .. ".checkpoints.checkpoint", function (_, key)
		local checkpoint = ScenarioCheckpoint.new(self)

		if checkpoint:loadFromXML(xmlFile, key, self.baseDirectory, self.rootNode) then
			checkpoint:resolveObjectReferences(self.objectsById)
			checkpoint:setId(#self.checkpoints + 1)
			table.insert(self.checkpoints, checkpoint)
		else
			checkpoint:delete()
		end
	end)

	self.totalCheckPointsSteps = #self.checkpoints
	self.initialCheckPointsSteps = self.totalCheckPointsSteps
end
