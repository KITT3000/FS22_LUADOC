PlaceablePalletizer = {
	MOD_DIRECTORY = g_currentModDirectory,
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".placeablePalletizer",
	initSpecialization = function ()
	end,
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerXMLPaths = function (schema, basePath)
		schema:setXMLSpecializationType("PlaceablePalletizer")
		schema:register(XMLValueType.STRING, "placeable.palletizer#xmlFilename", "The palletizer xml")
		schema:setXMLSpecializationType()
	end,
	registerSavegameXMLPaths = function (schema, basePath)
		StrawHarvestPalletizer.registerSavegameXMLPaths(schema, basePath .. ".palletizer")
	end,
	registerEventListeners = function (placeableType)
		SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePalletizer)
		SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceablePalletizer)
		SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePalletizer)
		SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceablePalletizer)
		SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceablePalletizer)
		SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceablePalletizer)
	end
}

function PlaceablePalletizer:onLoad(savegame)
	self.spec_placeablePalletizer = self[("spec_%s.placeablePalletizer"):format(PlaceablePalletizer.MOD_NAME)]
	local spec = self.spec_placeablePalletizer
	local xmlPelletizerFilename = self.xmlFile:getValue("placeable.palletizer#xmlFilename")

	if xmlPelletizerFilename ~= nil then
		spec.palletizer = StrawHarvestPalletizer.new(self.isServer, self.isClient)
		local x = self.position.x
		local y = self.position.y
		local z = self.position.z
		local rx = self.rotation.x
		local ry = self.rotation.y
		local rz = self.rotation.z

		if not spec.palletizer:load(Utils.getFilename(xmlPelletizerFilename, self.baseDirectory), x, y, z, rx, ry, rz, "palletizer") then
			Logging.xmlWarning(self.configFileName, "Could not create palletizer!")
		end
	end
end

function PlaceablePalletizer:onPostLoad(savegame)
	local spec = self.spec_placeablePalletizer

	if savegame ~= nil and spec.palletizer ~= nil then
		spec.palletizer:loadFromXMLFile(savegame.xmlFile, savegame.key .. "." .. PlaceablePalletizer.SPEC_NAME .. ".palletizer")
	end
end

function PlaceablePalletizer:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_placeablePalletizer

	if spec.palletizer ~= nil then
		spec.palletizer:saveToXMLFile(xmlFile, key .. ".palletizer", usedModNames)
	end
end

function PlaceablePalletizer:onDelete()
	local spec = self.spec_placeablePalletizer

	if spec.palletizer ~= nil then
		spec.palletizer:delete()
	end
end

function PlaceablePalletizer:onReadStream(streamId, connection)
	local spec = self.spec_placeablePalletizer

	if connection:getIsServer() and spec.palletizer ~= nil then
		local palletizerId = NetworkUtil.readNodeObjectId(streamId)

		spec.palletizer:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.palletizer, palletizerId)
	end
end

function PlaceablePalletizer:onWriteStream(streamId, connection)
	local spec = self.spec_placeablePalletizer

	if not connection:getIsServer() and spec.palletizer ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.palletizer))
		spec.palletizer:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.palletizer)
	end
end

function PlaceablePalletizer:onPostFinalizePlacement()
	local spec = self.spec_placeablePalletizer

	if spec.palletizer ~= nil then
		spec.palletizer:setOwnerFarmId(self:getOwnerFarmId(), true)
		spec.palletizer:register(true)
		spec.palletizer:finalizePlacement()
	end
end
