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
	end,
	isNotNil = function (actual, message)
		assert(actual ~= nil, string.format("%s value was nil", message))

		return actual
	end,
	isTrue = function (actual, message)
		assert(actual == true, message)
	end,
	isFalse = function (actual, message)
		assert(actual == false, message)
	end,
	throwsError = function (testFunction, message)
		local status = pcall(testFunction)

		assert(not status, message or "function threw no error")
	end,
	fail = function (message)
		assert(false, message)
	end
}
