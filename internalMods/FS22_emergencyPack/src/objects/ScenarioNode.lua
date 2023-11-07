ScenarioNode = {}
local ScenarioNode_mt = Class(ScenarioNode, PhysicsObject)

InitObjectClass(ScenarioNode, "ScenarioNode")

function ScenarioNode.registerXMLPaths(schema, basePath)
	ScenarioEffectObject.registerXMLPaths(schema, basePath)
	ScenarioTree.registerXMLPaths(schema, basePath)
end

function ScenarioNode.new(isServer, isClient, custom_mt)
	local self = ScenarioNode:superClass().new(isServer, isClient, custom_mt or ScenarioNode_mt)
	self.groupId = "unknown"
	self.positionOffset = {
		0,
		0,
		0
	}
	self.rotationOffset = {
		0,
		0,
		0
	}
	self.groundYOffset = 0.05
	self.startWithPhysics = true

	return self
end

function ScenarioNode:delete()
	self.isDeleted = true

	ScenarioNode:superClass().delete(self)
end

function ScenarioNode:readStream(streamId, connection, objectId)
	ScenarioNode:superClass().readStream(self, streamId, connection, objectId)
end

function ScenarioNode:writeStream(streamId, connection)
	ScenarioNode:superClass().writeStream(self, streamId, connection)
end

function ScenarioNode:writeUpdateStream(streamId, connection, dirtyMask)
	if self.simulatePhysics then
		ScenarioNode:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	end
end

function ScenarioNode:readUpdateStream(streamId, timestamp, connection)
	if self.simulatePhysics then
		ScenarioNode:superClass().readUpdateStream(self, streamId, timestamp, connection)
	end
end

function ScenarioNode:updateTick(dt)
	if not self.simulatePhysics then
		return
	end

	ScenarioNode:superClass().updateTick(self, dt)
end

function ScenarioNode:load()
	local rootNode = createTransformGroup("ScenarioNodeRoot")

	link(getRootNode(), rootNode)
	self:setNodeId(rootNode)
end

function ScenarioNode:setNodeId(rootNode)
	if self.groupId == "unknown" then
		self.groupId = tostring(rootNode)
	end

	if getHasClassId(rootNode, ClassIds.SHAPE) then
		self.rigidBodyType = getRigidBodyType(rootNode)
	else
		self.rigidBodyType = RigidBodyType.NONE
	end

	self.simulatePhysics = self.rigidBodyType ~= RigidBodyType.NONE and self.rigidBodyType ~= RigidBodyType.STATIC

	ScenarioNode:superClass().setNodeId(self, rootNode)

	if self.visibilityIsControlled then
		self:setVisibility(false)
	end
end

function ScenarioNode:loadFromXML(xmlFile, key, baseDirectory, rootNode)
	self.groupId = xmlFile:getString(key .. "#id") or self.groupId
	self.visibilityIsControlled = xmlFile:getBool(key .. "#visibilityIsControlled", false)
	self.positionIsControlled = xmlFile:getBool(key .. "#positionIsControlled", false)
	self.positionOffset = xmlFile:getVector(key .. "#positionOffset", self.positionOffset, 3)
	self.rotationOffset = xmlFile:getVector(key .. "#rotationOffset", self.rotationOffset, 3)
	self.groundYOffset = xmlFile:getFloat(key .. "#groundYOffset", self.groundYOffset)

	return true
end

function ScenarioNode:loadAtWorldPosition(x, y, z, rx, ry, rz, limitToGround)
	self:load()
	self:setWorldPositionAndRotation(x, y, z, rx, ry, rz, limitToGround)
end

function ScenarioNode:setWorldPositionAndRotation(x, y, z, rotX, rotY, rotZ, limitToGround)
	if limitToGround then
		y = self:getTerrainLimitedYPosition(x, y, z, self.groundYOffset)
	end

	local dirX, dirY, dirZ = localDirectionToWorld(self.nodeId, 0, 0, 1)
	local upX, upY, upZ = localDirectionToWorld(self.nodeId, 0, 1, 0)
	local offsetX, offsetY, offsetZ = unpack(self.positionOffset)
	x, y, z = MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, offsetX, offsetY, offsetZ)
	offsetX, offsetY, offsetZ = unpack(self.rotationOffset)
	offsetX = math.rad(offsetX)
	offsetY = math.rad(offsetY)
	offsetZ = math.rad(offsetZ)
	local qx, qy, qz, qw = mathEulerToQuaternion(localRotationToWorld(self.nodeId, rotX + offsetX, rotY + offsetY, rotZ + offsetZ))

	self:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, true)
end

function ScenarioNode:setWorldPosition(x, y, z, limitToGround)
	local rotX, rotY, rotZ = getWorldRotation(self.nodeId)

	self:setWorldPositionAndRotation(x, y, z, rotX, rotY, rotZ, limitToGround)
end

function ScenarioNode:setWorldRotation(rotX, rotY, rotZ)
	local x, y, z = getWorldTranslation(self.nodeId)

	self:setWorldPositionAndRotation(x, y, z, rotX, rotY, rotZ, false)
end

function ScenarioNode:setVisibility(isVisible)
	setVisibility(self.nodeId, isVisible)
end

function ScenarioNode:addToPhysics()
	if self.nodeId ~= nil then
		addToPhysics(self.nodeId)
	end
end

function ScenarioNode:removeFromPhysics()
	if self.nodeId ~= nil then
		removeFromPhysics(self.nodeId)
	end
end

function ScenarioNode:getDefaultRigidBodyType()
	if self.simulatePhysics then
		if self.isServer then
			return RigidBodyType.DYNAMIC
		else
			return RigidBodyType.KINEMATIC
		end
	end

	return self.rigidBodyType
end

function ScenarioNode:start()
	if not self.isStarted then
		if self.simulatePhysics then
			if self.startWithPhysics then
				self:addToPhysics()
			else
				self:removeFromPhysics()
			end
		end

		self.isStarted = true
	end
end

function ScenarioNode:complete()
end

function ScenarioNode:getTerrainLimitedYPosition(x, y, z, offset)
	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
	self.correctedY = -1

	raycastClosest(x, y + offset, z, 0, -1, 0, "groundRaycastCallback", 5, self, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT)

	return math.max(terrainY, self.correctedY) + offset
end

function ScenarioNode:groundRaycastCallback(hitObjectId, x, y, z, distance)
	if getHasTrigger(hitObjectId) then
		return true
	end

	self.correctedY = y

	return true
end
