StrawHarvestPelletizer = {
	MOD_NAME = g_currentModName,
	DEFAULT_SPEED_LIMIT = 10,
	TIMER_THRESHOLD = 500,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(Pickup, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end,
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("pelletizer", false)

		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("StrawHarvestPelletizer")
		schema:register(XMLValueType.INT, "vehicle.pelletizer#fillUnitIndex", "Fillunit index of the pelletizer")
		schema:register(XMLValueType.INT, "vehicle.pelletizer#workAreaIndex", "WorkArea index of the pelletizer")
		schema:register(XMLValueType.INT, "vehicle.pelletizer#maxPickupLitersPerSecond", "Max liters per second")
		schema:register(XMLValueType.INT, "vehicle.pelletizer#attachedBaleShredderJointIndex", "Attached schredder index of the pelletizer")
		schema:register(XMLValueType.STRING, "vehicle.pelletizer#fillTypeConverter", "Fill type converter name")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.pelletizer.inputEffect")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.pelletizer.outputEffect")
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.pelletizer.animationNodes")
		schema:setXMLSpecializationType()
	end
}

function StrawHarvestPelletizer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processPelletizerArea", StrawHarvestPelletizer.processPelletizerArea)
	SpecializationUtil.registerFunction(vehicleType, "setEffectActive", StrawHarvestPelletizer.setEffectActive)
	SpecializationUtil.registerFunction(vehicleType, "isStationary", StrawHarvestPelletizer.isStationary)
	SpecializationUtil.registerFunction(vehicleType, "isShreddingBaleAllowed", StrawHarvestPelletizer.isShreddingBaleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "hasAttachedBaleShredder", StrawHarvestPelletizer.hasAttachedBaleShredder)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedBaleShredder", StrawHarvestPelletizer.getAttachedBaleShredder)
	SpecializationUtil.registerFunction(vehicleType, "fillPelletizer", StrawHarvestPelletizer.fillPelletizer)
end

function StrawHarvestPelletizer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", StrawHarvestPelletizer.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", StrawHarvestPelletizer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", StrawHarvestPelletizer.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanChangePickupState", StrawHarvestPelletizer.getCanChangePickupState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", StrawHarvestPelletizer.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", StrawHarvestPelletizer.getTurnedOnNotAllowedWarning)
end

function StrawHarvestPelletizer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", StrawHarvestPelletizer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", StrawHarvestPelletizer)
end

function StrawHarvestPelletizer:onLoad(savegame)
	self.spec_strawHarvestPelletizer = self[("spec_%s.strawHarvestPelletizer"):format(StrawHarvestPelletizer.MOD_NAME)]
	local spec = self.spec_strawHarvestPelletizer
	spec.isFilling = false
	spec.pickupFillType = FillType.UNKNOWN
	spec.isFillingSent = false
	spec.fillTimer = 0
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.pelletizer#fillUnitIndex", 1)
	spec.workAreaIndex = self.xmlFile:getValue("vehicle.pelletizer#workAreaIndex", 1)
	spec.fillTypeConverters = {}
	spec.fillTypeConvertersByOutput = {}
	local converter = self.xmlFile:getValue("vehicle.pelletizer#fillTypeConverter", "PELLETIZER")

	if converter ~= nil then
		local data = g_fillTypeManager:getConverterDataByName(converter)

		if data ~= nil then
			for input, converted in pairs(data) do
				spec.fillTypeConverters[input] = converted

				if spec.fillTypeConvertersByOutput[converted.targetFillTypeIndex] ~= nil then
					log("Error: There's already a output registered for target fill type", converter.targetFillTypeIndex)

					return
				end

				spec.fillTypeConvertersByOutput[converted.targetFillTypeIndex] = input
			end
		end
	else
		print(string.format("Warning: Missing fill type converter in '%s'", self.configFileName))
	end

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.pelletizer.animationNodes", self.components, self, self.i3dMappings)
		spec.inputEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.pelletizer.inputEffect", self.components, self, self.i3dMappings)
		spec.outputEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.pelletizer.outputEffect", self.components, self, self.i3dMappings)
	end

	spec.workAreaParameters = {
		lastPickupLiters = 0,
		lastPickupFillType = FillType.UNKNOWN
	}
	spec.maxPickupLitersPerSecond = self.xmlFile:getValue("vehicle.pelletizer#maxPickupLitersPerSecond", 150)
	spec.pickUpLitersBuffer = ValueBuffer.new(750)
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.attachedBaleShredder = nil
	spec.attachedBaleShredderJointIndex = self.xmlFile:getValue("vehicle.pelletizer#attachedBaleShredderJointIndex", 1)
end

function StrawHarvestPelletizer:onDelete()
	local spec = self.spec_strawHarvestPelletizer

	if self.isClient then
		g_animationManager:deleteAnimations(spec.animationNodes)
		g_effectManager:deleteEffects(spec.inputEffects)
		g_effectManager:deleteEffects(spec.outputEffects)
	end
end

function StrawHarvestPelletizer:onReadStream(streamId, connection)
	local spec = self.spec_strawHarvestPelletizer
	spec.isFilling = streamReadBool(streamId)
	spec.pickupFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
end

function StrawHarvestPelletizer:onWriteStream(streamId, connection)
	local spec = self.spec_strawHarvestPelletizer

	streamWriteBool(streamId, spec.isFillingSent)
	streamWriteUIntN(streamId, spec.pickupFillType, FillTypeManager.SEND_NUM_BITS)
end

function StrawHarvestPelletizer:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_strawHarvestPelletizer

		if streamReadBool(streamId) then
			spec.isFilling = streamReadBool(streamId)
			spec.pickupFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

			self:setEffectActive(spec.isFilling)
		end
	end
end

function StrawHarvestPelletizer:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_strawHarvestPelletizer

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.isFilling)
			streamWriteUIntN(streamId, spec.pickupFillType, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

function StrawHarvestPelletizer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_strawHarvestPelletizer

	if self.isServer then
		if self:isStationary() then
			spec.workAreaParameters.lastPickupLiters = 0
			spec.workAreaParameters.lastPickupFillType = FillType.UNKNOWN
			local baleShredder = self:getAttachedBaleShredder()

			if baleShredder ~= nil and baleShredder.processBale ~= nil then
				if self:getFillUnitFreeCapacity(spec.fillUnitIndex) ~= 0 then
					local delta, fillType = baleShredder:processBale(dt)

					if delta > 0 then
						self:fillPelletizer(delta, fillType)

						spec.workAreaParameters.lastPickupLiters = spec.workAreaParameters.lastPickupLiters + delta
						spec.workAreaParameters.lastPickupFillType = fillType
					end
				else
					self:setIsTurnedOn(false)
				end
			end
		end

		local lastPickupFillType = spec.workAreaParameters.lastPickupFillType
		local isFilling = spec.fillTimer > 0

		if isFilling then
			spec.fillTimer = spec.fillTimer - dt
		end

		spec.isFilling = isFilling

		if spec.isFilling ~= spec.isFillingSent or spec.pickupFillType ~= lastPickupFillType then
			spec.pickupFillType = lastPickupFillType
			spec.isFillingSent = spec.isFilling

			self:raiseDirtyFlags(spec.dirtyFlag)
			self:setEffectActive(spec.isFilling)
		end

		spec.pickUpLitersBuffer:add(spec.workAreaParameters.lastPickupLiters)
	end
end

function StrawHarvestPelletizer:isShreddingBaleAllowed(fillType)
	local spec = self.spec_strawHarvestPelletizer
	local lastFillType = self:getFillUnitFillType(spec.fillUnitIndex)
	local lastInputFillType = spec.fillTypeConvertersByOutput[lastFillType]
	local allowsFillType = spec.fillTypeConverters[fillType] ~= nil

	return allowsFillType and (lastFillType == FillType.UNKNOWN or lastInputFillType ~= nil and fillType == lastInputFillType)
end

function StrawHarvestPelletizer:isStationary()
	if not self:getIsTurnedOn() then
		return false
	end

	if self:hasAttachedBaleShredder() then
		local baleShredder = self:getAttachedBaleShredder()

		if baleShredder:getIsInWorkPosition() then
			return true
		end
	end

	return false
end

function StrawHarvestPelletizer:hasAttachedBaleShredder()
	local spec = self.spec_strawHarvestPelletizer

	return spec.attachedBaleShredder ~= nil
end

function StrawHarvestPelletizer:getAttachedBaleShredder()
	local spec = self.spec_strawHarvestPelletizer

	return spec.attachedBaleShredder
end

function StrawHarvestPelletizer:setEffectActive(isActive)
	local spec = self.spec_strawHarvestPelletizer

	if isActive then
		if spec.inputEffects ~= nil and spec.pickupFillType ~= FillType.UNKNOWN then
			local lastValidFillType = spec.pickupFillType

			g_effectManager:setFillType(spec.inputEffects, lastValidFillType)
			g_effectManager:startEffects(spec.inputEffects)
		end

		if spec.outputEffects ~= nil then
			local lastValidFillType = self:getFillUnitLastValidFillType(spec.fillUnitIndex)

			g_effectManager:setFillType(spec.outputEffects, lastValidFillType)
			g_effectManager:startEffects(spec.outputEffects)
		end
	else
		if spec.inputEffects ~= nil then
			g_effectManager:stopEffects(spec.inputEffects)
		end

		if spec.outputEffects ~= nil then
			g_effectManager:stopEffects(spec.outputEffects)
		end
	end
end

function StrawHarvestPelletizer:processPelletizerArea(workArea)
	local spec = self.spec_strawHarvestPelletizer
	local currentFillType = spec.workAreaParameters.lastPickupFillType
	local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
	local inputLiters = 0

	if currentFillType ~= FillType.UNKNOWN then
		inputLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, currentFillType, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, nil, false, nil)
	else
		for _, inputFillType in pairs(spec.fillTypeConvertersByOutput) do
			inputLiters = inputLiters + -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, inputFillType, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, nil, false, nil)

			if inputLiters > 0 then
				currentFillType = inputFillType

				break
			end
		end
	end

	workArea.lastPickUpLiters = inputLiters
	workArea.pickupParticlesActive = inputLiters > 0
	spec.workAreaParameters.lastPickupFillType = currentFillType
	spec.workAreaParameters.lastPickupLiters = spec.workAreaParameters.lastPickupLiters + inputLiters

	return inputLiters, inputLiters
end

function StrawHarvestPelletizer:onStartWorkAreaProcessing(dt)
	local spec = self.spec_strawHarvestPelletizer
	spec.workAreaParameters.lastPickupLiters = 0
	spec.workAreaParameters.lastPickupFillType = FillType.UNKNOWN
	local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

	if self:getFillTypeChangeThreshold(spec.fillUnitIndex) < fillLevel then
		local lastPickupFillType = spec.fillTypeConvertersByOutput[self:getFillUnitFillType(spec.fillUnitIndex)]
		spec.workAreaParameters.lastPickupFillType = lastPickupFillType
	end
end

function StrawHarvestPelletizer:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_strawHarvestPelletizer

	if self.isServer then
		local inputLiters = spec.workAreaParameters.lastPickupLiters
		local inputFruitType = spec.workAreaParameters.lastPickupFillType

		if inputLiters > 0 then
			self:fillPelletizer(inputLiters, inputFruitType)
		end
	end
end

function StrawHarvestPelletizer:fillPelletizer(inputLiters, inputFruitType)
	local spec = self.spec_strawHarvestPelletizer
	local conversionFactor = 1
	local outputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(inputFruitType)

	if spec.fillTypeConverters[inputFruitType] ~= nil then
		outputFillType = spec.fillTypeConverters[inputFruitType].targetFillTypeIndex
		conversionFactor = spec.fillTypeConverters[inputFruitType].conversionFactor
	end

	local deltaFillLevel = inputLiters * conversionFactor

	self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, deltaFillLevel, outputFillType, ToolType.UNDEFINED)

	spec.fillTimer = StrawHarvestPelletizer.TIMER_THRESHOLD
end

function StrawHarvestPelletizer:onTurnedOn()
	local spec = self.spec_strawHarvestPelletizer

	if self.isClient then
		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function StrawHarvestPelletizer:onTurnedOff()
	local spec = self.spec_strawHarvestPelletizer

	if self.isClient then
		spec.fillTimer = 0

		self:setEffectActive(false)
		g_animationManager:stopAnimations(spec.animationNodes)
	end
end

function StrawHarvestPelletizer:onDeactivate()
	local spec = self.spec_strawHarvestPelletizer

	if self.isClient then
		spec.fillTimer = 0

		self:setEffectActive(false)
	end
end

function StrawHarvestPelletizer:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_strawHarvestPelletizer

	if jointDescIndex == spec.attachedBaleShredderJointIndex then
		spec.attachedBaleShredder = attachable

		self:setPickupState(false)
	end
end

function StrawHarvestPelletizer:onPostDetachImplement(implementIndex)
	local spec = self.spec_strawHarvestPelletizer
	local attachedImplements = self:getAttachedImplements()

	if attachedImplements[implementIndex].jointDescIndex == spec.attachedBaleShredderJointIndex then
		spec.attachedBaleShredder = nil
	end
end

function StrawHarvestPelletizer:getCanChangePickupState(superFunc, newState)
	if self:hasAttachedBaleShredder() then
		return false
	end

	return superFunc(self, newState)
end

function StrawHarvestPelletizer:getCanBeTurnedOn(superFunc)
	if self:hasAttachedBaleShredder() then
		local baleShredder = self:getAttachedBaleShredder()

		if not baleShredder:getIsInWorkPosition() then
			return false
		end
	end

	return superFunc(self)
end

function StrawHarvestPelletizer:getTurnedOnNotAllowedWarning(superFunc)
	if self:hasAttachedBaleShredder() then
		local baleShredder = self:getAttachedBaleShredder()

		if not baleShredder:getIsInWorkPosition() then
			return g_i18n:getText("warning_firstUnfoldTheTool"):format(baleShredder:getName())
		end
	end

	return superFunc(self)
end

function StrawHarvestPelletizer:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_strawHarvestPelletizer
	local area = self.spec_workArea.workAreas[spec.workAreaIndex]

	if area ~= nil and workArea == area and (not self:getIsTurnedOn() or not self:allowPickingUp()) then
		return false
	end

	if self:getFillUnitFreeCapacity(spec.fillUnitIndex) == 0 then
		return false
	end

	return superFunc(self, workArea)
end

function StrawHarvestPelletizer.getDefaultSpeedLimit()
	return StrawHarvestPelletizer.DEFAULT_SPEED_LIMIT
end

function StrawHarvestPelletizer:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and self:getIsLowered()
end

function StrawHarvestPelletizer:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local spec = self.spec_strawHarvestPelletizer
	local loadPercentage = spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond

	return value + loadPercentage, count + 1
end
