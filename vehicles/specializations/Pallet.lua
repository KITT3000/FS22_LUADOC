Pallet = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Pallet")
		schema:register(XMLValueType.INT, "vehicle.pallet#fillUnitIndex", "Fill unit index", 1)
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet#node", "Root visual pallet node")
		schema:register(XMLValueType.INT, "vehicle.pallet.content(?)#fillUnitIndex", "Fill unit index for this content", "pallet#fillUnitIndex")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#node", "Object node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#tensionBeltNode", "Object used for tension belt calculations")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.pallet.sounds", "unload")
		schema:setXMLSpecializationType()
	end,
	registerFunctions = function (vehicleType)
	end
}

function Pallet.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMeshNodes", Pallet.getMeshNodes)
end

function Pallet.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pallet)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Pallet)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Pallet)
end

function Pallet:onLoad(savegame)
	local spec = self.spec_pallet
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.pallet#fillUnitIndex", 1)
	spec.node = self.xmlFile:getValue("vehicle.pallet#node", nil, self.components, self.i3dMappings)
	spec.contents = {}

	self.xmlFile:iterate("vehicle.pallet.content", function (_, contentKey)
		local content = {
			objects = {},
			fillUnitIndex = self.xmlFile:getValue(contentKey .. "#fillUnitIndex", spec.fillUnitIndex)
		}

		self.xmlFile:iterate(contentKey .. ".object", function (index, key)
			local object = {
				node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
			}

			if object.node ~= nil then
				object.tensionBeltNode = self.xmlFile:getValue(key .. "#tensionBeltNode", nil, self.components, self.i3dMappings)
				object.isActive = false

				setVisibility(object.node, object.isActive)
				table.insert(content.objects, object)
			end
		end)

		if #content.objects > 0 then
			content.numObjects = #content.objects

			table.insert(spec.contents, content)
		end
	end)

	spec.tensionBeltMeshes = {
		spec.node
	}
	spec.tensionBeltMeshesDirty = false

	if self.isClient then
		spec.samples = {
			unload = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.pallet.sounds", "unload", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
end

function Pallet:onDelete()
	if self.isClient then
		local spec = self.spec_pallet

		g_soundManager:deleteSamples(spec.samples)
	end

	g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
end

function Pallet:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_pallet

	for i = 1, #spec.contents do
		local content = spec.contents[i]

		if content.fillUnitIndex == fillUnitIndex then
			local fillLevelPct = self:getFillUnitFillLevelPercentage(fillUnitIndex)
			local visibleIndex = math.floor(content.numObjects * fillLevelPct)

			if visibleIndex == 0 and fillLevelPct then
				visibleIndex = 1
			end

			for j = 1, #content.objects do
				local object = content.objects[j]
				local isActive = j <= visibleIndex

				if object.isActive ~= isActive then
					local unloading = object.isActive and not isActive

					if unloading and self.isClient then
						g_soundManager:playSample(spec.samples.unload)
					end

					object.isActive = isActive

					setVisibility(object.node, object.isActive)

					spec.tensionBeltMeshesDirty = true
				end
			end
		end
	end
end

function Pallet:getMeshNodes(superFunc)
	local spec = self.spec_pallet

	if spec.tensionBeltMeshesDirty then
		spec.tensionBeltMeshes = {}

		if spec.node ~= nil then
			table.insert(spec.tensionBeltMeshes, spec.node)
		end

		for i = 1, #spec.contents do
			local content = spec.contents[i]

			for j = 1, #content.objects do
				local object = content.objects[j]

				if object.isActive then
					table.insert(spec.tensionBeltMeshes, object.tensionBeltNode or object.node)
				end
			end
		end
	end

	if #spec.tensionBeltMeshes > 0 then
		return spec.tensionBeltMeshes
	end

	return superFunc(self)
end
