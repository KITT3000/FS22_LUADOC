PlaceableStorageBoxes = {
	MOD_DIRECTORY = g_currentModDirectory,
	MOD_NAME = g_currentModName,
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerXMLPaths = function (schema, basePath)
		schema:setXMLSpecializationType("StorageBoxes")
		schema:register(XMLValueType.NODE_INDEX, "placeable.disableStorageBoxes#node", "The disable storage boxes node")
		schema:register(XMLValueType.NODE_INDEX, "placeable.disableStorageBoxes.visual(?)#node", "The disable storage boxes visual node")
		schema:setXMLSpecializationType()
	end
}

function PlaceableStorageBoxes.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateStorageBoxes", PlaceableStorageBoxes.updateStorageBoxes)
end

function PlaceableStorageBoxes.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableStorageBoxes)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableStorageBoxes)
end

function PlaceableStorageBoxes:onLoad(savegame)
	self.spec_placeableStorageBoxes = self[("spec_%s.placeableStorageBoxes"):format(PlaceableStorageBoxes.MOD_NAME)]
	local spec = self.spec_placeableStorageBoxes
	spec.physicsNode = self.xmlFile:getValue("placeable.disableStorageBoxes#node", nil, self.components, self.i3dMappings)

	if spec.physicsNode ~= nil then
		spec.storageVisuals = {}
		local i = 0

		while true do
			local visualKey = ("placeable.disableStorageBoxes.visual(%d)"):format(i)

			if not self.xmlFile:hasProperty(visualKey) then
				break
			end

			local node = self.xmlFile:getValue(visualKey .. "#node", nil, self.components, self.i3dMappings)

			if node ~= nil then
				table.insert(spec.storageVisuals, node)
			end

			i = i + 1
		end
	end

	self:updateStorageBoxes()
end

function PlaceableStorageBoxes:onPostFinalizePlacement()
	self:updateStorageBoxes()
end

function PlaceableStorageBoxes:updateStorageBoxes()
	local spec = self.spec_placeableStorageBoxes

	if spec.physicsNode ~= nil then
		for _, node in ipairs(spec.storageVisuals) do
			setVisibility(node, false)
		end

		setVisibility(spec.physicsNode, false)
		removeFromPhysics(spec.physicsNode)
		setRigidBodyType(spec.physicsNode, RigidBodyType.NONE)
		setCollisionMask(spec.physicsNode, 0)
	end
end
