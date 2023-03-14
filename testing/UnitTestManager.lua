UnitTestManager = {
	UNIT_TESTS_DIRECTORY = "dataS/scripts/testing/unitTests/",
	TEST_FUNCTION_PREFIX = "test_"
}

function UnitTestManager.testAll()
	log("\n Beginning unit tests:")

	local totalRunClassesCount = 0
	local passedClassesCount = 0
	local failedClassesCount = 0
	local files = Files.new(UnitTestManager.UNIT_TESTS_DIRECTORY)

	for _, file in pairs(files.files) do
		if not file.isDirectory then
			local className, extension = Utils.getFilenameInfo(file.filename)

			if extension ~= "lua" then
				Logging.warning(string.format("Cannot test non-lua file: %s", file.filename))
			else
				source(UnitTestManager.UNIT_TESTS_DIRECTORY .. file.filename)

				local class = _G[className]
				local targetTestClass = string.sub(className, 1, #className - #"Test")
				local succeeded = UnitTestManager.testClass(targetTestClass, class)
				totalRunClassesCount = totalRunClassesCount + 1

				if succeeded then
					passedClassesCount = passedClassesCount + 1
				else
					failedClassesCount = failedClassesCount + 1
				end
			end
		end
	end

	local allPassed = failedClassesCount <= 0
	local logFunction = allPassed and UnitTestManager.logTotalSuccess or UnitTestManager.logTotalFailure

	logFunction(totalRunClassesCount, passedClassesCount, failedClassesCount)
end

function UnitTestManager.testClass(className, class)
	log(string.format("  Testing %s class: ", className))

	local totalRunFunctionsCount = 0
	local passedFunctionsCount = 0
	local failedFunctionsCount = 0

	for memberName, member in pairs(class) do
		if type(member) == "function" and string.startsWith(memberName, UnitTestManager.TEST_FUNCTION_PREFIX) then
			local functionName = string.sub(memberName, #UnitTestManager.TEST_FUNCTION_PREFIX + 1)
			local status = xpcall(member, function (message)
				UnitTestManager.logFunctionFailure(functionName, message)
			end)

			if status then
				UnitTestManager.logFunctionSuccess(functionName)

				passedFunctionsCount = passedFunctionsCount + 1
			else
				failedFunctionsCount = failedFunctionsCount + 1
			end

			totalRunFunctionsCount = totalRunFunctionsCount + 1
		end
	end

	local succeeded = failedFunctionsCount <= 0
	local logFunction = succeeded and UnitTestManager.logClassSuccess or UnitTestManager.logClassFailure

	logFunction(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount)

	return succeeded
end

function UnitTestManager.logTotalSuccess(totalRunClassesCount, passedClassesCount, failedClassesCount)
	log(string.format("✔ Finished %d class tests. (%d passed, %d failed)\n", totalRunClassesCount, passedClassesCount, failedClassesCount))
end

function UnitTestManager.logTotalFailure(totalRunClassesCount, passedClassesCount, failedClassesCount)
	log(string.format("❌ Finished %d class tests. (%d passed, %d failed)\n", totalRunClassesCount, passedClassesCount, failedClassesCount))
end

function UnitTestManager.logClassSuccess(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount)
	log(string.format("  ✔ Finished %d tests for %s class. (%d passed, %d failed)", totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount))
end

function UnitTestManager.logClassFailure(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount)
	log(string.format("  ❌ Finished %d tests for %s class. (%d passed, %d failed)", totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount))
end

function UnitTestManager.logFunctionSuccess(functionName)
	log(string.format("     ✔ %s passed", functionName))
end

function UnitTestManager.logFunctionFailure(functionName, message)
	log(string.format("     ❌ %s failed: ", functionName))
	log("       " .. message)
	printCallstack()
end
