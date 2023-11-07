StartStrategySpline = {
	ROAD_SPLINE = 1,
	MAX_TRIES = 20
}
local StartStrategySpline_mt = Class(StartStrategySpline, StartStrategy)

function StartStrategySpline.new(custom_mt)
	local self = StartStrategySpline:superClass().new(custom_mt or StartStrategySpline_mt)
	self.type = StartStrategySpline.ROAD_SPLINE

	return self
end

function StartStrategySpline:canBeUsed()
	local canBeUsed, reason = StartStrategySpline:superClass().canBeUsed(self)

	if not canBeUsed then
		return false, reason
	end

	local splines = self:getSplines()

	if #splines == 0 then
		return false, g_i18n:getText("info_scenario_validationError_noSplines")
	end

	return true, nil
end

function StartStrategySpline:setType(type)
	self.type = type or StartStrategySpline.ROAD_SPLINE
end

function StartStrategySpline:getSourceSpline()
	local mission = g_currentMission

	if self.type == StartStrategySpline.ROAD_SPLINE and #mission.aiSystem.roadSplines ~= 0 then
		return mission.aiSystem.roadSplines
	end

	return {}
end

function StartStrategySpline:getSplines()
	if self.splines == nil then
		self.splines = {}

		for _, splineOrNode in ipairs(self:getSourceSpline()) do
			if I3DUtil.getIsSpline(splineOrNode) then
				table.insert(self.splines, splineOrNode)
			end

			I3DUtil.interateRecursively(splineOrNode, function (node)
				if I3DUtil.getIsSpline(node) then
					table.insert(self.splines, node)
				end
			end)
		end
	end

	return self.splines
end

function StartStrategySpline:getPosition()
	local splines = self:getSplines()
	local i = math.random(#splines)

	if g_currentMission.rolePlay.isDebug then
		i = math.min(354, #splines)
	end

	local currentId = 1
	local position = self:getSplinePosition(splines, i)

	while not self:isValidPosition(position.x, position.y, position.z) and currentId < StartStrategySpline.MAX_TRIES do
		i = math.random(#splines)
		position = self:getSplinePosition(splines, i)
		currentId = currentId + 1
	end

	return {
		position.x,
		position.y,
		position.z,
		position.dirX,
		position.dirY,
		position.dirZ
	}
end

function StartStrategySpline:isValidPosition(x, y, z)
	if not StartStrategySpline:superClass().isValidPosition(self, x, y, z) then
		return false
	end

	return g_currentMission.aiSystem:getIsPositionReachable(x, y, z)
end

function StartStrategySpline:getSplinePosition(splines, index)
	local spline = splines[index]
	local positions = self:getSplinePositions(spline)
	local position = table.getRandomElement(positions)
	position.x, position.z = self:getNonBlockingPosition(position.x, position.z, position.dirX, position.dirZ, 2)

	return position
end

function StartStrategySpline:getSplinePositions(spline)
	local positions = {}

	local function getSplineProperties(node, t)
		local x, y, z = getSplinePosition(node, t)
		local dirX, dirY, dirZ = getSplineDirection(node, t)

		return {
			x = x,
			y = y,
			z = z,
			dirX = dirX,
			dirY = dirY,
			dirZ = dirZ
		}
	end

	local splineLength = getSplineLength(spline)

	table.insert(positions, getSplineProperties(spline, 0.5))
	table.insert(positions, getSplineProperties(spline, 0.5 / splineLength))
	table.insert(positions, getSplineProperties(spline, 1 - 0.5 / splineLength))

	return positions
end
