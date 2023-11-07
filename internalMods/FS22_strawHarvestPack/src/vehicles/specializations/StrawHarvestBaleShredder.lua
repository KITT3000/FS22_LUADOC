StrawHarvestBaleShredder = {
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".strawHarvestBaleShredder",
	SEND_OBJECT_NUM_BITS = 5,
	WARNING_FILLTYPE_BALE_NOT_SUPPORTED = 1,
	WARNING_ROUND_BALE_NOT_SUPPORTED = 2,
	DAMAGED_SPEEDLIMIT_REDUCTION = 0.8,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
}

function StrawHarvestBaleShredder.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("StrawHarvestBaleShredder")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.baleShredder.objectChanges")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.baleShredder.supportObjectChanges")
	schema:register(XMLValueType.STRING, "vehicle.baleShredder.supportObjectChanges#animationName", "Support changes animation name")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleShredder.detection#detectionRootNode", "The detection node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleShredder.detection#detectionTriggerNode", "The detection trigger node")
	schema:register(XMLValueType.BOOL, "vehicle.baleShredder.baleAnimation#allowRoundBales", "Allow round bales to shred")
	schema:register(XMLValueType.FLOAT, "vehicle.baleShredder.baleAnimation#feedThreshold", "Feed treshold")
	schema:register(XMLValueType.FLOAT, "vehicle.baleShredder.baleAnimation#movementSpeed", "Movement speed")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleShredder.baleAnimation#scaleNode", "The bale animation scale node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleShredder.baleAnimation#baleNode", "The bale animation bale node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleShredder.twineAnimation#detectionRootNode", "The detection node for the twine animation")
	schema:register(XMLValueType.FLOAT, "vehicle.baleShredder.twineAnimation#startThreshold", "The start threshold for the twine animation")
	schema:register(XMLValueType.STRING, "vehicle.baleShredder.twineAnimation#animationName", "The animation name for the twine animation")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleShredder.knifeAnimation#detectionRootNode", "The detection node for the knife animation")
	schema:register(XMLValueType.FLOAT, "vehicle.baleShredder.knifeAnimation#startThreshold", "The start threshold for the knife animation")
	schema:register(XMLValueType.STRING, "vehicle.baleShredder.knifeAnimation#animationName", "The animation name for the knife animation")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baleShredder.twineAnimation.animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baleShredder.knifeAnimation.animationNodes")
	EffectManager.registerEffectXMLPaths(schema, "vehicle.baleShredder.effect")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local baseKey = "vehicles.vehicle(?)." .. StrawHarvestBaleShredder.SPEC_NAME

	schemaSavegame:register(XMLValueType.STRING, baseKey .. "#fillType", "Bale fill type")
	schemaSavegame:register(XMLValueType.STRING, baseKey .. "#filename", "Bale filename")
	schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#fillLevel", "Bale fill level")
	schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#capacity", "Bale capacity")
	schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#currentBaleYOffset", "Bale y offset")
	schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#currentBaleZOffset", "Bale z offset")
	schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#scale", "Bale scale")
end

function StrawHarvestBaleShredder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "detectionTriggerCallback", StrawHarvestBaleShredder.detectionTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "addBale", StrawHarvestBaleShredder.addBale)
	SpecializationUtil.registerFunction(vehicleType, "removeBale", StrawHarvestBaleShredder.removeBale)
	SpecializationUtil.registerFunction(vehicleType, "isBaleAllowed", StrawHarvestBaleShredder.isBaleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", StrawHarvestBaleShredder.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", StrawHarvestBaleShredder.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "hasDummyBale", StrawHarvestBaleShredder.hasDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "createDummyBaleFromBale", StrawHarvestBaleShredder.createDummyBaleFromBale)
	SpecializationUtil.registerFunction(vehicleType, "deleteDummyBale", StrawHarvestBaleShredder.deleteDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "processBale", StrawHarvestBaleShredder.processBale)
end

function StrawHarvestBaleShredder.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", StrawHarvestBaleShredder.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadObjectChangeValuesFromXML", StrawHarvestBaleShredder.loadObjectChangeValuesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setObjectChangeValues", StrawHarvestBaleShredder.setObjectChangeValues)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", StrawHarvestBaleShredder.getFillLevelInformation)
end

function StrawHarvestBaleShredder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onStartAnimation", StrawHarvestBaleShredder)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", StrawHarvestBaleShredder)
end

function StrawHarvestBaleShredder:onLoad(savegame)
	self.spec_strawHarvestBaleShredder = self[("spec_%s.strawHarvestBaleShredder"):format(StrawHarvestBaleShredder.MOD_NAME)]
	local spec = self.spec_strawHarvestBaleShredder
	spec.objectChanges = {}
	spec.supportObjectChanges = {}
	spec.supportObjectChangesAnimationName = self.xmlFile:getValue("vehicle.baleShredder.supportObjectChanges#animationName", "moveOnPallet")

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.baleShredder.objectChanges", spec.objectChanges, self.components, self)
	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.baleShredder.supportObjectChanges", spec.supportObjectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(spec.objectChanges, false)
	ObjectChangeUtil.setObjectChanges(spec.supportObjectChanges, false)

	spec.dynamicMountedObjects = {}
	spec.activeBaleToTarget = {}
	spec.activeBales = {}

	if self.isServer then
		spec.detectionRootNode = self.xmlFile:getValue("vehicle.baleShredder.detection#detectionRootNode", nil, self.components, self.i3dMappings)
		local node = createTransformGroup("detectionRootNodeReverse")

		link(spec.detectionRootNode, node)
		setTranslation(node, 0, 0, 0)
		setRotation(node, 0, 0, math.rad(180))

		spec.detectionRootNodeReverse = node
	end

	spec.detectionTriggerNode = self.xmlFile:getValue("vehicle.baleShredder.detection#detectionTriggerNode", nil, self.components, self.i3dMappings)

	if spec.detectionTriggerNode ~= nil then
		addTrigger(spec.detectionTriggerNode, "detectionTriggerCallback", self)
	end

	spec.allowRoundBales = self.xmlFile:getValue("vehicle.baleShredder.baleAnimation#allowRoundBales", false)
	spec.feedThreshold = self.xmlFile:getValue("vehicle.baleShredder.baleAnimation#feedThreshold", 0.1)
	spec.baleMovementSpeed = self.xmlFile:getValue("vehicle.baleShredder.baleAnimation#movementSpeed", 0.05)
	spec.twineAnimation = {
		node = self.xmlFile:getValue("vehicle.baleShredder.twineAnimation#detectionRootNode", nil, self.components, self.i3dMappings),
		startThreshold = self.xmlFile:getValue("vehicle.baleShredder.twineAnimation#startThreshold", 0.1),
		name = self.xmlFile:getValue("vehicle.baleShredder.twineAnimation#animationName", "removeTwine")
	}
	spec.knifeAnimation = {
		node = self.xmlFile:getValue("vehicle.baleShredder.knifeAnimation#detectionRootNode", nil, self.components, self.i3dMappings),
		startThreshold = self.xmlFile:getValue("vehicle.baleShredder.knifeAnimation#startThreshold", 0.1),
		name = self.xmlFile:getValue("vehicle.baleShredder.knifeAnimation#animationName", "removeTwine")
	}

	if self.isClient then
		spec.twineAnimation.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baleShredder.twineAnimation.animationNodes", self.components, self, self.i3dMappings)
		spec.knifeAnimation.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baleShredder.knifeAnimation.animationNodes", self.components, self, self.i3dMappings)
	end

	spec.dummyBaleToCreate = nil
	spec.dummyBale = {
		scaleNode = self.xmlFile:getValue("vehicle.baleShredder.baleAnimation#scaleNode", nil, self.components, self.i3dMappings),
		baleNode = self.xmlFile:getValue("vehicle.baleShredder.baleAnimation#baleNode", nil, self.components, self.i3dMappings),
		currentBaleFillType = FillType.UNKNOWN,
		currentBale = nil,
		scale = 1,
		scaleSent = 1,
		networkTimeInterpolator = InterpolationTime.new(1.2),
		networkScaleInterpolator = InterpolatorValue.new(0)
	}

	spec.dummyBale.networkScaleInterpolator:setMinMax(0, 1)

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.baleShredder.effect", self.components, self, self.i3dMappings)
	end

	spec.currentWarning = 0
	spec.warnings = {
		[StrawHarvestBaleShredder.WARNING_FILLTYPE_BALE_NOT_SUPPORTED] = g_i18n:getText("warning_baleFillTypeNotSupported"),
		[StrawHarvestBaleShredder.WARNING_ROUND_BALE_NOT_SUPPORTED] = g_i18n:getText("warning_roundBalesNotSupported")
	}
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.dynamicMountedObjectsDirtyFlag = self:getNextDirtyFlag()
end

function StrawHarvestBaleShredder:onPostLoad(savegame)
	local spec = self.spec_strawHarvestBaleShredder

	if savegame ~= nil and not savegame.resetVehicles then
		local key = savegame.key .. "." .. StrawHarvestBaleShredder.SPEC_NAME
		local filename = savegame.xmlFile:getValue(key .. "#filename")

		if filename ~= nil then
			filename = NetworkUtil.convertFromNetworkFilename(filename)
			local fillTypeStr = savegame.xmlFile:getValue(key .. "#fillType")
			local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
			local fillLevel = savegame.xmlFile:getValue(key .. "#fillLevel")
			local capacity = savegame.xmlFile:getValue(key .. "#capacity")
			local currentBaleYOffset = savegame.xmlFile:getValue(key .. "#currentBaleYOffset")
			local currentBaleZOffset = savegame.xmlFile:getValue(key .. "#currentBaleZOffset")
			local scale = savegame.xmlFile:getValue(key .. "#scale")

			self:createDummyBaleFromBale(filename, currentBaleYOffset, currentBaleZOffset, fillType.index, fillLevel, capacity)

			spec.dummyBale.scale = Utils.getNoNil(scale, spec.dummyBale.scale)

			setScale(spec.dummyBale.scaleNode, 1, 1, scale)
		end
	end
end

function StrawHarvestBaleShredder:onDelete()
	local spec = self.spec_strawHarvestBaleShredder

	if self.isClient then
		g_effectManager:deleteEffects(spec.effects)
		g_animationManager:deleteAnimations(spec.twineAnimation.animationNodes)
		g_animationManager:deleteAnimations(spec.knifeAnimation.animationNodes)
	end

	self:deleteDummyBale()

	if self.isServer and spec.detectionTriggerNode ~= nil then
		removeTrigger(spec.detectionTriggerNode)
	end
end

function StrawHarvestBaleShredder:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_strawHarvestBaleShredder
		local scale = streamReadFloat32(streamId)

		spec.dummyBale.networkScaleInterpolator:setValue(scale)
		spec.dummyBale.networkTimeInterpolator:reset()

		if streamReadBool(streamId) then
			local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
			local yOffset = streamReadFloat32(streamId)
			local zOffset = streamReadFloat32(streamId)
			local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			spec.dummyBaleToCreate = {
				i3dFilename,
				yOffset,
				zOffset,
				fillType,
				scale
			}
		end
	end
end

function StrawHarvestBaleShredder:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_strawHarvestBaleShredder

		streamWriteFloat32(streamId, spec.dummyBale.scaleSent)

		local hasDummyBale = spec.dummyBale.currentBale ~= nil

		if streamWriteBool(streamId, hasDummyBale) then
			streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(spec.dummyBale.currentFilename))
			streamWriteFloat32(streamId, spec.dummyBale.currentBaleYOffset)
			streamWriteFloat32(streamId, spec.dummyBale.currentBaleZOffset)
			streamWriteUIntN(streamId, spec.dummyBale.currentBaleFillType, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

function StrawHarvestBaleShredder:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_strawHarvestBaleShredder

		if streamReadBool(streamId) then
			local scale = streamReadFloat32(streamId)

			spec.dummyBale.networkScaleInterpolator:setTargetValue(scale)
			spec.dummyBale.networkTimeInterpolator:startNewPhaseNetwork()
		end

		if streamReadBool(streamId) then
			local amount = streamReadUIntN(streamId, StrawHarvestBaleShredder.SEND_OBJECT_NUM_BITS)
			spec.dynamicMountedObjects = {}

			for i = 1, amount do
				local object = NetworkUtil.readNodeObject(streamId)

				if object ~= nil then
					spec.dynamicMountedObjects[object] = object
				end
			end
		end
	end
end

function StrawHarvestBaleShredder:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_strawHarvestBaleShredder

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, spec.dummyBale.scale)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dynamicMountedObjectsDirtyFlag) ~= 0) then
			local objects = {}

			for object, _ in pairs(spec.dynamicMountedObjects) do
				table.insert(objects, object)
			end

			streamWriteUIntN(streamId, #objects, StrawHarvestBaleShredder.SEND_OBJECT_NUM_BITS)

			for i = 1, #objects do
				local object = objects[i]

				NetworkUtil.writeNodeObject(streamId, object)
			end
		end
	end
end

function StrawHarvestBaleShredder:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_strawHarvestBaleShredder

	if self:hasDummyBale() then
		local currentBale = spec.dummyBale
		local fillType = currentBale.currentBaleFillType
		local fillTypeStr = "UNKNOWN"

		if fillType ~= FillType.UNKNOWN then
			fillTypeStr = g_fillTypeManager:getFillTypeNameByIndex(fillType)
		end

		xmlFile:setValue(key .. "#fillType", fillTypeStr)
		xmlFile:setValue(key .. "#fillLevel", currentBale.currentBaleFillLevel)
		xmlFile:setValue(key .. "#capacity", currentBale.currentBaleCapacity)
		xmlFile:setValue(key .. "#currentBaleYOffset", currentBale.currentBaleYOffset)
		xmlFile:setValue(key .. "#currentBaleZOffset", currentBale.currentBaleZOffset)
		xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(currentBale.currentFilename)))
		xmlFile:setValue(key .. "#scale", currentBale.scale)
	end
end

function StrawHarvestBaleShredder:onUpdate(dt)
	local spec = self.spec_strawHarvestBaleShredder

	if spec.dummyBaleToCreate ~= nil then
		local i3dFilename, yOffset, zOffset, fillType, scale = unpack(spec.dummyBaleToCreate)

		self:createDummyBaleFromBale(i3dFilename, yOffset, zOffset, fillType)

		if spec.dummyBale.currentBale ~= nil then
			setScale(spec.dummyBale.scaleNode, 1, 1, scale)

			spec.dummyBaleToCreate = nil
		end
	end

	local currentBale = spec.dummyBale
	local scale = currentBale.scale

	if not self.isServer then
		currentBale.networkTimeInterpolator:update(dt)

		local interpolationAlpha = currentBale.networkTimeInterpolator:getAlpha()
		scale = currentBale.networkScaleInterpolator:getInterpolatedValue(interpolationAlpha)
	end

	if self.isClient then
		local isFilling = self:hasDummyBale() and self:getIsTurnedOn()

		if isFilling then
			setScale(currentBale.scaleNode, 1, 1, scale)

			isFilling = scale > 0.01

			if not isFilling then
				self:deleteDummyBale()
			end
		end

		if spec.effects ~= nil then
			if isFilling then
				g_effectManager:setFillType(spec.effects, currentBale.currentBaleFillType)
				g_effectManager:startEffects(spec.effects)
			else
				g_effectManager:stopEffects(spec.effects)
			end
		end
	end

	if not self.isServer and currentBale.networkTimeInterpolator:isInterpolating() then
		self:raiseActive()
	end

	if self.isClient and self:getIsActiveForInput(true) and spec.currentWarning ~= 0 then
		local warning = spec.warnings[spec.currentWarning]

		g_currentMission:showBlinkingWarning(warning, 5000)

		spec.currentWarning = 0
	end
end

function StrawHarvestBaleShredder:onUpdateTick(dt)
	if not self.isServer then
		return
	end

	if not self:getIsTurnedOn() then
		return
	end

	local spec = self.spec_strawHarvestBaleShredder

	for object, target in pairs(spec.activeBaleToTarget) do
		if spec.dynamicMountedObjects[object] == nil then
			local objectId = object.nodeId or object.rootNode

			if object.lastMoveTime + 50 < g_currentMission.time and not object.isAttachedToBaleHook and object.dynamicMountJointIndex == nil then
				local x, y, z = localToLocal(objectId, spec.detectionRootNode, 0, 0, 0)

				if y <= 0 then
					object:unmountDynamic()
					setTranslation(target.jointNode, x, y, z)

					local _, _, bz = getRotation(objectId)
					local isInverted = MathUtil.round(bz) == 0
					local node = isInverted and spec.detectionRootNodeReverse or spec.detectionRootNode
					local rx, ry, rz = localRotationToLocal(objectId, getParent(node), getRotation(node))

					setRotation(target.jointNode, rx, ry, rz)

					if object:mountDynamic(self, self.rootNode, target.jointNode, DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ, 45) then
						self:addDynamicMountedObject(object, isInverted)
					end
				end
			end
		end
	end

	local positionIsDirty = false

	for object, _ in pairs(spec.dynamicMountedObjects) do
		local target = spec.activeBaleToTarget[object]

		if target ~= nil then
			local baleOffset = -target.z

			if target.direction == nil then
				local dx, dy, dz = localDirectionToWorld(target.jointNode, 0, 0, 1)
				target.direction = {
					worldDirectionToLocal(getParent(target.jointNode), dx, dy, dz)
				}
			end

			target.time = target.time + dt * 0.2
			local distance = calcDistanceFrom(target.detectionNode, target.jointNode) - baleOffset

			if spec.feedThreshold < distance then
				local x, y, z = localToWorld(target.jointNode, 0, 0, 0)
				local _, _, dot = worldDirectionToLocal(target.jointNode, localDirectionToWorld(spec.detectionRootNode, 0, 0, 1))
				local dir = MathUtil.sign(dot)
				local dirX, dirY, dirZ = localDirectionToWorld(target.jointNode, 0, 0, (distance + 0.1) * dir)

				if distance > 0.0001 then
					dirZ = dirZ / distance
					dirY = dirY / distance
					dirX = dirX / distance
				end

				local threshHoldTime = 1000

				if target.time <= threshHoldTime then
					local alpha = target.time / threshHoldTime
					local localDirX, localDirY, localDirZ = worldDirectionToLocal(target.jointNode, dirX, dirY, dirZ)
					local ox, oy, oz = unpack(target.direction)
					localDirX, localDirY, localDirZ = MathUtil.vector3Lerp(ox, oy, oz, localDirX, localDirY, localDirZ, alpha)
					local localUpX, localUpY, localUpZ = worldDirectionToLocal(getParent(target.jointNode), localDirectionToWorld(target.jointNode, 0, 1, 0))

					I3DUtil.setDirection(target.jointNode, localDirX, localDirY, localDirZ, localUpX, localUpY, localUpZ)
				end

				local movementFactor = 1
				local damage = self:getVehicleDamage()

				if damage > 0 then
					movementFactor = movementFactor - damage * StrawHarvestBaleShredder.DAMAGED_SPEEDLIMIT_REDUCTION
				end

				local speed = spec.baleMovementSpeed * movementFactor * 0.001 * dt
				local tx = x + dirX * speed
				local tz = z + dirZ * speed

				setWorldTranslation(target.jointNode, tx, y, tz)

				positionIsDirty = true

				if not target.isTwineCut then
					local knifeAnimation = spec.knifeAnimation

					if not self:getIsAnimationPlaying(knifeAnimation.name) and self:getAnimationTime(knifeAnimation.name) == 1 then
						self:playAnimation(knifeAnimation.name, -1, nil, false)
					end

					local knifeDistance = calcDistanceFrom(knifeAnimation.node, target.jointNode) - baleOffset

					if knifeDistance <= knifeAnimation.startThreshold then
						self:playAnimation(knifeAnimation.name, 1, nil, false)

						target.isTwineCut = true
					end
				end

				if not target.isTwineRemoved then
					local twineAnimation = spec.twineAnimation

					if not self:getIsAnimationPlaying(twineAnimation.name) and self:getAnimationTime(twineAnimation.name) == 1 then
						self:playAnimation(twineAnimation.name, -1, nil, false)
					end

					local twineDistance = calcDistanceFrom(twineAnimation.node, target.jointNode) - baleOffset

					if twineDistance <= twineAnimation.startThreshold then
						self:playAnimation(twineAnimation.name, 1, nil, false)

						target.isTwineRemoved = true
					end
				end

				if VehicleDebug.state == VehicleDebug.DEBUG then
					DebugUtil.drawDebugNode(target.jointNode, "N")

					x, y, z = localToWorld(target.detectionNode, 0, 0, 0)

					drawDebugLine(x, y + 1, z, 1, 1, 0, tx, y + 1, tz, 1, 1, 0)
				end
			else
				local isBaleAllowed, warning = self:isBaleAllowed(object)

				if isBaleAllowed then
					if not self:hasDummyBale() then
						self:removeDynamicMountedObject(object, true)

						local fillType = object:getFillType()
						local fillLevel = object:getFillLevel()
						local isRoundBale = object.isRoundbale
						local width = MathUtil.round(Utils.getNoNil(object.width, 1.2), 2)
						local height = MathUtil.round(Utils.getNoNil(object.height, 0.9), 2)
						local length = MathUtil.round(Utils.getNoNil(object.length, 2.4), 2)
						local diameter = MathUtil.round(Utils.getNoNil(object.diameter, 1.8), 2)
						local filename = g_baleManager:getBaleXMLFilename(fillType, isRoundBale, width, height, length, diameter, self.customEnvironment)

						self:createDummyBaleFromBale(filename, target.y, target.z, fillType, fillLevel, fillLevel)
						object:delete()
					end
				else
					self:removeDynamicMountedObject(object)

					spec.currentWarning = warning
				end
			end
		else
			self:removeDynamicMountedObject(object)
		end
	end

	if positionIsDirty then
		for object, _ in pairs(spec.dynamicMountedObjects) do
			local target = spec.activeBaleToTarget[object]

			if target ~= nil then
				if object.dynamicMountJointIndex ~= nil then
					setJointFrame(object.dynamicMountJointIndex, 0, target.jointNode)
				end

				if object.backupMass == nil then
					local mass = getMass(object.nodeId)

					if mass ~= 1 then
						object.backupMass = mass

						setMass(object.nodeId, 0.1)
					end
				end
			end
		end
	end
end

function StrawHarvestBaleShredder:processBale(dt)
	local spec = self.spec_strawHarvestBaleShredder
	local delta = 0
	local fillType = FillType.UNKNOWN
	local currentBale = spec.dummyBale

	if self:hasDummyBale() then
		fillType = currentBale.currentBaleFillType
		local movementFactor = 1
		local damage = self:getVehicleDamage()

		if damage > 0 then
			movementFactor = movementFactor - damage * StrawHarvestBaleShredder.DAMAGED_SPEEDLIMIT_REDUCTION
		end

		local speed = spec.baleMovementSpeed * movementFactor * 0.001 * dt
		delta = math.abs(currentBale.currentBaleCapacity * speed / (currentBale.currentBaleZOffset * 2))
		delta = math.min(delta, currentBale.currentBaleFillLevel, currentBale.currentBaleCapacity)
		currentBale.currentBaleFillLevel = currentBale.currentBaleFillLevel - delta
		currentBale.scale = currentBale.currentBaleFillLevel / currentBale.currentBaleCapacity
	end

	if currentBale.scaleSent ~= currentBale.scale then
		if currentBale.scale <= 0 then
			self:deleteDummyBale()
		end

		currentBale.scaleSent = currentBale.scale

		self:raiseDirtyFlags(spec.dirtyFlag)
	end

	return delta, fillType
end

function StrawHarvestBaleShredder:isBaleAllowed(object)
	local spec = self.spec_strawHarvestBaleShredder
	local isRoundBale = object.isRoundbale
	local allowBale = isRoundBale and spec.allowRoundBales or not isRoundBale
	local warning = nil

	if not allowBale then
		warning = StrawHarvestBaleShredder.WARNING_ROUND_BALE_NOT_SUPPORTED
	else
		local baleFillType = object:getFillType()

		if spec.attacherVehicle ~= nil then
			allowBale = spec.attacherVehicle:isShreddingBaleAllowed(baleFillType)

			if not allowBale then
				warning = StrawHarvestBaleShredder.WARNING_FILLTYPE_BALE_NOT_SUPPORTED
			end
		end
	end

	return allowBale, warning
end

function StrawHarvestBaleShredder:addBale(object)
	local spec = self.spec_strawHarvestBaleShredder
	local target = {}
	local z = object.isRoundbale and object.diameter or object.length
	target.z = -z * 0.5
	target.time = 0
	target.isTwineCut = false
	target.isTwineRemoved = false
	target.object = object
	target.jointNode = createTransformGroup("targetJointNode")

	link(spec.detectionRootNode, target.jointNode)

	spec.activeBaleToTarget[object] = target

	table.insert(spec.activeBales, target)
end

function StrawHarvestBaleShredder:removeBale(object)
	local spec = self.spec_strawHarvestBaleShredder
	local target = spec.activeBaleToTarget[object]

	if target ~= nil and self.isServer then
		delete(target.jointNode)
	end

	table.removeElement(spec.activeBales, target)

	spec.activeBaleToTarget[object] = nil
end

function StrawHarvestBaleShredder:addDynamicMountedObject(object, isInverted)
	if isInverted == nil then
		return
	end

	local spec = self.spec_strawHarvestBaleShredder
	local target = spec.activeBaleToTarget[object]

	if target ~= nil then
		target.detectionNode = isInverted and spec.detectionRootNodeReverse or spec.detectionRootNode
		local _, y, _ = getTranslation(target.jointNode)
		target.y = y
		target.time = 0
		target.direction = nil
	end

	spec.dynamicMountedObjects[object] = object

	self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
end

function StrawHarvestBaleShredder:removeDynamicMountedObject(object, isDeleting)
	local spec = self.spec_strawHarvestBaleShredder

	if spec.dynamicMountedObjects[object] == nil then
		return
	end

	spec.dynamicMountedObjects[object] = nil

	if isDeleting then
		self:removeBale(object)
	end

	if self.isServer then
		object:unmountDynamic()

		if object.backupMass ~= nil then
			setMass(object.nodeId, object.backupMass)

			object.backupMass = nil
		end
	end

	self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
end

function StrawHarvestBaleShredder:hasDummyBale()
	local spec = self.spec_strawHarvestBaleShredder

	return spec.dummyBale.currentBaleFillType ~= FillType.UNKNOWN
end

function StrawHarvestBaleShredder:createDummyBaleFromBale(filename, yOffset, zOffset, fillTypeIndex, fillLevel, capacity)
	local spec = self.spec_strawHarvestBaleShredder
	local baleId, sharedLoadRequestId = Bale.createDummyBale(filename, fillTypeIndex)

	link(spec.dummyBale.baleNode, baleId)
	setTranslation(baleId, 0, yOffset, zOffset)

	spec.dummyBale.currentBale = baleId
	spec.dummyBale.sharedLoadRequestId = sharedLoadRequestId
	spec.dummyBale.currentFilename = filename
	spec.dummyBale.scale = 1

	spec.dummyBale.networkScaleInterpolator:setValue(1)

	spec.dummyBale.currentBaleYOffset = yOffset
	spec.dummyBale.currentBaleZOffset = zOffset
	spec.dummyBale.currentBaleFillType = fillTypeIndex

	if self.isServer then
		spec.dummyBale.currentBaleFillLevel = fillLevel
		spec.dummyBale.currentBaleCapacity = capacity
		spec.dummyBale.scaleSent = spec.dummyBale.scale

		g_server:broadcastEvent(StrawHarvestLoadDummyBaleEvent.new(self, filename, yOffset, zOffset, fillTypeIndex), nil, nil, self)
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function StrawHarvestBaleShredder:deleteDummyBale()
	local spec = self.spec_strawHarvestBaleShredder
	spec.dummyBale.currentBaleFillType = FillType.UNKNOWN

	if spec.dummyBale.currentBale ~= nil then
		delete(spec.dummyBale.currentBale)

		spec.dummyBale.currentBale = nil
	end

	if spec.dummyBale.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(spec.dummyBale.sharedLoadRequestId)

		spec.dummyBale.sharedLoadRequestId = nil
	end
end

function StrawHarvestBaleShredder:detectionTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_strawHarvestBaleShredder
	local object = g_currentMission:getNodeObject(otherActorId)

	if object ~= nil and object:isa(Bale) then
		if onEnter and self:getIsInWorkPosition() then
			local isBaleAllowed, warning = self:isBaleAllowed(object)

			if warning ~= nil then
				spec.currentWarning = warning
			end

			if self.isServer and spec.activeBaleToTarget[object] == nil and isBaleAllowed then
				self:addBale(object)
			end
		end

		if self.isServer and onLeave then
			self:removeDynamicMountedObject(object, true)
		end
	end
end

function StrawHarvestBaleShredder:onStartAnimation(animationName)
	local spec = self.spec_strawHarvestBaleShredder
	local twineAnimation = spec.twineAnimation

	if animationName == twineAnimation.name then
		g_animationManager:startAnimations(twineAnimation.animationNodes)
	end

	local knifeAnimation = spec.knifeAnimation

	if animationName == knifeAnimation.name then
		g_animationManager:startAnimations(knifeAnimation.animationNodes)
	end
end

function StrawHarvestBaleShredder:onFinishAnimation(animationName)
	local spec = self.spec_strawHarvestBaleShredder
	local twineAnimation = spec.twineAnimation

	if animationName == twineAnimation.name then
		g_animationManager:stopAnimations(twineAnimation.animationNodes)
	end

	local knifeAnimation = spec.knifeAnimation

	if animationName == knifeAnimation.name then
		g_animationManager:stopAnimations(knifeAnimation.animationNodes)
	end

	if animationName == spec.supportObjectChangesAnimationName then
		local isAttached = self:getAnimationTime(animationName) == 0

		ObjectChangeUtil.setObjectChanges(spec.supportObjectChanges, isAttached, self)
	end
end

function StrawHarvestBaleShredder:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_strawHarvestBaleShredder
	spec.attacherVehicle = attacherVehicle

	ObjectChangeUtil.setObjectChanges(spec.objectChanges, true, self)
end

function StrawHarvestBaleShredder:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_strawHarvestBaleShredder
	spec.attacherVehicle = nil

	ObjectChangeUtil.setObjectChanges(spec.objectChanges, false, self)

	if self.getFoldAnimTime ~= nil then
		local animationTime = self:getFoldAnimTime()
		local spec_foldable = self.spec_foldable

		if self:getIsInWorkPosition() or spec_foldable.detachingMinLimit < animationTime or animationTime < spec_foldable.detachingMaxLimit then
			Foldable.setAnimTime(self, 1, false)
		end
	end
end

function StrawHarvestBaleShredder:onTurnedOff()
	local spec = self.spec_strawHarvestBaleShredder

	if self.isClient then
		g_effectManager:stopEffects(spec.effects)
	end
end

function StrawHarvestBaleShredder:onDeactivate()
	local spec = self.spec_strawHarvestBaleShredder

	if self.isClient then
		g_effectManager:stopEffects(spec.effects)
	end
end

function StrawHarvestBaleShredder:loadObjectChangeValuesFromXML(superFunc, xmlFile, key, node, object)
	superFunc(self, xmlFile, key, node, object)

	local collisionMask = getCollisionMask(node)
	object.collisionMaskActive = xmlFile:getInt(key .. "#collisionMaskActive", collisionMask)
	object.collisionMaskInactive = xmlFile:getInt(key .. "#collisionMaskInactive", collisionMask)
end

function StrawHarvestBaleShredder:setObjectChangeValues(superFunc, object, isActive)
	superFunc(self, object, isActive)

	local collisionMaskToSet = isActive and object.collisionMaskActive or object.collisionMaskInactive

	setCollisionMask(object.node, collisionMaskToSet)
end

function StrawHarvestBaleShredder:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_strawHarvestBaleShredder

	if #spec.activeBales > 0 or self:hasDummyBale() then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil and attacherVehicle.getIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function StrawHarvestBaleShredder:getFillLevelInformation(superFunc, display)
	superFunc(self, display)

	local spec = self.spec_strawHarvestBaleShredder

	for object, _ in pairs(spec.dynamicMountedObjects) do
		if object:isa(Bale) then
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
