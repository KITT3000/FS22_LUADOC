DestructibleMapObjectSystem = {
	GROUP_ID_NUM_BITS = 8
}
DestructibleMapObjectSystem.MAX_GORUP_ID = 2^DestructibleMapObjectSystem.GROUP_ID_NUM_BITS - 1
DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS = 8
DestructibleMapObjectSystem.MAX_CHILD_INDEX = 2^DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS - 1
DestructibleMapObjectSystem.XML_FILENAME = "destructibleMapObjectSystem.xml"
DestructibleMapObjectSystem.xmlSchema = nil
local DestructibleMapObjectSystem_mt = Class(DestructibleMapObjectSystem)

g_xmlManager:addCreateSchemaFunction(function ()
	DestructibleMapObjectSystem.xmlSchemaSavegame = XMLSchema.new("destructibleMapObjects_savegame")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = DestructibleMapObjectSystem.xmlSchemaSavegame

	schema:register(XMLValueType.INT, "destructibleMapObjects.group(?)#id", "Group id defined as user attribute in map")
	schema:register(XMLValueType.INT, "destructibleMapObjects.group(?).item(?)#index", "I3d child index of destroyed object in group")
end)

function DestructibleMapObjectSystem:onCreate(node)
	g_remoteProfiler.ZoneBeginN("DestructibleMapObjectSystem:onCreate")
	g_currentMission.destructibleMapObjectSystem:addGroup(node)
	g_remoteProfiler.ZoneEnd()
end

function DestructibleMapObjectSystem.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or DestructibleMapObjectSystem_mt)
	self.mission = mission
	self.isServer = isServer
	self.groups = {}
	self.groupIdToGroupRoot = {}
	self.destructibleTypes = {}
	self.nodeToDestructible = {}
	self.destructibleToGroup = {}
	self.destructibleToRigidBodies = {}

	addConsoleCommand("gsDestructibleObjectsDebug", "Toggle DestructibleMapObjectSystem debug", "consoleCommandToggleDebug", self)

	if self.isServer then
		addConsoleCommand("gsDestructibleObjectsDestroy", "Destroy destructible object camera is pointed at", "consoleCommandDestroyNode", self)
	end

	return self
end

function DestructibleMapObjectSystem:delete()
	removeConsoleCommand("gsDestructibleObjectsDebug")
	removeConsoleCommand("gsDestructibleObjectsDestroy")
end

function DestructibleMapObjectSystem:onClientJoined(connection)
	for groupRoot, group in pairs(self.groups) do
		local childIndices = {}
		local numChildren = getNumOfChildren(groupRoot)

		for childIndex = 0, numChildren - 1 do
			childIndices[childIndex + 1] = not getVisibility(getChildAt(groupRoot, childIndex))
		end

		connection:sendEvent(DestroyedMapObjectsEvent.new(group.groupId, childIndices))
	end
end

function DestructibleMapObjectSystem:addGroup(groupRootNode)
	local function printUserAttributeInterface()
		print("Supported userAttributes next to DestructibleMapObjectSystem.onCreate")
		printf("    'destructibleType' (string)  (required)")
		printf("    'groupId'          (integer) (required if more than one group exists) default: 0; allowed values: 0 - %d)", DestructibleMapObjectSystem.MAX_GORUP_ID)
		printf("    'dropFillTypeName' (string)  (optional) default: nil")
		printf("    'dropAmount'       (float)   (optional) default: 500")
	end

	local destructibleType = getUserAttribute(groupRootNode, "destructibleType")

	if destructibleType == nil then
		Logging.error("Missing userAttribute 'destructibleType' for '%s'", I3DUtil.getNodePath(groupRootNode))
		printUserAttributeInterface()

		return false
	end

	local groupId = math.floor(tonumber(getUserAttribute(groupRootNode, "groupId")) or 0)

	if groupId < 0 or DestructibleMapObjectSystem.MAX_GORUP_ID < groupId then
		Logging.error("GroupId '%d' for %s out of allowed rage [0 %d]", groupId, I3DUtil.getNodePath(groupRootNode), DestructibleMapObjectSystem.MAX_GORUP_ID)

		return false
	end

	if self.groupIdToGroupRoot[groupId] ~= nil then
		Logging.error("GroupId '%d' of '%s' already in use in '%s'. Please use a different groupId", groupId, I3DUtil.getNodePath(groupRootNode), I3DUtil.getNodePath(self.groupIdToGroupRoot[groupId]))
		printUserAttributeInterface()

		return false
	end

	local dropFillTypeName = getUserAttribute(groupRootNode, "dropFillTypeName") or destructibleType
	local dropFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(dropFillTypeName)
	local dropAmount = getUserAttribute(groupRootNode, "dropAmount") or 500
	local group = {
		destructibleType = string.upper(destructibleType),
		groupId = groupId,
		dropFillTypeIndex = dropFillTypeIndex,
		dropAmount = dropAmount
	}
	self.groupIdToGroupRoot[groupId] = groupRootNode
	self.groups[groupRootNode] = group

	if self.destructibleTypes[destructibleType] == nil then
		self.destructibleTypes[destructibleType] = {}
	end

	self.destructibleTypes[destructibleType][group] = true
	local numChildren = getNumOfChildren(groupRootNode)

	if DestructibleMapObjectSystem.MAX_CHILD_INDEX < numChildren then
		Logging.warning("Only %d child nodes supported per group. Ignoring additional children for '%s'", DestructibleMapObjectSystem.MAX_CHILD_INDEX + 1, I3DUtil.getNodePath(groupRootNode))
	end

	local function addRigidBodyMapping(childNode, node)
		self.nodeToDestructible[node] = childNode
		self.destructibleToGroup[childNode] = group
		self.destructibleToRigidBodies[childNode] = self.destructibleToRigidBodies[childNode] or {}

		table.insert(self.destructibleToRigidBodies[childNode], node)
	end

	for childIndex = 0, math.min(numChildren - 1, DestructibleMapObjectSystem.MAX_CHILD_INDEX) do
		local childNode = getChildAt(groupRootNode, childIndex)

		local function checkRigidBody(node)
			if getRigidBodyType(node) ~= RigidBodyType.NONE then
				addRigidBodyMapping(childNode, node)
			end
		end

		checkRigidBody(childNode)
		I3DUtil.interateRecursively(childNode, checkRigidBody)
	end

	return true
end

function DestructibleMapObjectSystem:setDestructibleDestroyed(destructible, dropTipAny)
	local lx = 0
	local ly = 0
	local lz = 0
	local radius = 0
	local wx, wy, wz, minX, maxX, minZ, maxZ = nil
	local rigidBodies = self.destructibleToRigidBodies[destructible]

	if rigidBodies ~= nil then
		for _, rigidBody in ipairs(rigidBodies) do
			setRigidBodyType(rigidBody, RigidBodyType.NONE)

			lx, ly, lz, radius = getShapeBoundingSphere(rigidBody)
			wx, _, wz = localToWorld(rigidBody, lx, ly, lz)
			minX = wx - radius
			maxX = wx + radius
			minZ = wz - radius
			maxZ = wz + radius

			g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
			self.mission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
		end
	end

	setVisibility(destructible, false)

	if dropTipAny then
		local group = self.destructibleToGroup[destructible]

		if group.dropFillTypeIndex ~= nil and group.dropAmount > 0 then
			wx, wy, wz = getWorldTranslation(destructible)

			DensityMapHeightUtil.tipToGroundAroundLine(nil, group.dropAmount, group.dropFillTypeIndex, wx - 0.5, wy, wz - 0.5, wx + 0.5, wy + 1, wz + 0.5, nil, nil, nil, nil, nil)
		end
	end

	if g_server ~= nil then
		local group = self.destructibleToGroup[destructible]

		if group ~= nil then
			local childIndex = getChildIndex(destructible)

			g_server:broadcastEvent(MapObjectDestroyedEvent.new(group.groupId, childIndex))
		end
	end
end

function DestructibleMapObjectSystem:setGroupChildIndexDestroyed(groupId, childIndex, dropTipAny)
	local groupRoot = self.groupIdToGroupRoot[groupId]

	if groupRoot == nil then
		Logging.error("DestructibleMapObjectSystem: Unable to get groupRoot for group id " .. tostring(groupId))
	end

	self:setChildIndexDestroyed(groupRoot, childIndex, dropTipAny)
end

function DestructibleMapObjectSystem:setChildIndexDestroyed(groupRoot, childIndex, dropTipAny)
	if getNumOfChildren(groupRoot) < childIndex then
		local group = self.groups[groupRoot]

		Logging.warning("DestructibleMapObjectSystem: invalid child index %d, group %d at '%s' only has %d children", childIndex, group.groupId, I3DUtil.getNodePath(groupRoot), getNumOfChildren(groupRoot))

		return
	end

	local destructible = getChildAt(groupRoot, childIndex)

	self:setDestructibleDestroyed(destructible, dropTipAny)
end

function DestructibleMapObjectSystem:getDestructedChildIndices(groupRoot)
	local destructedChildIndices = {}
	local numChildren = getNumOfChildren(groupRoot)

	for childIndex = 0, numChildren - 1 do
		if not getVisibility(getChildAt(groupRoot, childIndex)) then
			table.insert(destructedChildIndices, childIndex)
		end
	end

	return destructedChildIndices
end

function DestructibleMapObjectSystem:saveToXMLFile(xmlPath, usedModNames)
	if xmlPath ~= nil and next(self.groups) ~= nil then
		local xmlFile = XMLFile.create("DestructibleMapObjectSystemXML", xmlPath, "destructibleMapObjects", DestructibleMapObjectSystem.xmlSchemaSavegame)
		local numItems = 0

		xmlFile:setTable("destructibleMapObjects.group", self.groups, function (groupKey, group, groupRoot)
			local destructedChildIndices = self:getDestructedChildIndices(groupRoot)

			if #destructedChildIndices == 0 then
				return 0
			end

			numItems = numItems + #destructedChildIndices

			xmlFile:setValue(groupKey .. "#id", group.groupId)
			xmlFile:setTable(groupKey .. ".item", destructedChildIndices, function (path, childIndex, key)
				xmlFile:setValue(path .. "#index", childIndex)
			end)
		end)
		xmlFile:save()
		xmlFile:delete()
	end
end

function DestructibleMapObjectSystem:loadFromXMLFile(xmlPath)
	if xmlPath ~= nil and next(self.groups) ~= nil then
		local xmlFile = XMLFile.loadIfExists("DestructibleMapObjectSystemXML", xmlPath, DestructibleMapObjectSystem.xmlSchemaSavegame)

		if xmlFile ~= nil then
			local loadedGroups = 0
			local loadedChildren = 0

			xmlFile:iterate("destructibleMapObjects.group", function (groupIndex, groupKey)
				local groupId = xmlFile:getValue(groupKey .. "#id")

				if groupId == nil then
					Logging.xmlWarning(xmlFile, "Group %s is missing an 'id' attribute", groupKey)

					return true
				end

				local groupRoot = self.groupIdToGroupRoot[groupId]

				if groupRoot == nil then
					Logging.xmlWarning(xmlFile, "Group with id '%s' (%s) does not exist in map", groupId, groupKey)

					return true
				end

				loadedGroups = loadedGroups + 1

				xmlFile:iterate(groupKey .. ".item", function (itemIndex, itemKey)
					local childIndex = xmlFile:getValue(itemKey .. "#index")
					loadedChildren = loadedChildren + 1

					self:setChildIndexDestroyed(groupRoot, childIndex, false)
				end)

				return true
			end)
			xmlFile:delete()
		else
			Logging.devInfo("DestructibleMapObjectSystem: no xml to load from savegame")
		end
	end
end

function DestructibleMapObjectSystem:consoleCommandDestroyNode(destructibleType)
	destructibleType = destructibleType and string.upper(destructibleType)
	local cam = getCamera(0)
	local wx, wy, wz = getWorldTranslation(cam)
	local dx, dy, dz = localDirectionToWorld(cam, 0, 0, -1)
	wz = wz + dz
	wy = wy + dy
	wx = wx + dx
	local distance = 30

	raycastClosest(wx, wy, wz, dx, dy, dz, "consoleCommandDestroyNodeRaycastCallback", distance, self, CollisionMask.ALL - CollisionFlag.PLAYER)

	local callbackNode = self.callbackNode
	self.callbackNode = nil
	local destructible = self.nodeToDestructible[callbackNode]

	if destructible then
		if destructibleType ~= nil then
			local destructibleTypeGroups = self.destructibleTypes[destructibleType]

			if not destructibleTypeGroups or not destructibleTypeGroups[self.destructibleToGroup[destructible]] then
				return string.format("No destructible found for given destructible type '%s'", destructibleType)
			end
		end

		self:setDestructibleDestroyed(destructible, true)

		local group = self.destructibleToGroup[destructible]

		return string.format("Destroyed destructible %d of group %d", getChildIndex(destructible), group.groupId)
	else
		return "No destructible found"
	end
end

function DestructibleMapObjectSystem:consoleCommandDestroyNodeRaycastCallback(transformId, x, y, z, distance, nx, ny, nz)
	if getName(transformId) == "playerCCT" then
		return true
	end

	self.callbackNode = transformId

	return false
end

function DestructibleMapObjectSystem:consoleCommandToggleDebug()
	if not self.mission:getHasDrawable(self) then
		self.mission:addDrawable(self)

		return "DestructibleMapObjectSystem: Enabled debug"
	else
		self.mission:removeDrawable(self)

		return "DestructibleMapObjectSystem: Disabled debug"
	end
end

function DestructibleMapObjectSystem:draw()
	local i = 1

	if next(self.groups) then
		renderText(0.28, 0.96, 0.02, tostring(table.size(self.groups)) .. " Groups - Total num destructibles: " .. tostring(table.size(self.nodeToDestructible)))

		for groupRootNode, group in pairs(self.groups) do
			local destructedChildIndices = self:getDestructedChildIndices(groupRootNode)

			renderText(0.3, 0.96 - i * 0.02, 0.02, string.format("%s (%s) (%s) - %d destructibles - %d destroyed", getName(groupRootNode), groupRootNode, group.destructibleType, getNumOfChildren(groupRootNode), #destructedChildIndices))

			for childNumber, childIndex in ipairs(destructedChildIndices) do
				i = i + 1

				renderText(0.32, 0.96 - i * 0.02, 0.02, string.format("#%d - node child index: %d", childNumber, childIndex))
			end

			i = i + 1
		end
	end

	i = i + 1

	if next(self.destructibleTypes) then
		renderText(0.28, 0.96 - i * 0.02, 0.02, "Destructible Types")

		i = i + 1

		for typeName, groups in pairs(self.destructibleTypes) do
			renderText(0.3, 0.96 - i * 0.02, 0.02, string.format("%s - num groups: %d", typeName, table.size(groups)))

			i = i + 1
		end
	end
end

MapObjectDestroyedEvent = {}
local MapObjectDestroyedEvent_mt = Class(MapObjectDestroyedEvent, Event)

InitEventClass(MapObjectDestroyedEvent, "MapObjectDestroyedEvent")

function MapObjectDestroyedEvent.emptyNew()
	local self = Event.new(MapObjectDestroyedEvent_mt)

	return self
end

function MapObjectDestroyedEvent.new(groupId, childIndex)
	local self = MapObjectDestroyedEvent.emptyNew()
	self.groupId = groupId
	self.childIndex = childIndex

	return self
end

function MapObjectDestroyedEvent:readStream(streamId, connection)
	self.groupId = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	self.childIndex = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)

	self:run(connection)
end

function MapObjectDestroyedEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	streamWriteUIntN(streamId, self.childIndex, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
end

function MapObjectDestroyedEvent:run(connection)
	if connection:getIsServer() and self.groupId and self.childIndex then
		g_currentMission.destructibleMapObjectSystem:setGroupChildIndexDestroyed(self.groupId, self.childIndex, false)
	end
end

DestroyedMapObjectsEvent = {}
local DestroyedMapObjectsEvent_mt = Class(DestroyedMapObjectsEvent, Event)

InitEventClass(DestroyedMapObjectsEvent, "DestroyedMapObjectsEvent")

function DestroyedMapObjectsEvent.emptyNew()
	local self = Event.new(DestroyedMapObjectsEvent_mt)

	return self
end

function DestroyedMapObjectsEvent.new(groupId, childIndicesStatus)
	local self = DestroyedMapObjectsEvent.emptyNew()
	self.groupId = groupId
	self.childIndicesStatus = childIndicesStatus

	return self
end

function DestroyedMapObjectsEvent:readStream(streamId, connection)
	self.groupId = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	local numChildIndices = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
	self.childIndicesStatus = {}

	for i = 1, numChildIndices do
		self.childIndicesStatus[i] = streamReadBool(streamId)
	end

	self:run(connection)
end

function DestroyedMapObjectsEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	streamWriteUIntN(streamId, #self.childIndicesStatus, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)

	for _, childVisibility in ipairs(self.childIndicesStatus) do
		streamWriteBool(streamId, childVisibility)
	end
end

function DestroyedMapObjectsEvent:run(connection)
	if connection:getIsServer() and self.groupId and self.childIndicesStatus then
		for childIndex, isDestroyed in ipairs(self.childIndicesStatus) do
			if isDestroyed then
				g_currentMission.destructibleMapObjectSystem:setGroupChildIndexDestroyed(self.groupId, childIndex - 1, false)
			end
		end
	end
end
