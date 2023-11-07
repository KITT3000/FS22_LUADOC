WreckageTool = {}
local WreckageTool_mt = Class(WreckageTool, RolePlayHandTool)

InitObjectClass(WreckageTool, "WreckageTool")

function WreckageTool.registerXMLPaths(schema, basePath)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".wreckage.sounds", "work")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".wreckage.effects")
	WreckageCutter.registerXMLPaths(schema, basePath .. ".wreckage")
	schema:register(XMLValueType.FLOAT, basePath .. ".wreckage#workDistance", "The work distance of the wreckage tool", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".wreckage#focusDistance", "The focus distance of the wreckage tool", 2)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wreckage#raycastNode", "Raycast node")
	schema:register(XMLValueType.STRING, basePath .. ".wreckage.workingAnimation#name", "Working animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".wreckage.workingAnimation#workingDirection", "Working animation direction if is working", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".wreckage.workingAnimation#releasingDirection", "Working animation direction if is releasing", "-workingDirection")
end

function WreckageTool.new(isServer, isClient, customMt)
	local self = WreckageTool:superClass().new(isServer, isClient, customMt or WreckageTool_mt)
	self.isWorking = false
	self.hasWreckedObject = false
	self.isInWorkRange = false
	self.isInWorkRangeSent = false
	self.isInFocusRange = false
	self.isInFocusRangeSent = false
	self.workDistance = 1
	self.focusDistance = self.workDistance * 2
	self.lastHitDistance = self.workDistance
	self.workedTime = 0
	self.workedTimeThreshold = 5000

	return self
end

function WreckageTool:delete()
	g_effectManager:deleteEffects(self.effects)
	g_soundManager:deleteSample(self.sample)
	WreckageTool:superClass().delete(self)
end

function WreckageTool:postLoad(xmlFile)
	if not WreckageTool:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.effects = g_effectManager:loadEffect(xmlFile, "handTool.wreckage.effects", self.components, self, self.i3dMappings)
	self.sample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.wreckage.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	self.workDistance = xmlFile:getValue("handTool.wreckage#workDistance", self.workDistance)
	self.focusDistance = xmlFile:getValue("handTool.wreckage#focusDistance", self.focusDistance)
	self.raycastNode = xmlFile:getValue("handTool.wreckage#raycastNode", nil, self.components, self.i3dMappings)
	local animation = {
		name = xmlFile:getValue("handTool.wreckage.workingAnimation#name"),
		workingDirection = xmlFile:getValue("handTool.wreckage.workingAnimation#workingDirection", 1)
	}
	animation.releasingDirection = xmlFile:getValue("handTool.wreckage.workingAnimation#releasingDirection", -animation.workingDirection)
	self.workingAnimation = animation

	return true
end

function WreckageTool:onActivate(allowInput)
	WreckageTool:superClass().onActivate(self, allowInput)
end

function WreckageTool:onDeactivate(allowInput)
	WreckageTool:superClass().onDeactivate(self, allowInput)
	self:setIsWorking(false, true)

	if self.isClient then
		self:updateVisual(false)
	end

	if self.isServer then
		if not self.setAction then
			self:validateActionProgression()
		end

		self.hasWreckedObject = false
		self.workedTime = 0
	end
end

function WreckageTool:update(dt, allowInput)
	WreckageTool:superClass().update(self, dt, allowInput)

	if self.isActive and allowInput then
		self:setIsWorking(self.activatePressed, false, false)
	end

	self.activatePressed = false
end

function WreckageTool:updateTick(dt, allowInput)
	WreckageTool:superClass().updateTick(self, dt, allowInput)

	if not self.isServer then
		return
	end

	self.isInFocusRange = false
	self.isInWorkRange = false

	if not self.hasWreckedObject then
		self.lastHitDistance = self.focusDistance

		self:tryWreckObject(self.player.cameraNode, dt)

		if self.raycastNode ~= nil then
			self:tryWreckObject(self.raycastNode, dt)
		end

		self.isInWorkRange = self.lastHitDistance < self.workDistance
		self.isInFocusRange = self.lastHitDistance < self.focusDistance

		if self.isWorking and self.isInWorkRange then
			self.workedTime = self.workedTime + dt

			if self.workedTimeThreshold <= self.workedTime then
				self:wreckObject()

				self.workedTime = 0
			end
		end
	end

	if self.isInFocusRange ~= self.isInFocusRangeSent or self.isInWorkRange ~= self.isInWorkRangeSent then
		self.isInWorkRangeSent = self.isInWorkRange
		self.isInFocusRangeSent = self.isInFocusRange

		WreckageToolStateEvent.sendEvent(self.player, self.isInWorkRange, self.isInFocusRange)
	end

	if self.setAction then
		return
	end

	self:validateActionProgression()
end

function WreckageTool:validateActionProgression()
	if self.isServer and self.isActive and not self.isWorking and self.hasWreckedObject then
		local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

		if scenario ~= nil then
			local checkpoint = scenario.scenarioCheckPoint

			if checkpoint ~= nil then
				checkpoint:setActionCompleted(true)

				self.setAction = true
			end
		end
	end
end

function WreckageTool:tryWreckObject(node, dt)
	local x, y, z = getWorldTranslation(node)
	local dx, dy, dz = localDirectionToWorld(node, 0, 0, -1)

	raycastAll(x, y, z, dx, dy, dz, "raycastCallback", self.focusDistance * 2, self, CollisionFlag.STATIC_WORLD + CollisionFlag.DYNAMIC_OBJECT)
end

function WreckageTool:isWreckageNode(nodeId, x, y, z)
	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario ~= nil then
		local checkpoint = scenario.scenarioCheckPoint

		if checkpoint == nil then
			return false
		end

		local ref = checkpoint:getObjectReferenceById(nodeId)

		return ref ~= nil
	end

	return false
end

function WreckageTool:raycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= g_currentMission.terrainRootNode and self:isWreckageNode(hitObjectId, x, y, z) and distance <= self.lastHitDistance then
		self.lastHitDistance = distance

		return false
	end

	return true
end

function WreckageTool:setIsWorking(isWorking, force, noEventSend)
	WreckageToolWorkEvent.sendEvent(self.player, isWorking, noEventSend)

	if self.isWorking ~= isWorking then
		if isWorking then
			g_effectManager:startEffects(self.effects)
			g_soundManager:playSample(self.sample)

			local animation = self.workingAnimation

			if animation.name ~= nil then
				self.animations:playAnimation(animation.name, self.isInWorkRange and animation.workingDirection or 0)
			end
		else
			if force then
				g_effectManager:resetEffects(self.effects)
			else
				g_effectManager:stopEffects(self.effects)
			end

			g_soundManager:stopSample(self.sample)

			local animation = self.workingAnimation

			if animation.name ~= nil then
				self.animations:playAnimation(animation.name, animation.releasingDirection)
			end
		end

		self.isWorking = isWorking
	end
end

function WreckageTool:setState(state, noEventSend)
	WreckageTool:superClass().setState(self, state, noEventSend)

	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil then
		return
	end

	local visualRef = checkpoint:getObjectReferenceById("visual")
	local physicsRef = checkpoint:getObjectReferenceById("physics")

	setVisibility(visualRef.node, false)
	setVisibility(physicsRef.node, true)

	local physicsObjects = checkpoint:getObjectReferencePhysics(visualRef.node)

	for _, object in ipairs(physicsObjects) do
		removeFromPhysics(object)
	end

	local x, y, z = getWorldTranslation(self.player.cameraNode)

	physicsRef.object:setWorldPositionAndRotation(x, y, z, 0, 0, 0, true)

	self.hasWreckedObject = true
end

function WreckageTool:wreckObject()
	self:setState(true)
end

function WreckageTool:updateVisual(doReset)
end
