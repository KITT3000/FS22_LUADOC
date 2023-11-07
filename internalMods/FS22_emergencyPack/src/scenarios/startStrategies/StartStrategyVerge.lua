StartStrategyVerge = {
	SPLINE_OFFSET = 18
}
local StartStrategyVerge_mt = Class(StartStrategyVerge, StartStrategySpline)

function StartStrategyVerge.new(custom_mt)
	local self = StartStrategyVerge:superClass().new(custom_mt or StartStrategyVerge_mt)

	return self
end

function StartStrategyVerge:getPosition()
	local position = StartStrategyVerge:superClass().getPosition(self)
	local x, y, z, dirX, dirY, dirZ = unpack(position)
	local direction = {
		-1,
		1
	}
	local offsetDirection = direction[math.random(1, 2)]
	local x1, y1, z1 = MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, offsetDirection * StartStrategyVerge.SPLINE_OFFSET, 0, 0)

	return {
		x1,
		y1,
		z1
	}
end
