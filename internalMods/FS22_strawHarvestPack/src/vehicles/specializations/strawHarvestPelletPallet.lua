StrawHarvestPelletPallet = {
	MOD_NAME = g_currentModName,
	FILLLEVEL_SELLING_BENEFIT = 3,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end
}

function StrawHarvestPelletPallet.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", StrawHarvestPelletPallet.addFillUnitFillLevel)
end

function StrawHarvestPelletPallet.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawHarvestPelletPallet)
end

function StrawHarvestPelletPallet:onLoad(savegame)
	self.spec_strawHarvestPelletPallet = self[("spec_%s.strawHarvestPelletPallet"):format(StrawHarvestPelletPallet.MOD_NAME)]
end

function StrawHarvestPelletPallet:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local dischargeNode = self:getCurrentDischargeNode()

	if dischargeNode ~= nil then
		local dischargeObject = self:getCurrentDischargeObject(dischargeNode)

		if dischargeObject ~= nil and dischargeObject.target ~= nil and dischargeObject.target:isa(SellingStation) then
			fillLevelDelta = fillLevelDelta / StrawHarvestPelletPallet.FILLLEVEL_SELLING_BENEFIT
		end
	end

	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end
