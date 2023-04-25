Assert = {
	areEqual = function (actual, expected, message)
		assert(expected == actual, string.format("%s expected: %s, actual: %s", message, tostring(expected), tostring(actual)))
	end,
	areNotEqual = function (actual, expected, message)
		assert(expected ~= actual, string.format("%s expected: %s, actual: %s", message, tostring(expected), tostring(actual)))
	end,
	areRoughlyEqual = function (actual, expected, message, epsilon)
		epsilon = epsilon or 0.001

		assert(math.abs(actual - expected) <= epsilon, string.format("%s expected: %s, actual: %s", message, tostring(expected), tostring(actual)))
	end
}

function Assert.isBetween(actual, lowerLimit, upperLimit, message, lowerInclusive, upperInclusive)
	if lowerInclusive == nil then
		lowerInclusive = true
	end

	if upperInclusive == nil then
		upperInclusive = true
	end

	if lowerInclusive then
		Assert.greaterThanOrEqualTo(actual, lowerLimit, message)
	else
		Assert.greaterThan(actual, lowerLimit, message)
	end

	if upperInclusive then
		Assert.lessThanOrEqualTo(actual, lowerLimit, message)
	else
		Assert.lessThan(actual, lowerLimit, message)
	end
end

function Assert.greaterThan(actual, lowerLimit, message)
	assert(lowerLimit < actual, string.format("%s lower limit: %s, actual: %s", message, tostring(lowerLimit), tostring(actual)))
end

function Assert.greaterThanOrEqualTo(actual, lowerLimit, message)
	assert(lowerLimit <= actual, string.format("%s lower limit: %s, actual: %s", message, tostring(lowerLimit), tostring(actual)))
end

function Assert.lessThan(actual, upperLimit, message)
	assert(actual < upperLimit, string.format("%s upper limit: %s, actual: %s", message, tostring(upperLimit), tostring(actual)))
end

function Assert.lessThanOrEqualTo(actual, upperLimit, message)
	assert(actual <= upperLimit, string.format("%s upper limit: %s, actual: %s", message, tostring(upperLimit), tostring(actual)))
end

function Assert.isType(object, expectedType, message)
	assert(type(object) == expectedType, string.format("%s expected: %s, actual: %s", message, expectedType, object and type(object) or "nil"))
end

function Assert.isNotNil(actual, message)
	assert(actual ~= nil, string.format("%s value was nil", message))
end

function Assert.isTrue(actual, message)
	assert(actual == true, message)
end

function Assert.isFalse(actual, message)
	assert(actual == false, message)
end

function Assert.throwsError(testFunction, message)
	local status = pcall(testFunction)

	assert(not status, message or "function threw no error")
end

function Assert.fail(message)
	assert(false, message)
end
