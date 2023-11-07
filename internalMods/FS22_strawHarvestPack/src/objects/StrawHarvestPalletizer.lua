StrawHarvestPalletizer = {
	BAG_LIFTER_MAX_BAG_ROWS = 6,
	BAGS_PER_ROW = 5
}
local strawHarvestPalletizer_mt = Class(StrawHarvestPalletizer, Object)

InitObjectClass(StrawHarvestPalletizer, "StrawHarvestPalletizer")
g_xmlManager:addCreateSchemaFunction(function ()
	StrawHarvestPalletizer.xmlSchema = XMLSchema.new("palletizer")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = StrawHarvestPalletizer.xmlSchema

	StrawHarvestPalletizer.registerXMLPaths(schema, "palletizer")
end)

function StrawHarvestPalletizer.registerXMLPaths(schema, basePath)
	I3DUtil.registerI3dMappingXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".i3dFilename", "I3d filename", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. ".litersPerSecond", "Liters per second to palletize", 10)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".playerTrigger#node", "Player trigger node")
	StrawHarvestStorageBuffer.registerXMLPaths(schema, basePath .. ".bunkerBuffer")
	StrawHarvestStorageBuffer.registerXMLPaths(schema, basePath .. ".pelletizerBuffer")
	UnloadTrigger.registerXMLPaths(schema, basePath .. ".unloadTrigger")
	schema:register(XMLValueType.INT, basePath .. ".bagCreations#literPerBag", "Liters per bag", 50)
	schema:register(XMLValueType.FLOAT, basePath .. ".bagCreations#costPerBag", "Cost per bag", 1.25)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bagCreations#fillGuideNode", "Fill guide node", nil, true)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bagCreations#dropGuideNode", "Drop guide node", nil, true)

	local bagCreationPath = basePath .. ".bagCreations.bagCreation(?)"

	schema:register(XMLValueType.STRING, bagCreationPath .. "#fillType", "Fill type name", "")
	schema:register(XMLValueType.FLOAT, bagCreationPath .. "#fillTypeDecisionWeight", "Decision weight", 1)
	schema:register(XMLValueType.NODE_INDEX, bagCreationPath .. "#cloneNode", "Clone node", nil, true)
	schema:register(XMLValueType.STRING, bagCreationPath .. "#palletXMLFilename", "Pallet xml filename", "")

	local patternPath = basePath .. ".bagCreations.patterns.pattern(?)"

	schema:register(XMLValueType.NODE_INDEX, patternPath .. ".guideNodes.guideNode(?)#node", "Guide node")
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, patternPath .. ".rotatory.rotatoryAnimationPackage", false)
	schema:register(XMLValueType.NODE_INDEX, patternPath .. ".rotatory#guideNode", "Guide node")
	schema:register(XMLValueType.VECTOR_N, patternPath .. ".rotatory#playPattern", "Rotary play pattern")
	schema:register(XMLValueType.INT, patternPath .. "#firstMovementBagThreshold", "First movement bag threshold", 0)
	schema:register(XMLValueType.INT, patternPath .. "#secondMovementBagThreshold", "Second movement bag threshold", 0)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, patternPath .. ".firstMovementAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, patternPath .. ".secondMovementAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, patternPath .. ".pusher.pusherFirstAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, patternPath .. ".pusher.pusherPushThroughAnimationPackage", false)

	local bagLifterPath = basePath .. ".bagLifter"

	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, bagLifterPath .. ".bagLifterMovementAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, bagLifterPath .. ".bagLifterPutBagsOnPalletAnimationPackage", false)
	schema:register(XMLValueType.NODE_INDEX, bagLifterPath .. "#palletGuideNode", "Pallet guide node")
	schema:register(XMLValueType.NODE_INDEX, bagLifterPath .. "#bagGuideNode", "Bag guide node")
	schema:register(XMLValueType.FLOAT, bagLifterPath .. "#minAnimationTime", "Min animation time", nil, true)
	schema:register(XMLValueType.FLOAT, bagLifterPath .. "#maxAnimationTime", "Max animation time", nil, true)
	schema:register(XMLValueType.FLOAT, bagLifterPath .. "#loadPosAnimationTime", "Load position animation time", nil, true)
	schema:register(XMLValueType.FLOAT, bagLifterPath .. "#animationTimePerBagLayer", "Animation time per bag layer", nil, true)
	schema:register(XMLValueType.INT, bagLifterPath .. "#numBagRowsOnPallet", "Num bag rows on pallet", nil, true)

	local palletStackerPath = basePath .. ".palletStacker"

	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, palletStackerPath .. ".palletStackerDeliverPalletAnimationPackage", false)
	schema:register(XMLValueType.NODE_INDEX, palletStackerPath .. "#palletGuideNode", "Pallet guide node")
	schema:register(XMLValueType.NODE_INDEX, palletStackerPath .. "#palletCloneNode", "Pallet clone node")

	local conveyorPath = basePath .. ".conveyor"

	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, conveyorPath .. ".conveyorMovePalletOutAnimationPackage", false)
	schema:register(XMLValueType.NODE_INDEX, conveyorPath .. "#palletGuideNode", "Pallet guide node")

	local palletOutputPath = basePath .. ".palletOutput"

	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, palletOutputPath .. ".movePalletToDestinationAnimationPackage", false)
	schema:register(XMLValueType.NODE_INDEX, palletOutputPath .. "#palletGuideNode", "Pallet guide node")

	local palletOutputPlacePath = palletOutputPath .. ".places.place(?)"

	schema:register(XMLValueType.NODE_INDEX, palletOutputPlacePath .. "#triggerNode", "Pallet place trigger node")
	schema:register(XMLValueType.FLOAT, palletOutputPlacePath .. "#animationTime", "Animation time", nil, true)
	schema:register(XMLValueType.FLOAT, palletOutputPlacePath .. "#spawnOffset", "Spawn offset", 0)
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effect")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work")
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.unloadAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.loadAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.beltBunkerAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.beltBagAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.bagFillAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.bagDropAnimationPackage", false)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.ghostAnimation", true)
	StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath .. ".animationPackages.rotatoryBeltAnimationPackage", false)
end

function StrawHarvestPalletizer.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Farm id")
	StrawHarvestStorageBuffer.registerSavegameXMLPaths(schema, basePath .. ".bunkerBuffer")
	StrawHarvestStorageBuffer.registerSavegameXMLPaths(schema, basePath .. ".pelletizerBuffer")
	schema:register(XMLValueType.BOOL, basePath .. ".isPalletMovingToDestination", "Is pallet moving to destination", false)
	schema:register(XMLValueType.INT, basePath .. ".bagsToday", "Pelletized bags today")
	schema:register(XMLValueType.INT, basePath .. ".palletsToday", "Pelletized pallets today")
	schema:register(XMLValueType.INT, basePath .. ".currentRotatoryPattern", "Current rotary pattern")
	schema:register(XMLValueType.INT, basePath .. ".currentPusherPattern", "Current pusher pattern")
	schema:register(XMLValueType.INT, basePath .. ".currentLifterPattern", "Current lifter pattern")

	local liftBagsPath = basePath .. ".liftBags.bag(?)"

	schema:register(XMLValueType.INT, basePath .. ".liftBags#liftAnimationTime", "Lift animation time")

	local pusherBagsPath = basePath .. ".pusherBags.bag(?)"
	local palletBagsPath = basePath .. ".palletBags.bag(?)"

	schema:register(XMLValueType.INT, basePath .. ".palletBags#bagRows", "Bag rows")

	for _, path in ipairs({
		liftBagsPath,
		pusherBagsPath,
		palletBagsPath
	}) do
		schema:register(XMLValueType.VECTOR_TRANS, path .. "#position", "Bag translation")
		schema:register(XMLValueType.VECTOR_ROT, path .. "#rotation", "Bag rotation")
	end
end

function StrawHarvestPalletizer:onCreate()
	log("StrawHarvestPalletizer onCreate is not supported!")
end

function StrawHarvestPalletizer.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or strawHarvestPalletizer_mt)
	self.nodeId = 0
	self.activeDirtyFlag = self:getNextDirtyFlag()
	self.statsDirtyFlag = self:getNextDirtyFlag()
	self.syncDirtyFlag = self:getNextDirtyFlag()

	registerObjectClassName(self, "StrawHarvestPalletizer")

	return self
end

function StrawHarvestPalletizer:load(xmlFilename, x, y, z, rx, ry, rz, key)
	self.configFileName = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	local xmlFile = XMLFile.load("palletizer", xmlFilename, StrawHarvestPalletizer.xmlSchema)

	if xmlFile == 0 then
		Logging.xmlError(self.configFileName, "Filename (xml) of the palletizer cannot be nil!")

		return false
	end

	local i3dFilename = xmlFile:getValue(key .. ".i3dFilename")

	if i3dFilename == nil then
		Logging.xmlError(self.configFileName, "I3d Filename of the palletizer cannot be nil!")
		xmlFile:delete()

		return false
	end

	self.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
	self.components = {}

	if not self:createNode(self.i3dFilename) then
		Logging.xmlError(self.configFileName, "Failed to load i3d file: [%s]", self.i3dFilename)
		xmlFile:delete()

		return false
	end

	self.i3dMappings = {}

	I3DUtil.loadI3DMapping(xmlFile, key, self.components, self.i3dMappings, 1)
	self:initPose(x, y, z, rx, ry, rz)

	self.isActive = false
	self.isActiveNextFrame = false
	self.isFillingActive = false
	self.litersPerSecond = xmlFile:getValue(key .. ".litersPerSecond", 10)
	local bunkerBuffer = self:createBufferStorage(self.components, xmlFile, ("%s.bunkerBuffer"):format(key))

	if bunkerBuffer ~= nil then
		self.bunkerBuffer = bunkerBuffer
	end

	local pelletizerBuffer = self:createBufferStorage(self.components, xmlFile, ("%s.pelletizerBuffer"):format(key))

	if pelletizerBuffer ~= nil then
		self.pelletizerBuffer = pelletizerBuffer

		self.pelletizerBuffer:addDependingStorageBuffer(self.bunkerBuffer)
	end

	local unloadKey = ("%s.unloadTrigger"):format(key)
	local unloadPlace = UnloadTrigger.new(self.isServer, self.isClient)

	if unloadPlace:load(self.components, xmlFile, unloadKey, self.bunkerBuffer) then
		unloadPlace:register(true)

		self.unloadPlace = unloadPlace
	else
		unloadPlace:delete()
	end

	local triggerNode = xmlFile:getValue(key .. ".playerTrigger#node", nil, self.components, self.i3dMappings)

	if triggerNode == nil then
		Logging.xmlError(self.configFileName, "StrawHarvestPalletizer could not load player trigger")
		xmlFile:delete()

		return false
	end

	self.playerTriggerNode = triggerNode
	self.playerInRange = false

	addTrigger(triggerNode, "playerTriggerCallback", self)

	self.animationUtil = StrawHarvestAnimationUtil.new(self.isServer, self.isClient, self.baseDirectory)

	self:loadBagCreations(xmlFile, key)

	self.samples = {}

	if self.isClient then
		self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effect", self.components, self, self.i3dMappings)
		self.samples.work = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
	end

	self.unloadAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.unloadAnimationPackage"):format(key), self.i3dMappings)
	self.loadAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.loadAnimationPackage"):format(key), self.i3dMappings)
	self.beltBunkerAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.beltBunkerAnimationPackage"):format(key), self.i3dMappings)

	self.bunkerBuffer:setFillProgressListenerFunction(function (progress)
		self.animationUtil:setAnimationPackageTime(self.unloadAnimationPackage, progress)
	end)
	self.pelletizerBuffer:setFillProgressListenerFunction(function (progress)
		self.animationUtil:setAnimationPackageTime(self.loadAnimationPackage, progress)
	end)

	self.beltBagAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.beltBagAnimationPackage"):format(key), self.i3dMappings)
	self.bagFillAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.bagFillAnimationPackage"):format(key), self.i3dMappings)
	self.bagDropAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.bagDropAnimationPackage"):format(key), self.i3dMappings)
	self.conveyorBeltGhostAnimationPackage = self.animationUtil:loadGhostAnimation(xmlFile, self.components, ("%s.animationPackages.ghostAnimation"):format(key), self.i3dMappings)
	self.currentConveyorBeltGhostAnimationPackage = nil
	self.rotatoryBeltAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.animationPackages.rotatoryBeltAnimationPackage"):format(key), self.i3dMappings)

	if self.isServer then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
		g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
		g_messageCenter:subscribe(MessageType.STRAW_HARVEST_CRANE_MOUNT_OBJECT, self.onObjectRemovedFromPhysics, self)
	end

	xmlFile:delete()

	return true
end

function StrawHarvestPalletizer:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	if self.unloadPlace ~= nil then
		self.unloadPlace:delete()
	end

	if self.bunkerBuffer ~= nil then
		self.bunkerBuffer:delete()
	end

	if self.pelletizerBuffer ~= nil then
		self.pelletizerBuffer:delete()
	end

	if self.isClient then
		g_effectManager:deleteEffects(self.effects)
		g_soundManager:deleteSamples(self.samples)
	end

	self.animationUtil:delete()
	removeTrigger(self.playerTriggerNode)

	for _, place in pairs(self.palletOutputPlaces) do
		removeTrigger(place.triggerId)
	end

	if self.components ~= nil then
		for _, v in pairs(self.components) do
			if entityExists(v.node) then
				delete(v.node)
			end
		end
	end

	if self.nodeId ~= 0 then
		if entityExists(self.nodeId) then
			delete(self.nodeId)
		end

		self.nodeId = 0
	end

	if self.isServer then
		g_messageCenter:unsubscribeAll(self)
	end

	unregisterObjectClassName(self)
	StrawHarvestPalletizer:superClass().delete(self)
end

function StrawHarvestPalletizer:readPositionInStream(streamId)
	local x = streamReadFloat32(streamId)
	local y = streamReadFloat32(streamId)
	local z = streamReadFloat32(streamId)
	local rx = NetworkUtil.readCompressedAngle(streamId)
	local ry = NetworkUtil.readCompressedAngle(streamId)
	local rz = NetworkUtil.readCompressedAngle(streamId)

	return x, y, z, rx, ry, rz
end

function StrawHarvestPalletizer:writePositionInStream(node, streamId)
	local x, y, z = getTranslation(node)
	local rx, ry, rz = getRotation(node)

	streamWriteFloat32(streamId, x)
	streamWriteFloat32(streamId, y)
	streamWriteFloat32(streamId, z)
	NetworkUtil.writeCompressedAngle(streamId, rx)
	NetworkUtil.writeCompressedAngle(streamId, ry)
	NetworkUtil.writeCompressedAngle(streamId, rz)
end

function StrawHarvestPalletizer:readStream(streamId, connection)
	StrawHarvestPalletizer:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		if self.nodeId == 0 then
			self:createNode(i3dFilename)
		end

		local bunkerId = NetworkUtil.readNodeObjectId(streamId)

		self.bunkerBuffer:readStream(streamId, connection)
		g_client:finishRegisterObject(self.bunkerBuffer, bunkerId)

		local pelletizerId = NetworkUtil.readNodeObjectId(streamId)

		self.pelletizerBuffer:readStream(streamId, connection)
		g_client:finishRegisterObject(self.pelletizerBuffer, pelletizerId)

		local unloadPlaceId = NetworkUtil.readNodeObjectId(streamId)

		self.unloadPlace:readStream(streamId, connection)
		g_client:finishRegisterObject(self.unloadPlace, unloadPlaceId)

		local animationId = NetworkUtil.readNodeObjectId(streamId)

		g_client:finishRegisterObject(self.animationUtil, animationId)

		local isActive = streamReadBool(streamId)
		self.isFillingActive = streamReadBool(streamId)

		self.animationUtil:setIsActive(self.isActive)

		local bagsToday = streamReadInt32(streamId)
		local palletsToday = streamReadInt32(streamId)

		self:setStatistics(bagsToday, palletsToday)

		self.isActive = false

		self.animationUtil:setIsActive(false)

		self.currentRotatoryPattern = streamReadInt8(streamId)
		self.currentPusherPattern = streamReadInt8(streamId)
		self.currentLifterPattern = streamReadInt8(streamId)
		local pattern = self.bagPatterns[self.currentPusherPattern]
		local animationTime = streamReadFloat32(streamId)

		self.animationUtil:setAnimationPackageTime(pattern.pusherFirstAnimationPackage, animationTime)

		local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		local numOfLiftNodes = streamReadInt8(streamId)
		local lifterPattern = self.bagPatterns[self.currentLifterPattern]

		for i = 1, numOfLiftNodes do
			local node = self:getClonedBag(fillType)
			local x, y, z, rx, ry, rz = self:readPositionInStream(streamId)

			self:linkToNode(node, self.bagLifterBagGuideNode)
			table.insert(lifterPattern.bagNodes, node)
			setTranslation(node, x, y, z)
			setRotation(node, rx, ry, rz)
		end

		local liftAnimationTime = streamReadFloat32(streamId)

		if numOfLiftNodes ~= 0 then
			self:handBagOverToLift(liftAnimationTime)
		end

		self.bagLifterCurrentBagRow = streamReadInt8(streamId)
		local numOfPalletNodes = streamReadInt8(streamId)

		if self.bagLifterCurrentBagRow > 0 and self:canCreateLiftPallet() then
			self:createLiftPallet(true)
		end

		for i = 1, numOfPalletNodes do
			local node = self:getClonedBag(fillType)

			self:linkToNode(node, self.bagLifterPalletGuideNode)
			table.insert(self.bagLifterPalletNodes, node)

			local x, y, z, rx, ry, rz = self:readPositionInStream(streamId)

			setTranslation(node, x, y, z)
			setRotation(node, rx, ry, rz)
		end

		local numOfPusherNodes = streamReadInt8(streamId)

		for i = 1, numOfPusherNodes do
			local node = self:getClonedBag(fillType)
			local x, y, z, rx, ry, rz = self:readPositionInStream(streamId)
			pattern.currentRotatoryBag = node

			self:handBagOverToPusher()
			self:guideNodesMoved()
			setTranslation(node, x, y, z)
			setRotation(node, rx, ry, rz)
		end
	end
end

function StrawHarvestPalletizer:writeStream(streamId, connection)
	StrawHarvestPalletizer:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.bunkerBuffer))
		self.bunkerBuffer:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.bunkerBuffer)
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.pelletizerBuffer))
		self.pelletizerBuffer:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.pelletizerBuffer)
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadPlace))
		self.unloadPlace:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.unloadPlace)
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.animationUtil))
		g_server:registerObjectInStream(connection, self.animationUtil)
		streamWriteBool(streamId, self.isActive)
		streamWriteBool(streamId, self.isFillingActive)
		streamWriteInt32(streamId, self.bagsToday)
		streamWriteInt32(streamId, self.palletsToday)

		local isActive = self.isActive
		self.isActive = false

		self.animationUtil:setIsActive(false)
		self:cleanBagsOnLine()
		streamWriteInt8(streamId, self.currentRotatoryPattern)
		streamWriteInt8(streamId, self.currentPusherPattern)
		streamWriteInt8(streamId, self.currentLifterPattern)

		local pattern = self.bagPatterns[self.currentPusherPattern]

		streamWriteFloat32(streamId, self.animationUtil:getAnimationPackageTime(pattern.pusherFirstAnimationPackage))

		local fillType = self.pelletizerBuffer:getFillType()

		if fillType == FillType.UNKNOWN then
			fillType = self.pelletizerBuffer:getLastValidFillType()
		end

		if fillType == nil then
			fillType = FillType.STRAW_PELLETS
		end

		streamWriteUIntN(streamId, fillType, FillTypeManager.SEND_NUM_BITS)
		streamWriteInt8(streamId, #self.bagLifterBags)

		for i = 1, #self.bagLifterBags do
			local node = self.bagLifterBags[i]

			self:writePositionInStream(node, streamId)
		end

		local liftAnimationTime = self.animationUtil:getAnimationPackageTime(self.bagLifterMovementAnimationPackage)

		streamWriteFloat32(streamId, liftAnimationTime)
		streamWriteInt8(streamId, self.bagLifterCurrentBagRow)
		streamWriteInt8(streamId, #self.bagLifterPalletNodes)

		for i = 1, #self.bagLifterPalletNodes do
			local node = self.bagLifterPalletNodes[i]

			self:writePositionInStream(node, streamId)
		end

		streamWriteInt8(streamId, #pattern.bagNodes)

		for i = 1, #pattern.bagNodes do
			local node = pattern.bagNodes[i]

			self:writePositionInStream(node, streamId)
		end

		self.isActiveNextFrame = isActive
	end
end

function StrawHarvestPalletizer:readUpdateStream(streamId, timestamp, connection)
	StrawHarvestPalletizer:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if streamReadBool(streamId) and not self.isActiveNextFrame then
		local isActive = self.isActive
		self.isActive = false

		self.animationUtil:setIsActive(false)
		self:cleanBagsOnLine()

		self.isActiveNextFrame = isActive
	end

	if connection:getIsServer() then
		if streamReadBool(streamId) then
			self.isActive = streamReadBool(streamId)
			self.isFillingActive = streamReadBool(streamId)

			self.animationUtil:setIsActive(self.isActive)
		end

		if streamReadBool(streamId) then
			local bagsToday = streamReadUInt16(streamId)
			local palletsToday = streamReadUInt16(streamId)

			self:setStatistics(bagsToday, palletsToday)
		end
	end
end

function StrawHarvestPalletizer:writeUpdateStream(streamId, connection, dirtyMask)
	StrawHarvestPalletizer:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	streamWriteBool(streamId, bitAND(dirtyMask, self.syncDirtyFlag) ~= 0)

	if not connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, self.activeDirtyFlag) ~= 0) then
			streamWriteBool(streamId, self.isActive)
			streamWriteBool(streamId, self.isFillingActive)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.statsDirtyFlag) ~= 0) then
			streamWriteUInt16(streamId, self.bagsToday)
			streamWriteUInt16(streamId, self.palletsToday)
		end
	end
end

function StrawHarvestPalletizer:update(dt)
	StrawHarvestPalletizer:superClass().update(self, dt)

	if self.isServer and self.isActiveNextFrame then
		self:raiseDirtyFlags(self.syncDirtyFlag)
	end

	if self.isActive then
		self:raiseActive()
	end

	if self.isServer then
		local isFilling = self:fillPalletizer(dt)

		self:checkActiveState(isFilling)
	end

	if self.isClient then
		if self.animationUtil:isAnimationPackagePlaying(self.beltBagAnimationPackage) ~= self.isActive then
			self.animationUtil:setIsAnimationPackagePlaying(self.beltBagAnimationPackage, self.isActive)
		end

		if self.animationUtil:isAnimationPackagePlaying(self.beltBunkerAnimationPackage) ~= self.isFillingActive then
			self.animationUtil:setIsAnimationPackagePlaying(self.beltBunkerAnimationPackage, self.isFillingActive)
		end

		local pattern = self.bagPatterns[self.currentRotatoryPattern]

		if pattern ~= nil and self.animationUtil:isAnimationPackagePlaying(pattern.rotatoryAnimationPackage) ~= self.isActive then
			self.animationUtil:setIsAnimationPackagePlaying(self.rotatoryBeltAnimationPackage, self.isActive)
		end

		if self.playerInRange then
			self:showStatistics()
			self:raiseActive()
		end

		self:setEffectActive(self.isFillingActive)

		if self.isActive then
			if not g_soundManager:getIsSamplePlaying(self.samples.work) then
				g_soundManager:playSample(self.samples.work)
			end
		elseif g_soundManager:getIsSamplePlaying(self.samples.work) then
			g_soundManager:stopSample(self.samples.work)
		end
	end

	if self.isActive then
		if self:canCreateBag() then
			self:createBag()
		end

		if self:canCreateLiftPallet() then
			self:createLiftPallet(false)
		end
	end

	if self.isServer and self.createPalletNextFrameFromSave then
		local fillType = self.pelletizerBuffer:getFillType()

		if fillType == FillType.UNKNOWN then
			fillType = self.pelletizerBuffer:getLastValidFillType()
		end

		local outputPlaceIndex = self:getNextOutputPlace(1)

		self:createPallet(outputPlaceIndex, fillType)

		self.createPalletNextFrameFromSave = false
	end

	if self.isActiveNextFrame then
		self.isActive = true

		self.animationUtil:setIsActive(self.isActive)

		self.isActiveNextFrame = false
	end
end

function StrawHarvestPalletizer:fillPalletizer(dt)
	local bunkerFillLevel = self.bunkerBuffer:getFillLevel()
	local bunkerFillType = self.bunkerBuffer:getFillType()
	local palletizerFillProgress = self.pelletizerBuffer:getFillProgress()
	local thresholdReached = false

	if bunkerFillLevel > 0 and self.pelletizerBuffer:getIsFillTypeAllowed(bunkerFillType) and not self.isFillingActive and palletizerFillProgress < 0.5 then
		thresholdReached = true
	end

	local delta = 0

	if self.isFillingActive then
		local palletizerFillLevel = self.pelletizerBuffer:getFillLevel()
		local palletizerFreeCapacity = self.pelletizerBuffer:getFreeCapacity()
		delta = math.min(bunkerFillLevel, self.litersPerSecond * dt * 0.001, palletizerFreeCapacity)

		self.pelletizerBuffer:setFillLevel(palletizerFillLevel + delta, bunkerFillType)
		self.bunkerBuffer:setFillLevel(bunkerFillLevel - delta, bunkerFillType)
	end

	return delta > 0 or thresholdReached
end

function StrawHarvestPalletizer:checkActiveState(isFillingActive)
	if self.isServer then
		local isFilled = self.pelletizerBuffer:getFillProgress() > 0

		if not isFilled then
			local fillType = self.pelletizerBuffer:getFillType()
			local amountOfBagsOnBelt = self.fillTypeToClonedBagCount[fillType] or 0
			local amountOfBagsPerPallet = self.bagLifterNumBagRowsOnPallet * StrawHarvestPalletizer.BAGS_PER_ROW
			isFilled = amountOfBagsOnBelt - amountOfBagsPerPallet > 0
		end

		local isActive = isFillingActive or isFilled

		if isActive and not self:hasAvailableOutputPlaces() and (StrawHarvestPalletizer.BAG_LIFTER_MAX_BAG_ROWS <= self.bagLifterCurrentBagRow or #self.palletConveyorBags > 0) then
			isActive = false
		end

		if self.isActive ~= isActive or self.isFillingActive ~= isFillingActive then
			if not isActive then
				g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("notification_palletizer_stopped"))
			end

			self.isActive = isActive
			self.isFillingActive = isFillingActive

			self:raiseDirtyFlags(self.activeDirtyFlag)
			self.animationUtil:setIsActive(isActive)
		end
	end
end

function StrawHarvestPalletizer:loadFromXMLFile(xmlFile, key)
	local bunkerKey = ("%s.bunkerBuffer"):format(key)

	if not self.bunkerBuffer:loadFromXMLFile(xmlFile, bunkerKey) then
		return false
	end

	local pelletizerKey = ("%s.pelletizerBuffer"):format(key)

	if not self.pelletizerBuffer:loadFromXMLFile(xmlFile, pelletizerKey) then
		return false
	end

	self.createPalletNextFrameFromSave = xmlFile:getValue(key .. ".isPalletMovingToDestination", false)
	self.bagsToday = xmlFile:getValue(key .. ".bagsToday", self.bagsToday)
	self.palletsToday = xmlFile:getValue(key .. ".palletsToday", self.palletsToday)
	self.currentRotatoryPattern = xmlFile:getValue(key .. ".currentRotatoryPattern", self.currentRotatoryPattern)
	self.currentPusherPattern = xmlFile:getValue(key .. ".currentPusherPattern", self.currentPusherPattern)
	self.currentLifterPattern = xmlFile:getValue(key .. ".currentLifterPattern", self.currentLifterPattern)
	local fillType = self.pelletizerBuffer:getFillType()

	if fillType == FillType.UNKNOWN then
		fillType = self.pelletizerBuffer:getLastValidFillType()
	end

	local liftKey = ("%s.liftBags"):format(key)

	if liftKey ~= nil then
		local i = 0
		local lifterPattern = self.bagPatterns[self.currentLifterPattern]

		while i < StrawHarvestPalletizer.BAGS_PER_ROW do
			local bagKey = ("%s.bag(%d)"):format(liftKey, i)

			if not xmlFile:hasProperty(bagKey) then
				break
			end

			local node = self:getClonedBag(fillType)
			local translation = xmlFile:getValue(bagKey .. "#position", nil, true)
			local rotation = xmlFile:getValue(bagKey .. "#rotation", nil, true)

			self:linkToNode(node, self.bagLifterBagGuideNode)
			table.insert(lifterPattern.bagNodes, node)
			setTranslation(node, unpack(translation))
			setRotation(node, unpack(rotation))

			i = i + 1
		end

		if i ~= 0 then
			local liftAnimationTime = xmlFile:getValue(liftKey .. "#liftAnimationTime")

			self:handBagOverToLift(liftAnimationTime)
		end
	end

	local patternKey = ("%s.pusherBags"):format(key)

	if patternKey ~= nil then
		local pattern = self.bagPatterns[self.currentPusherPattern]
		local i = 0

		while i < StrawHarvestPalletizer.BAGS_PER_ROW do
			local bagKey = ("%s.bag(%d)"):format(patternKey, i)

			if not xmlFile:hasProperty(bagKey) then
				break
			end

			local node = self:getClonedBag(fillType)
			local translation = xmlFile:getValue(bagKey .. "#position", nil, true)
			local rotation = xmlFile:getValue(bagKey .. "#rotation", nil, true)
			pattern.currentRotatoryBag = node

			self:handBagOverToPusher()
			self:guideNodesMoved()
			setTranslation(node, unpack(translation))
			setRotation(node, unpack(rotation))

			i = i + 1
		end
	end

	local palletKey = ("%s.palletBags"):format(key)
	local rows = xmlFile:getValue(palletKey .. "#bagRows")

	if rows ~= nil and rows > 0 then
		if self:canCreateLiftPallet() then
			self:createLiftPallet(true)
		end

		self.bagLifterCurrentBagRow = math.min(rows, self.bagLifterNumBagRowsOnPallet)
		local maxAmountOfBags = self.bagLifterCurrentBagRow * StrawHarvestPalletizer.BAGS_PER_ROW
		local i = 0

		while maxAmountOfBags > i do
			local bagKey = ("%s.bag(%d)"):format(palletKey, i)

			if not xmlFile:hasProperty(bagKey) then
				break
			end

			local node = self:getClonedBag(fillType)

			self:linkToNode(node, self.bagLifterPalletGuideNode)
			table.insert(self.bagLifterPalletNodes, node)

			local translation = xmlFile:getValue(bagKey .. "#position", nil, true)
			local rotation = xmlFile:getValue(bagKey .. "#rotation", nil, true)

			setTranslation(node, unpack(translation))
			setRotation(node, unpack(rotation))

			i = i + 1
		end
	end

	self:raiseActive()

	return true
end

function StrawHarvestPalletizer:saveToXMLFile(xmlFile, key, usedModNames)
	local isActive = self.isActive
	self.isActive = false

	self.animationUtil:setIsActive(false)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())

	local bunkerKey = ("%s.bunkerBuffer"):format(key)

	self.bunkerBuffer:saveToXMLFile(xmlFile, bunkerKey, usedModNames)

	local pelletizerKey = ("%s.pelletizerBuffer"):format(key)

	self.pelletizerBuffer:saveToXMLFile(xmlFile, pelletizerKey, usedModNames)
	xmlFile:setValue(key .. ".isPalletMovingToDestination", self.isPalletMovingToDestination)
	xmlFile:setValue(key .. ".bagsToday", self.bagsToday)
	xmlFile:setValue(key .. ".palletsToday", self.palletsToday)
	xmlFile:setValue(key .. ".currentRotatoryPattern", self.currentRotatoryPattern)
	xmlFile:setValue(key .. ".currentPusherPattern", self.currentPusherPattern)
	xmlFile:setValue(key .. ".currentLifterPattern", self.currentLifterPattern)
	self:cleanBagsOnLine()

	local function saveBag(bagKey, node)
		local x, y, z = getTranslation(node)
		local xRot, yRot, zRot = getRotation(node)

		xmlFile:setValue(bagKey .. "#position", x, y, z)
		xmlFile:setValue(bagKey .. "#rotation", xRot, yRot, zRot)
	end

	local pattern = self.bagPatterns[self.currentPusherPattern]

	if pattern.numOfBags > 0 then
		local patternKey = ("%s.pusherBags"):format(key)

		for i, node in ipairs(pattern.bagNodes) do
			local bagKey = ("%s.bag(%d)"):format(patternKey, i - 1)

			saveBag(bagKey, node)
		end
	end

	local liftKey = ("%s.liftBags"):format(key)
	local liftAnimationTime = self.animationUtil:getAnimationPackageTime(self.bagLifterMovementAnimationPackage)

	xmlFile:setValue(liftKey .. "#liftAnimationTime", liftAnimationTime)

	for i, node in ipairs(self.bagLifterBags) do
		local bagKey = ("%s.bag(%d)"):format(liftKey, i - 1)

		saveBag(bagKey, node)
	end

	local palletKey = ("%s.palletBags"):format(key)
	local rows = #self.bagLifterPalletNodes / StrawHarvestPalletizer.BAGS_PER_ROW

	xmlFile:setValue(palletKey .. "#bagRows", math.min(rows, self.bagLifterCurrentBagRow))

	for i, node in ipairs(self.bagLifterPalletNodes) do
		local bagKey = ("%s.bag(%d)"):format(palletKey, i - 1)

		saveBag(bagKey, node)
	end

	self.isActiveNextFrame = isActive
end

function StrawHarvestPalletizer:cleanBagsOnLine()
	local numOfBagsLeft = 0
	numOfBagsLeft = numOfBagsLeft + self:removeActiveBag(self.currentBag, self.bagFillAnimationPackage)
	numOfBagsLeft = numOfBagsLeft + self:removeActiveBag(self.currentDropBag, self.bagDropAnimationPackage)
	local rotatoryPattern = self.bagPatterns[self.currentRotatoryPattern]
	numOfBagsLeft = numOfBagsLeft + self:removeActiveBag(rotatoryPattern.currentRotatoryBag, self.currentConveyorBeltGhostAnimationPackage)
	numOfBagsLeft = numOfBagsLeft + self.animationUtil:resetGhostPackages()

	if self.isServer and numOfBagsLeft > 0 then
		local fillType = self.pelletizerBuffer:getFillType()

		if fillType == FillType.UNKNOWN then
			fillType = self.pelletizerBuffer:getLastValidFillType()
		end

		local palletizerFillLevel = self.pelletizerBuffer:getFillLevel()
		local delta = numOfBagsLeft * self.literPerBag

		self.pelletizerBuffer:setFillLevel(palletizerFillLevel + delta, fillType)

		if numOfBagsLeft ~= 0 then
			self:setStatistics(self.bagsToday - numOfBagsLeft, self.palletsToday)
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("notification_palletizer_refilled"):format(numOfBagsLeft))
		end
	end
end

function StrawHarvestPalletizer:removeActiveBag(bag, animationPackage)
	if bag ~= nil then
		if animationPackage ~= nil then
			self.animationUtil:stopAnimationPackage(animationPackage)
			self.animationUtil:setAnimationPackageTime(animationPackage, 0)
		end

		self:removeClonedBag(bag)

		bag = nil

		return 1
	end

	return 0
end

function StrawHarvestPalletizer:finalizePlacement()
	addToPhysics(self.nodeId)

	local farmId = self:getOwnerFarmId()

	self.bunkerBuffer:setOwnerFarmId(farmId, true)
	self.bunkerBuffer:register(true)
	self.pelletizerBuffer:setOwnerFarmId(farmId, true)
	self.pelletizerBuffer:register(true)
	self.animationUtil:setOwnerFarmId(farmId, true)
	self.animationUtil:register(true)
end

function StrawHarvestPalletizer:collectPickObjects(node)
	if not node == self.unloadPlace.exactFillRootNode then
		StrawHarvestPalletizer:superClass().collectPickObjects(self, node)
	end
end

function StrawHarvestPalletizer:initPose(x, y, z, rx, ry, rz)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)
end

function StrawHarvestPalletizer:createBufferStorage(components, xmlFile, key)
	local buffer = StrawHarvestStorageBuffer.new(self.isServer, self.isClient)

	if not buffer:load(components, xmlFile, key, self.i3dMappings, self) then
		buffer:delete()

		return nil
	end

	return buffer
end

function StrawHarvestPalletizer:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local root, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId

	if root == 0 then
		return false
	end

	local numChildren = getNumOfChildren(root)

	for i = 0, numChildren - 1 do
		local component = {
			node = getChildAt(root, i)
		}

		table.insert(self.components, component)
		link(getRootNode(), component.node)
	end

	delete(root)

	self.nodeId = self.components[1].node

	return true
end

function StrawHarvestPalletizer:loadGuideNodes(xmlFile, baseKey)
	local nodes = {}
	local i = 0

	while true do
		local key = ("%s.guideNode(%d)"):format(baseKey, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

		table.insert(nodes, node)

		i = i + 1
	end

	return nodes
end

function StrawHarvestPalletizer:loadBagCreationPatterns(xmlFile, baseKey)
	self.bagPatterns = {}
	self.currentRotatoryPattern = 1
	self.currentPusherPattern = 1
	self.currentLifterPattern = 1
	local i = 0

	while true do
		local key = ("%s.patterns.pattern(%d)"):format(baseKey, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local pattern = {
			numOfBags = 0,
			guideNodes = self:loadGuideNodes(xmlFile, key .. ".guideNodes"),
			bagNodes = {},
			rotatoryAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.rotatory.rotatoryAnimationPackage"):format(key), self.i3dMappings),
			rotatoryGuideNode = xmlFile:getValue(key .. ".rotatory#guideNode", nil, self.components, self.i3dMappings),
			rotatoryPlayPattern = xmlFile:getValue(key .. ".rotatory#playPattern", nil, true),
			firstMovementBagThreshold = xmlFile:getValue(key .. "#firstMovementBagThreshold", 0),
			secondMovementBagThreshold = xmlFile:getValue(key .. "#secondMovementBagThreshold", 0),
			firstMovementAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.firstMovementAnimationPackage"):format(key), self.i3dMappings),
			secondMovementAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.secondMovementAnimationPackage"):format(key), self.i3dMappings),
			pusherFirstAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.pusher.pusherFirstAnimationPackage"):format(key), self.i3dMappings),
			pusherPushThroughAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, ("%s.pusher.pusherPushThroughAnimationPackage"):format(key), self.i3dMappings)
		}

		self.animationUtil:setAnimationPackageTime(pattern.pusherFirstAnimationPackage, 0)
		table.insert(self.bagPatterns, pattern)

		i = i + 1
	end
end

function StrawHarvestPalletizer:loadPalletOutputPlaces(xmlFile, baseKey)
	local palletOutputKey = baseKey .. ".palletOutput"
	self.movePalletToDestinationAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, palletOutputKey .. ".movePalletToDestinationAnimationPackage", self.i3dMappings)
	self.isPalletMovingToDestination = false
	self.createPalletNextFrameFromSave = false
	self.palletOutputGuideNode = xmlFile:getValue(palletOutputKey .. "#palletGuideNode", nil, self.components, self.i3dMappings)
	self.palletOutputPlacesByTrigger = {}
	self.palletOutputPlaces = {}
	local duration = self.animationUtil:getAnimationPackageDuration(self.movePalletToDestinationAnimationPackage)
	local i = 0

	while true do
		local key = ("%s.places.place(%d)"):format(palletOutputKey, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local place = {}
		local triggerId = xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)

		if triggerId ~= nil then
			place.triggerId = triggerId

			addTrigger(triggerId, "outputPlaceTriggerCallback", self)

			place.numOfObjectsInTrigger = 0
			place.objectsInTrigger = {}
			place.animationTime = xmlFile:getValue(key .. "#animationTime") * duration
			place.spawnOffset = xmlFile:getValue(key .. "#spawnOffset", 0)
			self.palletOutputPlacesByTrigger[triggerId] = place

			table.insert(self.palletOutputPlaces, place)
		end

		i = i + 1
	end
end

function StrawHarvestPalletizer:loadPalletConveyor(xmlFile, baseKey)
	local conveyorKey = baseKey .. ".conveyor"
	self.conveyorMovePalletOutAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, conveyorKey .. ".conveyorMovePalletOutAnimationPackage", self.i3dMappings)
	self.conveyorPalletGuideNode = xmlFile:getValue(conveyorKey .. "#palletGuideNode", nil, self.components, self.i3dMappings)
	self.palletConveyorBags = {}
	self.palletConveyorPallet = nil
end

function StrawHarvestPalletizer:loadPalletStacker(xmlFile, baseKey)
	local palletStackerKey = baseKey .. ".palletStacker"
	self.palletStackerDeliverPalletAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, palletStackerKey .. ".palletStackerDeliverPalletAnimationPackage", self.i3dMappings)
	self.palletGuideNode = xmlFile:getValue(palletStackerKey .. "#palletGuideNode", nil, self.components, self.i3dMappings)
	self.palletCloneNode = xmlFile:getValue(palletStackerKey .. "#palletCloneNode", nil, self.components, self.i3dMappings)
end

function StrawHarvestPalletizer:loadBagLifter(xmlFile, baseKey)
	local bagLifterKey = baseKey .. ".bagLifter"
	self.bagLifterMovementAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, bagLifterKey .. ".bagLifterMovementAnimationPackage", self.i3dMappings)
	self.bagLifterPutBagsOnPalletAnimationPackage = self.animationUtil:loadAnimationPackage(xmlFile, self.components, bagLifterKey .. ".bagLifterPutBagsOnPalletAnimationPackage", self.i3dMappings)
	self.bagLifterPalletGuideNode = xmlFile:getValue(bagLifterKey .. "#palletGuideNode", nil, self.components, self.i3dMappings)
	self.bagLifterBagGuideNode = xmlFile:getValue(bagLifterKey .. "#bagGuideNode", nil, self.components, self.i3dMappings)
	local duration = self.animationUtil:getAnimationPackageDuration(self.bagLifterMovementAnimationPackage)
	self.bagLifterMinAnimationTime = xmlFile:getValue(bagLifterKey .. "#minAnimationTime") * duration
	self.bagLifterMaxAnimationTime = xmlFile:getValue(bagLifterKey .. "#maxAnimationTime") * duration
	self.bagLifterLoadPosAnimationTime = xmlFile:getValue(bagLifterKey .. "#loadPosAnimationTime") * duration

	self.animationUtil:setAnimationPackageTime(self.bagLifterMovementAnimationPackage, self.bagLifterLoadPosAnimationTime / duration)

	self.bagLifterAnimationTimePerBagLayer = xmlFile:getValue(bagLifterKey .. "#animationTimePerBagLayer") * duration
	self.bagLifterNumBagRowsOnPallet = xmlFile:getValue(bagLifterKey .. "#numBagRowsOnPallet")
	self.bagLifterCurrentBagRow = 0
	self.bagLifterBags = {}
	self.bagLifterPalletNodes = {}
end

function StrawHarvestPalletizer:loadBagCreations(xmlFile, baseKey)
	local bagCreationsKey = baseKey .. ".bagCreations"
	self.literPerBag = xmlFile:getValue(bagCreationsKey .. "#literPerBag", 50)
	self.costPerBag = xmlFile:getValue(bagCreationsKey .. "#costPerBag", 1.25)
	self.hourlyCosts = 0
	self.bagsToday = 0
	self.palletsToday = 0
	self.bagFillGuideNode = xmlFile:getValue(bagCreationsKey .. "#fillGuideNode", nil, self.components, self.i3dMappings)
	self.bagDropGuideNode = xmlFile:getValue(bagCreationsKey .. "#dropGuideNode", nil, self.components, self.i3dMappings)
	self.currentBag = nil
	self.currentDropBag = nil
	self.fillTypeToCloneableBag = {}
	self.fillTypeToClonedBagCount = {}
	self.fillTypeToDecisionWeight = {}
	self.clonedBagToFillType = {}
	self.fillTypeToPalletXML = {}
	local i = 0

	while true do
		local key = ("%s.bagCreation(%d)"):format(bagCreationsKey, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local fillType = xmlFile:getValue(key .. "#fillType")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillType)
		local decisionWeight = xmlFile:getValue(key .. "#fillTypeDecisionWeight", 1)
		local cloneNode = xmlFile:getValue(key .. "#cloneNode", nil, self.components, self.i3dMappings)
		local palletXMLFilename = xmlFile:getValue(key .. "#palletXMLFilename", "")

		if fillTypeIndex ~= nil and cloneNode ~= nil then
			self.fillTypeToCloneableBag[fillTypeIndex] = cloneNode
			self.fillTypeToDecisionWeight[fillTypeIndex] = decisionWeight
			self.fillTypeToPalletXML[fillTypeIndex] = Utils.getFilename(palletXMLFilename, self.baseDirectory)
		end

		i = i + 1
	end

	self:loadBagCreationPatterns(xmlFile, bagCreationsKey)
	self:loadBagLifter(xmlFile, baseKey)
	self:loadPalletStacker(xmlFile, baseKey)
	self:loadPalletConveyor(xmlFile, baseKey)
	self:loadPalletOutputPlaces(xmlFile, baseKey)
end

function StrawHarvestPalletizer:setEffectActive(isActive)
	if isActive then
		if self.effects ~= nil then
			local lastValidFillType = self.bunkerBuffer:getFillType()

			g_effectManager:setFillType(self.effects, lastValidFillType)
			g_effectManager:startEffects(self.effects)
		end
	elseif self.effects ~= nil then
		g_effectManager:stopEffects(self.effects)
	end
end

function StrawHarvestPalletizer:setStatistics(numOfBags, numOfPallets)
	self.bagsToday = numOfBags
	self.palletsToday = numOfPallets

	if self.isServer then
		self:raiseDirtyFlags(self.statsDirtyFlag)
	end
end

function StrawHarvestPalletizer:showStatistics()
	local statsText = g_i18n:getText("statistics_palletizer_bags"):format(self.bagsToday, self.palletsToday)

	g_currentMission:addExtraPrintText(statsText)

	local capacity = self.pelletizerBuffer:getCapacity()
	local bunkerFillLevel = self.bunkerBuffer:getFillLevel()
	local fillLevel = self.pelletizerBuffer:getFillLevel()
	local numBagToGoLeft = (fillLevel + bunkerFillLevel) / self.literPerBag
	local numMinutesLeft = numBagToGoLeft * self.animationUtil:getAnimationPackageDuration(self.bagFillAnimationPackage) * 0.001 / 60
	local timeText = g_i18n:getText("statistics_palletizer_time"):format(math.floor(numMinutesLeft), math.floor((numMinutesLeft - math.floor(numMinutesLeft)) * 60))

	g_currentMission:addExtraPrintText(timeText)

	local fillType = g_fillTypeManager:getFillTypeByIndex(self.pelletizerBuffer:getFillType())
	local fillTypeName = fillType ~= nil and fillType.title or ""
	local fillInfoText = string.format(g_i18n:getText("info_fillLevel") .. " %s: %s (%d%%)", fillTypeName, g_i18n:formatFluid(fillLevel), math.floor(100 * fillLevel / capacity))

	g_currentMission:addExtraPrintText(fillInfoText)

	if not self.isActive and not self:hasAvailableOutputPlaces() then
		g_currentMission:addExtraPrintText(g_i18n:getText("statistics_palletizer_blocked"))
	end
end

function StrawHarvestPalletizer:hasBlockingOutputNeighbour(nextIndex)
	local nextPlace = self.palletOutputPlaces[nextIndex]
	local isBlocking = nextPlace.numOfObjectsInTrigger > 0
	local neighbourIndex = nextIndex + 1

	if not isBlocking and neighbourIndex <= #self.palletOutputPlaces then
		return self:hasBlockingOutputNeighbour(neighbourIndex)
	end

	return isBlocking
end

function StrawHarvestPalletizer:hasAvailableOutputPlaces()
	local startIndex = 1
	local placeIndex = self:getNextOutputPlace(startIndex)
	local isBlocking = placeIndex == nil
	isBlocking = isBlocking or self:hasBlockingOutputNeighbour(math.min(placeIndex + 1, #self.palletOutputPlaces))

	return not isBlocking
end

function StrawHarvestPalletizer:getNextOutputPlace(index)
	local nextIndex = index

	if nextIndex > #self.palletOutputPlaces then
		return nil
	end

	local place = self.palletOutputPlaces[nextIndex]

	if place.numOfObjectsInTrigger > 0 then
		return self:getNextOutputPlace(nextIndex + 1)
	end

	return nextIndex
end

function StrawHarvestPalletizer:canCreateBag()
	if self.animationUtil:isAnimationPackagePlaying(self.bagFillAnimationPackage) then
		return false
	end

	local fillLevel = self.pelletizerBuffer:getFillLevel()
	local fillType = self.pelletizerBuffer:getFillType()

	return fillLevel > 0 and fillType ~= FillType.UNKNOWN
end

function StrawHarvestPalletizer:createBag()
	local fillType = self.pelletizerBuffer:getFillType()

	if self.isServer then
		local fillLevel = self.pelletizerBuffer:getFillLevel()
		local delta = -self.literPerBag

		self.pelletizerBuffer:setFillLevel(fillLevel + delta, fillType)

		if self.pelletizerBuffer:isEmpty() then
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("notification_palletizer_empty"))
		end

		self.hourlyCosts = self.hourlyCosts + self.costPerBag

		self:setStatistics(self.bagsToday + 1, self.palletsToday)
	end

	self.currentBag = self:getClonedBag(fillType)

	link(self.bagFillGuideNode, self.currentBag)
	setTranslation(self.currentBag, 0, 0, 0)
	self.animationUtil:playAnimationPackage(self.bagFillAnimationPackage, 0, self.processBag, self)
end

function StrawHarvestPalletizer:canCreateLiftPallet()
	return self.currentLiftPallet == nil and not self.animationUtil:isAnimationPackagePlaying(self.palletStackerDeliverPalletAnimationPackage)
end

function StrawHarvestPalletizer:createLiftPallet(setInitialPosition)
	self.currentLiftPallet = clone(self.palletCloneNode, false, false, false)

	link(self.palletGuideNode, self.currentLiftPallet)
	setTranslation(self.currentLiftPallet, 0, 0, 0)
	setVisibility(self.currentLiftPallet, true)

	if setInitialPosition then
		local duration = self.animationUtil:getAnimationPackageDuration(self.palletStackerDeliverPalletAnimationPackage)

		self.animationUtil:setAnimationPackageTime(self.palletStackerDeliverPalletAnimationPackage, duration)
		self:handOverPallet()
	else
		self.animationUtil:playAnimationPackage(self.palletStackerDeliverPalletAnimationPackage, 0, self.handOverPallet, self)
	end
end

function StrawHarvestPalletizer:getClonedBag(fillType)
	local cloneNode = self.fillTypeToCloneableBag[fillType]
	local node = clone(cloneNode, false, false, false)
	self.clonedBagToFillType[node] = fillType
	local count = self.fillTypeToClonedBagCount[fillType] or 0
	self.fillTypeToClonedBagCount[fillType] = count + 1

	return node
end

function StrawHarvestPalletizer:removeClonedBag(node)
	local fillType = self.clonedBagToFillType[node]
	self.clonedBagToFillType[node] = nil

	if fillType == nil then
		return
	end

	local count = self.fillTypeToClonedBagCount[fillType] or 0
	self.fillTypeToClonedBagCount[fillType] = math.max(count - 1, 0)

	if entityExists(node) then
		delete(node)
	end
end

function StrawHarvestPalletizer:processBag()
	local node = self.currentBag
	self.currentDropBag = node
	self.currentBag = nil

	self:linkToNode(node, self.bagDropGuideNode)
	self.animationUtil:playAnimationPackage(self.bagDropAnimationPackage, 0, self.handBagOverToBelt, self)
end

function StrawHarvestPalletizer:handBagOverToBelt()
	unlink(self.currentDropBag)

	local bag = self.currentDropBag or self:getClonedBag(self.pelletizerBuffer:getFillType())
	local nodes = {
		bag = bag
	}

	setTranslation(self.currentDropBag, 0, 0, 0)

	self.currentDropBag = nil
	local package = self.animationUtil:createGhostPackage(self.conveyorBeltGhostAnimationPackage, nodes, self.removeClonedBag, self)
	self.currentConveyorBeltGhostAnimationPackage = package

	self.animationUtil:playAnimationPackage(package, 0, self.handBagOverToRotatory, self, {
		package,
		nodes
	})
end

function StrawHarvestPalletizer:handBagOverToRotatory(package, nodes)
	self.animationUtil:deleteGhostPackage(package, false)

	self.currentConveyorBeltGhostAnimationPackage = nil
	local pattern = self.bagPatterns[self.currentRotatoryPattern]

	if nodes ~= nil and not entityExists(nodes.bag) then
		nodes.bag = self:getClonedBag(self.pelletizerBuffer:getFillType())
	end

	pattern.currentRotatoryBag = nodes ~= nil and nodes.bag or self:getClonedBag(self.pelletizerBuffer:getFillType())

	self.animationUtil:setAnimationPackageTime(pattern.rotatoryAnimationPackage, 0)
	self:linkToNode(pattern.currentRotatoryBag, pattern.rotatoryGuideNode)

	local playPatternIndex = pattern.numOfBags + 1

	if pattern.rotatoryPlayPattern[playPatternIndex] == 1 then
		self.animationUtil:playAnimationPackage(pattern.rotatoryAnimationPackage, 0, self.handBagOverToPusher, self)
	else
		self:handBagOverToPusher()
	end
end

function StrawHarvestPalletizer:handBagOverToPusher()
	local pattern = self.bagPatterns[self.currentPusherPattern]
	pattern.numOfBags = pattern.numOfBags + 1

	if not entityExists(pattern.currentRotatoryBag) then
		pattern.currentRotatoryBag = self:getClonedBag(self.pelletizerBuffer:getFillType())
	end

	self:linkToNode(pattern.currentRotatoryBag, pattern.guideNodes[math.min(pattern.numOfBags, #pattern.guideNodes)])
	setTranslation(pattern.currentRotatoryBag, 0, 0, 0)
	table.insert(pattern.bagNodes, pattern.currentRotatoryBag)

	pattern.currentRotatoryBag = nil

	if pattern.numOfBags <= pattern.firstMovementBagThreshold then
		local duration = self.animationUtil:getAnimationPackageDuration(pattern.firstMovementAnimationPackage)
		local startTime = (pattern.numOfBags - 1) / pattern.firstMovementBagThreshold * duration
		local stopTime = pattern.numOfBags / pattern.firstMovementBagThreshold * duration

		self.animationUtil:playAnimationPackageUntil(pattern.firstMovementAnimationPackage, startTime, stopTime, self.guideNodesMoved, self)
	elseif pattern.numOfBags <= pattern.secondMovementBagThreshold then
		if pattern.numOfBags == pattern.secondMovementBagThreshold then
			self.currentRotatoryPattern = self.currentRotatoryPattern + 1

			if self.currentRotatoryPattern > #self.bagPatterns then
				self.currentRotatoryPattern = 1
			end
		end

		local duration = self.animationUtil:getAnimationPackageDuration(pattern.secondMovementAnimationPackage)
		local startTime = (pattern.numOfBags - 1 - pattern.firstMovementBagThreshold) / (pattern.secondMovementBagThreshold - pattern.firstMovementBagThreshold) * duration
		local stopTime = (pattern.numOfBags - pattern.firstMovementBagThreshold) / (pattern.secondMovementBagThreshold - pattern.firstMovementBagThreshold) * duration

		self.animationUtil:playAnimationPackageUntil(pattern.secondMovementAnimationPackage, startTime, stopTime, self.guideNodesMoved, self)
	end
end

function StrawHarvestPalletizer:guideNodesMoved()
	local pattern = self.bagPatterns[self.currentPusherPattern]

	if pattern.numOfBags == pattern.firstMovementBagThreshold then
		self.animationUtil:playAnimationPackage(pattern.pusherFirstAnimationPackage, 0)
	end

	if pattern.numOfBags == pattern.secondMovementBagThreshold then
		self.currentLifterPattern = self.currentPusherPattern

		self.animationUtil:playAnimationPackage(pattern.pusherPushThroughAnimationPackage, 0, self.handBagOverToLift, self)

		self.currentPusherPattern = self.currentRotatoryPattern
	end
end

function StrawHarvestPalletizer:handBagOverToLift(posAnimationTime)
	local pattern = self.bagPatterns[self.currentLifterPattern]

	for _, node in ipairs(pattern.bagNodes) do
		self:linkToNode(node, self.bagLifterBagGuideNode)
		table.insert(self.bagLifterBags, node)
	end

	pattern.bagNodes = {}
	pattern.numOfBags = 0
	local targetTime = self.bagLifterMinAnimationTime + self.bagLifterAnimationTimePerBagLayer * self.bagLifterCurrentBagRow

	self.animationUtil:playAnimationPackageUntil(self.bagLifterMovementAnimationPackage, posAnimationTime or self.bagLifterLoadPosAnimationTime, targetTime, self.bagLifterReachedPalletHeight, self)
end

function StrawHarvestPalletizer:bagLifterReachedPalletHeight()
	self.animationUtil:playAnimationPackage(self.bagLifterPutBagsOnPalletAnimationPackage, 0, self.handBagsOverToPallet, self)
end

function StrawHarvestPalletizer:handBagsOverToPallet()
	for _, node in ipairs(self.bagLifterBags) do
		self:linkToNode(node, self.bagLifterPalletGuideNode)
		table.insert(self.bagLifterPalletNodes, node)
	end

	self.bagLifterBags = {}
	self.bagLifterCurrentBagRow = self.bagLifterCurrentBagRow + 1

	if self.bagLifterCurrentBagRow < self.bagLifterNumBagRowsOnPallet then
		self.animationUtil:playAnimationPackageUntil(self.bagLifterMovementAnimationPackage, nil, self.bagLifterLoadPosAnimationTime)
	elseif self.bagLifterCurrentBagRow == self.bagLifterNumBagRowsOnPallet then
		self.animationUtil:playAnimationPackageUntil(self.bagLifterMovementAnimationPackage, nil, self.bagLifterMaxAnimationTime, self.bagLifterReachedTop, self)

		self.bagLifterCurrentBagRow = 0
	end
end

function StrawHarvestPalletizer:handOverPallet()
	self:linkToNode(self.currentLiftPallet, self.bagLifterPalletGuideNode)
end

function StrawHarvestPalletizer:bagLifterReachedTop()
	self.animationUtil:setAnimationPackageTime(self.conveyorMovePalletOutAnimationPackage, 0)

	for _, node in ipairs(self.bagLifterPalletNodes) do
		self:linkToNode(node, self.conveyorPalletGuideNode)
		table.insert(self.palletConveyorBags, node)
	end

	self.bagLifterPalletNodes = {}

	self:linkToNode(self.currentLiftPallet, self.conveyorPalletGuideNode)

	self.palletConveyorPallet = self.currentLiftPallet

	self.animationUtil:playAnimationPackage(self.conveyorMovePalletOutAnimationPackage, 0, self.handOverToDestinationAnimation, self)

	if self.isServer then
		self.isPalletMovingToDestination = true
	end

	self.currentLiftPallet = nil
end

function StrawHarvestPalletizer:handOverToDestinationAnimation()
	self.animationUtil:setAnimationPackageTime(self.movePalletToDestinationAnimationPackage, 0)

	for _, node in ipairs(self.palletConveyorBags) do
		self:linkToNode(node, self.palletOutputGuideNode)
	end

	self:linkToNode(self.palletConveyorPallet, self.palletOutputGuideNode)

	local outputPlaceIndex = self:getNextOutputPlace(1)

	if outputPlaceIndex ~= nil then
		local animationTime = self.palletOutputPlaces[outputPlaceIndex].animationTime

		self.animationUtil:playAnimationPackageUntil(self.movePalletToDestinationAnimationPackage, 0, animationTime, self.calculatePalletBags, self)
		self.animationUtil:playAnimationPackageUntil(self.bagLifterMovementAnimationPackage, nil, self.bagLifterLoadPosAnimationTime)
	end
end

function StrawHarvestPalletizer:calculatePalletBags()
	local bagsPerFillType = {}

	for _, node in ipairs(self.palletConveyorBags) do
		local fillType = self.clonedBagToFillType[node] or FillType.STRAW_PELLETS
		local amount = bagsPerFillType[fillType] or 0
		bagsPerFillType[fillType] = amount + 1

		self:removeClonedBag(node)
	end

	delete(self.palletConveyorPallet)

	self.palletConveyorBags = {}
	self.palletConveyorPallet = nil

	if self.isServer then
		local lastFillTypeIndex, lastAmount = nil

		for fillTypeIndex, amount in pairs(bagsPerFillType) do
			local updateFillType = lastFillTypeIndex == nil
			updateFillType = updateFillType or lastAmount < amount

			if updateFillType then
				lastFillTypeIndex = fillTypeIndex
				lastAmount = amount * self.fillTypeToDecisionWeight[fillTypeIndex]
			end
		end

		local outputPlaceIndex = self:getNextOutputPlace(1)

		self:createPallet(outputPlaceIndex, lastFillTypeIndex)
	end
end

function StrawHarvestPalletizer:createPallet(outputPlaceIndex, fillType)
	if self.isServer then
		local outputPlace = self.palletOutputPlaces[outputPlaceIndex]
		local palletFilename = self.fillTypeToPalletXML[fillType]
		local location = {}
		location.x, location.y, location.z = localToWorld(outputPlace.triggerId, 0, 0, 0)
		_, location.yRot, _ = getRotation(self.nodeId)
		location.yRot = location.yRot - math.pi * 0.5

		VehicleLoadingUtil.loadVehicle(palletFilename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, self:getOwnerFarmId(), {}, nil, StrawHarvestPalletizer.onLoadedPallet, self, {
			fillType
		})
	end
end

function StrawHarvestPalletizer:onLoadedPallet(pallet, vehicleLoadState, asyncCallbackArguments)
	local fillType = asyncCallbackArguments[1]

	pallet:emptyAllFillUnits(true)

	local fillUnitIndex = pallet:getFirstValidFillUnitToFill(fillType)

	if fillUnitIndex ~= nil then
		pallet:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, pallet:getFillUnitCapacity(fillUnitIndex), fillType, ToolType.UNDEFINED, nil)
	end

	self:setStatistics(self.bagsToday, self.palletsToday + 1)

	self.isPalletMovingToDestination = false
end

function StrawHarvestPalletizer:linkToNode(node, linkNode)
	if not entityExists(node) then
		return
	end

	local x, y, z = localToLocal(node, linkNode, 0, 0, 0)
	local dx, dy, dz = localDirectionToLocal(node, linkNode, 0, 0, 1)
	local upX, upY, upZ = localDirectionToLocal(node, linkNode, 0, 1, 0)

	setDirection(node, dx, dy, dz, upX, upY, upZ)
	setTranslation(node, x, y, z)
	unlink(node)
	link(linkNode, node)
end

function StrawHarvestPalletizer:onObjectRemovedFromPhysics(object)
	for _, place in ipairs(self.palletOutputPlaces) do
		if place.objectsInTrigger[object] ~= nil then
			place.objectsInTrigger[object] = nil
			place.numOfObjectsInTrigger = math.max(place.numOfObjectsInTrigger - 1, 0)

			self:raiseActive()
		end
	end
end

function StrawHarvestPalletizer:outputPlaceTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil and object ~= self then
			local place = self.palletOutputPlacesByTrigger[triggerId]
			local numOfObjectsInTrigger = place.numOfObjectsInTrigger

			if onEnter then
				if place.objectsInTrigger[object] == nil then
					place.numOfObjectsInTrigger = numOfObjectsInTrigger + 1
					place.objectsInTrigger[object] = place.numOfObjectsInTrigger
				end
			else
				place.objectsInTrigger[object] = nil
				place.numOfObjectsInTrigger = math.max(numOfObjectsInTrigger - 1, 0)
			end

			self:raiseActive()
		end
	end
end

function StrawHarvestPalletizer:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			local farmId = self:getOwnerFarmId()

			if farmId == nil or farmId == AccessHandler.EVERYONE or g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), farmId) then
				self.playerInRange = true
			end
		else
			self.playerInRange = false
		end

		self:raiseActive()
	end
end

function StrawHarvestPalletizer:onDayChanged()
	self:setStatistics(0, 0)
end

function StrawHarvestPalletizer:onHourChanged()
	local farmId = self:getOwnerFarmId()

	if farmId == nil or farmId == AccessHandler.EVERYONE then
		return
	end

	local costs = self.hourlyCosts

	g_currentMission:addMoney(-costs, farmId, MoneyType.PROPERTY_MAINTENANCE, true, false)
	g_currentMission:broadcastNotifications(MoneyType.PROPERTY_MAINTENANCE, farmId)

	self.hourlyCosts = 0
end
