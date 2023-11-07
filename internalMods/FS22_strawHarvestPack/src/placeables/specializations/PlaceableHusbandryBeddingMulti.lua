PlaceableHusbandryBeddingMulti = {
	MOD_DIRECTORY = g_currentModDirectory,
	MOD_NAME = g_currentModName
}
local pdlc_pumpsAndHosesPackIsLoaded = g_modIsLoaded.pdlc_pumpsAndHosesPack
PlaceableHusbandryBeddingMulti.INPUT_FILLTYPES = {
	"SEPARATED_MANURE",
	"STRAW_PELLETS"
}

function PlaceableHusbandryBeddingMulti.prerequisitesPresent(specializations)
	return true
end

function PlaceableHusbandryBeddingMulti.registerFunctions(placeableType)
	if not pdlc_pumpsAndHosesPackIsLoaded then
		SpecializationUtil.registerFunction(placeableType, "updatePlane", PlaceableHusbandryBeddingMulti.updatePlane)
	end

	SpecializationUtil.registerFunction(placeableType, "updatePlaneMulti", PlaceableHusbandryBeddingMulti.updatePlaneMulti)
end

function PlaceableHusbandryBeddingMulti.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryBeddingMulti.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryBeddingMulti.updateProduction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryBeddingMulti.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryBeddingMulti.updateInfo)

	if pdlc_pumpsAndHosesPackIsLoaded then
		SpecializationUtil.registerOverwrittenFunction(placeableType, "updatePlane", PlaceableHusbandryBeddingMulti.updatePlane)
	end
end

function PlaceableHusbandryBeddingMulti.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onPreLoad", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryBeddingMulti)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryFillLevelChanged", PlaceableHusbandryBeddingMulti)
end

function PlaceableHusbandryBeddingMulti:onPreLoad(savegame)
	self.spec_husbandryBeddingMulti = self[("spec_%s.husbandryBeddingMulti"):format(PlaceableHusbandryBeddingMulti.MOD_NAME)]
	local spec = self.spec_husbandryBeddingMulti
	spec.extendFillType = FillType.STRAW
	spec.inputFillTypes = {}

	for _, fillTypeName in ipairs(PlaceableHusbandryBeddingMulti.INPUT_FILLTYPES) do
		if FillType[fillTypeName] ~= nil then
			table.addElement(spec.inputFillTypes, FillType[fillTypeName])
		end
	end

	spec.outputFillType = FillType.MANURE
end

function PlaceableHusbandryBeddingMulti:onLoad(savegame)
	local spec = self.spec_husbandryBeddingMulti
	local unloadingStation = self.spec_husbandry.unloadingStation

	if unloadingStation ~= nil then
		for _, trigger in ipairs(unloadingStation.unloadTriggers) do
			if trigger.fillTypes[spec.extendFillType] ~= nil then
				for _, inputFillType in ipairs(spec.inputFillTypes) do
					trigger.fillTypes[inputFillType] = true
				end
			end
		end

		unloadingStation:updateSupportedFillTypes()
	end

	local storage = self.spec_husbandry.storage

	if storage ~= nil then
		for _, inputFillType in ipairs(spec.inputFillTypes) do
			storage.fillTypes[inputFillType] = true
			storage.capacities[inputFillType] = storage.capacities[spec.extendFillType]

			table.insert(storage.sortedFillTypes, inputFillType)

			storage.fillLevels[inputFillType] = 0
			storage.fillLevelsLastSynced[inputFillType] = 0

			table.sort(storage.sortedFillTypes)
		end
	end

	spec.manureFactor = self.xmlFile:getValue("placeable.husbandry.straw.manure#factor", 1)
	spec.isManureActive = self.xmlFile:getValue("placeable.husbandry.straw.manure#active", true)

	if self.isClient then
		local beddingPlane = FillPlane.new()

		if beddingPlane:load(self.components, self.xmlFile, "placeable.husbandry.straw.strawPlane", self.i3dMappings) then
			local linkNode = getParent(beddingPlane.node)
			local node = clone(beddingPlane.node, false, false, false)

			link(linkNode, node)

			if beddingPlane.colorChange then
				FillPlaneUtil.assignDefaultMaterials(node)
				FillPlaneUtil.setFillType(node, spec.inputFillTypes[1])
				setShaderParameter(node, "isCustomShape", 1, 0, 0, 0, false)
			end

			beddingPlane.node = node

			beddingPlane:setState(0)

			spec.beddingPlane = beddingPlane
		else
			beddingPlane:delete()
		end
	end

	spec.inputLitersPerHour = 0
	spec.outputLitersPerHour = 0
	spec.info = {}

	for _, inputFillType in ipairs(spec.inputFillTypes) do
		spec.info[inputFillType] = {
			text = "",
			title = g_fillTypeManager:getFillTypeTitleByIndex(inputFillType)
		}
	end
end

function PlaceableHusbandryBeddingMulti:onPostLoad(savegame)
	local spec_husbandryBedding = self.spec_husbandryBedding

	if spec_husbandryBedding ~= nil and spec_husbandryBedding.beddingPlane ~= nil then
		spec_husbandryBedding.beddingPlane:delete()

		spec_husbandryBedding.beddingPlane = nil
	end
end

function PlaceableHusbandryBeddingMulti:onDelete()
	local spec = self.spec_husbandryBeddingMulti

	if spec == nil then
		return
	end

	if spec.beddingPlane ~= nil then
		spec.beddingPlane:delete()

		spec.beddingPlane = nil
	end
end

function PlaceableHusbandryBeddingMulti:onPostFinalizePlacement()
	self:updatePlane()
end

function PlaceableHusbandryBeddingMulti:onReadStream(streamId, connection)
	self:updatePlane()
end

function PlaceableHusbandryBeddingMulti:updatePlaneMulti()
	local spec = self.spec_husbandryBeddingMulti

	if spec.beddingPlane ~= nil then
		local maxFillLevel = 0
		local activeFillType = spec.inputFillTypes[1]

		for _, inputFillType in ipairs(spec.inputFillTypes) do
			local fillLevel = self:getHusbandryFillLevel(inputFillType, nil)

			if fillLevel > 0 and maxFillLevel < fillLevel then
				activeFillType = inputFillType
				maxFillLevel = fillLevel
			end
		end

		local capacity = self:getHusbandryCapacity(activeFillType, nil)
		local fillLevel = self:getHusbandryFillLevel(activeFillType, nil)
		local factor = 0

		if capacity > 0 then
			factor = fillLevel / capacity
		end

		spec.beddingPlane:setState(factor)
	end
end

function PlaceableHusbandryBeddingMulti:onHusbandryFillLevelChanged(fillTypeIndex, delta)
	local spec = self.spec_husbandryBeddingMulti

	if table.hasElement(spec.inputFillTypes, fillTypeIndex) then
		self:updatePlane()
	end
end

function PlaceableHusbandryBeddingMulti:onHusbandryAnimalsUpdate(clusters)
	local spec = self.spec_husbandryBeddingMulti
	spec.inputLitersPerHour = 0
	spec.outputLitersPerHour = 0

	if self:getHusbandryFillLevel(spec.extendFillType) > 0 then
		return
	end

	for _, cluster in ipairs(clusters) do
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		if subType ~= nil then
			local straw = subType.input.straw

			if straw ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = straw:get(age) * 1.5
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.inputLitersPerHour = spec.inputLitersPerHour + litersPerDay / 24
			end

			local manure = subType.output.manure

			if manure ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = manure:get(age)
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.outputLitersPerHour = spec.outputLitersPerHour + litersPerDay / 24
			end
		end
	end
end

function PlaceableHusbandryBeddingMulti:updatePlane(superFunc)
	if superFunc ~= nil and type(superFunc) == "function" then
		superFunc(self)
	end

	self:updatePlaneMulti()
end

function PlaceableHusbandryBeddingMulti:updateProduction(superFunc, foodFactor)
	local factor = superFunc(self, foodFactor)
	local spec = self.spec_husbandryBeddingMulti

	if self:getHusbandryFillLevel(spec.extendFillType) > 0 then
		return factor
	end

	for _, inputFillType in ipairs(spec.inputFillTypes) do
		if self:getHusbandryFillLevel(inputFillType) > 0 then
			local freeCapacity = self:getHusbandryFreeCapacity(spec.outputFillType)

			if freeCapacity <= 0 then
				factor = factor * 0.8
			end
		end
	end

	return factor
end

function PlaceableHusbandryBeddingMulti:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local spec = self.spec_husbandryBeddingMulti

		if spec.inputLitersPerHour > 0 then
			local amount = spec.inputLitersPerHour * g_currentMission.environment.timeAdjustment
			local delta = 0

			for _, inputFillType in ipairs(spec.inputFillTypes) do
				local fillTypeDelta = amount - self:removeHusbandryFillLevel(self:getOwnerFarmId(), amount, inputFillType)
				amount = amount - fillTypeDelta
				delta = delta + fillTypeDelta

				if amount <= 0 then
					break
				end
			end

			if spec.outputLitersPerHour > 0 and delta > 0 then
				local liters = foodFactor * math.min(spec.outputLitersPerHour, delta) * g_currentMission.environment.timeAdjustment

				if liters > 0 then
					self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, spec.outputFillType, nil, ToolType.UNDEFINED, nil)
				end
			end

			self:updatePlane()
		end
	end

	local spec_husbandryBedding = self.spec_husbandryBedding

	if spec_husbandryBedding ~= nil then
		spec_husbandryBedding.inputLitersPerHour = 0
		spec_husbandryBedding.outputLitersPerHour = 0
	end

	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

function PlaceableHusbandryBeddingMulti:getConditionInfos(superFunc)
	local infos = superFunc(self)
	local spec = self.spec_husbandryBeddingMulti
	local maxFillLevel = 0
	local activeFillType = spec.inputFillTypes[1]

	for _, inputFillType in ipairs(spec.inputFillTypes) do
		local fillLevel = self:getHusbandryFillLevel(inputFillType)

		if fillLevel > 0 and maxFillLevel < fillLevel then
			activeFillType = inputFillType
			maxFillLevel = fillLevel
		end
	end

	if maxFillLevel > 0 then
		local extendFillType = g_fillTypeManager:getFillTypeByIndex(spec.extendFillType)
		local indexToUse = nil

		for i, info in ipairs(infos) do
			if info.title == extendFillType.title and info.value <= 0 then
				indexToUse = i

				break
			end
		end

		if indexToUse ~= nil then
			infos[indexToUse] = nil
			local fillType = g_fillTypeManager:getFillTypeByIndex(activeFillType)
			local capacity = self:getHusbandryCapacity(activeFillType)
			local ratio = 0

			if capacity > 0 then
				ratio = maxFillLevel / capacity
			end

			infos[indexToUse] = {
				invertedBar = false,
				title = fillType.title,
				value = maxFillLevel,
				ratio = ratio
			}
		end
	end

	return infos
end

function PlaceableHusbandryBeddingMulti:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_husbandryBeddingMulti

	for _, inputFillType in ipairs(spec.inputFillTypes) do
		local addInfo = true

		if pdlc_pumpsAndHosesPackIsLoaded then
			addInfo = inputFillType ~= FillType.SEPARATED_MANURE
		end

		if addInfo then
			local fillLevel = self:getHusbandryFillLevel(inputFillType)
			spec.info[inputFillType].text = string.format("%d l", fillLevel)

			table.insert(infoTable, spec.info[inputFillType])
		end
	end
end
