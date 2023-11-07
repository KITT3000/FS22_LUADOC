StartStrategyField = {}
local StartStrategyField_mt = Class(StartStrategyField, StartStrategy)

function StartStrategyField.new(custom_mt)
	return StartStrategyField:superClass().new(custom_mt or StartStrategyField_mt)
end

function StartStrategyField:delete()
	StartStrategyField:superClass().delete(self)
end

function StartStrategyField:canBeUsed()
	local canBeUsed, reason = StartStrategyField:superClass().canBeUsed(self)

	if not canBeUsed then
		return false, reason
	end

	local fieldIndices = self:getFields()

	if #fieldIndices == 0 then
		return false, g_i18n:getText("info_scenario_validationError_noFields")
	end

	local validField = self:getValidField(fieldIndices)

	if validField == nil then
		return false, g_i18n:getText("info_scenario_validationError_noFields")
	end

	return true, nil
end

function StartStrategyField:setActiveField(fieldId)
	self.activeField = fieldId
end

function StartStrategyField:getActiveField()
	return self.activeField
end

function StartStrategyField:isValidField(field)
	if g_currentMission.rolePlay.isDebug then
		return true
	end

	if field.farmland.isOwned then
		return false
	end

	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return false
	end

	if fruitType == FruitType.GRASS then
		return true
	end

	local maxGrowthState = FieldUtil.getMaxGrowthState(field, fruitType)
	local maxHarvestState = FieldUtil.getMaxHarvestState(field, fruitType)

	if maxGrowthState == 0 and maxHarvestState == nil then
		return true
	end

	return false
end

function StartStrategyField:getFields()
	if self.fieldIndices == nil then
		self.fieldIndices = {}

		for i = 1, #g_fieldManager:getFields() do
			table.insert(self.fieldIndices, i)
		end
	end

	return self.fieldIndices
end

function StartStrategyField:getValidField(indices)
	for _, id in ipairs(indices) do
		local field = g_fieldManager:getFieldByIndex(id)

		if self:isValidField(field) then
			return field
		end
	end

	return nil
end

function StartStrategyField:getParallelogramOfField(field)
	local numDimensions = getNumOfChildren(field.fieldDimensions)
	local fieldDimension = math.random(numDimensions) - 1
	local dimWidth = getChildAt(field.fieldDimensions, fieldDimension)
	local dimStart = getChildAt(dimWidth, 0)
	local dimHeight = getChildAt(dimWidth, 1)
	local x0, _, z0 = getWorldTranslation(dimStart)
	local x1, _, z1 = getWorldTranslation(dimWidth)
	local x2, _, z2 = getWorldTranslation(dimHeight)

	return x0, z0, x1, z1, x2, z2
end

function StartStrategyField:getPositionOfField(field)
	local x0, z0, x1, z1, x2, z2 = self:getParallelogramOfField(field)

	return (x0 + x1 + x2) / 3, (z0 + z1 + z2) / 3
end

function StartStrategyField:getPosition()
	local fieldIndices = self:getFields()

	if not g_currentMission.rolePlay.isDebug then
		Utils.shuffle(fieldIndices)
	end

	local field = self:getValidField(fieldIndices)

	if field ~= nil then
		local x, z = self:getPositionOfField(field)
		local y = self:getTerrainLimitedYPosition(x, 0, z, 0.01)

		self:setActiveField(field.fieldId)

		return {
			x,
			y,
			z
		}
	end

	return nil
end
