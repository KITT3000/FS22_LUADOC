EmergencyVehicle = {
	MOD_NAME = g_currentModName
}

function EmergencyVehicle.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("EmergencyVehicle")

	local warningLightKey = "vehicle.emergencyVehicle.warningLights.warningLight(?)"

	schema:register(XMLValueType.NODE_INDEX, warningLightKey .. "#node", "Link node")
	schema:register(XMLValueType.STRING, warningLightKey .. "#filename", "Warning light xml file")
	schema:register(XMLValueType.FLOAT, warningLightKey .. "#speed", "Warning light speed override")
	schema:register(XMLValueType.FLOAT, warningLightKey .. "#realLightRange", "Factor that is applied on real light range of the warning light", 1)
	schema:register(XMLValueType.INT, warningLightKey .. "#intensity", "Warning light intensity override")
	schema:register(XMLValueType.NODE_INDEX, warningLightKey .. ".realLight#node", "Real light node")
	schema:register(XMLValueType.NODE_INDEX, warningLightKey .. ".rotator#node", "Rotator node")
	schema:register(XMLValueType.BOOL, warningLightKey .. "#multiBlink", "Is multiblink light")
	BeaconLightManager.registerXMLPaths(schema, warningLightKey .. ".device")

	local emergencySoundGroupKey = "vehicle.emergencyVehicle.emergencySoundGroups.emergencySoundGroup(?)"

	schema:register(XMLValueType.STRING, emergencySoundGroupKey .. "#name", "Sound group name", nil, true)
	schema:register(XMLValueType.STRING, emergencySoundGroupKey .. "#toggleInputButton", "Toggle sound group input button", nil, true)
	schema:register(XMLValueType.STRING, emergencySoundGroupKey .. "#switchInputButton", "Switch sound group input button")
	schema:register(XMLValueType.STRING, emergencySoundGroupKey .. ".emergencySound(?)#name", "Sound name", nil, true)
	SoundManager.registerSampleXMLPaths(schema, emergencySoundGroupKey .. ".emergencySound(?)", "sound")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.emergencyVehicle.beaconLightHorn", "sound")

	local automaticLightTypesKey = "vehicle.emergencyVehicle.automaticLightTypes.automaticLightType(?)"

	schema:register(XMLValueType.INT, automaticLightTypesKey .. "#lightType", "Light type to control", nil, true)
	schema:register(XMLValueType.INT, automaticLightTypesKey .. "#correspondingLightType", "corresponding light type", nil, true)
	schema:register(XMLValueType.NODE_INDEX, automaticLightTypesKey .. ".movingTool(?)#node", "Moving tool node")
	schema:register(XMLValueType.INT, automaticLightTypesKey .. ".movingTool(?)#translationAxis", "Translation axis to validate")
	schema:register(XMLValueType.FLOAT, automaticLightTypesKey .. ".movingTool(?)#transMax", "Max. translation")
	schema:register(XMLValueType.FLOAT, automaticLightTypesKey .. ".movingTool(?)#transMin", "Min. translation")
	schema:register(XMLValueType.INT, automaticLightTypesKey .. ".movingTool(?)#rotationAxis", "Rotation axis to validate")
	schema:register(XMLValueType.ANGLE, automaticLightTypesKey .. ".movingTool(?)#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, automaticLightTypesKey .. ".movingTool(?)#rotMin", "Min. rotation")
	schema:setXMLSpecializationType()

	local warningLightXMLSchema = XMLSchema.new("warningLight")

	warningLightXMLSchema:register(XMLValueType.STRING, "warningLight.filename", "Path to i3d file", nil, true)
	warningLightXMLSchema:register(XMLValueType.NODE_INDEX, "warningLight.rootNode#node", "Root node")
	warningLightXMLSchema:register(XMLValueType.NODE_INDEX, "warningLight.rotator#node", "Node that is rotating")
	warningLightXMLSchema:register(XMLValueType.FLOAT, "warningLight.rotator#speed", "Rotating speed", 0.015)
	warningLightXMLSchema:register(XMLValueType.NODE_INDEX, "warningLight.light#node", "Visibility toggle node")
	warningLightXMLSchema:register(XMLValueType.NODE_INDEX, "warningLight.light#shaderNode", "Light control shader node")
	warningLightXMLSchema:register(XMLValueType.FLOAT, "warningLight.light#intensity", "Light intensity of shader node", 1000)
	warningLightXMLSchema:register(XMLValueType.BOOL, "warningLight.light#multiBlink", "Uses multiblink functionality", false)
	warningLightXMLSchema:register(XMLValueType.NODE_INDEX, "warningLight.realLight#node", "Real light source node")
	BeaconLightManager.registerXMLPaths(warningLightXMLSchema, "warningLight.device")

	EmergencyVehicle.warningLightXMLSchema = warningLightXMLSchema
end

function EmergencyVehicle.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RolePlayVehicle, specializations)
end

function EmergencyVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadEmergencySoundGroupFromXML", EmergencyVehicle.loadEmergencySoundGroupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadEmergencySoundFromXML", EmergencyVehicle.loadEmergencySoundFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getEmergencySoundGroupByToggleInput", EmergencyVehicle.getEmergencySoundGroupByToggleInput)
	SpecializationUtil.registerFunction(vehicleType, "getEmergencySoundGroupBySwitchInput", EmergencyVehicle.getEmergencySoundGroupBySwitchInput)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentEmergencySound", EmergencyVehicle.getCurrentEmergencySound)
	SpecializationUtil.registerFunction(vehicleType, "toggleCurrentEmergencySound", EmergencyVehicle.toggleCurrentEmergencySound)
	SpecializationUtil.registerFunction(vehicleType, "setEmergencySoundStateByIndex", EmergencyVehicle.setEmergencySoundStateByIndex)
	SpecializationUtil.registerFunction(vehicleType, "setEmergencyGroupCurrentSound", EmergencyVehicle.setEmergencyGroupCurrentSound)
	SpecializationUtil.registerFunction(vehicleType, "loadWarningLightFromXML", EmergencyVehicle.loadWarningLightFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onWarningLightI3DLoaded", EmergencyVehicle.onWarningLightI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "toggleWarningLights", EmergencyVehicle.toggleWarningLights)
	SpecializationUtil.registerFunction(vehicleType, "getWarningLightsState", EmergencyVehicle.getWarningLightsState)
	SpecializationUtil.registerFunction(vehicleType, "setWarningLightsState", EmergencyVehicle.setWarningLightsState)
	SpecializationUtil.registerFunction(vehicleType, "loadAutomaticLightTypeFromXML", EmergencyVehicle.loadAutomaticLightTypeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateAutomaticLightType", EmergencyVehicle.updateAutomaticLightType)
	SpecializationUtil.registerFunction(vehicleType, "isAutomaticLightTypeActivateable", EmergencyVehicle.isAutomaticLightTypeActivateable)
end

function EmergencyVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", EmergencyVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", EmergencyVehicle)
end

function EmergencyVehicle:onLoad(savegame)
	self.spec_emergencyVehicle = self[("spec_%s.emergencyVehicle"):format(EmergencyVehicle.MOD_NAME)]
	local spec = self.spec_emergencyVehicle
	spec.warningLightsState = false
	spec.hasRealBeaconLights = g_gameSettings:getValue("realBeaconLights")
	spec.warningLights = {}

	self.xmlFile:iterate("vehicle.emergencyVehicle.warningLights.warningLight", function (_, key)
		self:loadWarningLightFromXML(self.xmlFile, key)
	end)

	spec.emergencySoundGroups = {}
	spec.emergencySoundGroupsByToggleInput = {}
	spec.emergencySoundGroupsBySwitchInput = {}
	spec.emergencySounds = {}

	self.xmlFile:iterate("vehicle.emergencyVehicle.emergencySoundGroups.emergencySoundGroup", function (_, key)
		self:loadEmergencySoundGroupFromXML(self.xmlFile, key)
	end)

	if self.isClient then
		spec.beaconLightHornSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.emergencyVehicle.beaconLightHorn", "sound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	spec.automaticLightTypes = {}

	self.xmlFile:iterate("vehicle.emergencyVehicle.automaticLightTypes.automaticLightType", function (_, key)
		local entry = {}

		if self:loadAutomaticLightTypeFromXML(self.xmlFile, key, entry) then
			table.addElement(spec.automaticLightTypes, entry)
		end
	end)
end

function EmergencyVehicle:onPostLoad(savegame)
	local spec = self.spec_emergencyVehicle

	if #spec.warningLights == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", EmergencyVehicle)
	end

	if #spec.automaticLightTypes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", EmergencyVehicle)
	end
end

function EmergencyVehicle:onDelete()
	local spec = self.spec_emergencyVehicle

	if self.isClient then
		for _, soundGroup in ipairs(spec.emergencySoundGroups) do
			for _, emergencySound in ipairs(soundGroup.emergencySounds) do
				g_soundManager:deleteSample(emergencySound.sound)
			end
		end

		g_soundManager:deleteSample(spec.beaconLightHornSound)

		if spec.honkSampleBackup ~= nil then
			g_soundManager:deleteSample(spec.honkSampleBackup)
		end
	end
end

function EmergencyVehicle:onReadStream(streamId, connection)
	local spec = self.spec_emergencyVehicle
	local warningLightsActive = streamReadBool(streamId)

	self:setWarningLightsState(warningLightsActive, true)

	for _, soundGroup in ipairs(spec.emergencySoundGroups) do
		soundGroup.currentSoundIndex = streamReadUInt8(streamId)
	end

	for index in ipairs(spec.emergencySounds) do
		local isPlaying = streamReadBool(streamId)

		self:setEmergencySoundStateByIndex(index, isPlaying, true)
	end
end

function EmergencyVehicle:onWriteStream(streamId, connection)
	local spec = self.spec_emergencyVehicle

	streamWriteBool(streamId, spec.warningLightsState)

	for _, soundGroup in ipairs(spec.emergencySoundGroups) do
		streamWriteUInt8(streamId, soundGroup.currentSoundIndex)
	end

	for _, emergencySound in ipairs(spec.emergencySounds) do
		streamWriteBool(streamId, emergencySound.isPlaying)
	end
end

function EmergencyVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_emergencyVehicle

		if spec.warningLightsState then
			for _, warningLight in pairs(spec.warningLights) do
				if warningLight.rotatorNode ~= nil then
					rotate(warningLight.rotatorNode, 0, warningLight.speed * dt, 0)
				end

				if warningLight.realLightNode ~= nil and spec.hasRealBeaconLights and warningLight.multiBlink then
					local x, y, z, _ = getShaderParameter(warningLight.lightShaderNode or spec.beaconLights[1].lightShaderNode, "blinkOffset")
					local cTime_s = getShaderTimeSec()
					local alpha = MathUtil.clamp(math.sin(cTime_s * z) - math.max(cTime_s * z % ((x * 2 + y * 2) * math.pi) - (x * 2 - 1) * math.pi, 0) + 0.2, 0, 1)
					local r = warningLight.defaultColor[1]
					local g = warningLight.defaultColor[2]
					local b = warningLight.defaultColor[3]

					setLightColor(warningLight.realLightNode, r * alpha, g * alpha, b * alpha)

					for i = 0, getNumOfChildren(warningLight.realLightNode) - 1 do
						setLightColor(getChildAt(warningLight.realLightNode, i), r * alpha, g * alpha, b * alpha)
					end
				end
			end

			self:raiseActive()
		end
	end
end

function EmergencyVehicle:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_emergencyVehicle

	for _, automaticLightType in ipairs(spec.automaticLightTypes) do
		self:updateAutomaticLightType(automaticLightType)
	end
end

function EmergencyVehicle:onBeaconLightsVisibilityChanged(visibility)
	local spec = self.spec_emergencyVehicle
	local spec_honk = self.spec_honk

	if spec_honk == nil or spec.beaconLightHornSound == nil then
		return
	end

	if self.isClient then
		g_soundManager:stopSample(spec_honk.sample)
	end

	if spec.honkSampleBackup == nil then
		spec.honkSampleBackup = table.copy(spec_honk.sample, 2)
	end

	spec_honk.sample = nil
	spec_honk.sample = visibility and spec.beaconLightHornSound or spec.honkSampleBackup
end

function EmergencyVehicle:loadEmergencySoundGroupFromXML(xmlFile, key)
	local spec = self.spec_emergencyVehicle
	local name = xmlFile:getValue(key .. "#name")

	if name == nil or name == "" then
		Logging.xmlWarning(xmlFile, "EmergencyVehicle: Please define a name in '%s'", key)

		return
	end

	local soundGroup = {
		name = name
	}
	local toggleInputButtonStr = xmlFile:getValue(key .. "#toggleInputButton")

	if toggleInputButtonStr == nil then
		Logging.xmlWarning(xmlFile, "EmergencyVehicle: Please define 'toggleInputButton' in '%s'", key)

		return
	end

	soundGroup.toggleInputButton = InputAction[toggleInputButtonStr]

	if soundGroup.toggleInputButton == nil then
		Logging.xmlWarning(xmlFile, "EmergencyVehicle: Invalid toggle input button '%s' in '%s'", toggleInputButtonStr, key)

		return
	end

	soundGroup.currentSoundIndex = 0
	soundGroup.emergencySounds = {}

	xmlFile:iterate(key .. ".emergencySound", function (_, soundKey)
		local entry = {}

		if self:loadEmergencySoundFromXML(xmlFile, soundKey, entry) then
			table.addElement(soundGroup.emergencySounds, entry)

			spec.emergencySounds[entry.index] = entry
		end
	end)

	if #soundGroup.emergencySounds > 1 then
		local switchInputButtonStr = xmlFile:getValue(key .. "#switchInputButton")

		if switchInputButtonStr == nil then
			Logging.xmlWarning(xmlFile, "EmergencyVehicle: Please define 'switchInputButton' in '%s'", key)

			return
		end

		soundGroup.switchInputButton = InputAction[switchInputButtonStr]

		if soundGroup.switchInputButton == nil then
			Logging.xmlWarning(xmlFile, "EmergencyVehicle: Invalid switch input button '%s' in '%s'", switchInputButtonStr, key)

			return
		end
	end

	table.addElement(spec.emergencySoundGroups, soundGroup)

	spec.emergencySoundGroupsByToggleInput[soundGroup.toggleInputButton] = soundGroup

	if soundGroup.switchInputButton ~= nil then
		spec.emergencySoundGroupsBySwitchInput[soundGroup.switchInputButton] = soundGroup
	end
end

function EmergencyVehicle:loadEmergencySoundFromXML(xmlFile, key, entry)
	local spec = self.spec_emergencyVehicle
	entry.index = #spec.emergencySounds + 1
	entry.isPlaying = false

	if self.isClient then
		entry.sound = g_soundManager:loadSampleFromXML(xmlFile, key, "sound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	return true
end

function EmergencyVehicle:getEmergencySoundGroupByToggleInput(actionName)
	local spec = self.spec_emergencyVehicle

	return spec.emergencySoundGroupsByToggleInput[actionName]
end

function EmergencyVehicle:getEmergencySoundGroupBySwitchInput(actionName)
	local spec = self.spec_emergencyVehicle

	return spec.emergencySoundGroupsBySwitchInput[actionName]
end

function EmergencyVehicle:getCurrentEmergencySound(soundGroup)
	if soundGroup == nil or #soundGroup.emergencySounds == 0 then
		return nil
	end

	return soundGroup.emergencySounds[soundGroup.currentSoundIndex + 1]
end

function EmergencyVehicle:toggleCurrentEmergencySound(soundGroup)
	local currentEmergencySound = self:getCurrentEmergencySound(soundGroup)

	if currentEmergencySound ~= nil then
		self:setEmergencySoundStateByIndex(currentEmergencySound.index, not currentEmergencySound.isPlaying)
	end
end

function EmergencyVehicle:setEmergencySoundStateByIndex(index, state, noEventSend)
	local spec = self.spec_emergencyVehicle
	local emergencySound = spec.emergencySounds[index]

	if emergencySound == nil then
		return
	end

	if state ~= emergencySound.isPlaying then
		SetEmergencySoundEvent.sendEvent(self, index, state, noEventSend)

		emergencySound.isPlaying = state

		if state then
			if self.isClient then
				g_soundManager:playSample(emergencySound.sound)
			end
		else
			g_soundManager:stopSample(emergencySound.sound)
		end
	end
end

function EmergencyVehicle:setEmergencyGroupCurrentSound(actionName, index, noEventSend)
	if actionName == nil then
		return
	end

	local soundGroup = self:getEmergencySoundGroupBySwitchInput(actionName)
	local currentEmergencySound = self:getCurrentEmergencySound(soundGroup)

	if currentEmergencySound == nil or index == nil or soundGroup.currentSoundIndex == index then
		return
	end

	SetCurrentEmergencySoundEvent.sendEvent(self, actionName, index, noEventSend)

	local soundWasPlaying = currentEmergencySound.isPlaying

	if soundWasPlaying then
		self:setEmergencySoundStateByIndex(currentEmergencySound.index, false, true)
	end

	soundGroup.currentSoundIndex = index

	if soundWasPlaying then
		currentEmergencySound = self:getCurrentEmergencySound(soundGroup)

		if currentEmergencySound == nil then
			return
		end

		self:setEmergencySoundStateByIndex(currentEmergencySound.index, true, true)
	end
end

function EmergencyVehicle:loadWarningLightFromXML(xmlFile, key)
	local spec = self.spec_emergencyVehicle
	local warningLight = {
		node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	}

	if warningLight.node ~= nil then
		local lightXmlFilename = xmlFile:getValue(key .. "#filename")
		warningLight.speed = xmlFile:getValue(key .. "#speed")
		warningLight.realLightRange = xmlFile:getValue(key .. "#realLightRange", 1)
		warningLight.intensity = xmlFile:getValue(key .. "#intensity")

		if lightXmlFilename ~= nil then
			lightXmlFilename = Utils.getFilename(lightXmlFilename, self.baseDirectory)
			local warningLightXMLFile = XMLFile.load("warningLightXML", lightXmlFilename, EmergencyVehicle.warningLightXMLSchema)

			if warningLightXMLFile ~= nil then
				spec.xmlLoadingHandles[warningLightXMLFile] = true
				warningLight.xmlFile = warningLightXMLFile
				local i3dFilename = warningLightXMLFile:getValue("warningLight.filename")

				if i3dFilename ~= nil then
					warningLight.filename = Utils.getFilename(i3dFilename, self.baseDirectory)
					local sharedLoadRequestId = self:loadSubSharedI3DFile(warningLight.filename, false, false, self.onWarningLightI3DLoaded, self, warningLight)

					table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
				end
			end
		else
			warningLight.lightShaderNode = warningLight.node
			warningLight.realLightNode = xmlFile:getValue(key .. ".realLight#node", nil, self.components, self.i3dMappings)
			warningLight.rotatorNode = xmlFile:getValue(key .. ".rotator#node", nil, self.components, self.i3dMappings)
			warningLight.multiBlink = xmlFile:getValue(key .. "#multiBlink", false)
			warningLight.device = BeaconLightManager.loadDeviceFromXML(xmlFile, key .. ".device")

			if warningLight.realLightNode ~= nil then
				warningLight.defaultColor = {
					getLightColor(warningLight.realLightNode)
				}

				setVisibility(warningLight.realLightNode, false)

				warningLight.defaultLightRange = getLightRange(warningLight.realLightNode)

				setLightRange(warningLight.realLightNode, warningLight.defaultLightRange * warningLight.realLightRange)
			end

			table.insert(spec.warningLights, warningLight)
		end
	end
end

function EmergencyVehicle:onWarningLightI3DLoaded(i3dNode, failedReason, warningLight)
	local spec = self.spec_emergencyVehicle
	local xmlFile = warningLight.xmlFile

	if i3dNode ~= 0 then
		local rootNode = xmlFile:getValue("warningLight.rootNode#node", nil, i3dNode)
		local lightNode = xmlFile:getValue("warningLight.light#node", nil, i3dNode)
		local lightShaderNode = xmlFile:getValue("warningLight.light#shaderNode", nil, i3dNode)

		if rootNode ~= nil and (lightNode ~= nil or lightShaderNode ~= nil) then
			warningLight.rootNode = rootNode
			warningLight.lightNode = lightNode
			warningLight.lightShaderNode = lightShaderNode
			warningLight.realLightNode = xmlFile:getValue("warningLight.realLight#node", nil, i3dNode)
			warningLight.rotatorNode = xmlFile:getValue("warningLight.rotator#node", nil, i3dNode)
			warningLight.speed = xmlFile:getValue("warningLight.rotator#speed", warningLight.speed or 0.015)
			warningLight.intensity = xmlFile:getValue("warningLight.light#intensity", warningLight.intensity or 1000)
			warningLight.multiBlink = xmlFile:getValue("warningLight.light#multiBlink", false)
			warningLight.device = BeaconLightManager.loadDeviceFromXML(xmlFile, "warningLight.device")

			link(warningLight.node, rootNode)
			setTranslation(rootNode, 0, 0, 0)

			if warningLight.realLightNode ~= nil then
				warningLight.defaultColor = {
					getLightColor(warningLight.realLightNode)
				}

				setVisibility(warningLight.realLightNode, false)

				warningLight.defaultLightRange = getLightRange(warningLight.realLightNode)

				setLightRange(warningLight.realLightNode, warningLight.defaultLightRange * warningLight.realLightRange)
			end

			if lightNode ~= nil then
				setVisibility(lightNode, false)
			end

			if lightShaderNode ~= nil then
				local _, y, z, w = getShaderParameter(lightShaderNode, "lightControl")

				setShaderParameter(lightShaderNode, "lightControl", 0, y, z, w, false)
			end

			if warningLight.speed > 0 then
				local rot = math.random(0, math.pi * 2)

				if warningLight.rotatorNode ~= nil then
					setRotation(warningLight.rotatorNode, 0, rot, 0)
				end
			end

			table.insert(spec.warningLights, warningLight)
		end

		delete(i3dNode)
	end

	xmlFile:delete()

	warningLight.xmlFile = nil
	spec.xmlLoadingHandles[xmlFile] = nil
end

function EmergencyVehicle:toggleWarningLights()
	self:setWarningLightsState(not self:getWarningLightsState())
end

function EmergencyVehicle:getWarningLightsState()
	local spec = self.spec_emergencyVehicle

	return spec.warningLightsState
end

function EmergencyVehicle:setWarningLightsState(state, noEventSend)
	local spec = self.spec_emergencyVehicle

	if state ~= spec.warningLightsState then
		SetWarningLightsEvent.sendEvent(self, state, noEventSend)

		spec.warningLightsState = state
		local isActiveForInput = self:getIsActiveForInput(true)

		for _, warningLight in pairs(spec.warningLights) do
			if spec.hasRealBeaconLights and warningLight.realLightNode ~= nil then
				setVisibility(warningLight.realLightNode, state)
			end

			if warningLight.lightNode ~= nil then
				setVisibility(warningLight.lightNode, state)
			end

			if warningLight.lightShaderNode ~= nil then
				local value = 1 * warningLight.intensity

				if not state then
					value = 0
				end

				local _, y, z, w = getShaderParameter(warningLight.lightShaderNode, "lightControl")

				setShaderParameter(warningLight.lightShaderNode, "lightControl", value, y, z, w, false)
			end

			if isActiveForInput then
				local device = warningLight.device

				if device ~= nil then
					if state then
						device.deviceId = g_beaconLightManager:activateBeaconLight(device.mode, device.numLEDScale, device.rpm, device.brightnessScale)
					elseif device.deviceId ~= nil then
						g_beaconLightManager:deactivateBeaconLight(device.deviceId)

						device.deviceId = nil
					end
				end
			end
		end
	end
end

function EmergencyVehicle:loadAutomaticLightTypeFromXML(xmlFile, key, automaticLightType)
	local lightType = xmlFile:getValue(key .. "#lightType")

	if lightType == nil or lightType == "" then
		Logging.xmlWarning(xmlFile, "EmergencyVehicle: Please define a lightType in '%s'", key)

		return false
	end

	local correspondingLightType = xmlFile:getValue(key .. "#correspondingLightType")

	if correspondingLightType == nil or correspondingLightType == "" then
		Logging.xmlWarning(xmlFile, "EmergencyVehicle: Please define a correspondingLightType in '%s'", key)

		return false
	end

	automaticLightType.lightType = lightType
	automaticLightType.correspondingLightType = correspondingLightType
	automaticLightType.movingTools = {}

	self.xmlFile:iterate(key .. ".movingTool", function (_, movingToolkey)
		local node = xmlFile:getValue(movingToolkey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local movingToolRef = {
				node = node,
				translationAxis = xmlFile:getValue(movingToolkey .. "#translationAxis")
			}

			if movingToolRef.translationAxis ~= nil then
				movingToolRef.transMin = xmlFile:getValue(movingToolkey .. "#transMin")
				movingToolRef.transMax = xmlFile:getValue(movingToolkey .. "#transMax")
			end

			movingToolRef.rotationAxis = xmlFile:getValue(movingToolkey .. "#rotationAxis")

			if movingToolRef.rotationAxis ~= nil then
				movingToolRef.rotMin = xmlFile:getValue(movingToolkey .. "#rotMin")
				movingToolRef.rotMax = xmlFile:getValue(movingToolkey .. "#rotMax")
			end

			table.addElement(automaticLightType.movingTools, movingToolRef)
		end
	end)

	return true
end

function EmergencyVehicle:updateAutomaticLightType(automaticLightType)
	local lightsTypesMask = self:getLightsTypesMask()
	local isLightTypeActive = bitAND(lightsTypesMask, 2^automaticLightType.lightType) ~= 0
	local isCorrespondingLightTypeActive = self:isAutomaticLightTypeActivateable(automaticLightType) and bitAND(lightsTypesMask, 2^automaticLightType.correspondingLightType) ~= 0

	if isLightTypeActive ~= isCorrespondingLightTypeActive then
		local bitOP = isLightTypeActive and bitXOR or bitOR
		lightsTypesMask = bitOP(lightsTypesMask, 2^automaticLightType.lightType)

		self:setLightsTypesMask(lightsTypesMask, true)
	end
end

function EmergencyVehicle:isAutomaticLightTypeActivateable(automaticLightType)
	if automaticLightType.movingTools ~= nil then
		for _, movingToolRef in ipairs(automaticLightType.movingTools) do
			local movingTool = self:getMovingToolByNode(movingToolRef.node)

			if movingTool ~= nil then
				if movingToolRef.translationAxis ~= nil then
					local curTrans = movingTool.curTrans[movingToolRef.translationAxis]

					if curTrans < movingToolRef.transMin or movingToolRef.transMax < curTrans then
						return false
					end
				end

				if movingToolRef.rotationAxis ~= nil then
					local curRot = movingTool.curRot[movingToolRef.rotationAxis]

					if curRot < movingToolRef.rotMin or movingToolRef.rotMax < curRot then
						return false
					end
				end
			end
		end
	end

	return true
end

function EmergencyVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_emergencyVehicle

		self:clearActionEventsTable(spec.actionEvents)

		if self:getIsActiveForInput(true, true) then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.RP_WARNING_LIGHTS_TOGGLE, self, EmergencyVehicle.actionEventToggleWarningLights, false, true, false, true, nil)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)

			for _, soundGroup in ipairs(spec.emergencySoundGroups) do
				_, actionEventId = self:addActionEvent(spec.actionEvents, soundGroup.toggleInputButton, self, EmergencyVehicle.actionEventToggleEmergenySoundGroup, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventTextVisibility(actionEventId, true)

				if soundGroup.switchInputButton ~= nil then
					_, actionEventId = self:addActionEvent(spec.actionEvents, soundGroup.switchInputButton, self, EmergencyVehicle.actionEventSwitchEmergenySoundGroup, false, true, false, true, nil)

					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					g_inputBinding:setActionEventTextVisibility(actionEventId, true)
				end
			end
		end
	end
end

function EmergencyVehicle:actionEventToggleWarningLights(actionName, inputValue, callbackState, isAnalog)
	self:toggleWarningLights()
end

function EmergencyVehicle:actionEventToggleEmergenySoundGroup(actionName, inputValue, callbackState, isAnalog)
	local soundGroup = self:getEmergencySoundGroupByToggleInput(actionName)

	if soundGroup == nil then
		return
	end

	self:toggleCurrentEmergencySound(soundGroup)
end

function EmergencyVehicle:actionEventSwitchEmergenySoundGroup(actionName, inputValue, callbackState, isAnalog)
	local soundGroup = self:getEmergencySoundGroupBySwitchInput(actionName)

	if soundGroup == nil then
		return
	end

	local currentSoundIndex = soundGroup.currentSoundIndex + 1

	if currentSoundIndex >= #soundGroup.emergencySounds then
		currentSoundIndex = 0
	end

	self:setEmergencyGroupCurrentSound(actionName, currentSoundIndex)
end
