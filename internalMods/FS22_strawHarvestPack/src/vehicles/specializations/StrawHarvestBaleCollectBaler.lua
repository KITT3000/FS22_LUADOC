StrawHarvestBaleCollectBaler = {
	MOD_NAME = g_currentModName,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Baler, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("StrawHarvestBaleCollectBaler")
		schema:register(XMLValueType.INT, "vehicle.baleCollectBaler#attacherJointIndex", "AttacherJoint index of the bale collect")
		schema:register(XMLValueType.STRING, "vehicle.baleCollectBaler#configurationName", "Configuration name to check for the bale collect")
		schema:register(XMLValueType.INT, "vehicle.baleCollectBaler#configurationIndex", "Configuration index to check for the bale collect")
		schema:register(XMLValueType.FLOAT, "vehicle.baleCollectBaler.baleAnimation.key(?)#time", "Key time")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.baleCollectBaler.baleAnimation.key(?)#pos", "Key position")
		schema:register(XMLValueType.VECTOR_ROT, "vehicle.baleCollectBaler.baleAnimation.key(?)#rot", "Key rotation")
		schema:setXMLSpecializationType()
	end
}

function StrawHarvestBaleCollectBaler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "hasAttachedBaleCollect", StrawHarvestBaleCollectBaler.hasAttachedBaleCollect)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedBaleCollect", StrawHarvestBaleCollectBaler.getAttachedBaleCollect)
	SpecializationUtil.registerFunction(vehicleType, "isBaleCollectActive", StrawHarvestBaleCollectBaler.isBaleCollectActive)
end

function StrawHarvestBaleCollectBaler.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", StrawHarvestBaleCollectBaler.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", StrawHarvestBaleCollectBaler.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", StrawHarvestBaleCollectBaler.getTurnedOnNotAllowedWarning)
end

function StrawHarvestBaleCollectBaler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestBaleCollectBaler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", StrawHarvestBaleCollectBaler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", StrawHarvestBaleCollectBaler)
end

function StrawHarvestBaleCollectBaler:onLoad(savegame)
	self.spec_strawHarvestBaleCollectBaler = self[("spec_%s.strawHarvestBaleCollectBaler"):format(StrawHarvestBaleCollectBaler.MOD_NAME)]
	local spec = self.spec_strawHarvestBaleCollectBaler
	spec.attachedBaleCollectIsActive = false
	spec.attachedBaleCollectJointIndex = self.xmlFile:getValue("vehicle.baleCollectBaler#attacherJointIndex", 1)
	local configurationName = self.xmlFile:getValue("vehicle.baleCollectBaler#configurationName", "attacherJoint")
	local configurationIndex = self.xmlFile:getValue("vehicle.baleCollectBaler#configurationIndex", 1)
	local configuration = self.configurations[configurationName]

	if configuration ~= nil then
		spec.attachedBaleCollectIsActive = configuration == configurationIndex
	end

	if spec.attachedBaleCollectIsActive then
		local baleAnimCurve = AnimCurve.new(linearInterpolatorN)
		local i = 0

		while true do
			local key = ("vehicle.baleCollectBaler.baleAnimation.key(%d)"):format(i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local time = self.xmlFile:getValue(key .. "#time")
			local x, y, z = self.xmlFile:getValue(key .. "#pos")
			local rx, ry, rz = self.xmlFile:getValue(key .. "#rot", "0 0 0")

			baleAnimCurve:addKeyframe({
				x,
				y,
				z,
				rx,
				ry,
				rz,
				time = time
			})

			i = i + 1
		end

		if i > 0 then
			self.spec_baler.baleAnimCurve = baleAnimCurve
		end

		if self.spec_foldable ~= nil then
			self.spec_foldable.turnOnFoldMaxLimit = 1
			self.spec_foldable.turnOnFoldMinLimit = 0
		end
	end

	spec.attachedBaleCollect = nil
end

function StrawHarvestBaleCollectBaler:hasAttachedBaleCollect()
	return self.spec_strawHarvestBaleCollectBaler.attachedBaleCollect ~= nil
end

function StrawHarvestBaleCollectBaler:getAttachedBaleCollect()
	return self.spec_strawHarvestBaleCollectBaler.attachedBaleCollect
end

function StrawHarvestBaleCollectBaler:isBaleCollectActive()
	return self.spec_strawHarvestBaleCollectBaler.attachedBaleCollectIsActive
end

function StrawHarvestBaleCollectBaler:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_strawHarvestBaleCollectBaler

	if jointDescIndex == spec.attachedBaleCollectJointIndex then
		spec.attachedBaleCollect = attachable
	end
end

function StrawHarvestBaleCollectBaler:onPostDetachImplement(implementIndex)
	local spec = self.spec_strawHarvestBaleCollectBaler
	local object = nil

	if self.getObjectFromImplementIndex ~= nil then
		object = self:getObjectFromImplementIndex(implementIndex)
	end

	if object ~= nil then
		local attachedImplements = self:getAttachedImplements()

		if attachedImplements[implementIndex].jointDescIndex == spec.attachedBaleCollectJointIndex then
			spec.attachedBaleCollect = nil
		end
	end
end

function StrawHarvestBaleCollectBaler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self:isBaleCollectActive() then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function StrawHarvestBaleCollectBaler:getCanBeTurnedOn(superFunc)
	if self:isBaleCollectActive() then
		if self:hasAttachedBaleCollect() then
			local baleCollect = self:getAttachedBaleCollect()

			if not baleCollect:getIsInWorkPosition() then
				return false
			end
		else
			return false
		end
	end

	return superFunc(self)
end

function StrawHarvestBaleCollectBaler:getTurnedOnNotAllowedWarning(superFunc)
	if self:isBaleCollectActive() then
		if self:hasAttachedBaleCollect() then
			local baleCollect = self:getAttachedBaleCollect()

			if not baleCollect:getIsInWorkPosition() then
				return g_i18n:getText("warning_firstUnfoldTheTool"):format(baleCollect:getName())
			end
		else
			return g_i18n:getText("warning_needsABaleTrailer")
		end
	end

	return superFunc(self)
end
