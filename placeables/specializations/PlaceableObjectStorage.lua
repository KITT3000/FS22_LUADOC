PlaceableObjectStorage = {}

source("dataS/scripts/placeables/specializations/events/PlaceableObjectStorageErrorEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableObjectStorageUnloadEvent.lua")

PlaceableObjectStorage.COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.PLAYER
PlaceableObjectStorage.NUM_BITS_OBJECT_INFO = 8
PlaceableObjectStorage.NUM_BITS_AMOUNT = 16
PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES = 10

function PlaceableObjectStorage.prerequisitesPresent(specializations)
	return true
end

function PlaceableObjectStorage.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableObjectStorage.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableObjectStorage.updateInfo)
end

function PlaceableObjectStorage.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageSupportsFillType", PlaceableObjectStorage.getObjectStorageSupportsFillType)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageSupportsObject", PlaceableObjectStorage.getObjectStorageSupportsObject)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageCanStoreObject", PlaceableObjectStorage.getObjectStorageCanStoreObject)
	SpecializationUtil.registerFunction(placeableType, "getIsBaleSupportedByUnloadTrigger", PlaceableObjectStorage.getIsBaleSupportedByUnloadTrigger)
	SpecializationUtil.registerFunction(placeableType, "addObjectToObjectStorage", PlaceableObjectStorage.addObjectToObjectStorage)
	SpecializationUtil.registerFunction(placeableType, "addAbstactObjectToObjectStorage", PlaceableObjectStorage.addAbstactObjectToObjectStorage)
	SpecializationUtil.registerFunction(placeableType, "removeAbstractObjectsFromStorage", PlaceableObjectStorage.removeAbstractObjectsFromStorage)
	SpecializationUtil.registerFunction(placeableType, "spawnNextObjectStorageObject", PlaceableObjectStorage.spawnNextObjectStorageObject)
	SpecializationUtil.registerFunction(placeableType, "removeAbstractObjectFromStorage", PlaceableObjectStorage.removeAbstractObjectFromStorage)
	SpecializationUtil.registerFunction(placeableType, "setObjectStorageObjectInfosDirty", PlaceableObjectStorage.setObjectStorageObjectInfosDirty)
	SpecializationUtil.registerFunction(placeableType, "updateDirtyObjectStorageObjectInfos", PlaceableObjectStorage.updateDirtyObjectStorageObjectInfos)
	SpecializationUtil.registerFunction(placeableType, "updateObjectStorageObjectInfos", PlaceableObjectStorage.updateObjectStorageObjectInfos)
	SpecializationUtil.registerFunction(placeableType, "getObjectStorageObjectInfos", PlaceableObjectStorage.getObjectStorageObjectInfos)
	SpecializationUtil.registerFunction(placeableType, "updateObjectStorageVisualAreas", PlaceableObjectStorage.updateObjectStorageVisualAreas)
	SpecializationUtil.registerFunction(placeableType, "onObjectStoragePlayerTriggerCallback", PlaceableObjectStorage.onObjectStoragePlayerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "onObjectStorageObjectTriggerCallback", PlaceableObjectStorage.onObjectStorageObjectTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "onObjectStorageSpawnOverlapCallback", PlaceableObjectStorage.onObjectStorageSpawnOverlapCallback)
end

function PlaceableObjectStorage.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableObjectStorage)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableObjectStorage)
end

function PlaceableObjectStorage.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ObjectStorage")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.playerTrigger#node", "Player trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.objectTrigger#node", "Object trigger node")
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage#fillTypeCategories", "List of supported fill type categories (if no fill types defined, all are allowed)")
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage#fillTypes", "List of supported fill types (if no fill types defined, all are allowed)")
	schema:register(XMLValueType.BOOL, basePath .. ".objectStorage#supportsBales", "Bales can be stored", true)
	schema:register(XMLValueType.BOOL, basePath .. ".objectStorage#supportsPallets", "Pallets can be stored", true)
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage.supportedObject(?)#filename", "End part of the xml filename that can be stored (pallet or bale)")
	schema:register(XMLValueType.INT, basePath .. ".objectStorage.supportedObject(?)#amount", "Amount of this single object that can be stored (total capacity of the storage will still limit on top of this)", "unlimited")
	schema:register(XMLValueType.STRING, basePath .. ".objectStorage.supportedObject(?)#fillType", "FillType name to show in the shop")
	schema:register(XMLValueType.INT, basePath .. ".objectStorage#capacity", "Max. capacity", 250)
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage#maxLength", "Max. length of objects to store", "unlimited")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage#maxHeight", "Max. height of objects to store", "unlimited")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage#maxWidth", "Max. width of objects to store", "unlimited")
	schema:register(XMLValueType.INT, basePath .. ".objectStorage#maxUnloadAmount", "Max. amount of objects that can be unloaded at a time", 25)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.spawnAreas.spawnArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.spawnAreas.spawnArea(?)#endNode", "End node")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage.spawnAreas.spawnArea(?)#maxHeight", "Max. stacked height of spawned objects in the area", 4)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.storageAreas.storageArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectStorage.storageAreas.storageArea(?)#endNode", "End node")
	schema:register(XMLValueType.FLOAT, basePath .. ".objectStorage.storageAreas.storageArea(?)#maxHeight", "Max. stacked height of spawned objects in the area", 4)
	schema:setXMLSpecializationType()
end

function PlaceableObjectStorage.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".object(?)#className", "Object class name")

	for _, abstractObject in pairs(PlaceableObjectStorage.ABSTRACT_OBJECTS) do
		abstractObject.registerXMLPaths(schema, basePath .. ".object(?)")
	end
end

function PlaceableObjectStorage.initSpecialization()
	g_storeManager:addSpecType("objectStorageCapacity", "shopListAttributeIconCapacity", PlaceableObjectStorage.loadSpecValueCapacity, PlaceableObjectStorage.getSpecValueCapacity, "placeable")
	g_storeManager:addSpecType("objectStorageFillTypes", "shopListAttributeIconFillTypes", PlaceableObjectStorage.loadSpecValueFillTypes, PlaceableObjectStorage.getSpecValueFillTypes, "placeable")
end

function PlaceableObjectStorage:onLoad(savegame)
	local spec = self.spec_objectStorage
	spec.playerTriggerNode = self.xmlFile:getValue("placeable.objectStorage.playerTrigger#node", nil, self.components, self.i3dMappings)

	if spec.playerTriggerNode ~= nil then
		addTrigger(spec.playerTriggerNode, "onObjectStoragePlayerTriggerCallback", self)
	else
		Logging.xmlWarning(self.xmlFile, "Missing player trigger for object storage")
	end

	if self.isServer then
		spec.objectTriggerNode = self.xmlFile:getValue("placeable.objectStorage.objectTrigger#node", nil, self.components, self.i3dMappings)

		if spec.objectTriggerNode ~= nil then
			addTrigger(spec.objectTriggerNode, "onObjectStorageObjectTriggerCallback", self)
		else
			Logging.xmlWarning(self.xmlFile, "Missing object trigger for object storage")
		end
	end

	spec.supportedFillTypes = g_fillTypeManager:getFillTypesFromXML(self.xmlFile, "placeable.objectStorage#fillTypeCategories", "placeable.objectStorage#fillTypes", false)
	spec.supportsBales = self.xmlFile:getValue("placeable.objectStorage#supportsBales", true)
	spec.supportsPallets = self.xmlFile:getValue("placeable.objectStorage#supportsPallets", true)
	spec.supportedObjects = {}

	self.xmlFile:iterate("placeable.objectStorage.supportedObject", function (index, objectKey)
		local entry = {
			filename = self.xmlFile:getValue(objectKey .. "#filename")
		}

		if entry.filename ~= nil then
			entry.amount = self.xmlFile:getValue(objectKey .. "#amount", math.huge)

			table.insert(spec.supportedObjects, entry)
		end
	end)

	spec.capacity = self.xmlFile:getValue("placeable.objectStorage#capacity", 250)
	spec.maxLength = self.xmlFile:getValue("placeable.objectStorage#maxLength", math.huge)
	spec.maxHeight = self.xmlFile:getValue("placeable.objectStorage#maxHeight", math.huge)
	spec.maxWidth = self.xmlFile:getValue("placeable.objectStorage#maxWidth", math.huge)
	spec.maxUnloadAmount = self.xmlFile:getValue("placeable.objectStorage#maxUnloadAmount", 25)
	spec.objectSpawn = {
		isActive = false,
		connection = nil,
		objectInfoIndex = 1,
		numObjectsToSpawn = 0,
		overlapIsActive = false,
		overlapObjectCount = 0,
		nextSpawnPosition = {
			0,
			0,
			0
		},
		spawnAreaIndex = 1,
		spawnAreaData = {
			0,
			0,
			0,
			0,
			0,
			1
		},
		spawnedObjects = {},
		area = {}
	}

	self.xmlFile:iterate("placeable.objectStorage.spawnAreas.spawnArea", function (index, areaKey)
		local spawnArea = {
			startNode = self.xmlFile:getValue(areaKey .. "#startNode", nil, self.components, self.i3dMappings),
			endNode = self.xmlFile:getValue(areaKey .. "#endNode", nil, self.components, self.i3dMappings)
		}

		if spawnArea.startNode ~= nil and spawnArea.endNode ~= nil then
			local _ = nil
			spawnArea.sizeX, _, spawnArea.sizeZ = localToLocal(spawnArea.endNode, spawnArea.startNode, 0, 0, 0)
			spawnArea.maxHeight = self.xmlFile:getValue(areaKey .. "#maxHeight", 3)

			table.insert(spec.objectSpawn.area, spawnArea)
		else
			Logging.xmlWarning(self.xmlFile, "Incomplete spawn area definition in '%s'", areaKey)
		end
	end)

	spec.storageArea = {
		spawnNode = createTransformGroup("storageAreaSpawnNode")
	}

	link(self.rootNode, spec.storageArea.spawnNode)

	spec.storageArea.spawnAreaIndex = 1
	spec.storageArea.spawnAreaData = {
		0,
		0,
		0,
		0,
		0,
		1
	}
	spec.storageArea.area = {}

	self.xmlFile:iterate("placeable.objectStorage.storageAreas.storageArea", function (index, areaKey)
		local storageArea = {
			startNode = self.xmlFile:getValue(areaKey .. "#startNode", nil, self.components, self.i3dMappings),
			endNode = self.xmlFile:getValue(areaKey .. "#endNode", nil, self.components, self.i3dMappings)
		}

		if storageArea.startNode ~= nil and storageArea.endNode ~= nil then
			local _ = nil
			storageArea.sizeX, _, storageArea.sizeZ = localToLocal(storageArea.endNode, storageArea.startNode, 0, 0, 0)
			storageArea.maxHeight = self.xmlFile:getValue(areaKey .. "#maxHeight", 3)

			table.insert(spec.storageArea.area, storageArea)
		else
			Logging.xmlWarning(self.xmlFile, "Incomplete spawn area definition in '%s'", areaKey)
		end
	end)

	spec.storedObjects = {}
	spec.objectInfos = {}
	spec.pendingObjects = {}
	spec.numStoredObjects = 0
	spec.objectInfosUpdateTimer = 0
	spec.pendingVisualAreaUpdates = {}
	spec.texts = {
		warningNotEmpty = g_i18n:getText("info_objectStorageNotEmpty"),
		totalCapacity = g_i18n:getText("ui_silos_totalCapacity"),
		otherElements = g_i18n:getText("helpLine_IconOverview_Others")
	}
	spec.activatable = PlaceableObjectStorageActivatable.new(self)
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function PlaceableObjectStorage:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".object", function (index, objectKey)
		local className = xmlFile:getValue(objectKey .. "#className")

		if className ~= nil then
			local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[className]

			if abstractObjectClass ~= nil then
				abstractObjectClass.loadFromXMLFile(self, xmlFile, objectKey)
			end
		else
			Logging.xmlWarning(xmlFile, "Unable to find object class '%s' for stored object in '%s'", className, objectKey)
		end
	end)
	self:setObjectStorageObjectInfosDirty()
end

function PlaceableObjectStorage:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_objectStorage

	for i = 1, #spec.storedObjects do
		local object = spec.storedObjects[i]
		local objectKey = string.format("%s.object(%d)", key, i - 1)

		xmlFile:setValue(objectKey .. "#className", object.REFERENCE_CLASS_NAME)
		object:saveToXMLFile(self, xmlFile, objectKey)
	end
end

function PlaceableObjectStorage:onDelete()
	local spec = self.spec_objectStorage

	if spec.playerTriggerNode ~= nil then
		removeTrigger(spec.playerTriggerNode)
	end

	if spec.objectTriggerNode ~= nil then
		removeTrigger(spec.objectTriggerNode)
	end

	for i = #spec.storedObjects, 1, -1 do
		spec.storedObjects[i]:delete()

		spec.storedObjects[i] = nil
	end

	spec.numStoredObjects = 0

	for object, _ in pairs(spec.pendingObjects) do
		object:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)

		spec.pendingObjects[object] = nil
	end

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
end

function PlaceableObjectStorage:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_objectStorage
		spec.objectInfos = {}
		local numObjectInfos = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)

		for i = 1, numObjectInfos do
			local objectInfo = {
				numObjects = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_AMOUNT)
			}
			local abstractObjectId = streamReadUIntN(streamId, 2)
			local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_ID[abstractObjectId]
			objectInfo.objects = {
				abstractObjectClass.readStream(streamId, connection)
			}

			table.insert(spec.objectInfos, objectInfo)
		end

		spec.numStoredObjects = 0

		for i = 1, #spec.objectInfos do
			spec.numStoredObjects = spec.numStoredObjects + spec.objectInfos[i].numObjects
		end

		self:updateObjectStorageVisualAreas()
	end
end

function PlaceableObjectStorage:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_objectStorage
		local objectInfos = spec.objectInfos

		streamWriteUIntN(streamId, #objectInfos, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)

		for i = 1, #objectInfos do
			local objectInfo = objectInfos[i]

			streamWriteUIntN(streamId, objectInfo.numObjects, PlaceableObjectStorage.NUM_BITS_AMOUNT)
			streamWriteUIntN(streamId, objectInfo.objects[1].ABSTRACT_OBJECT_ID, 2)
			objectInfo.objects[1]:writeStream(streamId, connection)
		end
	end
end

function PlaceableObjectStorage:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		PlaceableObjectStorage.onReadStream(self, streamId, connection)
	end
end

function PlaceableObjectStorage:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.spec_objectStorage.dirtyFlag) ~= 0) then
		PlaceableObjectStorage.onWriteStream(self, streamId, connection)
	end
end

function PlaceableObjectStorage:onUpdate(dt)
	local spec = self.spec_objectStorage

	if self.isServer then
		if spec.objectSpawn.isActive then
			if not spec.objectSpawn.overlapIsActive then
				if spec.objectSpawn.overlapObjectCount == 0 then
					local spawnArea = spec.objectSpawn.area[spec.objectSpawn.spawnAreaIndex]
					local objectInfo = spec.objectInfos[spec.objectSpawn.objectInfoIndex]
					local objectToSpawn = objectInfo.objects[1]
					local ox, oy, oz, _, _, _, _ = objectToSpawn:getSpawnInfo()
					local cx, cy, cz = localToWorld(spawnArea.startNode, spec.objectSpawn.nextSpawnPosition[1] + ox, spec.objectSpawn.nextSpawnPosition[2] + oy, spec.objectSpawn.nextSpawnPosition[3] + oz)
					local rx, ry, rz = getWorldRotation(spawnArea.startNode)

					if objectToSpawn ~= nil then
						self:removeAbstractObjectFromStorage(objectToSpawn, cx, cy, cz, rx, ry, rz)
						table.remove(objectInfo.objects, 1)
					end

					spec.objectSpawn.numObjectsToSpawn = spec.objectSpawn.numObjectsToSpawn - 1
				end

				self:spawnNextObjectStorageObject(spec.objectSpawn.overlapObjectCount == 0)
			end

			self:raiseActive()
		end

		for object, _ in pairs(spec.pendingObjects) do
			local canStoreObject, _ = self:getObjectStorageCanStoreObject(object)

			if canStoreObject then
				self:addObjectToObjectStorage(object)
				self:setObjectStorageObjectInfosDirty()

				spec.pendingObjects[object] = nil

				object:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
			else
				self:raiseActive()
			end
		end
	end

	if spec.objectInfosUpdateTimer > 0 then
		spec.objectInfosUpdateTimer = spec.objectInfosUpdateTimer - dt

		if spec.objectInfosUpdateTimer <= 0 then
			self:updateObjectStorageObjectInfos()
			self:updateObjectStorageVisualAreas()
			self:raiseDirtyFlags(spec.dirtyFlag)

			spec.objectInfosUpdateTimer = 0
		end

		self:raiseActive()
	end

	for i = #spec.pendingVisualAreaUpdates, 1, -1 do
		local pendingVisualAreaUpdate = spec.pendingVisualAreaUpdates[i]

		if not pendingVisualAreaUpdate.spawnNextObjectInfo() then
			table.remove(spec.pendingVisualAreaUpdates, i)
		else
			self:raiseActive()
		end
	end
end

function PlaceableObjectStorage:getObjectStorageSupportsFillType(fillTypeIndex)
	local spec = self.spec_objectStorage

	if fillTypeIndex == nil or fillTypeIndex == FillType.UNKNOWN then
		return #spec.supportedFillTypes == 0
	else
		local found = #spec.supportedFillTypes == 0

		for i = 1, #spec.supportedFillTypes do
			if fillTypeIndex == spec.supportedFillTypes[i] then
				found = true
			end
		end

		if not found then
			return false
		end
	end

	return true
end

function PlaceableObjectStorage:getObjectStorageSupportsObject(object)
	local spec = self.spec_objectStorage
	local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[ClassUtil.getClassNameByObject(object)]

	if abstractObjectClass ~= nil and not abstractObjectClass.isObjectSupported(self, object) then
		return false
	end

	for i = 1, #spec.storedObjects do
		if object == spec.storedObjects[i]:getRealObject() then
			return false
		end
	end

	return true
end

function PlaceableObjectStorage:getObjectStorageCanStoreObject(object)
	local spec = self.spec_objectStorage

	if spec.objectSpawn.isActive then
		return false
	end

	if spec.capacity <= #spec.storedObjects then
		return false, PlaceableObjectStorageErrorEvent.ERROR_STORAGE_IS_FULL
	end

	if #spec.supportedObjects > 0 then
		local isSupported = false
		local filename = object.configFileName or object.xmlFilename

		for i = 1, #spec.supportedObjects do
			local supportedObject = spec.supportedObjects[i]

			if filename:endsWith(supportedObject.filename) then
				isSupported = true
				local storedAmount = 0

				for j = 1, #spec.storedObjects do
					local objectFilename = spec.storedObjects[j]:getXMLFilename()

					if objectFilename == filename then
						storedAmount = storedAmount + 1
					end
				end

				if supportedObject.amount <= storedAmount then
					return false, PlaceableObjectStorageErrorEvent.ERROR_MAX_AMOUNT_FOR_OBJECT_REACHED
				end
			end
		end

		if not isSupported then
			return false, PlaceableObjectStorageErrorEvent.ERROR_OBJECT_NOT_SUPPORTED
		end
	end

	local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[ClassUtil.getClassNameByObject(object)]

	if abstractObjectClass ~= nil and not abstractObjectClass.canStoreObject(self, object) then
		return false
	end

	return true
end

function PlaceableObjectStorage:getIsBaleSupportedByUnloadTrigger(bale)
	return self:getObjectStorageSupportsObject(bale)
end

function PlaceableObjectStorage:addObjectToObjectStorage(object, loadedFromSavegame)
	local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[ClassUtil.getClassNameByObject(object)]

	if abstractObjectClass ~= nil then
		local abstractObject = abstractObjectClass.new()

		abstractObject:addToStorage(self, object, loadedFromSavegame)
		self:addAbstactObjectToObjectStorage(abstractObject)
	end
end

function PlaceableObjectStorage:addAbstactObjectToObjectStorage(abstractObject)
	local spec = self.spec_objectStorage

	table.insert(spec.storedObjects, abstractObject)

	spec.numStoredObjects = #spec.storedObjects
end

function PlaceableObjectStorage:removeAbstractObjectsFromStorage(objectInfoIndex, amount, connection)
	local spec = self.spec_objectStorage

	if not spec.objectSpawn.isActive then
		if spec.objectInfosUpdateTimer ~= 0 then
			return
		end

		if spec.objectInfos[objectInfoIndex] == nil or spec.objectInfos[objectInfoIndex].numObjects < amount then
			return
		end

		spec.objectSpawn.isActive = true
		spec.objectSpawn.connection = connection
		spec.objectSpawn.objectInfoIndex = objectInfoIndex
		spec.objectSpawn.numObjectsToSpawn = amount
		spec.objectSpawn.overlapIsActive = false
		spec.objectSpawn.overlapObjectCount = 0
		spec.objectSpawn.spawnAreaIndex = 1
		spec.objectSpawn.spawnAreaData[6] = math.huge
		spec.objectSpawn.spawnAreaData[5] = 0
		spec.objectSpawn.spawnAreaData[4] = 0
		spec.objectSpawn.spawnAreaData[3] = 0
		spec.objectSpawn.spawnAreaData[2] = 0
		spec.objectSpawn.spawnAreaData[1] = 0

		for i = #spec.objectSpawn.spawnedObjects, 1, -1 do
			spec.objectSpawn.spawnedObjects[i] = nil
		end

		self:spawnNextObjectStorageObject()
	end
end

function PlaceableObjectStorage.getNextSpawnAreaAndOffset(areas, areaIndex, ox, oy, oz, nextX, nextZ, width, height, length, maxStackHeight, stackIndex, lastSuccess)
	local spawnArea = areas[areaIndex]

	if spawnArea ~= nil then
		if spawnArea.sizeX <= width then
			return PlaceableObjectStorage.getNextSpawnAreaAndOffset(areas, areaIndex + 1, 0, 0, 0, 0, 0, width, height, length, maxStackHeight, math.huge, false)
		end

		if spawnArea.sizeZ <= length then
			return PlaceableObjectStorage.getNextSpawnAreaAndOffset(areas, areaIndex + 1, 0, 0, 0, 0, 0, width, height, length, maxStackHeight, math.huge, false)
		end

		ox = ox + width * 0.5
		oz = oz + length * 0.5
		local limitedStackHeight = math.min(maxStackHeight, math.floor(spawnArea.maxHeight / height))

		if stackIndex < limitedStackHeight and lastSuccess ~= false then
			stackIndex = stackIndex + 1
			oz = oz - length
			oy = (stackIndex - 1) * height
		else
			stackIndex = 1
		end

		nextZ = math.max(nextZ, oz + length * 0.5)

		if spawnArea.sizeZ < nextZ then
			oz = 0
			ox = nextX

			return PlaceableObjectStorage.getNextSpawnAreaAndOffset(areas, areaIndex, ox, oy, oz, nextX, 0, width, height, length, maxStackHeight, math.huge, lastSuccess)
		end

		nextX = math.max(nextX, ox + width * 0.5)

		if spawnArea.sizeX < ox then
			return PlaceableObjectStorage.getNextSpawnAreaAndOffset(areas, areaIndex + 1, 0, 0, 0, 0, 0, width, height, length, maxStackHeight, math.huge, false)
		end

		return areaIndex, ox, oy, oz, ox - width * 0.5, 0, oz + length * 0.5, nextX, nextZ, stackIndex
	end

	return nil
end

function PlaceableObjectStorage:spawnNextObjectStorageObject(lastSuccess)
	local spec = self.spec_objectStorage
	local spawnErrorId = nil

	if spec.objectSpawn.numObjectsToSpawn > 0 then
		local objectInfo = spec.objectInfos[spec.objectSpawn.objectInfoIndex]
		local objectToSpawn = objectInfo.objects[1]
		local limitedObjectId, errorId = objectToSpawn:getLimitedObjectId()

		if limitedObjectId == nil or g_currentMission.slotSystem:getCanAddLimitedObjects(limitedObjectId, 1) then
			local _, _, _, width, height, length, maxStackHeight = objectToSpawn:getSpawnInfo()

			if maxStackHeight > 1.001 then
				maxStackHeight = math.huge
			end

			local areaIndex, spawnX, spawnY, spawnZ, offsetX, offsetY, offsetZ, nextOffsetX, nextOffsetZ, stackIndex = PlaceableObjectStorage.getNextSpawnAreaAndOffset(spec.objectSpawn.area, spec.objectSpawn.spawnAreaIndex, spec.objectSpawn.spawnAreaData[1], spec.objectSpawn.spawnAreaData[2], spec.objectSpawn.spawnAreaData[3], spec.objectSpawn.spawnAreaData[4], spec.objectSpawn.spawnAreaData[5], width, height, length, maxStackHeight, spec.objectSpawn.spawnAreaData[6], lastSuccess)

			if areaIndex ~= nil then
				spec.objectSpawn.spawnAreaData[6] = stackIndex
				spec.objectSpawn.spawnAreaData[5] = nextOffsetZ
				spec.objectSpawn.spawnAreaData[4] = nextOffsetX
				spec.objectSpawn.spawnAreaData[3] = offsetZ
				spec.objectSpawn.spawnAreaData[2] = offsetY
				spec.objectSpawn.spawnAreaData[1] = offsetX
				spec.objectSpawn.spawnAreaIndex = areaIndex
				local spawnArea = spec.objectSpawn.area[spec.objectSpawn.spawnAreaIndex]
				local cx, cy, cz = localToWorld(spawnArea.startNode, spawnX, spawnY + height * 0.5, spawnZ)
				local rx, ry, rz = getWorldRotation(spawnArea.startNode)
				spec.objectSpawn.nextSpawnPosition[3] = spawnZ
				spec.objectSpawn.nextSpawnPosition[2] = spawnY
				spec.objectSpawn.nextSpawnPosition[1] = spawnX
				spec.objectSpawn.overlapIsActive = true
				spec.objectSpawn.overlapObjectCount = 0

				overlapBox(cx, cy, cz, rx, ry, rz, width * 0.5, height * 0.5, length * 0.5, "onObjectStorageSpawnOverlapCallback", self, PlaceableObjectStorage.COLLISION_MASK, true, false, true, true)
				self:raiseActive()

				return
			end
		else
			spawnErrorId = errorId
		end
	end

	if spec.objectSpawn.isActive then
		if spec.objectSpawn.numObjectsToSpawn > 0 and spec.objectSpawn.connection ~= nil and g_server ~= nil then
			spec.objectSpawn.connection:sendEvent(PlaceableObjectStorageErrorEvent.new(self, spawnErrorId or PlaceableObjectStorageErrorEvent.ERROR_NOT_ENOUGH_SPACE))
		end

		spec.objectSpawn.isActive = false
		spec.objectSpawn.connection = nil
		spec.objectSpawn.objectInfoIndex = 1
		spec.objectSpawn.numObjectsToSpawn = 0

		for i = #spec.objectSpawn.spawnedObjects, 1, -1 do
			spec.objectSpawn.spawnedObjects[i] = nil
		end

		self:setObjectStorageObjectInfosDirty()
	end
end

function PlaceableObjectStorage:removeAbstractObjectFromStorage(abstractObject, x, y, z, rx, ry, rz)
	local spec = self.spec_objectStorage

	for i = 1, #spec.storedObjects do
		if spec.storedObjects[i] == abstractObject then
			table.remove(spec.storedObjects, i)
			abstractObject:removeFromStorage(self, x, y, z, rx, ry, rz, PlaceableObjectStorage.onObjectFromStorageSpawned)
		end
	end

	spec.numStoredObjects = #spec.storedObjects
end

function PlaceableObjectStorage:onObjectFromStorageSpawned(spawnedObject)
	local spec = self.spec_objectStorage

	if spec.objectSpawn.isActive then
		table.insert(spec.objectSpawn.spawnedObjects, spawnedObject)
	end
end

function PlaceableObjectStorage:setObjectStorageObjectInfosDirty()
	local spec = self.spec_objectStorage
	spec.objectInfosUpdateTimer = 1000

	self:raiseActive()
end

function PlaceableObjectStorage:updateDirtyObjectStorageObjectInfos()
	local spec = self.spec_objectStorage

	if spec.objectInfosUpdateTimer > 0 then
		self:updateObjectStorageObjectInfos()
	end
end

function PlaceableObjectStorage:updateObjectStorageObjectInfos()
	local spec = self.spec_objectStorage
	local objectInfos = {}

	for i = 1, #spec.storedObjects do
		local object = spec.storedObjects[i]
		local foundInfo = false

		for j = 1, #objectInfos do
			local objectInfo = objectInfos[j]

			if object:getIsIdentical(objectInfo.objects[1]) then
				table.insert(objectInfo.objects, object)

				objectInfo.numObjects = #objectInfo.objects
				foundInfo = true
			end
		end

		if not foundInfo then
			local objectInfo = {
				objects = {
					object
				},
				numObjects = 1
			}

			table.insert(objectInfos, objectInfo)
		end
	end

	table.sort(objectInfos, function (a, b)
		local _, _, _, widthA, _, _, _ = a.objects[1]:getSpawnInfo()
		local _, _, _, widthB, _, _, _ = b.objects[1]:getSpawnInfo()

		return widthA < widthB
	end)

	spec.objectInfos = objectInfos
end

function PlaceableObjectStorage:getObjectStorageObjectInfos()
	return self.spec_objectStorage.objectInfos
end

function PlaceableObjectStorage:updateObjectStorageVisualAreas()
	local spec = self.spec_objectStorage
	local area = spec.storageArea
	local oldSpawnNode = area.spawnNode
	area.spawnNode = createTransformGroup("storageAreaSpawnNode")

	link(self.rootNode, area.spawnNode)
	setVisibility(area.spawnNode, false)

	local pendingVisualAreaUpdate = {
		oldSpawnNode = oldSpawnNode,
		newSpawnNode = area.spawnNode,
		objectInfosToSpawn = {}
	}

	function pendingVisualAreaUpdate.spawnNextObjectInfo()
		if #pendingVisualAreaUpdate.objectInfosToSpawn > 0 then
			local objectInfo = pendingVisualAreaUpdate.objectInfosToSpawn[1]

			objectInfo.objects[1]:spawnVisualObjects(objectInfo.visualSpawnInfos)
			table.remove(pendingVisualAreaUpdate.objectInfosToSpawn, 1)

			return true
		else
			delete(pendingVisualAreaUpdate.oldSpawnNode)

			if entityExists(pendingVisualAreaUpdate.newSpawnNode) then
				setVisibility(pendingVisualAreaUpdate.newSpawnNode, true)
			end

			return false
		end
	end

	area.spawnAreaData[6] = math.huge
	area.spawnAreaData[5] = 0
	area.spawnAreaData[4] = 0
	area.spawnAreaData[3] = 0
	area.spawnAreaData[2] = 0
	area.spawnAreaData[1] = 0
	area.spawnAreaIndex = 1

	for i = 1, #spec.objectInfos do
		local objectInfo = spec.objectInfos[i]
		objectInfo.visualSpawnInfos = {}
		area.spawnAreaData[6] = math.huge
		local objectToSpawn = objectInfo.objects[1]
		local ox, oy, oz, width, height, length, maxStackHeight = objectToSpawn:getSpawnInfo()

		if maxStackHeight > 1.001 then
			maxStackHeight = math.huge
		end

		for j = 1, objectInfo.numObjects do
			local areaIndex, spawnX, spawnY, spawnZ, offsetX, offsetY, offsetZ, nextOffsetX, nextOffsetZ, stackIndex = PlaceableObjectStorage.getNextSpawnAreaAndOffset(area.area, area.spawnAreaIndex, area.spawnAreaData[1], area.spawnAreaData[2], area.spawnAreaData[3], area.spawnAreaData[4], area.spawnAreaData[5], width, height, length, maxStackHeight, area.spawnAreaData[6], true)

			if areaIndex ~= nil then
				area.spawnAreaData[6] = stackIndex
				area.spawnAreaData[5] = nextOffsetZ
				area.spawnAreaData[4] = nextOffsetX
				area.spawnAreaData[3] = offsetZ
				area.spawnAreaData[2] = offsetY
				area.spawnAreaData[1] = offsetX
				area.spawnAreaIndex = areaIndex
				local spawnArea = area.area[area.spawnAreaIndex]
				local cx, cy, cz = localToLocal(spawnArea.startNode, area.spawnNode, spawnX + ox, spawnY + oy, spawnZ + oz)
				local rx, ry, rz = localRotationToLocal(spawnArea.startNode, area.spawnNode, 0, 0, 0)

				table.insert(objectInfo.visualSpawnInfos, {
					area.spawnNode,
					cx,
					cy,
					cz,
					rx,
					ry,
					rz
				})
			end
		end

		if #objectInfo.visualSpawnInfos > 0 then
			table.insert(pendingVisualAreaUpdate.objectInfosToSpawn, objectInfo)
		end
	end

	if pendingVisualAreaUpdate.spawnNextObjectInfo() then
		table.insert(spec.pendingVisualAreaUpdates, pendingVisualAreaUpdate)
		self:raiseActive()
	end
end

function PlaceableObjectStorage:onObjectStoragePlayerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		local spec = self.spec_objectStorage

		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
		elseif onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
		end
	end
end

function PlaceableObjectStorage:onPendingObjectDelete(object)
	local spec = self.spec_objectStorage

	if spec.pendingObjects[object] ~= nil then
		spec.pendingObjects[object] = nil
	end
end

function PlaceableObjectStorage:onObjectStorageObjectTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil then
			if self:getObjectStorageSupportsObject(object) then
				local canStoreObject, errorId = self:getObjectStorageCanStoreObject(object)

				if canStoreObject then
					self:addObjectToObjectStorage(object, false)
					self:setObjectStorageObjectInfosDirty()
				else
					if errorId ~= nil and g_server ~= nil then
						g_server:broadcastEvent(PlaceableObjectStorageErrorEvent.new(self, errorId), true, nil, self)
					end

					local spec = self.spec_objectStorage
					spec.pendingObjects[object] = (spec.pendingObjects[object] or 0) + 1

					object:addDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
					self:raiseActive()
				end
			end

			if object:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, object.specializations) then
				object:addBaleUnloadTrigger(self)
			end
		end
	elseif onLeave then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil then
			local spec = self.spec_objectStorage
			spec.pendingObjects[object] = (spec.pendingObjects[object] or 0) - 1

			if spec.pendingObjects[object] <= 0 then
				spec.pendingObjects[object] = nil

				object:removeDeleteListener(self, PlaceableObjectStorage.onPendingObjectDelete)
			end

			if object:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, object.specializations) then
				object:removeBaleUnloadTrigger(self)
			end
		end
	end
end

function PlaceableObjectStorage:onObjectStorageSpawnOverlapCallback(objectId)
	local spec = self.spec_objectStorage
	spec.objectSpawn.overlapIsActive = false

	if objectId ~= 0 and not getHasTrigger(objectId) then
		local object = g_currentMission:getNodeObject(objectId)

		if object ~= nil then
			for i = 1, #spec.objectSpawn.spawnedObjects do
				if object == spec.objectSpawn.spawnedObjects[i] then
					return
				end
			end
		end

		spec.objectSpawn.overlapObjectCount = spec.objectSpawn.overlapObjectCount + 1
	end
end

function PlaceableObjectStorage:canBeSold(superFunc)
	local spec = self.spec_objectStorage

	if #spec.objectInfos > 0 then
		return true, spec.texts.warningNotEmpty
	end

	return superFunc(self)
end

function PlaceableObjectStorage:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_objectStorage

	table.insert(infoTable, {
		title = spec.texts.totalCapacity,
		text = string.format("%d / %d", spec.numStoredObjects, spec.capacity)
	})

	local numObjectInfos = #spec.objectInfos

	for i = 1, math.min(numObjectInfos, PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES) do
		local objectInfo = spec.objectInfos[i]

		if objectInfo.objects[1] ~= nil then
			local title = objectInfo.objects[1]:getDialogText()

			if string.len(title) > 32 then
				title = string.sub(title, 0, 32) .. "..."
			end

			table.insert(infoTable, {
				title = title,
				text = tostring(objectInfo.numObjects)
			})
		end
	end

	if PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES < numObjectInfos then
		local sumOthers = 0

		for i = PlaceableObjectStorage.MAX_HUD_INFO_ENTRIES + 1, numObjectInfos do
			sumOthers = sumOthers + spec.objectInfos[i].numObjects
		end

		table.insert(infoTable, {
			title = spec.texts.otherElements,
			text = tostring(sumOthers)
		})
	end
end

function PlaceableObjectStorage.loadSpecValueCapacity(xmlFile, customEnvironment, baseDir)
	if not xmlFile:hasProperty("placeable.objectStorage") then
		return nil
	end

	local totalCapacity = xmlFile:getValue("placeable.objectStorage#capacity", 250)
	local limitedObjectAmount = 0

	xmlFile:iterate("placeable.objectStorage.supportedObject", function (index, objectKey)
		if xmlFile:getValue(objectKey .. "#filename") ~= nil then
			limitedObjectAmount = limitedObjectAmount + xmlFile:getValue(objectKey .. "#amount")
		end
	end)

	if limitedObjectAmount > 0 then
		totalCapacity = math.min(totalCapacity, limitedObjectAmount)
	end

	return totalCapacity
end

function PlaceableObjectStorage.getSpecValueCapacity(storeItem, realItem)
	if storeItem.specs.objectStorageCapacity == nil then
		return nil
	end

	return string.format("%d %s", storeItem.specs.objectStorageCapacity, g_i18n:getText("unit_pieces"))
end

function PlaceableObjectStorage.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
	local fillTypes = {}

	xmlFile:iterate("placeable.objectStorage.supportedObject", function (index, objectKey)
		local fillTypeName = xmlFile:getValue(objectKey .. "#fillType")

		if fillTypeName ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName:upper())

			if fillTypeIndex ~= nil then
				table.insert(fillTypes, fillTypeIndex)
			end
		end
	end)

	return fillTypes
end

function PlaceableObjectStorage.getSpecValueFillTypes(storeItem, realItem)
	local fillTypes = storeItem.specs.objectStorageFillTypes

	if fillTypes == nil or #fillTypes == 0 then
		return nil
	end

	return fillTypes
end

PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME = {}
PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_ID = {}
PlaceableObjectStorage.ABSTRACT_OBJECTS = {}

function PlaceableObjectStorage.addAbstractObjectClass(class)
	PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME[class.REFERENCE_CLASS_NAME] = class

	table.insert(PlaceableObjectStorage.ABSTRACT_OBJECTS, class)

	class.ABSTRACT_OBJECT_ID = #PlaceableObjectStorage.ABSTRACT_OBJECTS
	PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_ID[class.ABSTRACT_OBJECT_ID] = class
end

local AbstractBaleObject = {}
local AbstractBaleObject_mt = Class(AbstractBaleObject)
AbstractBaleObject.REFERENCE_CLASS_NAME = "Bale"

function AbstractBaleObject.registerXMLPaths(schema, basePath)
	Bale.registerSavegameXMLPaths(schema, basePath)
end

function AbstractBaleObject.new()
	local self = {}

	setmetatable(self, AbstractBaleObject_mt)

	return self
end

function AbstractBaleObject:delete()
	if self.baleObject ~= nil then
		self.baleObject:delete()
	end
end

function AbstractBaleObject.isObjectSupported(storage, object)
	if not storage.spec_objectStorage.supportsBales then
		return false
	end

	if not storage:getObjectStorageSupportsFillType(object:getFillType()) then
		return false
	end

	return true
end

function AbstractBaleObject.canStoreObject(storage, object)
	local _, bWidth, bHeight, bLength, bDiameter, _ = g_baleManager:getBaleInfoByXMLFilename(object.xmlFilename)
	bLength = bLength or bDiameter
	bHeight = bHeight or bDiameter

	if storage.spec_objectStorage.maxLength < bLength or storage.spec_objectStorage.maxHeight < bHeight or storage.spec_objectStorage.maxWidth < bWidth then
		return false
	end

	if object.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
		return false
	end

	return true
end

function AbstractBaleObject:addToStorage(storage, object, loadedFromSavegame)
	if object.isFermenting then
		local x, y, z = getWorldTranslation(storage.rootNode)
		local rx, ry, rz = getWorldRotation(storage.rootNode)

		if not loadedFromSavegame then
			local baleAttributes = object:getBaleAttributes()

			object:delete()

			local baleObject = Bale.new(storage.isServer, storage.isClient)

			if baleObject:loadFromConfigXML(baleAttributes.xmlFilename, x, y, z, rx, ry, rz) then
				baleObject:applyBaleAttributes(baleAttributes)
				removeFromPhysics(baleObject.nodeId)
				setVisibility(baleObject.nodeId, false)
				g_currentMission.itemSystem:removeItemToSave(baleObject)
			end

			self.baleObject = baleObject
		else
			removeFromPhysics(object.nodeId)
			setVisibility(object.nodeId, false)
			setWorldTranslation(object.nodeId, x, y, z)
			setWorldRotation(object.nodeId, rx, ry, rz)
			object:unregister()
			g_currentMission.itemSystem:removeItemToSave(object)

			self.baleObject = object
		end
	else
		self.baleAttributes = object:getBaleAttributes()

		object:delete()
	end

	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", 1)
end

function AbstractBaleObject:removeFromStorage(storage, x, y, z, rx, ry, rz, spawnedCallback)
	local baleObject = nil

	if self.baleObject ~= nil then
		addToPhysics(self.baleObject.nodeId)
		setVisibility(self.baleObject.nodeId, true)

		local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)

		self.baleObject:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		self.baleObject:register()
		g_currentMission.itemSystem:addItemToSave(self.baleObject)

		baleObject = self.baleObject
	else
		baleObject = Bale.new(storage.isServer, storage.isClient)

		if baleObject:loadFromConfigXML(self.baleAttributes.xmlFilename, x, y, z, rx, ry, rz) then
			baleObject:applyBaleAttributes(self.baleAttributes)
			baleObject:register()
		end
	end

	if baleObject.isRoundbale then
		removeFromPhysics(baleObject.nodeId)
		rotateAboutLocalAxis(baleObject.nodeId, math.pi * 0.5, 1, 0, 0)
		addToPhysics(baleObject.nodeId)
	end

	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", -1)
	spawnedCallback(storage, baleObject)
end

function AbstractBaleObject.readStream(streamId, connection)
	local self = AbstractBaleObject.new()
	self.baleAttributes = {
		xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)),
		fillLevel = streamReadFloat32(streamId),
		fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS),
		wrappingState = streamReadBool(streamId) and 1 or 0
	}

	return self
end

function AbstractBaleObject:writeStream(streamId, connection)
	if self.baleObject ~= nil then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.baleObject.xmlFilename))
		streamWriteFloat32(streamId, self.baleObject:getFillLevel())
		streamWriteUIntN(streamId, self.baleObject:getFillType(), FillTypeManager.SEND_NUM_BITS)
		streamWriteBool(streamId, self.baleObject.wrappingState ~= 0)
	else
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.baleAttributes.xmlFilename))
		streamWriteFloat32(streamId, self.baleAttributes.fillLevel)
		streamWriteUIntN(streamId, self.baleAttributes.fillType, FillTypeManager.SEND_NUM_BITS)
		streamWriteBool(streamId, self.baleAttributes.wrappingState ~= 0)
	end
end

function AbstractBaleObject:getRealObject()
	return self.baleObject
end

function AbstractBaleObject:getXMLFilename()
	if self.baleObject ~= nil then
		return self.baleObject.xmlFilename
	elseif self.baleAttributes ~= nil then
		return self.baleAttributes.xmlFilename
	end
end

function AbstractBaleObject:getIsIdentical(otherAbstractObject)
	if self.REFERENCE_CLASS_NAME ~= otherAbstractObject.REFERENCE_CLASS_NAME then
		return false
	end

	if self.baleObject ~= nil and otherAbstractObject.baleObject ~= nil then
		if self.baleObject:getFillType() ~= otherAbstractObject.baleObject:getFillType() then
			return false
		end

		if self.baleObject:getFillLevel() ~= otherAbstractObject.baleObject:getFillLevel() then
			return false
		end

		if self.baleObject.xmlFilename ~= otherAbstractObject.baleObject.xmlFilename then
			return false
		end

		return true
	elseif self.baleAttributes ~= nil and otherAbstractObject.baleAttributes ~= nil then
		if self.baleAttributes.fillType ~= otherAbstractObject.baleAttributes.fillType then
			return false
		end

		if self.baleAttributes.fillLevel ~= otherAbstractObject.baleAttributes.fillLevel then
			return false
		end

		if self.baleAttributes.xmlFilename ~= otherAbstractObject.baleAttributes.xmlFilename then
			return false
		end

		return true
	end

	return false
end

function AbstractBaleObject:getDialogText()
	local xmlFilename, fillTypeTitle, fillLevel = nil

	if self.baleObject ~= nil then
		xmlFilename = self.baleObject.xmlFilename
		fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(self.baleObject:getFillType())
		fillLevel = self.baleObject:getFillLevel()
	else
		xmlFilename = self.baleAttributes.xmlFilename
		fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(self.baleAttributes.fillType)
		fillLevel = self.baleAttributes.fillLevel
	end

	local baleTitle = nil
	local isRoundbale, _, _, _, _, _ = g_baleManager:getBaleInfoByXMLFilename(xmlFilename, true)

	if isRoundbale then
		baleTitle = g_i18n:getText("fillType_roundBale")
	else
		baleTitle = g_i18n:getText("fillType_squareBale")
	end

	return string.format("%s (%s %s)", baleTitle, fillTypeTitle, g_i18n:formatFluid(fillLevel))
end

function AbstractBaleObject:getLimitedObjectId()
	return SlotSystem.LIMITED_OBJECT_BALE, PlaceableObjectStorageErrorEvent.ERROR_SLOT_LIMIT_REACHED_BALES
end

function AbstractBaleObject:getSpawnInfo()
	local xmlFilename = nil

	if self.baleObject ~= nil then
		xmlFilename = self.baleObject.xmlFilename
	else
		xmlFilename = self.baleAttributes.xmlFilename
	end

	local isRoundbale, bWidth, bHeight, bLength, bDiameter, bMaxStackHeight = g_baleManager:getBaleInfoByXMLFilename(xmlFilename, true)
	local ox, oy, oz, width, height, length = nil
	local maxStackHeight = bMaxStackHeight or 1

	if isRoundbale then
		oz = 0
		oy = bWidth * 0.5
		ox = 0
		length = bDiameter
		height = bWidth
		width = bDiameter
	else
		oz = 0
		oy = bHeight * 0.5
		ox = 0
		length = bLength
		height = bHeight
		width = bWidth
	end

	return ox, oy, oz, width, height, length, maxStackHeight
end

local recursiveCopyShaderParameter = nil

function recursiveCopyShaderParameter(target, source, shaderParameter)
	if getHasClassId(target, ClassIds.SHAPE) and getHasClassId(source, ClassIds.SHAPE) and getHasShaderParameter(target, shaderParameter) and getHasShaderParameter(source, shaderParameter) then
		local x, y, z, w = getShaderParameter(source, shaderParameter)

		setShaderParameter(target, shaderParameter, x, y, z, w, false)
	end

	for i = 1, math.min(getNumOfChildren(target), getNumOfChildren(source)) do
		local childTarget = getChildAt(target, i - 1)
		local childSource = getChildAt(source, i - 1)

		recursiveCopyShaderParameter(childTarget, childSource, shaderParameter)
	end
end

function AbstractBaleObject:spawnVisualObjects(visualSpawnInfos)
	local xmlFilename, fillType, wrappingState, wrappingColor = nil

	if self.baleObject ~= nil then
		wrappingColor = self.baleObject.wrappingColor
		wrappingState = self.baleObject.wrappingState
		fillType = self.baleObject:getFillType()
		xmlFilename = self.baleObject.xmlFilename
	else
		wrappingColor = self.baleAttributes.wrappingColor
		wrappingState = self.baleAttributes.wrappingState
		fillType = self.baleAttributes.fillType
		xmlFilename = self.baleAttributes.xmlFilename
	end

	local baleId, sharedLoadRequestId = Bale.createDummyBale(xmlFilename, fillType, wrappingState, wrappingColor)

	for i = 1, #visualSpawnInfos do
		local visualSpawnInfo = visualSpawnInfos[i]
		local clonedBale = clone(baleId, false, false, false)

		recursiveCopyShaderParameter(clonedBale, baleId, "wrappingState")
		recursiveCopyShaderParameter(clonedBale, baleId, "colorScale")
		link(visualSpawnInfo[1], clonedBale)
		setTranslation(clonedBale, visualSpawnInfo[2], visualSpawnInfo[3], visualSpawnInfo[4])
		setRotation(clonedBale, visualSpawnInfo[5], visualSpawnInfo[6], visualSpawnInfo[7])

		local isRoundbale, _, _, _, _, _ = g_baleManager:getBaleInfoByXMLFilename(xmlFilename, true)

		if isRoundbale then
			rotateAboutLocalAxis(clonedBale, math.pi * 0.5, 1, 0, 0)
		end
	end

	delete(baleId)
	g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
end

function AbstractBaleObject:saveToXMLFile(storage, xmlFile, key)
	if self.baleObject ~= nil then
		local attributes = self.baleObject:getBaleAttributes()

		Bale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
	else
		Bale.saveBaleAttributesToXMLFile(self.baleAttributes, xmlFile, key)
	end
end

function AbstractBaleObject.loadFromXMLFile(storage, xmlFile, key)
	local attributes = {}

	Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, false)

	if attributes.isFermenting then
		local bale = Bale.new(storage.isServer, storage.isClient)

		if bale:loadFromConfigXML(attributes.xmlFilename, 0, 0, 0, 0, 0, 0) then
			bale:applyBaleAttributes(attributes)
			storage:addObjectToObjectStorage(bale, true)
		end
	else
		local self = AbstractBaleObject.new()
		self.baleAttributes = attributes

		storage:addAbstactObjectToObjectStorage(self)
		g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", 1)
	end
end

PlaceableObjectStorage.addAbstractObjectClass(AbstractBaleObject)

local AbstractPackedBaleObject = {}
local AbstractPackedBaleObject_mt = Class(AbstractPackedBaleObject, AbstractBaleObject)
AbstractPackedBaleObject.REFERENCE_CLASS_NAME = "PackedBale"

function AbstractPackedBaleObject.new()
	local self = {}

	setmetatable(self, AbstractPackedBaleObject_mt)

	return self
end

PlaceableObjectStorage.addAbstractObjectClass(AbstractPackedBaleObject)

local AbstractPalletObject = {}
local AbstractPalletObject_mt = Class(AbstractPalletObject)
AbstractPalletObject.REFERENCE_CLASS_NAME = "Vehicle"

function AbstractPalletObject.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Owner farm id")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pallet xml file")
	schema:register(XMLValueType.STRING, basePath .. "#fillType", "Fill type")
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Fill level")
	schema:register(XMLValueType.BOOL, basePath .. "#isBigBag", "Is a big bag object")
	schema:register(XMLValueType.STRING, basePath .. ".configuration(?)#name", "Configuration name")
	schema:register(XMLValueType.STRING, basePath .. ".configuration(?)#id", "Configuration id")
end

function AbstractPalletObject.new()
	local self = {}

	setmetatable(self, AbstractPalletObject_mt)

	return self
end

function AbstractPalletObject:delete()
end

function AbstractPalletObject.isObjectSupported(storage, object)
	if not storage.spec_objectStorage.supportsPallets then
		return false
	end

	if not object.isPallet then
		return false
	end

	if object.propertyState ~= Vehicle.PROPERTY_STATE_OWNED then
		return false
	end

	if not storage:getObjectStorageSupportsFillType(object:getFillUnitFillType(object.spec_pallet.fillUnitIndex)) then
		return false
	end

	return true
end

function AbstractPalletObject.canStoreObject(storage, object)
	local size = AbstractPalletObject.getSize(object.configFileName)

	if storage.spec_objectStorage.maxLength < size.length or storage.spec_objectStorage.maxHeight < size.height or storage.spec_objectStorage.maxWidth < size.width then
		return false
	end

	if object.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
		return false
	end

	return true
end

function AbstractPalletObject:addToStorage(storage, object, loadedFromSavegame)
	self.palletAttributes = {
		ownerFarmId = object:getOwnerFarmId(),
		configFileName = object.configFileName,
		isBigBag = SpecializationUtil.hasSpecialization(BigBag, object.specializations)
	}

	if object.getFillUnitByIndex ~= nil and object.spec_pallet.fillUnitIndex ~= nil then
		self.palletAttributes.fillType = object:getFillUnitFillType(object.spec_pallet.fillUnitIndex)
		self.palletAttributes.fillLevel = object:getFillUnitFillLevel(object.spec_pallet.fillUnitIndex)
	end

	self.palletAttributes.configurations = {}

	for k, v in pairs(object.configurations) do
		self.palletAttributes.configurations[k] = v
	end

	object:delete()
	AbstractPalletObject.getSize(self.palletAttributes.configFileName)
	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedPallets", 1)
end

function AbstractPalletObject:removeFromStorage(storage, x, y, z, rx, ry, rz, spawnedCallback)
	local location = {
		x = x,
		y = y,
		z = z,
		yRot = ry
	}

	VehicleLoadingUtil.loadVehicle(self.palletAttributes.configFileName, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, self.palletAttributes.ownerFarmId, self.palletAttributes.configurations, nil, AbstractPalletObject.palletVehicleLoaded, self, {
		storage,
		spawnedCallback
	})
	g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedPallets", -1)
end

function AbstractPalletObject:palletVehicleLoaded(vehicle, vehicleLoadState, asyncCallbackArguments)
	if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK and vehicle ~= nil then
		if self.palletAttributes.fillType ~= nil then
			vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), vehicle.spec_pallet.fillUnitIndex, self.palletAttributes.fillLevel, self.palletAttributes.fillType, ToolType.UNDEFINED, nil)
		end

		asyncCallbackArguments[2](asyncCallbackArguments[1], vehicle)
	end
end

function AbstractPalletObject.readStream(streamId, connection)
	local self = AbstractPalletObject.new()
	self.palletAttributes = {
		configFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)),
		isBigBag = streamReadBool(streamId)
	}

	if streamReadBool(streamId) then
		self.palletAttributes.fillLevel = streamReadFloat32(streamId)
		self.palletAttributes.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	else
		self.palletAttributes.fillLevel = 0
		self.palletAttributes.fillType = nil
	end

	return self
end

function AbstractPalletObject:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.palletAttributes.configFileName))
	streamWriteBool(streamId, self.palletAttributes.isBigBag)

	if streamWriteBool(streamId, self.palletAttributes.fillType ~= nil) then
		streamWriteFloat32(streamId, self.palletAttributes.fillLevel)
		streamWriteUIntN(streamId, self.palletAttributes.fillType, FillTypeManager.SEND_NUM_BITS)
	end
end

function AbstractPalletObject:getRealObject()
	return nil
end

function AbstractPalletObject:getXMLFilename()
	if self.palletAttributes ~= nil then
		return self.palletAttributes.configFileName
	end
end

function AbstractPalletObject:getIsIdentical(otherAbstractObject)
	if self.REFERENCE_CLASS_NAME ~= otherAbstractObject.REFERENCE_CLASS_NAME then
		return false
	end

	if self.palletAttributes.fillType ~= otherAbstractObject.palletAttributes.fillType then
		return false
	end

	if self.palletAttributes.fillLevel ~= otherAbstractObject.palletAttributes.fillLevel then
		return false
	end

	if self.palletAttributes.configFileName ~= otherAbstractObject.palletAttributes.configFileName then
		return false
	end

	if self.palletAttributes.isBigBag ~= otherAbstractObject.palletAttributes.isBigBag then
		return false
	end

	return true
end

function AbstractPalletObject:getDialogText()
	local text = self.palletAttributes.isBigBag and "shopItem_bigBag" or "infohud_pallet"

	if self.palletAttributes.fillType ~= nil and self.palletAttributes.fillType ~= FillType.UNKNOWN then
		local fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(self.palletAttributes.fillType)
		local fillLevel = self.palletAttributes.fillLevel

		return string.format("%s (%s %s)", g_i18n:getText(text), fillTypeTitle, g_i18n:formatFluid(fillLevel))
	else
		local storeItem = g_storeManager:getItemByXMLFilename(self.palletAttributes.configFileName)

		if storeItem ~= nil then
			return string.format("%s (%s)", g_i18n:getText(text), storeItem.name)
		end
	end
end

function AbstractPalletObject:getLimitedObjectId()
	return SlotSystem.LIMITED_OBJECT_PALLET, PlaceableObjectStorageErrorEvent.ERROR_SLOT_LIMIT_REACHED_PALLETS
end

function AbstractPalletObject:getSpawnInfo()
	local size = AbstractPalletObject.getSize(self.palletAttributes.configFileName)

	return size.widthOffset, size.heightOffset, size.lengthOffset, size.width, size.height, size.length, 1
end

function AbstractPalletObject:spawnVisualObjects(visualSpawnInfos)
	local location = {
		yRot = 0,
		z = 0,
		x = 0,
		y = 0
	}

	VehicleLoadingUtil.loadVehicle(self.palletAttributes.configFileName, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, self.palletAttributes.ownerFarmId, self.palletAttributes.configurations, nil, AbstractPalletObject.visualPalletVehicleLoaded, self, {
		visualSpawnInfos
	}, false)
end

function AbstractPalletObject:visualPalletVehicleLoaded(vehicle, vehicleLoadState, asyncCallbackArguments)
	if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK and vehicle ~= nil then
		local visualSpawnInfos = asyncCallbackArguments[1]

		if self.palletAttributes.fillType ~= nil then
			vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), vehicle.spec_pallet.fillUnitIndex, self.palletAttributes.fillLevel, self.palletAttributes.fillType, ToolType.UNDEFINED, nil)
		end

		vehicle:setVisibility(true)

		local vehicleRootNode = createTransformGroup("vehicleRootNode")

		for i = 1, #vehicle.components do
			local component = vehicle.components[i]

			link(vehicleRootNode, component.node)
		end

		for i = 1, #visualSpawnInfos do
			local visualSpawnInfo = visualSpawnInfos[i]
			local clonedPallet = clone(vehicleRootNode, false, false, false)

			link(visualSpawnInfo[1], clonedPallet)
			setTranslation(clonedPallet, visualSpawnInfo[2], visualSpawnInfo[3], visualSpawnInfo[4])
			setRotation(clonedPallet, visualSpawnInfo[5], visualSpawnInfo[6], visualSpawnInfo[7])
		end

		vehicle:delete()
		delete(vehicleRootNode)
	end
end

function AbstractPalletObject:saveToXMLFile(storage, xmlFile, key)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.palletAttributes.configFileName)))
	xmlFile:setValue(key .. "#farmId", self.palletAttributes.ownerFarmId)
	xmlFile:setValue(key .. "#isBigBag", self.palletAttributes.isBigBag)

	if self.palletAttributes.fillType ~= nil then
		xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(self.palletAttributes.fillType))
		xmlFile:setValue(key .. "#fillLevel", self.palletAttributes.fillLevel)
	end

	local index = 0

	for configName, configId in pairs(self.palletAttributes.configurations) do
		local configKey = string.format("%s.configuration(%d)", key, index)
		local saveId = ConfigurationUtil.getSaveIdByConfigId(self.palletAttributes.configFileName, configName, configId)

		if saveId ~= nil then
			xmlFile:setValue(configKey .. "#name", configName)
			xmlFile:setValue(configKey .. "#id", saveId)
		end

		index = index + 1
	end
end

function AbstractPalletObject.loadFromXMLFile(storage, xmlFile, key)
	local attributes = {
		configFileName = NetworkUtil.convertFromNetworkFilename(xmlFile:getValue(key .. "#filename")),
		isBigBag = xmlFile:getValue(key .. "#isBigBag", false)
	}
	local storeItem = g_storeManager:getItemByXMLFilename(attributes.configFileName)

	if storeItem ~= nil then
		attributes.ownerFarmId = xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE)
		local fillTypeName = xmlFile:getValue(key .. "#fillType")

		if fillTypeName ~= nil then
			attributes.fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
			attributes.fillLevel = xmlFile:getValue(key .. "#fillLevel", 0)
		end

		attributes.configurations = {}

		xmlFile:iterate(key .. ".configuration", function (index, configKey)
			local configName = xmlFile:getValue(configKey .. "#name")
			local saveId = xmlFile:getValue(configKey .. "#id")
			local configId = ConfigurationUtil.getConfigIdBySaveId(attributes.configFileName, configName, saveId)

			if configId ~= nil then
				attributes.configurations[configName] = configId
			end
		end)

		local self = AbstractPalletObject.new()
		self.palletAttributes = attributes

		storage:addAbstactObjectToObjectStorage(self)
		AbstractPalletObject.getSize(self.palletAttributes.configFileName)
		g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedPallets", 1)
	else
		Logging.info("Pallet could not be loaded into the storage. Path does not exist anymore. (%s)", attributes.configFileName)
	end
end

AbstractPalletObject.configFileNameToSize = {}

function AbstractPalletObject.getSize(configFileName)
	if AbstractPalletObject.configFileNameToSize[configFileName] ~= nil then
		return AbstractPalletObject.configFileNameToSize[configFileName]
	else
		AbstractPalletObject.configFileNameToSize[configFileName] = StoreItemUtil.getSizeValues(configFileName, "vehicle", 0, {})

		return AbstractPalletObject.configFileNameToSize[configFileName]
	end
end

PlaceableObjectStorage.addAbstractObjectClass(AbstractPalletObject)

PlaceableObjectStorageActivatable = {}
local PlaceableObjectStorageActivatable_mt = Class(PlaceableObjectStorageActivatable)

function PlaceableObjectStorageActivatable.new(objectStorage)
	local self = setmetatable({}, PlaceableObjectStorageActivatable_mt)
	self.objectStorage = objectStorage
	self.activateText = g_i18n:getText("action_objectStorageMenu")
	self.warningText = g_i18n:getText("warning_objectStorageIsEmpty")

	return self
end

function PlaceableObjectStorageActivatable:getIsActivatable()
	if not g_currentMission.accessHandler:canPlayerAccess(self.objectStorage) then
		return false
	end

	if self.objectStorage.spec_objectStorage.objectSpawn.isActive then
		return false
	end

	return true
end

function PlaceableObjectStorageActivatable:run()
	self.objectStorage:updateDirtyObjectStorageObjectInfos()

	local objectInfos = self.objectStorage:getObjectStorageObjectInfos()

	if objectInfos ~= nil and #objectInfos > 0 then
		ObjectStorageDialog.show(self.onObjectInfoSelected, self, self.objectStorage:getName(), objectInfos, self.objectStorage.spec_objectStorage.maxUnloadAmount)
	else
		g_currentMission:showBlinkingWarning(string.format(self.warningText, self.objectStorage:getName()), 2000)
	end
end

function PlaceableObjectStorageActivatable:getDistance(x, y, z)
	if self.objectStorage.spec_objectStorage.playerTriggerNode ~= nil then
		local tx, ty, tz = getWorldTranslation(self.objectStorage.spec_objectStorage.playerTriggerNode)

		return MathUtil.vector3Length(x - tx, y - ty, z - tz)
	end

	return math.huge
end

function PlaceableObjectStorageActivatable:onObjectInfoSelected(objectInfoIndex, amount)
	if objectInfoIndex ~= nil and amount ~= nil then
		g_client:getServerConnection():sendEvent(PlaceableObjectStorageUnloadEvent.new(self.objectStorage, objectInfoIndex, amount))
	end
end
