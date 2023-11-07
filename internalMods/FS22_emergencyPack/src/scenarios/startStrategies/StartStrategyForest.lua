StartStrategyForest = {}
local StartStrategyForest_mt = Class(StartStrategyForest, StartStrategy)

function StartStrategyForest.new(custom_mt)
	return StartStrategyForest:superClass().new(custom_mt or StartStrategyForest_mt)
end

function StartStrategyForest:delete()
end

function StartStrategyForest:canBeUsed()
	return StartStrategyForest:superClass().canBeUsed(self)
end
