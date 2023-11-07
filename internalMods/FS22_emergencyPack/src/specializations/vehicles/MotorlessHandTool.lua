MotorlessHandTool = {
	MOD_NAME = g_currentModName,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Motorized, specializations) and SpecializationUtil.hasSpecialization(Attachable, specializations) and SpecializationUtil.hasSpecialization(Enterable, specializations)
	end
}

function MotorlessHandTool.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", MotorlessHandTool.getIsEnterable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", MotorlessHandTool.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMotorNotAllowedWarning", MotorlessHandTool.getMotorNotAllowedWarning)
end

function MotorlessHandTool.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", MotorlessHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", MotorlessHandTool)
end

function MotorlessHandTool:onLoad(savegame)
	self.spec_motorlessHandTool = self[("spec_%s.motorlessHandTool"):format(MotorlessHandTool.MOD_NAME)]
	local spec_motorized = self.spec_motorized
	spec_motorized.forceSpeedHudDisplay = true
end

function MotorlessHandTool:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec_motorized = self.spec_motorized

	if not spec_motorized.isMotorStarted then
		if self.getIsControlled ~= nil and self:getIsControlled() and self:getCanMotorRun() then
			self:startMotor()
		end

		if self:getRequiresPower() and self:getCanMotorRun() then
			self:startMotor()
		end
	elseif self.getIsControlled ~= nil and not self:getIsControlled() and self:getStopMotorOnLeave() then
		spec_motorized.motorNotRequiredTimer = spec_motorized.motorNotRequiredTimer + dt

		if spec_motorized.motorNotRequiredTimer > 250 then
			self:stopMotor()
		end

		self:raiseActive()
	end
end

function MotorlessHandTool:getIsEnterable(superFunc)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		return false
	end

	return superFunc(self)
end

function MotorlessHandTool:getCanToggleTurnedOn(superFunc)
	return false
end

function MotorlessHandTool:getMotorNotAllowedWarning(superFunc)
	return nil
end
