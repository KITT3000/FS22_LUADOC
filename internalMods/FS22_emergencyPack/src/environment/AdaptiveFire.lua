AdaptiveFire = {
	THRIVE_COOL_DOWN_TIME = 3000
}
local _id = 0

local function getNextFireId()
	_id = _id + 1

	return _id
end

local AdaptiveFire_mt = Class(AdaptiveFire)

function AdaptiveFire.new(isServer, isClient, baseDirectory, maxActiveFires, custom_mt)
	local self = setmetatable({}, custom_mt or AdaptiveFire_mt)
	self.id = getNextFireId()
	self.isServer = isServer
	self.isClient = isClient
	self.rootNode = 0
	self.baseDirectory = baseDirectory
	self.maxActiveFires = maxActiveFires or 10
	self.activeFiresAtStart = 0
	self.fires = {}
	self.firesByNode = {}
	self.activeFires = {}
	self.developedFires = {}
	self.thriveCoolDownTime = 0
	self.lastExtinguishedFire = nil

	g_messageCenter:subscribe(ScenarioMessageType.FIRE_THRIVES, self.startFireAtWorldPosition, self)
	g_messageCenter:subscribe(ScenarioMessageType.FIRE_STAGE_UPDATE, self.onFireStageChanged, self)
	g_messageCenter:subscribe(ScenarioMessageType.FIRE_EXTINGUISHED, self.onFireExtinguished, self)

	local windUpdater = g_currentMission.environment.weather.windUpdater

	windUpdater:addWindChangedListener(self)

	self.windDirX, self.windDirZ, self.windVelocity = windUpdater:getCurrentValues()

	return self
end

function AdaptiveFire:delete()
	g_messageCenter:unsubscribeAll(self)

	if g_currentMission.environment ~= nil then
		g_currentMission.environment.weather.windUpdater:removeWindChangedListener(self)
	end

	for _, fire in ipairs(self.fires) do
		fire:delete()
	end

	self.fires = {}

	if self.isFieldFire and self.field ~= nil then
		self:resetField()

		self.field = nil
	end
end

function AdaptiveFire:writeStream(streamId, connection)
	if not connection:getIsServer() then
		for _, fire in ipairs(self.fires) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(fire))
			fire:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, fire)
		end
	end
end

function AdaptiveFire:onPlayerJoinWriteStream(streamId, connection)
	if not connection:getIsServer() then
		for _, fire in ipairs(self.fires) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(fire))
			fire:writeStream(streamId, connection)
			g_server:finishRegisterObject(connection, fire)
		end
	end
end

function AdaptiveFire:readStream(streamId, connection)
	if connection:getIsServer() then
		for _, fire in ipairs(self.fires) do
			local fireObjectId = NetworkUtil.readNodeObjectId(streamId)

			fire:readStream(streamId, connection)
			g_client:finishRegisterObject(fire, fireObjectId)
		end
	end
end

function AdaptiveFire:onPlayerJoinReadStream(streamId, connection)
	if connection:getIsServer() then
		for _, fire in ipairs(self.fires) do
			local fireObjectId = NetworkUtil.readNodeObjectId(streamId)

			fire:readStream(streamId, connection)
			g_client:finishRegisterObject(fire, fireObjectId)
		end
	end
end

function AdaptiveFire:loadFromXML(xmlFile, baseKey)
	local duplicateFirstEntry = xmlFile:getBool(baseKey .. ".fireObjects#duplicateFirst") or false
	self.isFieldFire = xmlFile:getBool(baseKey .. ".fireObjects#isFieldFire") or false
	self.maxActiveFires = xmlFile:getInt(baseKey .. ".fireObjects#maxActiveFires") or self.maxActiveFires
	self.activeFiresAtStart = math.min(xmlFile:getInt(baseKey .. ".fireObjects#activeFiresAtStart") or 0, self.maxActiveFires)

	xmlFile:iterate(baseKey .. ".fireObjects.fireObject", function (i, key)
		if duplicateFirstEntry and i == 1 then
			for _ = 1, self.maxActiveFires do
				self:loadFireFromXML(xmlFile, key)
			end
		else
			self:loadFireFromXML(xmlFile, key)
		end
	end)
end

function AdaptiveFire:loadFireFromXML(xmlFile, key)
	local fire = FireObject.new(self.id, self.isServer, self.isClient)

	if fire:loadFromXML(xmlFile, key, self.baseDirectory, self.rootNode) then
		fire.fireId = #self.fires + 1
		self.firesByNode[fire.nodeId] = fire

		table.insert(self.fires, fire)
		fire:register(true)
	else
		fire:delete()
	end
end

function AdaptiveFire:setRootNode(rootNode)
	self.rootNode = rootNode
end

function AdaptiveFire:init(fieldId)
	if not self.isFieldFire then
		return
	end

	self.sprayLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	self.plowLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
	self.limeLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
	self.field = g_fieldManager:getFieldByIndex(fieldId)
	self.fieldSpraySet, self.sprayFactor, self.fieldPlowFactor, self.limeFactor, self.weedFactor, self.maxWeedState, self.stubbleFactor, self.rollerFactor = g_missionManager:getFieldData(self.field)
end

function AdaptiveFire:resetField()
	if not self.isFieldFire then
		return
	end

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, self.sprayFactor * self.sprayLevelMaxValue, self.fieldSpraySet, self.fieldPlowFactor * self.plowLevelMaxValue, self.weedState, self.limeFactor * self.limeLevelMaxValue)
	end
end

function AdaptiveFire:reset()
	for _, fire in ipairs(self.activeFires) do
		fire:reset()
	end

	self.activeFires = {}
	self.developedFires = {}

	if self.isFieldFire and self.field ~= nil then
		self:resetField()
	end
end

function AdaptiveFire:getFireByNode(nodeId)
	return self.firesByNode[nodeId]
end

function AdaptiveFire:getFires()
	return self.fires
end

function AdaptiveFire:getActiveFires()
	return self.activeFires
end

function AdaptiveFire:getAmountOfActiveFires()
	return #self.activeFires
end

function AdaptiveFire:getCompletedAmount()
	local total = #self.activeFires
	local alpha = 0

	for _, fire in ipairs(self.activeFires) do
		alpha = alpha + 1 - fire.alpha
	end

	return alpha / total
end

function AdaptiveFire:getDevelopedFires()
	return self.developedFires
end

function AdaptiveFire:getAmountDevelopedFires()
	return #self.developedFires
end

function AdaptiveFire:hasActiveFires()
	return #self.activeFires ~= 0
end

function AdaptiveFire:getNextFire()
	for _, fire in ipairs(self.fires) do
		if not fire:isExtinguished() and not table.hasElement(self.activeFires, fire) then
			return fire
		end
	end

	return nil
end

function AdaptiveFire:getNextFirePosition()
	local x, y, z = getWorldTranslation(self.rootNode)

	if #self.activeFires == 0 then
		return x, y, z
	end

	local fire = nil

	if #self.developedFires > 0 then
		local i = math.random(#self.developedFires)
		fire = self.developedFires[i]
	else
		local i = math.random(#self.activeFires)
		fire = self.activeFires[i]
	end

	local x0, z0, x1, z1, x2, z2 = fire:getMaxArea()
	x = (x0 + x1 + x2) / 3
	z = (z0 + z1 + z2) / 3

	if self.windDirX ~= nil and self.windDirZ ~= nil then
		local normX, _, normZ = MathUtil.crossProduct(0, 1, 0, -self.windDirX, 0, -self.windDirZ)
		local offset = fire.radius * 0.25
		x = x + -self.windDirX * offset + normX * offset
		z = z + -self.windDirZ * offset + normZ * offset
	end

	return x, y, z
end

function AdaptiveFire:startFireAtWorldPosition(id, fireId, x, y, z, yRot)
	if self.id ~= id then
		return
	end

	local fire = self.fires[fireId]

	fire:removeFromPhysics()
	fire:setWorldPositionAndRotation(x, y, z, 0, yRot, 0, true)
	fire:start()
	fire:addToPhysics()
	table.insert(self.activeFires, fire)
end

function AdaptiveFire:thrive(dt)
	if self.thriveCoolDownTime > 0 then
		self.thriveCoolDownTime = math.max(0, self.thriveCoolDownTime - dt)
	end

	if self.isServer and self:canThrive() then
		local fire = self:getNextFire()

		if fire ~= nil then
			local x, y, z = self:getNextFirePosition()
			local yRot = math.random() * 2 * math.pi

			self:startFireAtWorldPosition(self.id, fire.fireId, x, y, z, yRot)
			g_server:broadcastEvent(FireObjectAtWorldPositionEvent.new(self.id, fire.fireId, x, y, z, yRot), false)

			self.thriveCoolDownTime = AdaptiveFire.THRIVE_COOL_DOWN_TIME

			if self.activeFiresAtStart > 0 then
				self.activeFiresAtStart = math.max(self.activeFiresAtStart - 1, 0)
			end
		end
	end

	if self.windVelocity ~= nil then
		-- Nothing
	end
end

function AdaptiveFire:canThrive()
	if self.rootNode == 0 then
		return false
	end

	if self.thriveCoolDownTime > 0 then
		return false
	end

	local amountOfFires = #self.fires

	if amountOfFires == 0 then
		return false
	end

	if self.activeFiresAtStart > 0 then
		return true
	end

	local amountOfActiveFires = #self.activeFires

	if amountOfActiveFires == 0 then
		return self.lastExtinguishedFire == nil
	end

	if amountOfFires <= amountOfActiveFires or self.maxActiveFires <= amountOfActiveFires then
		return false
	end

	local amountOfDevelopedFires = #self.developedFires

	if amountOfDevelopedFires == amountOfActiveFires then
		return true
	end

	return false
end

function AdaptiveFire:update(dt)
	self:thrive(dt)

	for _, fire in ipairs(self.activeFires) do
		fire:raiseActive()

		if self.isServer and self.isFieldFire then
			local x0, z0, x1, z1, x2, z2 = fire:getArea()

			FSDensityMapUtil.updateWheelDestructionArea(x0, z0, x1, z1, x2, z2, true, false)
		end
	end
end

function AdaptiveFire:setWindValues(windDirX, windDirZ, windVelocity)
	self.windDirX = windDirX
	self.windDirZ = windDirZ
	self.windVelocity = windVelocity
end

function AdaptiveFire:onFireExtinguished(id, fireId)
	if self.id ~= id then
		return
	end

	self:fireExtinguishedInternal(fireId)

	if self.isServer then
		g_server:broadcastEvent(FireObjectExtinguishedEvent.new(self.id, fireId), false)
	end
end

function AdaptiveFire:fireExtinguishedInternal(fireId)
	local fire = self.fires[fireId]

	fire:reset()
	table.removeElement(self.activeFires, fire)
	table.removeElement(self.developedFires, fire)

	self.lastExtinguishedFire = fire
end

function AdaptiveFire:onFireStageChanged(id, fireId, stage)
	if self.id ~= id then
		return
	end

	self:fireStageChangedInternal(fireId, stage)

	if self.isServer then
		g_server:broadcastEvent(FireObjectStageChangedEvent.new(self.id, fireId, stage), false)
	end
end

function AdaptiveFire:fireStageChangedInternal(fireId, stage)
	local fire = self.fires[fireId]

	if stage == FireObject.STAGE_DEVELOPED and not table.hasElement(self.developedFires, fire) then
		table.insert(self.developedFires, fire)
	elseif stage < FireObject.STAGE_DEVELOPED then
		table.removeElement(self.developedFires, fire)
	end
end
