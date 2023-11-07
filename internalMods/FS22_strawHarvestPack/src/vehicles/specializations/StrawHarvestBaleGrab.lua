StrawHarvestBaleGrab = {
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".strawHarvestBaleGrab",
	SEND_OBJECT_NUM_BITS = 3,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("StrawHarvestBaleGrab")
		schema:register(XMLValueType.BOOL, "vehicle.baleGrab#skipFoldCheck", "Skip fold check")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab.units.unit(?)#baleTriggerNode", "Trigger node")
		schema:register(XMLValueType.STRING, "vehicle.baleGrab.units.unit(?)#animationName", "Animation name")
		schema:register(XMLValueType.FLOAT, "vehicle.baleGrab.units.unit(?)#animationSpeed", "Animation speed")
		schema:register(XMLValueType.BOOL, "vehicle.baleGrab.units.unit(?)#isZAxisGrabUnit", "Is Z axis grab")
		schema:register(XMLValueType.BOOL, "vehicle.baleGrab.units.unit(?)#onlyCloseIfTriggered", "Only close grab is triggered")
		schema:register(XMLValueType.STRING, "vehicle.baleGrab.units.unit(?)#noBaleAttachedAnimationName", "No bale attached animation name")
		schema:setXMLSpecializationType()
	end
}

function StrawHarvestBaleGrab.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadGrabUnitFromXML", StrawHarvestBaleGrab.loadGrabUnitFromXML)
	SpecializationUtil.registerFunction(vehicleType, "canOperateGrab", StrawHarvestBaleGrab.canOperateGrab)
	SpecializationUtil.registerFunction(vehicleType, "hasClosedGrabUnit", StrawHarvestBaleGrab.hasClosedGrabUnit)
	SpecializationUtil.registerFunction(vehicleType, "operateGrab", StrawHarvestBaleGrab.operateGrab)
	SpecializationUtil.registerFunction(vehicleType, "grabBales", StrawHarvestBaleGrab.grabBales)
	SpecializationUtil.registerFunction(vehicleType, "createBaleGrabJoint", StrawHarvestBaleGrab.createBaleGrabJoint)
	SpecializationUtil.registerFunction(vehicleType, "dropBales", StrawHarvestBaleGrab.dropBales)
	SpecializationUtil.registerFunction(vehicleType, "setIsGrabUnitClosed", StrawHarvestBaleGrab.setIsGrabUnitClosed)
	SpecializationUtil.registerFunction(vehicleType, "baleInTriggerCallback", StrawHarvestBaleGrab.baleInTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "hasAttachedBales", StrawHarvestBaleGrab.hasAttachedBales)
end

function StrawHarvestBaleGrab.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", StrawHarvestBaleGrab.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", StrawHarvestBaleGrab.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", StrawHarvestBaleGrab.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", StrawHarvestBaleGrab.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", StrawHarvestBaleGrab.getAllowDynamicMountFillLevelInfo)
end

function StrawHarvestBaleGrab.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", StrawHarvestBaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", StrawHarvestBaleGrab)
end

function StrawHarvestBaleGrab:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_strawHarvestBaleGrab

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionGrabEventId = self:addActionEvent(spec.actionEvents, InputAction.SH_GRAB_BALES, self, StrawHarvestBaleGrab.actionEventToggleGrab, false, true, false, true, nil)
			local _, actionDropEventId = self:addActionEvent(spec.actionEvents, InputAction.SH_DROP_BALES, self, StrawHarvestBaleGrab.actionEventToggleDrop, false, true, false, true, nil)

			g_inputBinding:setActionEventText(actionGrabEventId, g_i18n:getText("action_grabBales"))
			g_inputBinding:setActionEventText(actionDropEventId, g_i18n:getText("action_dropBales"))
			g_inputBinding:setActionEventTextPriority(actionGrabEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextPriority(actionDropEventId, GS_PRIO_NORMAL)
		end
	end
end

function StrawHarvestBaleGrab:onLoad(savegame)
	self.spec_strawHarvestBaleGrab = self[("spec_%s.strawHarvestBaleGrab"):format(StrawHarvestBaleGrab.MOD_NAME)]
	local spec = self.spec_strawHarvestBaleGrab
	spec.grabUnits = {}
	spec.baleJoints = {}
	spec.attachedBales = {}
	spec.triggerIdToGrabUnitIndex = {}
	spec.numAttachedBales = 0
	spec.numAttachedBalesSent = 0
	spec.skipFoldCheck = self.xmlFile:getValue("vehicle.baleGrab#skipFoldCheck", false)
	local i = 0

	while true do
		local key = ("vehicle.baleGrab.units.unit(%d)"):format(i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local unit = {}

		if self:loadGrabUnitFromXML(unit, self.xmlFile, key) then
			table.insert(spec.grabUnits, unit)

			spec.triggerIdToGrabUnitIndex[unit.baleTriggerId] = #spec.grabUnits
		end

		i = i + 1
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function StrawHarvestBaleGrab:onDelete()
	local spec = self.spec_strawHarvestBaleGrab

	for _, unit in ipairs(spec.grabUnits) do
		removeTrigger(unit.baleTriggerId)
	end

	self:dropBales()
end

function StrawHarvestBaleGrab:onReadStream(streamId, connection)
	local spec = self.spec_strawHarvestBaleGrab

	for _, unit in ipairs(spec.grabUnits) do
		self:setIsGrabUnitClosed(unit, streamReadBool(streamId))
	end
end

function StrawHarvestBaleGrab:onWriteStream(streamId, connection)
	local spec = self.spec_strawHarvestBaleGrab

	for _, unit in ipairs(spec.grabUnits) do
		streamWriteBool(streamId, unit.isClosed)
	end
end

function StrawHarvestBaleGrab:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_strawHarvestBaleGrab
		spec.numAttachedBales = streamReadInt8(streamId)

		for _, unit in ipairs(spec.grabUnits) do
			self:setIsGrabUnitClosed(unit, streamReadBool(streamId))
		end

		spec.attachedBales = {}
		local amount = streamReadUIntN(streamId, StrawHarvestBaleGrab.SEND_OBJECT_NUM_BITS)

		for i = 1, amount do
			local baleNetworkId = NetworkUtil.readNodeObjectId(streamId)

			table.insert(spec.attachedBales, baleNetworkId)
		end
	end
end

function StrawHarvestBaleGrab:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_strawHarvestBaleGrab

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteInt8(streamId, spec.numAttachedBales)

			for _, unit in ipairs(spec.grabUnits) do
				streamWriteBool(streamId, unit.isClosed)
			end

			streamWriteUIntN(streamId, #spec.attachedBales, StrawHarvestBaleGrab.SEND_OBJECT_NUM_BITS)

			for _, baleNetworkId in ipairs(spec.attachedBales) do
				NetworkUtil.writeNodeObjectId(streamId, baleNetworkId)
			end
		end
	end
end

function StrawHarvestBaleGrab:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_strawHarvestBaleGrab

	if self.isClient and spec.actionEvents ~= nil then
		local actionGrabEvent = spec.actionEvents[InputAction.SH_GRAB_BALES]

		if actionGrabEvent ~= nil then
			g_inputBinding:setActionEventActive(actionGrabEvent.actionEventId, self:canOperateGrab())
		end

		local actionDropEvent = spec.actionEvents[InputAction.SH_DROP_BALES]

		if actionDropEvent ~= nil then
			g_inputBinding:setActionEventActive(actionDropEvent.actionEventId, self:hasClosedGrabUnit())
		end
	end
end

function StrawHarvestBaleGrab:canOperateGrab()
	if not self.spec_strawHarvestBaleGrab.skipFoldCheck and self.getIsInWorkPosition ~= nil then
		return self:getIsInWorkPosition()
	end

	return true
end

function StrawHarvestBaleGrab:hasClosedGrabUnit()
	local spec = self.spec_strawHarvestBaleGrab

	for _, unit in ipairs(spec.grabUnits) do
		if unit.isClosed then
			return true
		end
	end

	return false
end

function StrawHarvestBaleGrab:operateGrab(doGrab, noEventSend)
	if not noEventSend then
		g_client:getServerConnection():sendEvent(StrawHarvestBaleGrabEvent.new(self, doGrab))
	end

	if not self.isServer then
		return
	end

	if doGrab then
		self:grabBales()
	else
		self:dropBales()
	end

	local spec = self.spec_strawHarvestBaleGrab

	if spec.numAttachedBales ~= spec.numAttachedBalesSent then
		spec.numAttachedBalesSent = spec.numAttachedBales

		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function StrawHarvestBaleGrab:createBaleGrabJoint(baleNodeId, jointTransform)
	local componentNode = self.components[1].node
	local constr = JointConstructor.new()

	constr:setActors(componentNode, baleNodeId)
	constr:setJointTransforms(jointTransform, jointTransform)

	for i = 0, 2 do
		constr:setRotationLimit(i, 0, 0)
		constr:setTranslationLimit(i, true, 0, 0)
	end

	local springForce = 7500
	local springDamping = 1500

	constr:setRotationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)
	constr:setTranslationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)

	return constr:finalize()
end

function StrawHarvestBaleGrab:grabBales()
	local spec = self.spec_strawHarvestBaleGrab

	for _, unit in ipairs(spec.grabUnits) do
		if not unit.isClosed and #unit.balesInTrigger > 0 then
			self:setIsGrabUnitClosed(unit, true)

			for _, baleNetworkId in ipairs(unit.balesInTrigger) do
				local bale = NetworkUtil.getObject(baleNetworkId)

				if bale ~= nil then
					local maxDist = nil

					if bale.isRoundbale then
						maxDist = math.min(bale.diameter, bale.width)
					else
						maxDist = math.min(bale.length, bale.height, bale.width)
					end

					local _, y, z = localToLocal(bale.nodeId, unit.baleTriggerId, 0, 0, 0)
					local outOfRange = unit.isZAxisGrabUnit and maxDist < math.abs(z) or maxDist < math.abs(y)

					if bale.isAttachedToBaleHook or bale.isCollectedByBaleCollect or g_currentMission.itemSystem.itemsToSave[bale] == nil or calcDistanceFrom(unit.baleTriggerId, bale.nodeId) > maxDist * 3 and outOfRange then
						table.removeElement(unit.balesInTrigger, baleNetworkId)
					else
						local jointIndex = self:createBaleGrabJoint(bale.nodeId, unit.baleTriggerId)

						table.insert(spec.baleJoints, jointIndex)
						table.insert(spec.attachedBales, baleNetworkId)

						bale.isAttachedToBaleHook = true
					end
				end
			end
		end
	end

	spec.numAttachedBales = #spec.attachedBales
end

function StrawHarvestBaleGrab:dropBales()
	local spec = self.spec_strawHarvestBaleGrab

	for _, joint in ipairs(spec.baleJoints) do
		removeJoint(joint)
	end

	for _, unit in ipairs(spec.grabUnits) do
		if unit.isClosed then
			self:setIsGrabUnitClosed(unit, false)

			for _, baleNetworkId in ipairs(unit.balesInTrigger) do
				local bale = NetworkUtil.getObject(baleNetworkId)

				if bale ~= nil and not entityExists(bale.nodeId) then
					table.removeElement(unit.balesInTrigger, baleNetworkId)
				end
			end
		end
	end

	for _, baleNetworkId in ipairs(spec.attachedBales) do
		local bale = NetworkUtil.getObject(baleNetworkId)

		if bale ~= nil then
			bale.isAttachedToBaleHook = false
		end
	end

	spec.baleJoints = {}
	spec.attachedBales = {}
	spec.numAttachedBales = 0
end

function StrawHarvestBaleGrab:setIsGrabUnitClosed(unit, isClosed)
	unit.isClosed = isClosed
	local animationSpeed = unit.animationSpeed

	if not unit.isClosed then
		animationSpeed = -unit.animationSpeed
	end

	self:playAnimation(unit.animationName, animationSpeed, nil, true)
end

function StrawHarvestBaleGrab:hasAttachedBales()
	return self.spec_strawHarvestBaleGrab.numAttachedBales > 0
end

function StrawHarvestBaleGrab:baleInTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local object = g_currentMission:getNodeObject(otherId)

	if object ~= nil and object:isa(Bale) then
		local spec = self.spec_strawHarvestBaleGrab
		local unitIndex = spec.triggerIdToGrabUnitIndex[triggerId]
		local unit = spec.grabUnits[unitIndex]
		local networkId = NetworkUtil.getObjectId(object)

		if onEnter then
			table.addElement(unit.balesInTrigger, networkId)
		elseif onLeave then
			table.removeElement(unit.balesInTrigger, networkId)
		end
	end
end

function StrawHarvestBaleGrab:loadGrabUnitFromXML(unit, xmlFile, key)
	unit.animationName = xmlFile:getValue(key .. "#animationName")
	unit.animationSpeed = xmlFile:getValue(key .. "#animationSpeed", 6)
	unit.baleTriggerId = xmlFile:getValue(key .. "#baleTriggerNode", nil, self.components, self.i3dMappings)

	if self.isServer then
		addTrigger(unit.baleTriggerId, "baleInTriggerCallback", self)
	end

	unit.isZAxisGrabUnit = xmlFile:getValue(key .. "#isZAxisGrabUnit", false)
	unit.onlyCloseIfTriggered = xmlFile:getValue(key .. "#onlyCloseIfTriggered", true)
	unit.noBaleAttachedAnimationName = xmlFile:getValue(key .. "#noBaleAttachedAnimationName")
	unit.balesInTrigger = {}
	unit.numBaleEnters = 0
	unit.isClosed = false

	return true
end

function StrawHarvestBaleGrab:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_strawHarvestBaleGrab

	for triggerId, _ in pairs(spec.triggerIdToGrabUnitIndex) do
		list[triggerId] = self
	end
end

function StrawHarvestBaleGrab:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_strawHarvestBaleGrab

	for triggerId, _ in pairs(spec.triggerIdToGrabUnitIndex) do
		list[triggerId] = nil
	end
end

function StrawHarvestBaleGrab:getAllowDynamicMountFillLevelInfo(superFunc)
	return not self:hasClosedGrabUnit()
end

function StrawHarvestBaleGrab:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self:hasAttachedBales() then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function StrawHarvestBaleGrab:getFillLevelInformation(superFunc, display)
	superFunc(self, display)

	local spec = self.spec_strawHarvestBaleGrab

	for _, baleNetworkId in ipairs(spec.attachedBales) do
		local bale = NetworkUtil.getObject(baleNetworkId)

		if bale ~= nil then
			local fillType = bale:getFillType()
			local fillLevel = bale:getFillLevel()
			local capacity = fillLevel

			if bale.getCapacity ~= nil then
				capacity = bale:getCapacity()
			end

			display:addFillLevel(fillType, fillLevel, capacity)
		end
	end
end

function StrawHarvestBaleGrab:actionEventToggleGrab(...)
	if self:canOperateGrab() then
		self:operateGrab(true)
	end
end

function StrawHarvestBaleGrab:actionEventToggleDrop(...)
	if self:canOperateGrab() then
		self:operateGrab(false)
	end
end
