BezierTest = {
	test_constructor = function ()
		Assert.throwsError(BezierCurve.new, "Calling constructor with no arguments threw no error.")
		Assert.throwsError(function ()
			BezierCurve.new(nil, 0, 0, 0)
		end, "X 1 was allowed to be invalid")
		Assert.throwsError(function ()
			BezierCurve.new(0, nil, 0, 0)
		end, "Y 1 was allowed to be invalid")
		Assert.throwsError(function ()
			BezierCurve.new(0, 0, nil, 0)
		end, "X 2 was allowed to be invalid")
		Assert.throwsError(function ()
			BezierCurve.new(0, 0, 0, nil)
		end, "Y 2 was allowed to be invalid")
	end,
	test_setters = function ()
		local curve = BezierCurve.new(0.25, 0, 0.75, 1)

		Assert.throwsError(function ()
			curve:setPositionX1(nil)
		end, "X 1 was allowed to be invalid")
		Assert.throwsError(function ()
			curve:setPositionY1(nil)
		end, "Y 1 was allowed to be invalid")
		Assert.throwsError(function ()
			curve:setPositionX2(nil)
		end, "X 2 was allowed to be invalid")
		Assert.throwsError(function ()
			curve:setPositionY2(nil)
		end, "Y 2 was allowed to be invalid")
	end,
	test_solvers = function ()
		local curve = BezierCurve.new(0.25, 0, 0.75, 1)

		Assert.throwsError(function ()
			curve:sampleY(nil)
		end, "t was allowed to be invalid")
		Assert.throwsError(function ()
			curve:sampleX(nil)
		end, "t was allowed to be invalid")
		Assert.throwsError(function ()
			curve:sampleDerivativeX(nil)
		end, "t was allowed to be invalid")
		Assert.throwsError(function ()
			curve:solveX(nil)
		end, "t was allowed to be invalid")
		Assert.throwsError(function ()
			curve:solveX(0.5, {})
		end, "epsilon was allowed to be invalid")
		Assert.throwsError(function ()
			curve:solve(nil)
		end, "t was allowed to be invalid")
		Assert.throwsError(function ()
			curve:solve(0.5, {})
		end, "epsilon was allowed to be invalid")

		local curveSampleCount = 100

		for curveIndex = 0, curveSampleCount do
			curve = BezierCurve.new(curveIndex / curveSampleCount, 0, 1 - curveIndex / curveSampleCount, 1)
			local sampleCount = 100

			for sampleIndex = 0, sampleCount do
				local value = curve:solve(sampleIndex / sampleCount)

				Assert.lessThanOrEqualTo(value, 1, "Value was greater than 1")
				Assert.greaterThanOrEqualTo(value, 0, "Value was less than 0")
			end
		end
	end
}
