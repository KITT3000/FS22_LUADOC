StrawHarvestCraneTools = {
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".strawHarvestCraneTools",
	TYPE_SHOVEL = 1,
	TYPE_GRAB = 2,
	TYPE_PALLET_GRAB = 3
}
StrawHarvestCraneTools.STR_TO_TYPE = {
	shovel = StrawHarvestCraneTools.TYPE_SHOVEL,
	grab = StrawHarvestCraneTools.TYPE_GRAB,
	palletgrab = StrawHarvestCraneTools.TYPE_PALLET_GRAB
}
StrawHarvestCraneTools.SEND_NUM_BITS = 2
StrawHarvestCraneTools.SEND_MOUNTOBJECT_NUM_BITS = 5

function StrawHarvestCraneTools.prerequisitesPresent(specializations)
	return true
end

function StrawHarvestCraneTools.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("StrawHarvestCraneTools")
	schema:register(XMLValueType.FLOAT, "vehicle.craneTools#dischargeThreshold", "The crane tool discharge threshold")
	schema:register(XMLValueType.FLOAT, "vehicle.craneTools#shovelThreshold", "The crane tool shovel threshold")
	schema:register(XMLValueType.STRING, "vehicle.craneTools.craneTool(?)#type", "The crane tool type")
	schema:register(XMLValueType.INT, "vehicle.craneTools.craneTool(?)#fillUnitIndex", "The crane tool fill unit index")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.craneTools.craneTool(?)#movingToolNode", "The crane tool moving tool node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.craneTools.craneTool(?)#jointNode", "The crane tool joint node")
	schema:register(XMLValueType.FLOAT, "vehicle.craneTools.craneTool(?)#movingToolMaxAnimationTime", "The crane tool max animation time")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.craneTools.craneTool(?).mount.trigger(?)#node", "The crane tool mount trigger node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.craneTools.craneTool(?)")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local baseKey = "vehicles.vehicle(?)." .. StrawHarvestCraneTools.SPEC_NAME

	schemaSavegame:register(XMLValueType.INT, baseKey .. "#currentCraneToolIndex", "The current crane tool index")
end

function StrawHarvestCraneTools.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "preSaveToXMLFile", StrawHarvestCraneTools.preSaveToXMLFile)
	SpecializationUtil.registerFunction(vehicleType, "loadCraneToolFromXML", StrawHarvestCraneTools.loadCraneToolFromXML)
	SpecializationUtil.registerFunction(vehicleType, "toolMountTriggerCallback", StrawHarvestCraneTools.toolMountTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "canMountObject", StrawHarvestCraneTools.canMountObject)
	SpecializationUtil.registerFunction(vehicleType, "addMountedObject", StrawHarvestCraneTools.addMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeMountedObject", StrawHarvestCraneTools.removeMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", StrawHarvestCraneTools.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", StrawHarvestCraneTools.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "getCraneTool", StrawHarvestCraneTools.getCraneTool)
	SpecializationUtil.registerFunction(vehicleType, "setCraneTool", StrawHarvestCraneTools.setCraneTool)
	SpecializationUtil.registerFunction(vehicleType, "canSwitchCraneTool", StrawHarvestCraneTools.canSwitchCraneTool)
	SpecializationUtil.registerFunction(vehicleType, "getIsCraneShovelClosing", StrawHarvestCraneTools.getIsCraneShovelClosing)
end

function StrawHarvestCraneTools.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", StrawHarvestCraneTools.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", StrawHarvestCraneTools.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", StrawHarvestCraneTools.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", StrawHarvestCraneTools.updateExtraDependentParts)
end

function StrawHarvestCraneTools.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", StrawHarvestCraneTools)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", StrawHarvestCraneTools)
end

function StrawHarvestCraneTools:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_strawHarvestCraneTools

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionGrabEventId = self:addActionEvent(spec.actionEvents, InputAction.SH_TOGGLE_CRANE_TOOL, self, StrawHarvestCraneTools.actionEventToggleTool, false, true, false, true, nil)

			g_inputBinding:setActionEventText(actionGrabEventId, g_i18n:getText("action_toggleCraneTool"))
			g_inputBinding:setActionEventTextPriority(actionGrabEventId, GS_PRIO_NORMAL)
		end
	end
end

function StrawHarvestCraneTools:onLoad(savegame)
	self.spec_strawHarvestCraneTools = self[("spec_%s.strawHarvestCraneTools"):format(StrawHarvestCraneTools.MOD_NAME)]
	local spec = self.spec_strawHarvestCraneTools
	spec.currentCraneToolIndex = -1
	spec.craneTools = {}
	spec.dischargeThreshold = self.xmlFile:getValue("vehicle.craneTools#dischargeThreshold", 0)
	spec.shovelThreshold = self.xmlFile:getValue("vehicle.craneTools#shovelThreshold", 0)
	local i = 0

	while true do
		local key = ("vehicle.craneTools.craneTool(%d)"):format(i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local tool = {}

		if self:loadCraneToolFromXML(tool, self.xmlFile, key, i + 1) then
			table.insert(spec.craneTools, tool)
		end

		i = i + 1
	end

	if self.isServer then
		spec.pendingMountObjects = {}
	end

	spec.mountedObjects = {}
	spec.mountedObjectsDirtyFlag = self:getNextDirtyFlag()
	local currentCraneToolIndex = 1

	if savegame ~= nil then
		local key = savegame.key .. "." .. StrawHarvestCraneTools.SPEC_NAME
		currentCraneToolIndex = savegame.xmlFile:getValue(key .. "#currentCraneToolIndex", currentCraneToolIndex)
	end

	self:setCraneTool(currentCraneToolIndex, true)
end

function StrawHarvestCraneTools:onPostLoad(savegame)
	self:removeFromPhysics()
end

function StrawHarvestCraneTools:onDelete()
	local spec = self.spec_strawHarvestCraneTools

	for object, _ in pairs(spec.mountedObjects) do
		self:removeMountedObject(object, true)
	end

	for _, tool in ipairs(spec.craneTools) do
		if self.isServer then
			for _, trigger in ipairs(tool.mountTriggers) do
				removeTrigger(trigger.triggerId)
			end
		end
	end
end

function StrawHarvestCraneTools:onReadStream(streamId, connection)
	local index = streamReadUIntN(streamId, StrawHarvestCraneTools.SEND_NUM_BITS) + 1

	self:setCraneTool(index, true)
end

function StrawHarvestCraneTools:onWriteStream(streamId, connection)
	local spec = self.spec_strawHarvestCraneTools

	streamWriteUIntN(streamId, spec.currentCraneToolIndex - 1, StrawHarvestCraneTools.SEND_NUM_BITS)
end

function StrawHarvestCraneTools:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_strawHarvestCraneTools
		local tool = self:getCraneTool(spec.currentCraneToolIndex)
		local amount = streamReadUIntN(streamId, StrawHarvestCraneTools.SEND_MOUNTOBJECT_NUM_BITS)

		for object, _ in pairs(spec.mountedObjects) do
			self:removeMountedObject(object, false)
		end

		spec.mountedObjects = {}

		for i = 1, amount do
			local object = NetworkUtil.readNodeObject(streamId)

			if object ~= nil and self:canMountObject(object) then
				self:addMountedObject(object, tool.jointNode)
			end
		end
	end
end

function StrawHarvestCraneTools:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_strawHarvestCraneTools

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.mountedObjectsDirtyFlag) ~= 0) then
			local objects = {}

			for object, _ in pairs(spec.mountedObjects) do
				table.insert(objects, object)
			end

			streamWriteUIntN(streamId, #objects, StrawHarvestCraneTools.SEND_MOUNTOBJECT_NUM_BITS)

			for i = 1, #objects do
				local object = objects[i]

				NetworkUtil.writeNodeObject(streamId, object)
			end
		end
	end
end

function StrawHarvestCraneTools:preSaveToXMLFile()
	if self.currentSavegameId == nil then
		self.currentSavegameId = 1
	end

	local spec = self.spec_strawHarvestCraneTools

	for object, _ in pairs(spec.mountedObjects) do
		self:removeMountedObject(object, false)
	end
end

function StrawHarvestCraneTools:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_strawHarvestCraneTools

	xmlFile:setValue(key .. "#currentCraneToolIndex", spec.currentCraneToolIndex)
end

function StrawHarvestCraneTools:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if not self.isServer then
		return
	end

	local spec = self.spec_strawHarvestCraneTools
	local tool = self:getCraneTool(spec.currentCraneToolIndex)
	local removeMountedObjects = tool.type == StrawHarvestCraneTools.TYPE_SHOVEL

	if not removeMountedObjects then
		local dischargeNode = self:getCurrentDischargeNode()

		if dischargeNode ~= nil and dischargeNode.movingToolActivation ~= nil then
			local didMove, canAddMountedObjects = self:getIsCraneShovelClosing(dischargeNode, 0)

			if didMove then
				removeMountedObjects = not canAddMountedObjects

				if canAddMountedObjects then
					for object, _ in pairs(spec.pendingMountObjects) do
						if spec.mountedObjects[object] == nil then
							if self:canMountObject(object) then
								self:addMountedObject(object, tool.jointNode)
							else
								spec.pendingMountObjects[object] = nil
							end
						end
					end
				end
			end
		end
	end

	if removeMountedObjects then
		for object, _ in pairs(spec.mountedObjects) do
			self:removeMountedObject(object, true)
		end
	end
end

function StrawHarvestCraneTools:canMountObject(object)
	local objectId = object.nodeId or object.rootNode

	if objectId ~= nil then
		if object.getCanByMounted ~= nil then
			return object:getCanByMounted()
		end

		return entityExists(objectId)
	end

	return false
end

function StrawHarvestCraneTools:addMountedObject(object, jointNode)
	local spec = self.spec_strawHarvestCraneTools
	local objectId = object.nodeId or object.rootNode

	if object.dynamicMountObject ~= nil then
		object.dynamicMountObject:removeDynamicMountedObject(object, true)
	end

	if object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic() then
		if self.isServer then
			object:mountDynamic(self, self:getParentComponent(jointNode), jointNode, DynamicMountUtil.TYPE_FIX_ATTACH, 0, false)
		end
	else
		local _, y, _ = localToLocal(objectId, jointNode, 0, 0, 0)
		local rx, ry, rz = localRotationToLocal(objectId, jointNode, 0, 0, 0)

		object:mount(self, jointNode, 0, y, 0, rx, ry, rz)
	end

	spec.mountedObjects[object] = object

	g_messageCenter:publish(MessageType.STRAW_HARVEST_CRANE_MOUNT_OBJECT, object)
	self:raiseDirtyFlags(spec.mountedObjectsDirtyFlag)
end

function StrawHarvestCraneTools:removeMountedObject(object, isDeleting)
	local spec = self.spec_strawHarvestCraneTools
	spec.mountedObjects[object] = nil

	if isDeleting then
		spec.pendingMountObjects[object] = nil
	end

	if object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic() then
		if self.isServer then
			object:unmountDynamic()
		end
	else
		object:unmount()
	end

	self:raiseDirtyFlags(spec.mountedObjectsDirtyFlag)
end

function StrawHarvestCraneTools:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	local spec = self.spec_strawHarvestCraneTools

	for object, _ in pairs(spec.mountedObjects) do
		if object.dynamicMountJointIndex == jointIndex then
			self:removeMountedObject(object, true)
		end
	end
end

function StrawHarvestCraneTools:addDynamicMountedObject(object)
end

function StrawHarvestCraneTools:removeDynamicMountedObject(object, isDeleting)
	self:removeMountedObject(object, isDeleting)
end

function StrawHarvestCraneTools:onEnterVehicle()
	self:setBeaconLightsVisibility(true, true, true)
end

function StrawHarvestCraneTools:onLeaveVehicle()
	self:setBeaconLightsVisibility(false, true, true)
end

function StrawHarvestCraneTools:getCraneTool(index)
	return self.spec_strawHarvestCraneTools.craneTools[index]
end

function StrawHarvestCraneTools:setCraneTool(index, noEventSend)
	local spec = self.spec_strawHarvestCraneTools

	if spec.currentCraneToolIndex ~= index then
		StrawHarvestCraneToolsEvent.sendEvent(self, index, noEventSend)
		self:removeFromPhysics()

		local function showFillUnitOnHud(fillUnitIndex, showOnHud)
			if fillUnitIndex ~= nil then
				local fillUnit = self:getFillUnitByIndex(fillUnitIndex)
				fillUnit.showOnHud = showOnHud
			end
		end

		local lastTool = self:getCraneTool(spec.currentCraneToolIndex)

		if lastTool ~= nil then
			showFillUnitOnHud(lastTool.fillUnitIndex, false)
			ObjectChangeUtil.setObjectChanges(lastTool.objectChanges, false, self)
		end

		local tool = self:getCraneTool(index)

		showFillUnitOnHud(tool.fillUnitIndex, true)
		ObjectChangeUtil.setObjectChanges(tool.objectChanges, true, self)

		if tool.movingToolNode ~= nil then
			local movingTool = self:getMovingToolByNode(tool.movingToolNode)

			if movingTool ~= nil then
				movingTool.animMaxTime = tool.animMaxTime
			end
		end

		spec.currentCraneToolIndex = index

		self:addToPhysics()
	end
end

function StrawHarvestCraneTools:canSwitchCraneTool()
	local spec = self.spec_strawHarvestCraneTools
	local tool = self:getCraneTool(spec.currentCraneToolIndex)

	if tool.fillUnitIndex ~= nil then
		local fillLevel = self:getFillUnitFillLevel(tool.fillUnitIndex)

		if fillLevel > 0 then
			return false
		end
	end

	return true
end

function StrawHarvestCraneTools:getIsCraneShovelClosing(node, activeThreshold)
	local movingToolActivation = node.movingToolActivation
	local movingTool = self.spec_cylindered.nodesToMovingTools[movingToolActivation.node]
	local state = Cylindered.getMovingToolState(self, movingTool)
	local previousState = movingToolActivation.lastState or state
	local activeState = state

	if movingToolActivation.isInverted then
		activeState = math.abs(state - 1)
	end

	local factor = movingToolActivation.openFactor
	local didMove = math.abs(previousState - state) > 0.001
	local isClosing = state - factor > previousState - factor
	movingToolActivation.lastState = state

	return didMove, isClosing and activeThreshold <= activeState, factor < state
end

function StrawHarvestCraneTools:loadCraneToolFromXML(tool, xmlFile, key, index)
	tool.index = index
	local typeStr = xmlFile:getValue(key .. "#type", "shovel")
	tool.type = StrawHarvestCraneTools.STR_TO_TYPE[typeStr:lower()]
	tool.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex")

	if tool.fillUnitIndex ~= nil then
		local fillUnit = self:getFillUnitByIndex(tool.fillUnitIndex)
		fillUnit.showOnHud = false
	end

	tool.movingToolNode = self.xmlFile:getValue(key .. "#movingToolNode", nil, self.components, self.i3dMappings)
	tool.animMaxTime = math.min(xmlFile:getValue(key .. "#movingToolMaxAnimationTime", 1), 1)
	tool.jointNode = self.xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)

	if self.isServer then
		tool.mountTriggerToEntry = {}
		tool.mountTriggers = {}
		local i = 0

		while true do
			local triggerKey = ("%s.mount.trigger(%d)"):format(key, i)

			if not xmlFile:hasProperty(triggerKey) then
				break
			end

			local entry = {
				triggerId = self.xmlFile:getValue(triggerKey .. "#node", nil, self.components, self.i3dMappings)
			}

			if entry.triggerId ~= nil then
				addTrigger(entry.triggerId, "toolMountTriggerCallback", self)
				table.insert(tool.mountTriggers, entry)

				tool.mountTriggerToEntry[entry.triggerId] = entry
			end

			i = i + 1
		end
	end

	tool.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, tool.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(tool.objectChanges, false)

	return true
end

function StrawHarvestCraneTools:toolMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_strawHarvestCraneTools
	local tool = self:getCraneTool(spec.currentCraneToolIndex)

	if tool.mountTriggerToEntry[triggerId] ~= nil then
		if onEnter then
			local object = g_currentMission:getNodeObject(otherActorId)

			if object == nil then
				object = g_currentMission.nodeToObject[otherActorId]
			end

			if object == self:getRootVehicle() or self.spec_attachable ~= nil and self.spec_attachable.attacherVehicle == object then
				object = nil
			end

			if object ~= nil and object ~= self then
				local isObject = object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic() and object.lastMoveTime ~= nil
				local isVehicle = object.getSupportsTensionBelts ~= nil and object:getSupportsTensionBelts() and object.lastMoveTime ~= nil

				if isObject or isVehicle then
					spec.pendingMountObjects[object] = Utils.getNoNil(spec.pendingMountObjects[object], 0) + 1
				end
			end
		elseif onLeave then
			local object = g_currentMission:getNodeObject(otherActorId)

			if object == nil then
				object = g_currentMission.nodeToObject[otherActorId]
			end

			if object ~= nil and spec.pendingMountObjects[object] ~= nil then
				local count = spec.pendingMountObjects[object] - 1

				if count == 0 then
					spec.pendingMountObjects[object] = nil

					if spec.mountedObjects[object] ~= nil then
						self:removeMountedObject(object, false)
					end
				else
					spec.pendingMountObjects[object] = count
				end
			end
		end
	end
end

function StrawHarvestCraneTools:getIsDischargeNodeActive(superFunc, dischargeNode)
	local spec = self.spec_strawHarvestCraneTools
	local tool = self:getCraneTool(spec.currentCraneToolIndex)

	if tool.type ~= StrawHarvestCraneTools.TYPE_SHOVEL then
		return false
	end

	if dischargeNode.movingToolActivation ~= nil then
		local _, isClosing, isClosed = self:getIsCraneShovelClosing(dischargeNode, spec.dischargeThreshold)

		if isClosing or isClosed then
			return false
		end
	end

	return superFunc(self, dischargeNode)
end

function StrawHarvestCraneTools:getShovelNodeIsActive(superFunc, shovelNode)
	local spec = self.spec_strawHarvestCraneTools
	local tool = self:getCraneTool(spec.currentCraneToolIndex)

	if tool.type ~= StrawHarvestCraneTools.TYPE_SHOVEL then
		return false
	end

	if shovelNode.movingToolActivation ~= nil then
		local didMove, isClosing = self:getIsCraneShovelClosing(shovelNode, spec.shovelThreshold)

		if didMove and isClosing then
			return true
		end
	end

	return superFunc(self, shovelNode)
end

function StrawHarvestCraneTools:getFillLevelInformation(superFunc, display)
	superFunc(self, display)

	local spec = self.spec_strawHarvestCraneTools

	for object, _ in pairs(spec.mountedObjects) do
		if object.getFillLevelInformation ~= nil then
			object:getFillLevelInformation(display)
		elseif object.getFillLevel ~= nil and object.getFillType ~= nil then
			local fillType = object:getFillType()
			local fillLevel = object:getFillLevel()
			local capacity = fillLevel

			if object.getCapacity ~= nil then
				capacity = object:getCapacity()
			end

			display:addFillLevel(fillType, fillLevel, capacity)
		end
	end
end

function StrawHarvestCraneTools:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if self.isServer then
		local spec = self.spec_strawHarvestCraneTools
		local tool = self:getCraneTool(spec.currentCraneToolIndex)

		if tool == nil or tool.type == StrawHarvestCraneTools.TYPE_SHOVEL then
			return
		end

		for object, _ in pairs(spec.mountedObjects) do
			if object.dynamicMountJointIndex ~= nil then
				setJointFrame(object.dynamicMountJointIndex, 0, tool.jointNode)
			end
		end
	end
end

function StrawHarvestCraneTools:actionEventToggleTool(...)
	local spec = self.spec_strawHarvestCraneTools

	if self:canSwitchCraneTool() then
		local index = spec.currentCraneToolIndex + 1

		if index > #spec.craneTools then
			index = 1
		end

		self:setCraneTool(index)
	end
end
