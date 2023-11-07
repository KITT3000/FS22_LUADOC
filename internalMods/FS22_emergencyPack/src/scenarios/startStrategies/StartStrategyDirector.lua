StartStrategyDirector = {
	TYPE_MARKER = "marker",
	TYPE_SPLINE = "spline",
	TYPE_SPLINE_VERGE = "splineVerge",
	TYPE_FIELD = "field",
	TYPE_SELLING_POINTS = "sellingPoints",
	TYPE_FOREST = "forest"
}
local StartStrategyDirector_mt = Class(StartStrategyDirector)

function StartStrategyDirector.new()
	local self = setmetatable({}, StartStrategyDirector_mt)

	return self
end

function StartStrategyDirector:delete()
end

function StartStrategyDirector:makeForType(type)
	if type == StartStrategyDirector.TYPE_SPLINE then
		return StartStrategySpline.new()
	elseif type == StartStrategyDirector.TYPE_SPLINE_VERGE then
		return StartStrategyVerge.new()
	elseif type == StartStrategyDirector.TYPE_SELLING_POINTS then
		return StartStrategySellingPoints.new()
	elseif type == StartStrategyDirector.TYPE_FOREST then
		return StartStrategyForest.new()
	elseif type == StartStrategyDirector.TYPE_FIELD then
		return StartStrategyField.new()
	end

	local startEntries = g_currentMission.rolePlay.scenarioStartEntriesByType[type]

	if startEntries ~= nil then
		return StartStrategyMarkerNode.new(startEntries)
	end

	return StartStrategyField.new()
end
