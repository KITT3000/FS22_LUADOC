MountableObject = {
	MOUNT_TYPE_NONE = 1,
	MOUNT_TYPE_DEFAULT = 2,
	MOUNT_TYPE_KINEMATIC = 3,
	MOUNT_TYPE_DYNAMIC = 4,
	FORCE_LIMIT_UPDATE_TIME = 1000,
	FORCE_LIMIT_RAYCAST_DISTANCE = 20
}
local MountableObject_mt = Class(MountableObject, PhysicsObject)

InitStaticObjectClass(MountableObject, "MountableObject", ObjectIds.OBJECT_MOUNTABLE_OBJECT)

function MountableObject.new(isServer, isClient, customMt)
	local self = PhysicsObject.new(isServer, isClient, customMt or MountableObject_mt)
	self.dynamicMountSingleAxisFreeX = false
	self.dynamicMountSingleAxisFreeY = false
	self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE
	self.forceLimitUpdate = {
		raycastActive = false,
		timer = 0,
		lastDistance = 0,
		nextMountingDistance = 0,
		additionalMass = 0
	}
	self.lastMoveTime = -100000
	self.mountStateChangeListeners = {}

	return self
end

function MountableObject:delete()
	if self.dynamicMountTriggerId ~= nil then
		removeTrigger(self.dynamicMountTriggerId)
	end

	if self.dynamicMountJointIndex ~= nil then
		removeJointBreakReport(self.dynamicMountJointIndex)
		removeJoint(self.dynamicMountJointIndex)
	end

	if self.dynamicMountObject ~= nil then
		self.dynamicMountObject:removeDynamicMountedObject(self, true)
	end

	if self.mountObject ~= nil and self.mountObject.removeMountedObject ~= nil then
		self.mountObject:removeMountedObject(self, true)
	end

	MountableObject:superClass().delete(self)
end

function MountableObject:getAllowsAutoDelete()
	return self.mountObject == nil and MountableObject:superClass().getAllowsAutoDelete(self)
end

function MountableObject:testScope(x, y, z, coeff)
	if self.mountObject ~= nil then
		return self.mountObject:testScope(x, y, z, coeff)
	end

	if self.dynamicMountObject ~= nil then
		return self.dynamicMountObject:testScope(x, y, z, coeff)
	end

	return MountableObject:superClass().testScope(self, x, y, z, coeff)
end

function MountableObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	if self.mountObject ~= nil then
		return self.mountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	end

	if self.dynamicMountObject ~= nil then
		return self.dynamicMountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
	end

	return MountableObject:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection, isGuiVisible)
end

function MountableObject:updateTick(dt)
	if self.isServer then
		if self:updateMove() then
			self.lastMoveTime = g_currentMission.time
		end

		if self.dynamicMountObjectTriggerCount ~= nil and self.dynamicMountObjectTriggerCount <= 0 then
			if self.dynamicMountJointNodeDynamicRefNode ~= nil then
				local _, _, zOffset = localToLocal(self.dynamicMountJointNodeDynamic, self.dynamicMountJointNodeDynamicRefNode, 0, 0, 0)

				if self.dynamicMountJointNodeDynamicMountOffset < zOffset then
					self.dynamicMountJointNodeDynamicMountOffset = nil
					self.dynamicMountJointNodeDynamicRefNode = nil

					self:unmountDynamic()

					self.dynamicMountObjectTriggerCount = nil
				else
					self:raiseActive()
				end
			else
				self:unmountDynamic()

				self.dynamicMountObjectTriggerCount = nil
			end
		end

		if self.dynamicMountJointIndex ~= nil then
			self:updateDynamicMountJointForceLimit(dt)
		end
	end
end

function MountableObject:mount(object, node, x, y, z, rx, ry, rz)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		self:unmountDynamic()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end

	self:unmountDynamic(true)

	if self.mountObject == nil then
		removeFromPhysics(self.nodeId)
	end

	link(node, self.nodeId)

	local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)

	self:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)

	self.mountObject = object

	self:setDynamicMountType(MountableObject.MOUNT_TYPE_DEFAULT, object)
end

function MountableObject:unmount()
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)

	if self.mountObject ~= nil then
		self.mountObject = nil
		local x, y, z = getWorldTranslation(self.nodeId)
		local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)

		link(getRootNode(), self.nodeId)
		self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		addToPhysics(self.nodeId)

		return true
	end

	return false
end

function MountableObject:mountKinematic(object, node, x, y, z, rx, ry, rz)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		self:unmount()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		self:unmountDynamic()
	end

	self:unmountDynamic(true)
	removeFromPhysics(self.nodeId)
	link(node, self.nodeId)

	local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)

	self:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
	addToPhysics(self.nodeId)

	if self.isServer then
		setRigidBodyType(self.nodeId, RigidBodyType.KINEMATIC)
	end

	if object.components ~= nil then
		for i = 1, #object.components do
			if getRigidBodyType(object.components[i].node) == RigidBodyType.DYNAMIC then
				setPairCollision(object.components[i].node, self.nodeId, false)
			end
		end
	end

	self.mountObject = object
	self.mountJointNode = node

	self:setDynamicMountType(MountableObject.MOUNT_TYPE_KINEMATIC, object)
end

function MountableObject:unmountKinematic()
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)

	if self.mountObject ~= nil then
		local components = self.mountObject.components
		self.mountObject = nil
		self.mountJointNode = nil
		local x, y, z = getWorldTranslation(self.nodeId)
		local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)

		removeFromPhysics(self.nodeId)
		link(getRootNode(), self.nodeId)
		self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		addToPhysics(self.nodeId)

		if self.isServer then
			setRigidBodyType(self.nodeId, RigidBodyType.DYNAMIC)
		end

		if components ~= nil then
			for i = 1, #components do
				if getRigidBodyType(components[i].node) == RigidBodyType.DYNAMIC then
					setPairCollision(components[i].node, self.nodeId, true)
				end
			end
		end

		return true
	end

	return false
end

function MountableObject:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	assert(self.isServer)

	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		self:unmount()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end

	if not self:getSupportsMountDynamic() or self.mountObject ~= nil then
		return false
	end

	if object:getOwnerFarmId() ~= nil and not g_currentMission.accessHandler:canFarmAccess(object:getOwnerFarmId(), self) then
		return false
	end

	if self.dynamicMountTriggerId ~= nil then
		local x, y, z = nil

		if mountType == DynamicMountUtil.TYPE_FORK then
			local _, _, zOffset = worldToLocal(jointNode, localToWorld(self.nodeId, getCenterOfMass(self.nodeId)))
			x, y, z = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, zOffset)
		else
			x, y, z = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0)
		end

		setTranslation(self.dynamicMountJointNodeDynamic, x, y, z)
		setRotation(self.dynamicMountJointNodeDynamic, localRotationToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0))

		local _ = nil
		_, _, self.dynamicMountJointNodeDynamicMountOffset = localToLocal(self.dynamicMountJointNodeDynamic, jointNode, 0, 0, 0)
		self.dynamicMountJointNodeDynamicRefNode = jointNode
	end

	self.mountBaseForceAcceleration = forceAcceleration
	self.mountBaseMass = self:getMass()

	if DynamicMountUtil.mountDynamic(self, self.nodeId, object, objectActorId, jointNode, mountType, forceAcceleration * self.dynamicMountForceLimitScale, self.dynamicMountJointNodeDynamic) then
		self:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, object)

		return true
	end

	return false
end

function MountableObject:unmountDynamic(isDelete)
	DynamicMountUtil.unmountDynamic(self, isDelete)
	self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)

	if self.isServer then
		self.lastMoveTime = g_currentMission.time
	end
end

function MountableObject:getSupportsMountDynamic()
	return true
end

function MountableObject:getAdditionalMountingDistance()
	return 0
end

function MountableObject:updateDynamicMountJointForceLimit(dt)
	if not self.forceLimitUpdate.raycastActive then
		self.forceLimitUpdate.timer = self.forceLimitUpdate.timer - dt

		if self.forceLimitUpdate.timer <= 0 then
			self.forceLimitUpdate.raycastActive = true
			self.forceLimitUpdate.timer = MountableObject.FORCE_LIMIT_UPDATE_TIME
			self.forceLimitUpdate.lastDistance = 0
			self.forceLimitUpdate.lastObject = nil
			self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
			self.forceLimitUpdate.additionalMass = 0
			local x, y, z = getWorldTranslation(self.nodeId)

			raycastAll(x, y, z, 0, 1, 0, "additionalMountingMassRaycastCallback", MountableObject.FORCE_LIMIT_RAYCAST_DISTANCE, self, CollisionFlag.DYNAMIC_OBJECT, false, true)
		end
	end
end

function MountableObject:getAdditionalMountingMass()
	return 0
end

function MountableObject:additionalMountingMassRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self.forceLimitUpdate.raycastActive = false
	local object = g_currentMission.nodeToObject[hitObjectId]

	if object ~= self and object ~= nil and object:isa(MountableObject) and self.getAdditionalMountingDistance ~= nil and object ~= self.forceLimitUpdate.lastObject then
		local offset = distance - self.forceLimitUpdate.lastDistance

		if math.abs(offset - self.forceLimitUpdate.nextMountingDistance) < 0.25 then
			self.forceLimitUpdate.lastDistance = distance
			self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
			self.forceLimitUpdate.additionalMass = self.forceLimitUpdate.additionalMass + object:getMass()
			self.forceLimitUpdate.lastObject = object
		end
	end

	if isLast and self.dynamicMountJointIndex ~= nil then
		local massFactor = (self.forceLimitUpdate.additionalMass + self.mountBaseMass) / self.mountBaseMass
		local forceAcceleration = self.mountBaseForceAcceleration * massFactor
		local forceLimit = self.mountBaseMass * forceAcceleration

		setJointLinearDrive(self.dynamicMountJointIndex, 2, false, true, 0, 0, forceLimit, 0, 0)
	end
end

function MountableObject:setNodeId(nodeId)
	MountableObject:superClass().setNodeId(self, nodeId)

	if self.isServer then
		local triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "dynamicMountTriggerIndex"))

		if triggerId ~= nil then
			local forceAcceleration = tonumber(getUserAttribute(nodeId, "dynamicMountTriggerForceAcceleration"))
			local forceLimitScale = tonumber(getUserAttribute(nodeId, "dynamicMountForceLimitScale"))
			local axisFreeY = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeY") == true
			local axisFreeX = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeX") == true

			self:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)
		end

		if self.dynamicMountJointNodeDynamic == nil then
			self.dynamicMountJointNodeDynamic = createTransformGroup("dynamicMountJointNodeDynamic")

			link(self.nodeId, self.dynamicMountJointNodeDynamic)
		end
	end
end

function MountableObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if not self.isServer then
		if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC and self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
			MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
		end
	else
		MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	end
end

function MountableObject:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)
	if self.isServer then
		if self.dynamicMountTriggerId == nil then
			self.dynamicMountTriggerId = triggerId

			if self.dynamicMountTriggerId ~= nil then
				addTrigger(self.dynamicMountTriggerId, "dynamicMountTriggerCallback", self)
			end
		end

		self.dynamicMountTriggerForceAcceleration = forceAcceleration or 4
		self.dynamicMountForceLimitScale = forceLimitScale or 1
		self.dynamicMountSingleAxisFreeY = axisFreeY
		self.dynamicMountSingleAxisFreeX = axisFreeX
	end
end

function MountableObject:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local vehicle = g_currentMission.nodeToObject[otherActorId]

	if vehicle ~= nil and vehicle:isa(Vehicle) then
		otherActorId = vehicle.components[1].node
	end

	if onEnter then
		if self.mountObject == nil then
			local dynamicMountAttacher = nil
			local dynamicMountType = DynamicMountUtil.TYPE_FORK
			local forceLimit = 1

			if vehicle ~= nil and vehicle.spec_dynamicMountAttacher ~= nil then
				dynamicMountAttacher = vehicle.spec_dynamicMountAttacher
				dynamicMountType, forceLimit = vehicle:getDynamicMountAttacherSettingsByNode(otherShapeId)
			end

			if dynamicMountAttacher ~= nil then
				if self.dynamicMountObjectActorId == nil then
					self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, dynamicMountType, self.dynamicMountTriggerForceAcceleration * forceLimit)

					self.dynamicMountObjectTriggerCount = 1
				elseif otherActorId ~= self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount == nil then
					self:unmountDynamic()
					self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, dynamicMountType, self.dynamicMountTriggerForceAcceleration * forceLimit)

					self.dynamicMountObjectTriggerCount = 1
				elseif otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
					self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount + 1
				end
			end
		end
	elseif onLeave and otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
		self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount - 1

		if self.dynamicMountObjectTriggerCount <= 0 then
			if self.dynamicMountTriggerId == nil then
				self:unmountDynamic()

				self.dynamicMountObjectTriggerCount = nil
			else
				self:raiseActive()
			end
		end
	end
end

function MountableObject:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	if jointIndex == self.dynamicMountJointIndex then
		self:unmountDynamic()
	end

	return false
end

function MountableObject:getMeshNodes()
	return nil
end

function MountableObject:setDynamicMountType(mountState, mountObject)
	if mountState ~= self.dynamicMountType then
		self.dynamicMountType = mountState

		for _, listener in ipairs(self.mountStateChangeListeners) do
			if type(listener.callbackFunc) == "string" then
				listener.object[listener.callbackFunc](listener.object, self, mountState, mountObject)
			elseif type(listener.callbackFunc) == "function" then
				listener.callbackFunc(listener.object, self, mountState, mountObject)
			end
		end
	end
end

function MountableObject:addMountStateChangeListener(object, callbackFunc)
	if callbackFunc == nil then
		callbackFunc = "onObjectMountStateChanged"
	end

	for _, listener in ipairs(self.mountStateChangeListeners) do
		if listener.object == object and listener.callbackFunc == callbackFunc then
			return
		end
	end

	table.insert(self.mountStateChangeListeners, {
		object = object,
		callbackFunc = callbackFunc
	})
end

function MountableObject:removeMountStateChangeListener(object, callbackFunc)
	if callbackFunc == nil then
		callbackFunc = "onObjectMountStateChanged"
	end

	local indexToRemove = -1

	for i, listener in ipairs(self.mountStateChangeListeners) do
		if listener.object == object and listener.callbackFunc == callbackFunc then
			indexToRemove = i
		end
	end

	if indexToRemove > 0 then
		table.remove(self.mountStateChangeListeners, indexToRemove)
	end
end
