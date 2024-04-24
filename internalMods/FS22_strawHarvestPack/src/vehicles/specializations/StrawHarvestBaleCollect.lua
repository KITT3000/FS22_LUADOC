StrawHarvestBaleCollect = {
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".strawHarvestBaleCollect",
	COLLECT_MODE_SINGLE = 1,
	COLLECT_MODE_TWO = 2,
	COLLECT_MODE_THREE = 3
}
StrawHarvestBaleCollect.COLLECT_MODES = {
	[true] = {
		StrawHarvestBaleCollect.COLLECT_MODE_TWO,
		StrawHarvestBaleCollect.COLLECT_MODE_THREE
	},
	[false] = {
		StrawHarvestBaleCollect.COLLECT_MODE_SINGLE,
		StrawHarvestBaleCollect.COLLECT_MODE_THREE
	}
}
StrawHarvestBaleCollect.VISUALS = {
	[StrawHarvestBaleCollect.COLLECT_MODE_SINGLE] = {
		"-",
		"x",
		"-"
	},
	[StrawHarvestBaleCollect.COLLECT_MODE_TWO] = {
		"x",
		"-",
		"x"
	},
	[StrawHarvestBaleCollect.COLLECT_MODE_THREE] = {
		"x",
		"x",
		"x"
	}
}
StrawHarvestBaleCollect.RESET_SCALE = -1
StrawHarvestBaleCollect.SCALE_ANIMATION_TIME_THRESHOLD = 0.5

local function getCollectPlaceVisualText(mode)
	local visuals = StrawHarvestBaleCollect.VISUALS[mode]

	return ("(%s)"):format(table.concat(visuals, "|"))
end

function StrawHarvestBaleCollect.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(Wheels, specializations)
end

function StrawHarvestBaleCollect.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("StrawHarvestBaleCollect")
	schema:register(XMLValueType.STRING, "vehicle.baleCollect#baleCollectAxisAnimationName", "Axis animation name")
	schema:register(XMLValueType.INT, "vehicle.baleCollect#baleCollectAxisIndex", "Axis index")
	schema:register(XMLValueType.FLOAT, "vehicle.baleCollect.collectPlaces#collectDepartBaleTime", "The time to depart bales (is multiplied by 1000)")
	schema:register(XMLValueType.INT, "vehicle.baleCollect.collectPlaces#fillUnitIndex", "Fill unit index of the collect places")
	schema:register(XMLValueType.STRING, "vehicle.baleCollect.collectPlaces#unloadAnimationName", "Unload animation name")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleCollect.collector#node", "The collector node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleCollect.collector#triggerNode", "The collector trigger node")
	schema:register(XMLValueType.FLOAT, "vehicle.baleCollect.collector#nearestDistance", "The nearest distance for the collector")
	schema:register(XMLValueType.BOOL, "vehicle.baleCollect.collectPlaces.place(?)#isSide", "If the collect place located on the side")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleCollect.collectPlaces.place(?)#node", "The collect place node")
	schema:register(XMLValueType.STRING, "vehicle.baleCollect.collectPlaces.place(?)#moveAnimationName", "The collect place move animation name")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local baseKey = "vehicles.vehicle(?)." .. StrawHarvestBaleCollect.SPEC_NAME

	schemaSavegame:register(XMLValueType.INT, baseKey .. ".collectPlaces.place(?)#index", "The collect place index")
	Bale.registerSavegameXMLPaths(schemaSavegame, baseKey .. ".collectPlaces.place(?).bale")
end

function StrawHarvestBaleCollect.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCollectPlaceFromXML", StrawHarvestBaleCollect.loadCollectPlaceFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setCollectMode", StrawHarvestBaleCollect.setCollectMode)
	SpecializationUtil.registerFunction(vehicleType, "canToggleCollectMode", StrawHarvestBaleCollect.canToggleCollectMode)
	SpecializationUtil.registerFunction(vehicleType, "updateBaleCollectAttacherJoint", StrawHarvestBaleCollect.updateBaleCollectAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "collectBale", StrawHarvestBaleCollect.collectBale)
	SpecializationUtil.registerFunction(vehicleType, "departBale", StrawHarvestBaleCollect.departBale)
	SpecializationUtil.registerFunction(vehicleType, "triggerDepartBales", StrawHarvestBaleCollect.triggerDepartBales)
	SpecializationUtil.registerFunction(vehicleType, "departBales", StrawHarvestBaleCollect.departBales)
	SpecializationUtil.registerFunction(vehicleType, "canDepartBales", StrawHarvestBaleCollect.canDepartBales)
	SpecializationUtil.registerFunction(vehicleType, "setDepartBales", StrawHarvestBaleCollect.setDepartBales)
	SpecializationUtil.registerFunction(vehicleType, "getCollectPlaceByIndex", StrawHarvestBaleCollect.getCollectPlaceByIndex)
	SpecializationUtil.registerFunction(vehicleType, "getActiveCollectPlaces", StrawHarvestBaleCollect.getActiveCollectPlaces)
	SpecializationUtil.registerFunction(vehicleType, "getAvailableActiveCollectPlaceIndex", StrawHarvestBaleCollect.getAvailableActiveCollectPlaceIndex)
	SpecializationUtil.registerFunction(vehicleType, "allowsCollectingBale", StrawHarvestBaleCollect.allowsCollectingBale)
	SpecializationUtil.registerFunction(vehicleType, "baleCollectTriggerCallback", StrawHarvestBaleCollect.baleCollectTriggerCallback)
end

function StrawHarvestBaleCollect.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", StrawHarvestBaleCollect.getIsFoldAllowed)
end

function StrawHarvestBaleCollect.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", StrawHarvestBaleCollect)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", StrawHarvestBaleCollect)
end

function StrawHarvestBaleCollect:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_strawHarvestBaleCollect

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionDepartEventId = self:addActionEvent(spec.actionEvents, InputAction.SH_DEPART_BALES, self, StrawHarvestBaleCollect.actionEventDepartBales, false, true, false, true, nil)
			local _, actionToggleEventId = self:addActionEvent(spec.actionEvents, InputAction.SH_TOGGLE_COLLECT_MODE, self, StrawHarvestBaleCollect.actionEventToggleCollectMode, false, true, false, true, nil)

			g_inputBinding:setActionEventText(actionDepartEventId, g_i18n:getText("action_baleloaderUnload"))

			local text = g_i18n:getText("action_collectMode"):format(getCollectPlaceVisualText(spec.collectMode))

			g_inputBinding:setActionEventText(actionToggleEventId, text)
			g_inputBinding:setActionEventTextPriority(actionDepartEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextPriority(actionToggleEventId, GS_PRIO_NORMAL)
		end
	end
end

function StrawHarvestBaleCollect:onLoad(savegame)
	self.spec_strawHarvestBaleCollect = self[("spec_%s.strawHarvestBaleCollect"):format(StrawHarvestBaleCollect.MOD_NAME)]
	local spec = self.spec_strawHarvestBaleCollect
	spec.collectMode = StrawHarvestBaleCollect.COLLECT_MODE_THREE
	spec.baleCollectAxisAnimationName = self.xmlFile:getValue("vehicle.baleCollect#baleCollectAxisAnimationName")
	spec.baleCollectAxisIndex = self.xmlFile:getValue("vehicle.baleCollect#baleCollectAxisIndex", 1) - 1
	spec.lastRotationLimitScale = StrawHarvestBaleCollect.RESET_SCALE
	spec.departBales = false
	spec.collectDepartBaleTime = self.xmlFile:getValue("vehicle.baleCollect.collectPlaces#collectDepartBaleTime", 1) * 1000
	spec.collectDepartBaleTimer = 0
	spec.collectResetGrabberTimer = 0
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.baleCollect.collectPlaces#fillUnitIndex", 1)
	local fillUnit = self:getFillUnitByIndex(spec.fillUnitIndex)
	fillUnit.needsSaving = false
	spec.collectPlacesUnloadAnimationName = self.xmlFile:getValue("vehicle.baleCollect.collectPlaces#unloadAnimationName")
	spec.collectPlaces = {}
	spec.collectPlacesToLoad = {}
	spec.collectPlacesToMount = {}
	spec.collectPlacesByMode = {}
	local i = 0

	while true do
		local key = ("vehicle.baleCollect.collectPlaces.place(%d)"):format(i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local place = {}

		if self:loadCollectPlaceFromXML(place, self.xmlFile, key, i + 1) then
			table.insert(spec.collectPlaces, place)

			for _, mode in pairs(StrawHarvestBaleCollect.COLLECT_MODES[place.isSide]) do
				if spec.collectPlacesByMode[mode] == nil then
					spec.collectPlacesByMode[mode] = {}
				end

				table.insert(spec.collectPlacesByMode[mode], place)
			end
		end

		i = i + 1
	end

	spec.collector = {
		balesInTrigger = {},
		node = self.xmlFile:getValue("vehicle.baleCollect.collector#node", nil, self.components, self.i3dMappings),
		triggerNode = self.xmlFile:getValue("vehicle.baleCollect.collector#triggerNode", nil, self.components, self.i3dMappings),
		orgNearestDistance = self.xmlFile:getValue("vehicle.baleCollect.collector#nearestDistance", 1.5)
	}
	spec.collector.nearestDistance = spec.collector.orgNearestDistance

	if spec.collector.triggerNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing bale collect trigger node '%s'. This is required for the bale collector.", "vehicle.baleCollect.grabber#triggerNode")
	else
		addTrigger(spec.collector.triggerNode, "baleCollectTriggerCallback", self)
	end
end

function StrawHarvestBaleCollect:onPostLoad(savegame)
	local spec = self.spec_strawHarvestBaleCollect
	spec.collectPlacesToLoad = {}

	if savegame ~= nil and not savegame.resetVehicles then
		local key = savegame.key .. "." .. StrawHarvestBaleCollect.SPEC_NAME
		local i = 0

		while true do
			local placeKey = ("%s.collectPlaces.place(%d)"):format(key, i)

			if not savegame.xmlFile:hasProperty(placeKey) then
				break
			end

			local placeIndex = savegame.xmlFile:getValue(placeKey .. "#index")
			local baleKey = ("%s.bale"):format(placeKey)
			local filename = NetworkUtil.convertFromNetworkFilename(savegame.xmlFile:getValue(baleKey .. "#filename"))
			local translation = savegame.xmlFile:getValue(baleKey .. "#position", "0 0 0", true)
			local rotation = savegame.xmlFile:getValue(baleKey .. "#rotation", "0 0 0", true)
			local attributes = {}

			Bale.loadBaleAttributesFromXMLFile(attributes, savegame.xmlFile, baleKey, savegame.resetVehicles)
			table.insert(spec.collectPlacesToLoad, {
				placeIndex = placeIndex,
				filename = filename,
				translation = translation,
				rotation = rotation,
				attributes = attributes
			})

			i = i + 1
		end
	end
end

function StrawHarvestBaleCollect:onDelete()
	local spec = self.spec_strawHarvestBaleCollect

	if spec.collector ~= nil and spec.collector.triggerNode ~= nil then
		removeTrigger(spec.collector.triggerNode)
	end

	for i, place in ipairs(spec.collectPlaces) do
		if place.baleNetworkId ~= nil then
			local bale = NetworkUtil.getObject(place.baleNetworkId)

			if bale ~= nil then
				self:departBale(i)

				if self.isReconfigurating ~= nil and self.isReconfigurating then
					bale:delete()
				end
			end
		end
	end
end

function StrawHarvestBaleCollect:onReadStream(streamId, connection)
	self:setCollectMode(streamReadInt8(streamId), true)

	local spec = self.spec_strawHarvestBaleCollect
	spec.collectPlacesToMount = {}

	for _, place in ipairs(spec.collectPlaces) do
		if streamReadBool(streamId) then
			local placeIndex = place.index
			local baleObjectId = NetworkUtil.readNodeObjectId(streamId)
			spec.collectPlacesToMount[baleObjectId] = {
				placeIndex = placeIndex,
				baleNetworkId = baleObjectId
			}
		end
	end
end

function StrawHarvestBaleCollect:onWriteStream(streamId, connection)
	local spec = self.spec_strawHarvestBaleCollect

	streamWriteInt8(streamId, spec.collectMode)

	for _, place in ipairs(spec.collectPlaces) do
		if streamWriteBool(streamId, place.baleNetworkId ~= nil) then
			NetworkUtil.writeNodeObjectId(streamId, place.baleNetworkId)
		end
	end
end

function StrawHarvestBaleCollect:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_strawHarvestBaleCollect

	for i, place in ipairs(spec.collectPlaces) do
		local placeKey = ("%s.collectPlaces.place(%d)"):format(key, i - 1)

		if place.baleNetworkId ~= nil then
			local bale = NetworkUtil.getObject(place.baleNetworkId)

			if bale ~= nil then
				xmlFile:setValue(placeKey .. "#index", i)
				bale:saveToXMLFile(xmlFile, placeKey .. ".bale")
			end
		end
	end
end

function StrawHarvestBaleCollect:onUpdate(dt)
	local spec = self.spec_strawHarvestBaleCollect

	if self.finishedFirstUpdate then
		for i, v in ipairs(spec.collectPlacesToLoad) do
			local bale = Bale.new(self.isServer, self.isClient)
			local x, y, z = unpack(v.translation)
			local rx, ry, rz = unpack(v.rotation)

			if bale:loadFromConfigXML(v.filename, x, y, z, rx, ry, rz) then
				bale:applyBaleAttributes(v.attributes)
				bale:register()
				self:collectBale(v.placeIndex, NetworkUtil.getObjectId(bale), false)
			end

			spec.collectPlacesToLoad[i] = nil
		end

		for _, v in pairs(spec.collectPlacesToMount) do
			self:collectBale(v.placeIndex, v.baleNetworkId, false)
		end
	end

	if self.isClient and spec.actionEvents ~= nil then
		local actionDepartEvent = spec.actionEvents[InputAction.SH_DEPART_BALES]

		if actionDepartEvent ~= nil then
			g_inputBinding:setActionEventActive(actionDepartEvent.actionEventId, self:getFillUnitFillLevel(spec.fillUnitIndex) ~= 0)
		end
	end
end

function StrawHarvestBaleCollect:onUpdateTick(dt)
	local spec = self.spec_strawHarvestBaleCollect

	if self.isServer then
		if self:getIsInWorkPosition() then
			if self:canDepartBales() then
				self:triggerDepartBales()
				self:setDepartBales(false)
			end

			if spec.collectResetGrabberTimer ~= 0 and spec.collectResetGrabberTimer < g_currentMission.time then
				spec.collector.nearestDistance = spec.collector.orgNearestDistance
				spec.collectResetGrabberTimer = 0
			end

			if self:allowsCollectingBale() then
				local nearestBale = StrawHarvestBaleCollect.getBaleInRange(self, spec.collector.node, spec.collector.nearestDistance)

				if nearestBale ~= nil then
					local placeIndex, doDepart = self:getAvailableActiveCollectPlaceIndex()

					self:collectBale(placeIndex, NetworkUtil.getObjectId(nearestBale), doDepart)
				end
			end
		end

		if spec.collectDepartBaleTimer ~= 0 and spec.collectDepartBaleTimer < g_currentMission.time then
			self:departBales()

			spec.collectDepartBaleTimer = 0
		end

		local animationTime = self:getAnimationTime(spec.baleCollectAxisAnimationName)
		local scale = math.max(0, (animationTime - StrawHarvestBaleCollect.SCALE_ANIMATION_TIME_THRESHOLD) * 2)

		self:updateBaleCollectAttacherJoint(scale)
	end
end

function StrawHarvestBaleCollect.getBaleInRange(object, refNode, distance)
	local spec = object.spec_strawHarvestBaleCollect
	local nearestDistance = distance
	local nearestBale = nil

	for bale, _ in pairs(spec.collector.balesInTrigger) do
		if bale.mountObject == nil and g_currentMission.itemSystem.itemsToSave[bale] ~= nil and entityExists(bale.nodeId) and not bale.isAttachedToBaleHook then
			local maxDist = nil

			if bale.isRoundbale then
				maxDist = math.min(bale.diameter, bale.width)
			else
				maxDist = math.min(bale.length, bale.height, bale.width)
			end

			local _, _, z = localToLocal(bale.nodeId, refNode, 0, 0, 0)

			if math.abs(z) < maxDist and calcDistanceFrom(refNode, bale.nodeId) < nearestDistance then
				nearestDistance = distance
				nearestBale = bale
			end
		end
	end

	return nearestBale
end

function StrawHarvestBaleCollect:allowsCollectingBale()
	local spec = self.spec_strawHarvestBaleCollect

	return spec.collectDepartBaleTimer == 0 and spec.collector.nearestDistance ~= 0 and spec.collector.node ~= nil
end

function StrawHarvestBaleCollect:collectBale(index, baleObjectId, doDepart)
	local spec = self.spec_strawHarvestBaleCollect

	if index ~= nil then
		local bale = NetworkUtil.getObject(baleObjectId)

		if bale ~= nil then
			spec.collector.balesInTrigger[bale] = nil
			local place = self:getCollectPlaceByIndex(index)
			place.baleNetworkId = baleObjectId
			bale.isCollectedByBaleCollect = true
			local _, _, _, visualLength = g_baleManager:getBaleInfoByXMLFilename(bale.xmlFilename, true)

			bale:mountKinematic(self, place.node, 0, 0, 1.2 - visualLength / 2, 0, 0, 0)
			bale:setReducedComponentMass(true)
			bale:setCanBeSold(false)

			if place.moveAnimationName ~= nil then
				self:playAnimation(place.moveAnimationName, 1, nil, true)
			end

			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED)

			spec.collectPlacesToMount[baleObjectId] = nil
		else
			spec.collectPlacesToMount[baleObjectId] = {
				placeIndex = index,
				baleNetworkId = baleObjectId
			}
		end
	end

	if self.isServer then
		if doDepart then
			self:setDepartBales(true)
		end

		g_server:broadcastEvent(StrawHarvestCollectBaleEvent.new(self, index, baleObjectId), nil, nil, self)
	end
end

function StrawHarvestBaleCollect:departBale(index)
	local spec = self.spec_strawHarvestBaleCollect

	if index ~= nil then
		local place = self:getCollectPlaceByIndex(index)
		local bale = NetworkUtil.getObject(place.baleNetworkId)

		if bale ~= nil then
			spec.collector.balesInTrigger[bale] = nil
			bale.isCollectedByBaleCollect = false

			bale:unmountKinematic()
			bale:setCanBeSold(true)

			spec.collectPlacesToMount[place.baleNetworkId] = nil
			place.baleNetworkId = nil
		end

		if place.moveAnimationName ~= nil then
			self:setAnimationTime(place.moveAnimationName, 0, true)
		end
	end
end

function StrawHarvestBaleCollect:departBales()
	local spec = self.spec_strawHarvestBaleCollect

	for _, place in ipairs(spec.collectPlaces) do
		self:departBale(place.index)
	end

	self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -self:getFillUnitCapacity(spec.fillUnitIndex), self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED)

	if self.isServer then
		g_server:broadcastEvent(StrawHarvestDepartBalesEvent.new(self, false, true), nil, nil, self)
	end
end

function StrawHarvestBaleCollect:triggerDepartBales()
	local spec = self.spec_strawHarvestBaleCollect

	self:playAnimation(spec.collectPlacesUnloadAnimationName, 1, nil, false)

	spec.collectDepartBaleTimer = g_currentMission.time + spec.collectDepartBaleTime
	spec.collectResetGrabberTimer = g_currentMission.time + spec.collectDepartBaleTime * 2
	spec.collector.nearestDistance = 0
end

function StrawHarvestBaleCollect:setDepartBales(depart, doForceDepart, noEventSend)
	if doForceDepart == nil then
		doForceDepart = false
	end

	local spec = self.spec_strawHarvestBaleCollect

	if spec.departBales ~= depart or doForceDepart then
		StrawHarvestDepartBalesEvent.sendEvent(self, depart, doForceDepart, noEventSend)

		spec.departBales = depart
	end
end

function StrawHarvestBaleCollect:canDepartBales()
	for _, place in pairs(self:getActiveCollectPlaces()) do
		if place.moveAnimationName ~= nil and self:getIsAnimationPlaying(place.moveAnimationName) then
			return false
		end
	end

	return self.spec_strawHarvestBaleCollect.departBales
end

function StrawHarvestBaleCollect:getAvailableActiveCollectPlaceIndex()
	local places = self:getActiveCollectPlaces()

	for index, place in pairs(self:getActiveCollectPlaces()) do
		if place.baleNetworkId == nil then
			return place.index, index == #places
		end
	end

	return nil, false
end

function StrawHarvestBaleCollect:getCollectPlaceByIndex(index)
	return self.spec_strawHarvestBaleCollect.collectPlaces[index]
end

function StrawHarvestBaleCollect:getActiveCollectPlaces()
	local spec = self.spec_strawHarvestBaleCollect
	local places = spec.collectPlacesByMode[spec.collectMode]

	return places or {}
end

function StrawHarvestBaleCollect:baleCollectTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 and getRigidBodyType(otherId) == RigidBodyType.DYNAMIC then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil and object:isa(Bale) then
			local spec = self.spec_strawHarvestBaleCollect

			if onEnter then
				spec.collector.balesInTrigger[object] = Utils.getNoNil(spec.collector.balesInTrigger[object], 0) + 1
			elseif onLeave and spec.collector.balesInTrigger[object] ~= nil then
				spec.collector.balesInTrigger[object] = math.max(0, spec.collector.balesInTrigger[object] - 1)

				if spec.collector.balesInTrigger[object] == 0 then
					spec.collector.balesInTrigger[object] = nil
				end
			end
		end
	end
end

function StrawHarvestBaleCollect:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_strawHarvestBaleCollect

	if attacherVehicle.isBaleCollectActive ~= nil and attacherVehicle:isBaleCollectActive() then
		local jointDesc = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
		spec.attacherJoint = jointDesc
	else
		if self:getFillUnitFillLevel(spec.fillUnitIndex) ~= 0 then
			self:triggerDepartBales()
			self:setDepartBales(false)
		end

		if self:getIsInWorkPosition() then
			self:setFoldDirection(1, true)
		end
	end
end

function StrawHarvestBaleCollect:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_strawHarvestBaleCollect
	spec.lastRotationLimitScale = StrawHarvestBaleCollect.RESET_SCALE
end

function StrawHarvestBaleCollect:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_strawHarvestBaleCollect
	spec.attacherJoint = nil

	if attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
		attacherVehicle:setIsTurnedOn(false)
	end
end

function StrawHarvestBaleCollect:updateBaleCollectAttacherJoint(scale)
	if self.isServer then
		local spec = self.spec_strawHarvestBaleCollect
		local jointDesc = spec.attacherJoint

		if jointDesc ~= nil and scale ~= spec.lastRotationLimitScale then
			local axisIndex = spec.baleCollectAxisIndex

			setJointRotationLimit(jointDesc.jointIndex, axisIndex, true, -jointDesc.lowerRotLimit[axisIndex + 1] * scale, jointDesc.lowerRotLimit[axisIndex + 1] * scale)

			spec.lastRotationLimitScale = scale
		end
	end
end

function StrawHarvestBaleCollect:setCollectMode(mode, noEventSend)
	local spec = self.spec_strawHarvestBaleCollect

	if mode ~= spec.collectMode then
		StrawHarvestCollectModeEvent.sendEvent(self, mode, noEventSend)

		local actionEvent = spec.actionEvents[InputAction.SH_TOGGLE_COLLECT_MODE]
		local text = g_i18n:getText("action_collectMode"):format(getCollectPlaceVisualText(mode))

		if actionEvent ~= nil then
			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end

		spec.collectMode = mode
		local index = self:getAvailableActiveCollectPlaceIndex()

		if index == nil then
			self:setDepartBales(true)
		end
	end
end

function StrawHarvestBaleCollect:canToggleCollectMode()
	for _, place in pairs(self:getActiveCollectPlaces()) do
		if place.moveAnimationName ~= nil and self:getIsAnimationPlaying(place.moveAnimationName) then
			return false
		end
	end

	local spec = self.spec_strawHarvestBaleCollect

	return not self:getIsAnimationPlaying(spec.collectPlacesUnloadAnimationName)
end

function StrawHarvestBaleCollect:loadCollectPlaceFromXML(place, xmlFile, key, index)
	place.index = index
	place.isSide = xmlFile:getValue(key .. "#isSide", false)
	place.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	place.moveAnimationName = xmlFile:getValue(key .. "#moveAnimationName")
	place.baleNetworkId = nil

	return true
end

function StrawHarvestBaleCollect:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_strawHarvestBaleCollect

	if spec.attacherJoint == nil then
		return false
	end

	if self:getFillUnitFillLevel(spec.fillUnitIndex) ~= 0 then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil and attacherVehicle.getIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function StrawHarvestBaleCollect:actionEventDepartBales(...)
	local spec = self.spec_strawHarvestBaleCollect

	if self:getFillUnitFillLevel(spec.fillUnitIndex) ~= 0 then
		self:setDepartBales(true, true)
	end
end

function StrawHarvestBaleCollect:actionEventToggleCollectMode(...)
	if self:canToggleCollectMode() then
		local spec = self.spec_strawHarvestBaleCollect
		local mode = spec.collectMode + 1

		if StrawHarvestBaleCollect.COLLECT_MODE_THREE < mode then
			mode = StrawHarvestBaleCollect.COLLECT_MODE_SINGLE
		end

		self:setCollectMode(mode)
	end
end
