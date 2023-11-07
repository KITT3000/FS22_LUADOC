local pdlc_goeweilPackIsLoaded = g_modIsLoaded.pdlc_goeweilPack
local pdlc_vermeerPackIsLoaded = g_modIsLoaded.pdlc_vermeerPack

if pdlc_goeweilPackIsLoaded or pdlc_vermeerPackIsLoaded then
	return
end

StrawHarvestBaleCounter = {}

VehicleHUDExtension.registerHUDExtension(StrawHarvestBaleCounter, StrawHarvestBaleCounterHUDExtension)

function StrawHarvestBaleCounter.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Baler, specializations)
end

function StrawHarvestBaleCounter.initSpecialization()
	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local baseKey = "vehicles.vehicle(?)." .. g_currentStrawHarvestModName .. ".strawHarvestBaleCounter"

	schemaSavegame:register(XMLValueType.INT, baseKey .. "#currentCount", "Current counter")
	schemaSavegame:register(XMLValueType.INT, baseKey .. "#lifetimeCount", "Lifetime counter")
end

function StrawHarvestBaleCounter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "resetBalerCurrentBalesCount", StrawHarvestBaleCounter.resetBalerCurrentBalesCount)
	SpecializationUtil.registerFunction(vehicleType, "canCountBales", StrawHarvestBaleCounter.canCountBales)
	SpecializationUtil.registerFunction(vehicleType, "isRoundBaler", StrawHarvestBaleCounter.isRoundBaler)
end

function StrawHarvestBaleCounter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "dropBale", StrawHarvestBaleCounter.dropBale)
end

function StrawHarvestBaleCounter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestBaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", StrawHarvestBaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StrawHarvestBaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StrawHarvestBaleCounter)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", StrawHarvestBaleCounter)
end

function StrawHarvestBaleCounter:onLoad(savegame)
	self.spec_strawHarvestBaleCounter = self[("spec_%s.strawHarvestBaleCounter"):format(g_currentStrawHarvestModName)]
	local spec = self.spec_strawHarvestBaleCounter
	spec.currentCount = 0
	spec.lifetimeCount = 0

	if savegame ~= nil and not savegame.resetVehicles then
		local key = savegame.key .. "." .. g_currentStrawHarvestModName .. ".strawHarvestBaleCounter"
		spec.currentCount = savegame.xmlFile:getValue(key .. "#currentCount", spec.currentCount)
		spec.lifetimeCount = savegame.xmlFile:getValue(key .. "#lifetimeCount", spec.lifetimeCount)
	end
end

function StrawHarvestBaleCounter:onReadStream(streamId, connection)
	local spec = self.spec_strawHarvestBaleCounter
	spec.currentCount = streamReadInt16(streamId)
	spec.lifetimeCount = streamReadInt16(streamId)
end

function StrawHarvestBaleCounter:onWriteStream(streamId, connection)
	local spec = self.spec_strawHarvestBaleCounter

	streamWriteInt16(streamId, spec.currentCount)
	streamWriteInt16(streamId, spec.lifetimeCount)
end

function StrawHarvestBaleCounter:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_strawHarvestBaleCounter

	xmlFile:setValue(key .. "#currentCount", spec.currentCount)
	xmlFile:setValue(key .. "#lifetimeCount", spec.lifetimeCount)
end

function StrawHarvestBaleCounter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_strawHarvestBaleCounter

	if self.isClient and spec.actionEvents ~= nil then
		local actionEvent = spec.actionEvents[InputAction.SH_RESET_BALE_COUNTER]

		if actionEvent ~= nil then
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.currentCount > 0)
		end
	end
end

function StrawHarvestBaleCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_strawHarvestBaleCounter

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.SH_RESET_BALE_COUNTER, self, StrawHarvestBaleCounter.actionEventResetBaleCount, false, true, false, true, nil)

			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_resetBaleCounter"))
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
		end
	end
end

function StrawHarvestBaleCounter:resetBalerCurrentBalesCount(noEventSend)
	if not noEventSend then
		g_client:getServerConnection():sendEvent(StrawHarvestResetBaleCountEvent.new(self))
	end

	local spec = self.spec_strawHarvestBaleCounter
	spec.currentCount = 0
end

function StrawHarvestBaleCounter:canCountBales()
	return self.finishedFirstUpdate and (self.spec_baler.balesToLoad == nil or #self.spec_baler.balesToLoad == 0)
end

function StrawHarvestBaleCounter:isRoundBaler()
	local baleType = self.spec_baler.baleTypes[self.spec_baler.currentBaleTypeIndex]

	return baleType.isRoundBale
end

function StrawHarvestBaleCounter:dropBale(superFunc, ...)
	local spec = self.spec_strawHarvestBaleCounter

	if self:canCountBales() then
		spec.currentCount = spec.currentCount + 1
		spec.lifetimeCount = spec.lifetimeCount + 1
	end

	superFunc(self, ...)
end

function StrawHarvestBaleCounter:actionEventResetBaleCount(...)
	self:resetBalerCurrentBalesCount(false)
end
