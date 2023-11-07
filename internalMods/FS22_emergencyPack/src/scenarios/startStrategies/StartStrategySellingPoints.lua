StartStrategySellingPoints = {
	MAX_TRIES = 20
}
local StartStrategySellingPoints_mt = Class(StartStrategySellingPoints, StartStrategy)

function StartStrategySellingPoints.new(custom_mt)
	return StartStrategySellingPoints:superClass().new(custom_mt or StartStrategySellingPoints_mt)
end

function StartStrategySellingPoints:delete()
end

function StartStrategySellingPoints:canBeUsed()
	local canBeUsed, reason = StartStrategySellingPoints:superClass().canBeUsed(self)

	if not canBeUsed then
		return false, reason
	end

	local stations = self:getStations()

	if #stations == 0 then
		return false, g_i18n:getText("info_scenario_validationError_noStations")
	end

	return true, nil
end

function StartStrategySellingPoints:isValidPosition(x, y, z)
	if not StartStrategySellingPoints:superClass().isValidPosition(self, x, y, z) then
		return false
	end

	return true
end

function StartStrategySellingPoints:getStations()
	if self.stations == nil then
		self.stations = {}

		for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
			if station:isa(SellingStation) then
				table.insert(self.stations, station)
			end
		end
	end

	return self.stations
end

function StartStrategySellingPoints:getPosition()
	local isDebug = g_currentMission.rolePlay.isDebug
	local stations = self:getStations()
	local currentId = 1
	local x, z, dirX, dirZ = nil

	while (x == nil or z == nil) and currentId < StartStrategySellingPoints.MAX_TRIES do
		local station = isDebug and stations[currentId] or table.getRandomElement(stations)
		x, z, dirX, dirZ = station:getAITargetPositionAndDirection(FillType.UNKNOWN)

		if x ~= nil and z ~= nil then
			x, z = self:getNonBlockingPosition(x, z, dirX, dirZ, 4)
		end

		currentId = currentId + 1
	end

	if currentId == StartStrategySellingPoints.MAX_TRIES then
		return nil
	end

	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 1
	local y = self:getTerrainLimitedYPosition(x, terrainY, z, 0)

	return {
		x,
		y,
		z
	}
end
