AttackNozzle = {}
local AttackNozzle_mt = Class(AttackNozzle, RolePlayHandTool)

InitObjectClass(AttackNozzle, "AttackNozzle")

function AttackNozzle.registerXMLPaths(schema, basePath)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".attackNozzle.sounds", "extinguishing")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".attackNozzle.effects")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".attackNozzle#raycastNode", "Raycast node")
	schema:register(XMLValueType.STRING, basePath .. ".attackNozzle.workingAnimation#name", "Working animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".attackNozzle.workingAnimation#workingDirection", "Working animation direction if is working", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".attackNozzle.workingAnimation#releasingDirection", "Working animation direction if is releasing", "-workingDirection")
end

function AttackNozzle.new(isServer, isClient, customMt)
	local self = AttackNozzle:superClass().new(isServer, isClient, customMt or AttackNozzle_mt)
	self.playerInputText = g_i18n:getText("input_extinguishFire")
	self.isExtinguishingFire = false
	self.actionRadius = 50
	self.actionDistance = 50
	self.extinguishMultiplier = 5

	return self
end

function AttackNozzle:postLoad(xmlFile)
	if not AttackNozzle:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.effects = g_effectManager:loadEffect(xmlFile, "handTool.attackNozzle.effects", self.components, self, self.i3dMappings)
	self.sample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.attackNozzle.sounds", "extinguishing", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	self.raycastNode = xmlFile:getValue("handTool.attackNozzle#raycastNode", nil, self.components, self.i3dMappings)

	g_effectManager:setFillType(self.effects, FillType.WATER)

	local animation = {
		name = xmlFile:getValue("handTool.attackNozzle.workingAnimation#name"),
		workingDirection = xmlFile:getValue("handTool.attackNozzle.workingAnimation#workingDirection", 1)
	}
	animation.releasingDirection = xmlFile:getValue("handTool.attackNozzle.workingAnimation#releasingDirection", -animation.workingDirection)
	self.workingAnimation = animation

	return true
end

function AttackNozzle:delete()
	g_effectManager:deleteEffects(self.effects)
	g_soundManager:deleteSample(self.sample)
	AttackNozzle:superClass().delete(self)
end

function AttackNozzle:onActivate(allowInput)
	AttackNozzle:superClass().onActivate(self, allowInput)
end

function AttackNozzle:onDeactivate(allowInput)
	self:setIsExtinguishingFire(false, true)
	AttackNozzle:superClass().onDeactivate(self, allowInput)
end

function AttackNozzle:isRolePlayVehicleInRange()
	local closestVehicle, closestDistance = g_currentMission.rolePlay:getClosestVehicle(self.handNode, self.player.farmId)

	if closestVehicle ~= nil then
		return closestDistance < self.actionRadius, closestVehicle, closestDistance
	end

	return false, nil, 0
end

function AttackNozzle:update(dt, allowInput)
	AttackNozzle:superClass().update(self, dt, allowInput)

	local rolePlayVehicleInRange, _, distance = self:isRolePlayVehicleInRange()

	if not rolePlayVehicleInRange then
		local maxRadius = self.actionRadius
		local distanceLeft = distance - maxRadius

		if distanceLeft > 0 then
			if self.player == g_currentMission.player then
				g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_rangeRestriction"), distanceLeft), 100)
			end

			self.activatePressed = false
		end
	end

	if self.isActive and allowInput then
		self:setIsExtinguishingFire(self.activatePressed, false, false)
	end

	if self.isServer and self.isExtinguishingFire then
		self:extinguishFire(self.player.cameraNode, dt)

		if self.raycastNode ~= nil then
			self:extinguishFire(self.raycastNode, dt)
		end
	end

	self.activatePressed = false

	self:raiseActive()
end

function AttackNozzle:updateTick(dt, allowInput)
	AttackNozzle:superClass().updateTick(self, dt, allowInput)
end

function AttackNozzle:setIsExtinguishingFire(isExtinguishingFire, force, noEventSend)
	AttackNozzleExtinguishingFireEvent.sendEvent(self.player, isExtinguishingFire, noEventSend)

	if self.isExtinguishingFire ~= isExtinguishingFire then
		if isExtinguishingFire then
			g_effectManager:startEffects(self.effects)
			g_soundManager:playSample(self.sample)

			local animation = self.workingAnimation

			if animation.name ~= nil then
				self.animations:playAnimation(animation.name, animation.workingDirection or 0)
			end
		else
			if force then
				g_effectManager:resetEffects(self.effects)
			else
				g_effectManager:stopEffects(self.effects)
			end

			g_soundManager:stopSample(self.sample)

			local animation = self.workingAnimation

			if animation.name ~= nil then
				self.animations:playAnimation(animation.name, animation.releasingDirection)
			end
		end

		self.isExtinguishingFire = isExtinguishingFire
	end
end

function AttackNozzle:extinguishFire(node, dt)
	local x, y, z = getWorldTranslation(node)
	local dx, dy, dz = localDirectionToWorld(node, 0, 0, -1)
	self.lastHitFire = nil

	raycastAll(x, y, z, dx, dy, dz, "raycastCallback", self.actionDistance, self, FireObject.COLLISION_MASK)

	if self.lastHitFire ~= nil then
		self.lastHitFire:extinguish(dt, self.extinguishMultiplier)
	end
end

function AttackNozzle:raycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= g_currentMission.terrainRootNode and self.isServer then
		local scenario = g_currentMission.rolePlay:getRunningScenarioForFarm(self.player.farmId)
		local fire = scenario.fire:getFireByNode(hitObjectId)

		if fire ~= nil then
			self.lastHitFire = fire

			return false
		end
	end

	return true
end
