AttackNozzleVehicle = {
	MOD_NAME = g_currentModName,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("AttackNozzleVehicle")

		local attackNozzleKey = "vehicle.emergencyVehicle.attackNozzle"

		SoundManager.registerSampleXMLPaths(schema, attackNozzleKey .. ".sounds", "extinguishing")
		EffectManager.registerEffectXMLPaths(schema, attackNozzleKey .. ".effects")

		local raycastNodeKey = attackNozzleKey .. ".raycastNodes.raycast(?)"

		schema:register(XMLValueType.NODE_INDEX, raycastNodeKey .. "#node", "Raycast node")
		schema:register(XMLValueType.FLOAT, raycastNodeKey .. "#actionDistance", "Action distance to extinguish fire", 50)
		schema:register(XMLValueType.FLOAT, attackNozzleKey .. "#extinguishMultiplier", "Multiplier for fire extinguishing", 5)
		schema:register(XMLValueType.FLOAT, attackNozzleKey .. "#foldMinLimit", "Fold min. time", 0)
		schema:register(XMLValueType.FLOAT, attackNozzleKey .. "#foldMaxLimit", "Fold max. time", 1)
		schema:setXMLSpecializationType()
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(EmergencyVehicle, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
}

function AttackNozzleVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAttackNozzleRaycastFromXML", AttackNozzleVehicle.loadAttackNozzleRaycastFromXML)
	SpecializationUtil.registerFunction(vehicleType, "raycastCallback", AttackNozzleVehicle.raycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "extinguishFire", AttackNozzleVehicle.extinguishFire)
end

function AttackNozzleVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", AttackNozzleVehicle.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", AttackNozzleVehicle.getTurnedOnNotAllowedWarning)
end

function AttackNozzleVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttackNozzleVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AttackNozzleVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttackNozzleVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttackNozzleVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", AttackNozzleVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", AttackNozzleVehicle)
end

function AttackNozzleVehicle:onLoad(savegame)
	self.spec_attackNozzleVehicle = self[("spec_%s.attackNozzleVehicle"):format(AttackNozzleVehicle.MOD_NAME)]
	local spec = self.spec_attackNozzleVehicle
	local attackNozzleKey = "vehicle.emergencyVehicle.attackNozzle"
	spec.extinguishMultiplier = self.xmlFile:getValue(attackNozzleKey .. "#extinguishMultiplier", 5)
	spec.currentRaycastIndex = 1
	spec.raycastNodes = {}

	self.xmlFile:iterate(attackNozzleKey .. ".raycastNodes.raycast", function (_, key)
		local raycast = {}

		if self:loadAttackNozzleRaycastFromXML(self.xmlFile, key, raycast) then
			table.addElement(spec.raycastNodes, raycast)
		end
	end)

	spec.foldMinLimit = self.xmlFile:getValue(attackNozzleKey .. "#foldMinLimit", 0)
	spec.foldMaxLimit = self.xmlFile:getValue(attackNozzleKey .. "#foldMaxLimit", 1)

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, attackNozzleKey .. ".effects", self.components, self, self.i3dMappings)
		spec.sample = g_soundManager:loadSampleFromXML(self.xmlFile, attackNozzleKey .. ".sounds", "extinguishing", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)

		g_effectManager:setFillType(spec.effects, FillType.WATER)
	end
end

function AttackNozzleVehicle:onPostLoad(savegame)
	local spec = self.spec_attackNozzleVehicle

	if #spec.raycastNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", AttackNozzleVehicle)
	end
end

function AttackNozzleVehicle:onDelete()
	local spec = self.spec_attackNozzleVehicle

	g_effectManager:deleteEffects(spec.effects)
	g_soundManager:deleteSample(spec.sample)
end

function AttackNozzleVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attackNozzleVehicle
	local isExtinguishing = self:getIsTurnedOn()

	if not isExtinguishing or not self.isServer then
		return
	end

	if spec.lastHitFire == nil then
		local raycast = spec.raycastNodes[spec.currentRaycastIndex]

		self:extinguishFire(raycast, dt)

		spec.currentRaycastIndex = spec.currentRaycastIndex + 1

		if spec.currentRaycastIndex > #spec.raycastNodes then
			spec.currentRaycastIndex = 1
		end
	else
		spec.lastHitFire:extinguish(dt, spec.extinguishMultiplier)

		spec.lastHitFire = nil
	end

	self:raiseActive()
end

function AttackNozzleVehicle:onTurnedOn()
	local spec = self.spec_attackNozzleVehicle

	if self.isClient then
		if spec.sample ~= nil then
			g_soundManager:playSample(spec.sample)
		end

		g_effectManager:startEffects(spec.effects)
	end
end

function AttackNozzleVehicle:onTurnedOff()
	local spec = self.spec_attackNozzleVehicle

	if self.isClient then
		if spec.sample ~= nil then
			g_soundManager:stopSample(spec.sample)
		end

		g_effectManager:resetEffects(spec.effects)
	end
end

function AttackNozzleVehicle:loadAttackNozzleRaycastFromXML(xmlFile, key, raycast)
	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node == nil then
		Logging.xmlWarning(xmlFile, "AttackNozzleVehicle: Please define a raycast node in '%s'", key)

		return false
	end

	raycast.node = node
	raycast.actionDistance = xmlFile:getValue(key .. "#actionDistance", 50)

	return true
end

function AttackNozzleVehicle:extinguishFire(raycast, dt)
	if raycast == nil then
		return
	end

	local x, y, z = getWorldTranslation(raycast.node)
	local dx, dy, dz = localDirectionToWorld(raycast.node, 0, 0, -1)

	raycastAll(x, y, z, dx, dy, dz, "raycastCallback", raycast.actionDistance, self, FireObject.COLLISION_MASK, false, true)

	if g_currentMission.rolePlay.isDebug then
		DebugUtil.drawDebugLine(x, y, z, x + dx * raycast.actionDistance, y + dy * raycast.actionDistance, z + dz * raycast.actionDistance, 1, 0, 0)
	end
end

function AttackNozzleVehicle:raycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= g_currentMission.terrainRootNode and self.isServer then
		local spec = self.spec_attackNozzleVehicle
		local scenario = g_currentMission.rolePlay:getRunningScenarioForFarm(self:getOwnerFarmId())

		if scenario == nil or scenario.scenarioCheckPoint == nil or not scenario.scenarioCheckPoint:hasAction() or not scenario.scenarioCheckPoint.action:isa(ScenarioHandToolAction) then
			return
		end

		if scenario ~= nil and scenario.fire ~= nil then
			local fire = scenario.fire:getFireByNode(hitObjectId)

			if fire ~= nil and not fire:isExtinguished() then
				spec.lastHitFire = fire
			end
		end
	end
end

function AttackNozzleVehicle:getCanBeTurnedOn(superFunc)
	local spec = self.spec_attackNozzleVehicle

	if spec.foldMinLimit ~= nil and spec.foldMaxLimit ~= nil and self.getFoldAnimTime ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if foldAnimTime < spec.foldMinLimit or spec.foldMaxLimit < foldAnimTime then
			return false
		end
	end

	return superFunc(self)
end

function AttackNozzleVehicle:getTurnedOnNotAllowedWarning(superFunc)
	local spec = self.spec_attackNozzleVehicle

	if spec.foldMinLimit ~= nil and spec.foldMaxLimit ~= nil and self.getFoldAnimTime ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if foldAnimTime < spec.foldMinLimit or spec.foldMaxLimit < foldAnimTime then
			return g_i18n:getText("warning_firstUnfoldTheTool", self.customEnvironment):format(self.spec_foldable.objectText)
		end
	end

	local scenario = g_currentMission.rolePlay:getRunningScenarioForFarm(self:getOwnerFarmId())

	if scenario == nil and not self:getCanBeTurnedOn() then
		return g_i18n:getText("warning_actionNotAllowedNow", self.customEnvironment)
	end

	return superFunc(self)
end
