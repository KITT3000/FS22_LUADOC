sh_overwrite = {}
local originalFunctions = {}

local function inj_sellingStation_load(object, superFunc, ...)
	if not superFunc(object, ...) then
		return false
	end

	local acceptsStraw = object.acceptedFillTypes[FillType.STRAW]
	local acceptsHay = object.acceptedFillTypes[FillType.DRYGRASS_WINDROW]

	local function addPelletFillType(fillTypeIndex)
		for _, trigger in ipairs(object.unloadTriggers) do
			trigger.fillTypes[fillTypeIndex] = true
		end

		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

		object:addAcceptedFillType(fillTypeIndex, fillType.pricePerLiter, true, false)
	end

	if acceptsStraw then
		addPelletFillType(FillType.STRAW_PELLETS)
	end

	if acceptsHay then
		addPelletFillType(FillType.HAY_PELLETS)
	end

	if acceptsStraw or acceptsHay then
		object:initPricingDynamics()
	end

	return true
end

local function inj_mixerWagon_onLoad(vehicle, savegame)
	local spec = vehicle.spec_mixerWagon

	for _, fillUnit in pairs(vehicle:getFillUnits()) do
		if fillUnit.supportedFillTypes[FillType.DRYGRASS_WINDROW] then
			fillUnit.supportedFillTypes[FillType.HAY_PELLETS] = true
		end

		if fillUnit.supportedFillTypes[FillType.STRAW] then
			fillUnit.supportedFillTypes[FillType.STRAW_PELLETS] = true
		end
	end

	for _, mixerWagonFillType in ipairs(spec.mixerWagonFillTypes) do
		if mixerWagonFillType.fillTypes[FillType.DRYGRASS_WINDROW] ~= nil then
			mixerWagonFillType.fillTypes[FillType.HAY_PELLETS] = true
			spec.fillTypeToMixerWagonFillType[FillType.HAY_PELLETS] = mixerWagonFillType
		end

		if mixerWagonFillType.fillTypes[FillType.STRAW] ~= nil then
			mixerWagonFillType.fillTypes[FillType.STRAW_PELLETS] = true
			spec.fillTypeToMixerWagonFillType[FillType.STRAW_PELLETS] = mixerWagonFillType
		end
	end
end

local function inj_mixerWagon_addFillUnitFillLevel(vehicle, injSuperFunc, superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local delta = injSuperFunc(vehicle, superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)

	if fillTypeIndex == FillType.STRAW_PELLETS or fillTypeIndex == FillType.HAY_PELLETS then
		delta = delta * 0.25
	end

	return delta
end

local function inj_unloadingStation_addFillLevelFromTool(unloadingStation, superFunc, farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
	local delta = superFunc(unloadingStation, farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)

	if unloadingStation.owningPlaceable == nil then
		return delta
	end

	if unloadingStation.owningPlaceable.spec_husbandryFood ~= nil and (fillType == FillType.STRAW_PELLETS or fillType == FillType.HAY_PELLETS) then
		delta = delta * 0.25
	end

	return delta
end

local function inj_placeableHusbandryFood_addFood(placeableHusbandryFood, superFunc, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local delta = superFunc(placeableHusbandryFood, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)

	if fillTypeIndex == FillType.STRAW_PELLETS or fillTypeIndex == FillType.HAY_PELLETS then
		delta = delta * 0.25
	end

	return delta
end

local function inj_getFillTypesFromXML(animalFoodSystem, superFunc, fillTypes, usedFillTypes, xmlFile, key)
	if not superFunc(animalFoodSystem, fillTypes, usedFillTypes, xmlFile, key) then
		return false
	end

	for _, fillTypeIndex in ipairs(fillTypes) do
		if fillTypeIndex == FillType.STRAW then
			table.addElement(fillTypes, FillType.STRAW_PELLETS)
		end

		if fillTypeIndex == FillType.DRYGRASS_WINDROW then
			table.addElement(fillTypes, FillType.HAY_PELLETS)
		end
	end

	return true
end

local function inj_placeable_saveToXMLFile(placeable, superFunc, xmlFile, key, usedModNames, ...)
	for id, spec in pairs(placeable.specializations) do
		local name = placeable.specializationNames[id]

		if spec.preSaveToXMLFile ~= nil then
			spec.preSaveToXMLFile(placeable, xmlFile, key .. "." .. name, usedModNames)
		end
	end

	superFunc(placeable, xmlFile, key, usedModNames, ...)
end

local function inj_vehicle_saveToXMLFile(vehicle, superFunc, xmlFile, key, usedModNames, ...)
	for id, spec in pairs(vehicle.specializations) do
		local name = vehicle.specializationNames[id]

		if spec.preSaveToXMLFile ~= nil then
			spec.preSaveToXMLFile(vehicle, xmlFile, key .. "." .. name, usedModNames)
		end
	end

	superFunc(vehicle, xmlFile, key, usedModNames, ...)
end

function sh_overwrite.init()
	sh_overwrite.overwrittenFunction(SellingStation, "load", inj_sellingStation_load)
	sh_overwrite.appendedFunction(MixerWagon, "onLoad", inj_mixerWagon_onLoad)
	sh_overwrite.overwrittenFunction(MixerWagon, "addFillUnitFillLevel", inj_mixerWagon_addFillUnitFillLevel)
	sh_overwrite.overwrittenFunction(AnimalFoodSystem, "getFillTypesFromXML", inj_getFillTypesFromXML)
	sh_overwrite.overwrittenFunction(UnloadingStation, "addFillLevelFromTool", inj_unloadingStation_addFillLevelFromTool)
	sh_overwrite.overwrittenFunction(PlaceableHusbandryFood, "addFood", inj_placeableHusbandryFood_addFood)
	sh_overwrite.overwrittenFunction(Placeable, "saveToXMLFile", inj_placeable_saveToXMLFile)
	sh_overwrite.overwrittenFunction(Vehicle, "saveToXMLFile", inj_vehicle_saveToXMLFile)
end

function sh_overwrite.load()
end

function sh_overwrite.validateTypes(typeManager, specializationManager, modDirectory, modName)
end

local function storeOriginalFunction(target, name)
	if not GS_IS_CONSOLE_VERSION then
		return
	end

	if originalFunctions[target] == nil then
		originalFunctions[target] = {}
	end

	if originalFunctions[target][name] == nil then
		originalFunctions[target][name] = target[name]
	end
end

function sh_overwrite.overwrittenFunction(target, name, newFunc)
	storeOriginalFunction(target, name)

	target[name] = Utils.overwrittenFunction(target[name], newFunc)
end

function sh_overwrite.appendedFunction(target, name, newFunc)
	storeOriginalFunction(target, name)

	target[name] = Utils.appendedFunction(target[name], newFunc)
end

function sh_overwrite.prependedFunction(target, name, newFunc)
	storeOriginalFunction(target, name)

	target[name] = Utils.prependedFunction(target[name], newFunc)
end

function sh_overwrite.resetOriginalFunctions()
	for target, functions in pairs(originalFunctions) do
		for name, func in pairs(functions) do
			target[name] = func
		end
	end
end
