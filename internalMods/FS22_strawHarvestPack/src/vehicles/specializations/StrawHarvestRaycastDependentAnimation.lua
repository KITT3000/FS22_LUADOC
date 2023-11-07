StrawHarvestRaycastDependentAnimation = {
	MOD_NAME = g_currentModName,
	SPEC_NAME = g_currentModName .. ".strawHarvestRaycastDependentAnimation",
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("StrawHarvestRaycastDependentAnimation")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.raycastAnimations.animation(?)#raycastNode", "Raycast node")
		schema:register(XMLValueType.STRING, "vehicle.raycastAnimations.animation(?)#name", "Animation name")
		schema:register(XMLValueType.INT, "vehicle.raycastAnimations.animation(?)#collisionMask", "The collision mask to filter")
		schema:register(XMLValueType.FLOAT, "vehicle.raycastAnimations.animation(?)#dist0", "Min distance")
		schema:register(XMLValueType.FLOAT, "vehicle.raycastAnimations.animation(?)#dist1", "Max distance")
		schema:register(XMLValueType.VECTOR_3, "vehicle.raycastAnimations.animation(?)#raycastDirection", "The raycast direction")
		schema:setXMLSpecializationType()
	end
}

function StrawHarvestRaycastDependentAnimation.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRaycastAnimationFromXML", StrawHarvestRaycastDependentAnimation.loadRaycastAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "raycastAnimationRaycastCallback", StrawHarvestRaycastDependentAnimation.raycastAnimationRaycastCallback)
end

function StrawHarvestRaycastDependentAnimation.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestRaycastDependentAnimation)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", StrawHarvestRaycastDependentAnimation)
end

function StrawHarvestRaycastDependentAnimation:onLoad(savegame)
	self.spec_strawHarvestRaycastDependentAnimation = self[("spec_%s.strawHarvestRaycastDependentAnimation"):format(StrawHarvestRaycastDependentAnimation.MOD_NAME)]
	local spec = self.spec_strawHarvestRaycastDependentAnimation
	spec.animations = {}
	spec.lastDist = 0
	local i = 0

	while true do
		local key = ("vehicle.raycastAnimations.animation(%d)"):format(i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local animation = {}

		if self:loadRaycastAnimationFromXML(animation, self.xmlFile, key) then
			table.insert(spec.animations, animation)
		end

		i = i + 1
	end
end

function StrawHarvestRaycastDependentAnimation:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsActive() then
		local spec = self.spec_strawHarvestRaycastDependentAnimation

		for _, animation in ipairs(spec.animations) do
			local x, y, z = getWorldTranslation(animation.raycastNodeId)
			local dirX, dirY, dirZ = localDirectionToWorld(animation.raycastNodeId, animation.raycastDir[1], animation.raycastDir[2], animation.raycastDir[3])
			spec.lastDist = 0

			raycastAll(x, y, z, dirX, dirY, dirZ, "raycastAnimationRaycastCallback", animation.raycastDist, self, animation.collisionMask, false)

			if spec.lastDist ~= 0 then
				animation.lastDist = spec.lastDist
			else
				animation.lastDist = animation.dist1
			end

			local dist = MathUtil.clamp(animation.lastDist - animation.dist0, 0, animation.dist1 - animation.dist0)
			local animTime = 1 - dist / (animation.dist1 - animation.dist0)

			self:setAnimationTime(animation.name, animTime, true)
		end
	end
end

function StrawHarvestRaycastDependentAnimation:raycastAnimationRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex)
	if getHasTrigger(hitObjectId) then
		return true
	end

	local spec = self.spec_strawHarvestRaycastDependentAnimation
	spec.lastDist = distance
end

function StrawHarvestRaycastDependentAnimation:loadRaycastAnimationFromXML(animation, xmlFile, key)
	animation.name = xmlFile:getValue(key .. "#name")
	animation.raycastNodeId = xmlFile:getValue(key .. "#raycastNode", nil, self.components, self.i3dMappings)
	animation.raycastDir = xmlFile:getValue(key .. "#raycastDirection", "0 -1 0", true)
	animation.collisionMask = xmlFile:getValue(key .. "#collisionMask", CollisionMask.VEHICLE)
	animation.dist0 = xmlFile:getValue(key .. "#dist0", 0)
	animation.dist1 = xmlFile:getValue(key .. "#dist1", 0.25)
	animation.raycastDist = animation.dist1
	animation.lastDist = animation.dist1

	return animation.name ~= nil
end
