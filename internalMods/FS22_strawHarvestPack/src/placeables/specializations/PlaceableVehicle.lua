PlaceableVehicle = {
	MOD_DIRECTORY = g_currentModDirectory,
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".placeableVehicle"
}
local vehicleBasePath = nil

function PlaceableVehicle.initSpecialization()
end

function PlaceableVehicle.postInitSpecialization()
	local schemaSavegame = Placeable.xmlSchemaSavegame

	schemaSavegame:setXMLSpecializationType("PlaceableVehicle")

	for _, vehicleSchemaValue in ipairs(Vehicle.xmlSchemaSavegame.orderedPaths) do
		if string.startsWith(vehicleSchemaValue.path, "vehicles.vehicle(?)") then
			local placeablePath = string.gsub(vehicleSchemaValue.path, "vehicles.vehicle%(%?%)", vehicleBasePath)

			schemaSavegame:register(vehicleSchemaValue.valueTypeId, placeablePath, vehicleSchemaValue.description, vehicleSchemaValue.defaultValue, vehicleSchemaValue.isRequired)
		end
	end

	schemaSavegame:setXMLSpecializationType()
end

function PlaceableVehicle.prerequisitesPresent(specializations)
	return true
end

function PlaceableVehicle.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PlaceableVehicle")
	schema:register(XMLValueType.STRING, "placeable.vehicle#xmlFilename", "The vehicle xml")
	schema:setXMLSpecializationType()
end

function PlaceableVehicle.registerSavegameXMLPaths(schema, basePath)
	vehicleBasePath = basePath .. ".vehicle"
end

function PlaceableVehicle.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "preSaveToXMLFile", PlaceableVehicle.preSaveToXMLFile)
	SpecializationUtil.registerFunction(placeableType, "onLoadedVehicle", PlaceableVehicle.onLoadedVehicle)
end

function PlaceableVehicle.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableVehicle)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableVehicle)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableVehicle)
	SpecializationUtil.registerEventListener(placeableType, "onUpdateTick", PlaceableVehicle)
end

function PlaceableVehicle:onLoad(savegame)
	self.spec_placeableVehicle = self[("spec_%s.placeableVehicle"):format(PlaceableVehicle.MOD_NAME)]
	local spec = self.spec_placeableVehicle
	spec.vehiclePlaced = false
	spec.vehicleAddedToPhysics = false

	if self.isServer then
		local filename = self.xmlFile:getValue("placeable.vehicle#xmlFilename")

		if filename ~= nil then
			spec.vehicleSaveGameData = nil

			if savegame ~= nil then
				spec.savegame = {
					key = savegame.key,
					xmlFile = XMLFile.load("PlaceableVehicleSavegameXML", savegame.xmlFile.filename, savegame.xmlFile.schema)
				}
				local key = spec.savegame.key .. "." .. PlaceableVehicle.SPEC_NAME
				spec.vehicleSaveGameData = {
					xmlFile = spec.savegame.xmlFile,
					key = key .. ".vehicle",
					resetVehicles = spec.savegame.resetVehicles
				}
			end

			local location = {
				x = self.position.x,
				z = self.position.z,
				yRot = self.rotation.y
			}

			VehicleLoadingUtil.loadVehicle(Utils.getFilename(filename, self.baseDirectory), location, false, 0, Vehicle.PROPERTY_STATE_OWNED, self:getOwnerFarmId(), nil, spec.vehicleSaveGameData, self.onLoadedVehicle, self, nil)
		end
	end
end

function PlaceableVehicle:preSaveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_placeableVehicle

	if spec.vehicle ~= nil and spec.vehicle.preSaveToXMLFile ~= nil then
		spec.vehicle:preSaveToXMLFile(xmlFile, key .. ".vehicle", usedModNames)
	end
end

function PlaceableVehicle:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_placeableVehicle

	if spec.vehicle ~= nil then
		spec.vehicle:saveToXMLFile(xmlFile, key .. ".vehicle", usedModNames)
	end
end

function PlaceableVehicle:onLoadedVehicle(vehicle, vehicleLoadState, arguments)
	if vehicle == nil then
		return
	end

	if vehicleLoadState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		Logging.xmlWarning(self.configFileName, "Could not create placeable vehicle!")
		vehicle:delete()

		return
	end

	local spec = self.spec_placeableVehicle
	spec.vehicle = vehicle

	if spec.vehicle.isAddedToPhysics then
		spec.vehicle:removeFromPhysics()
	end

	spec.vehicleAddedToPhysics = false

	if spec.savegame ~= nil then
		spec.savegame.xmlFile:delete()

		spec.savegame = nil
	end
end

function PlaceableVehicle:onDelete()
	local spec = self.spec_placeableVehicle

	if spec ~= nil and spec.vehicle ~= nil then
		g_currentMission:removeVehicle(spec.vehicle, true)
	end
end

function PlaceableVehicle:onUpdateTick(dt)
	if not self.isServer then
		return
	end

	local spec = self.spec_placeableVehicle

	if not spec.vehiclePlaced then
		return
	end

	if not spec.vehicleAddedToPhysics and spec.vehicle ~= nil then
		spec.vehicle:addToPhysics()

		spec.vehicleAddedToPhysics = true
	end
end

function PlaceableVehicle:onPostFinalizePlacement()
	local spec = self.spec_placeableVehicle
	spec.vehiclePlaced = true
end
