FireObject = {
	DEFAULT_RADIUS = 1,
	MAX_RADIUS = 5,
	MAX_TEMPERATURE = 1000,
	MAX_TEMPERATURE_DURATION = 5400000,
	DEVELOPED_TEMPERATURE_FACTOR = 0.7,
	EXTINGUISHED_THRESHOLD = 0.11,
	EXTINGUISHED_COOL_DOWN_TIME = 5000,
	MAX_LIGHT_RANGE = 10,
	CURVE = AnimCurve.new(linearInterpolator1)
}

FireObject.CURVE:addKeyframe({
	0.1,
	time = 0
})
FireObject.CURVE:addKeyframe({
	0.6,
	time = FireObject.MAX_TEMPERATURE_DURATION * 0.055
})
FireObject.CURVE:addKeyframe({
	0.8,
	time = FireObject.MAX_TEMPERATURE_DURATION * 0.24
})
FireObject.CURVE:addKeyframe({
	1,
	time = FireObject.MAX_TEMPERATURE_DURATION
})

FireObject.STAGE_INCIPIENT = 1
FireObject.STAGE_GROWTH = 2
FireObject.STAGE_DEVELOPED = 3
FireObject.STAGE_DECAY = 4
FireObject.STAGE_EXTINGUISHED = 5
FireObject.COLLISION_MASK = CollisionFlag.DEFAULT + CollisionFlag.STATIC_OBJECT + CollisionFlag.TRIGGER_PLAYER + CollisionFlag.TRIGGER_VEHICLE
FireObject.GROWTH_MULTIPLIER = 3
FireObject.DEBUG_MULTIPLIER = 5
FireObject.SEND_PRECISION = 0.001
local FireObject_mt = Class(FireObject, ScenarioEffectObject)

function FireObject.registerXMLPaths(schema, basePath)
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".extinguishEffects")
	ScenarioEffectObject.registerXMLPaths(schema, basePath)
end

function FireObject.new(parentId, isServer, isClient, custom_mt)
	local self = FireObject:superClass().new(isServer, isClient, custom_mt or FireObject_mt)
	self.parentId = parentId
	self.stage = FireObject.STAGE_INCIPIENT
	self.radius = FireObject.DEFAULT_RADIUS
	self.alpha = 0
	self.alphaSent = 0
	self.time = 0
	self.temperature = 0
	self.worldPosition = {
		0,
		0,
		0
	}
	self.extinguishCoolDownTime = 0
	self.effectsActiveTime = 0
	self.effectsStarted = false
	self.extinguishIsDirty = false
	self.extinguishIsDirtySent = false
	self.lightImpactTime = 0
	self.lightImpactTimeThreshold = 100
	self.lightImpact = 1
	self.developedTemperature = FireObject.MAX_TEMPERATURE * FireObject.DEVELOPED_TEMPERATURE_FACTOR
	self.dirtyFlag = self:getNextDirtyFlag()

	return self
end

function FireObject:delete()
	if self.isClient then
		g_effectManager:deleteEffects(self.extinguishEffects)
	end

	FireObject:superClass().delete(self)
end

function FireObject:readStream(streamId, connection, objectId)
	FireObject:superClass().readStream(self, streamId, connection, objectId)

	self.alpha = streamReadFloat32(streamId)
	self.temperature = FireObject.MAX_TEMPERATURE * self.alpha
	self.radius = FireObject.MAX_RADIUS * self.alpha
	self.stage = self:determineStage()

	if self.stage ~= FireObject.STAGE_INCIPIENT then
		self:start()
	end
end

function FireObject:writeStream(streamId, connection)
	FireObject:superClass().writeStream(self, streamId, connection)
	streamWriteFloat32(streamId, self.alpha)
end

function FireObject:readUpdateStream(streamId, timestamp, connection)
	FireObject:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		self.alpha = streamReadFloat32(streamId)
		self.extinguishIsDirty = streamReadBool(streamId)
	end
end

function FireObject:writeUpdateStream(streamId, connection, dirtyMask)
	FireObject:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.alpha)
		streamWriteBool(streamId, self.extinguishIsDirty)
	end
end

function FireObject:loadFromXML(xmlFile, key, baseDirectory, scenarioRootNode)
	if not FireObject:superClass().loadFromXML(self, xmlFile, key, baseDirectory, scenarioRootNode) then
		return false
	end

	self.alphaLimit = xmlFile:getFloat(key .. "#alphaLimit") or 1

	if self.alphaLimit < FireObject.DEVELOPED_TEMPERATURE_FACTOR then
		self.developedTemperature = FireObject.MAX_TEMPERATURE * self.alphaLimit
	end

	if self.isClient then
		local lightNodePath = xmlFile:getString(key .. "#lightNode")

		if lightNodePath ~= nil then
			self.lightNode = I3DUtil.indexToObject(self.nodeId, lightNodePath)

			setVisibility(self.lightNode, false)
		end

		self.extinguishEffects = g_effectManager:loadEffect(xmlFile, key .. ".extinguishEffects", self.nodeId, self, nil)

		self:setFireSmokeColors()
		self:setFireExtinguishColors()
		self:updateEffects(self.alpha)
	end

	return true
end

function FireObject:updateEffects(alpha)
	if alpha == nil then
		return
	end

	for _, effect in pairs(self.effects) do
		if effect.particleSystem ~= nil then
			ParticleUtil.setEmitCountScale(effect.particleSystem, effect.emitCountScale * alpha)

			if effect.particleType == "fire" then
				ParticleUtil.setParticleLifespan(effect.particleSystem, effect.lifespan * alpha)
			end
		end
	end
end

function FireObject:setFireSmokeColors()
	g_effectManager:setFillType(self.effects, FillType.MANURE)

	for _, effect in pairs(self.effects) do
		if effect.emitterShape ~= nil then
			setClipDistance(effect.emitterShape, 800)
		end

		if effect.setColor ~= nil then
			local c = math.random()

			effect:setColor(c, c, c, 0.75)
		end
	end
end

function FireObject:setFireExtinguishColors()
	g_effectManager:setFillType(self.extinguishEffects, FillType.MANURE)

	for _, effect in pairs(self.extinguishEffects) do
		if effect.setColor ~= nil then
			local c = math.max(0.7, math.random())

			effect:setColor(c, c, c, c)
		end
	end
end

function FireObject:start()
	FireObject:superClass().start(self)

	if self.lightNode ~= nil then
		setVisibility(self.lightNode, true)
	end
end

function FireObject:reset()
	self.radius = FireObject.DEFAULT_RADIUS
	self.alpha = 0
	self.time = 0
	self.temperature = 0

	if self.isClient then
		g_effectManager:stopEffects(self.extinguishEffects)
		g_effectManager:stopEffects(self.effects)
		g_soundManager:stopSample(self.sample)

		if self.lightNode ~= nil then
			setVisibility(self.lightNode, false)
		end
	end
end

function FireObject:update(dt)
	local isDebug = g_currentMission.rolePlay.isDebug
	local impactDt = dt * FireObject.GROWTH_MULTIPLIER

	if isDebug then
		impactDt = impactDt * FireObject.DEBUG_MULTIPLIER
	end

	if self.isServer then
		if self.extinguishCoolDownTime > 0 then
			self.extinguishCoolDownTime = math.max(0, self.extinguishCoolDownTime - impactDt)
		elseif not self:isExtinguished() then
			self.time = self.time + impactDt
		end

		self.alpha = MathUtil.clamp(FireObject.CURVE:get(self.time), 0, self.alphaLimit)
	end

	self.temperature = FireObject.MAX_TEMPERATURE * self.alpha
	self.radius = FireObject.MAX_RADIUS * self.alpha

	if self.isClient then
		if self.lightNode ~= nil then
			self.lightImpactTime = self.lightImpactTime + dt

			if self.lightImpactTimeThreshold <= self.lightImpactTime then
				self.lightImpactTime = 0
				self.lightImpact = math.random()
			end

			setLightRange(self.lightNode, FireObject.MAX_LIGHT_RANGE * self.alpha * 1 - self.lightImpact)
		end

		if self.extinguishIsDirty then
			self.effectsActiveTime = 10000
		elseif self.effectsActiveTime > 0 then
			self.effectsActiveTime = math.max(0, self.effectsActiveTime - impactDt)
		end

		local showEffects = self.effectsActiveTime > 0

		if showEffects then
			if not self.effectsStarted then
				self.effectsStarted = true

				g_effectManager:startEffects(self.extinguishEffects)
			end
		elseif self.effectsStarted then
			self.effectsStarted = false

			g_effectManager:stopEffects(self.extinguishEffects)
		end

		local effectAlpha = showEffects and self.alpha * 0.9 or self.alpha

		self:updateEffects(effectAlpha)
	end

	if isDebug then
		self:draw()
	end

	local stage = self:determineStage()

	if stage ~= self.stage then
		self.stage = stage

		if self.isServer then
			g_messageCenter:publish(ScenarioMessageType.FIRE_STAGE_UPDATE, self.parentId, self.fireId, stage)
		end
	end

	if self.isServer and (FireObject.SEND_PRECISION < math.abs(self.alpha - self.alphaSent) or self.extinguishIsDirty ~= self.extinguishIsDirtySent) then
		self.alphaSent = self.alpha
		self.extinguishIsDirtySent = self.extinguishIsDirty

		self:raiseActive()
		self:raiseDirtyFlags(self.dirtyFlag)
	end

	self.extinguishIsDirty = false
end

function FireObject:determineStage()
	if self.temperature == 0 then
		return FireObject.STAGE_INCIPIENT
	end

	if self.developedTemperature <= self.temperature then
		return FireObject.STAGE_DEVELOPED
	end

	return FireObject.STAGE_GROWTH
end

function FireObject:isDeveloped()
	return self.stage == FireObject.STAGE_DEVELOPED
end

function FireObject:isGrowing()
	return self.stage == FireObject.STAGE_GROWTH
end

function FireObject:isExtinguished()
	return self.stage == FireObject.STAGE_EXTINGUISHED
end

function FireObject:setWorldPosition(x, y, z, limitToGround)
	FireObject:superClass().setWorldPosition(self, x, y, z, limitToGround)

	self.worldPosition = {
		x,
		y,
		z
	}
end

function FireObject:setWorldPositionAndRotation(x, y, z, rotX, rotY, rotZ, limitToGround)
	FireObject:superClass().setWorldPositionAndRotation(self, x, y, z, rotX, rotY, rotZ, limitToGround)

	self.worldPosition = {
		x,
		y,
		z
	}
end

function FireObject:getWorldPosition()
	return self.worldPosition
end

function FireObject:getAreaByRadius(radius)
	local half = radius * 0.5
	local x0, _, z0 = localToWorld(self.nodeId, -half, 0, -half)
	local x1, _, z1 = localToWorld(self.nodeId, half, 0, -half)
	local x2, _, z2 = localToWorld(self.nodeId, -half, 0, half)

	return x0, z0, x1, z1, x2, z2
end

function FireObject:getArea()
	return self:getAreaByRadius(self.radius)
end

function FireObject:getMaxArea()
	return self:getAreaByRadius(FireObject.MAX_RADIUS)
end

function FireObject:extinguish(dt, multiplier)
	multiplier = multiplier or 1
	self.extinguishIsDirty = true
	local impact = dt * multiplier
	local isDebug = g_currentMission.rolePlay.isDebug

	if isDebug then
		impact = impact * FireObject.DEBUG_MULTIPLIER
	end

	if self.alpha <= FireObject.EXTINGUISHED_THRESHOLD then
		self:onExtinguished()

		return
	end

	if FireObject.STAGE_GROWTH < self.stage then
		impact = impact * 0.75
	end

	local radiusAlpha = math.max(self.radius / FireObject.MAX_RADIUS, 0.1)
	impact = impact + impact * (1 - radiusAlpha)
	self.time = math.max(0, self.time - impact)
	self.extinguishCoolDownTime = FireObject.EXTINGUISHED_COOL_DOWN_TIME
end

function FireObject:onExtinguished()
	g_messageCenter:publish(ScenarioMessageType.FIRE_EXTINGUISHED, self.parentId, self.fireId)
	self:reset()

	self.stage = FireObject.STAGE_EXTINGUISHED
end

function FireObject:draw()
	local x = self.worldPosition[1]
	local y = self.worldPosition[2]
	local z = self.worldPosition[3]

	if x == 0 and y == 0 and z == 0 then
		return
	end

	DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, 0, 0, 1, 0, 1, 0, ("Fire %f"):format(self.alpha), false)

	local x0, z0, x1, z1, x2, z2 = self:getArea()
	local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)

	DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0, 1, 1, 1, 1)
end
