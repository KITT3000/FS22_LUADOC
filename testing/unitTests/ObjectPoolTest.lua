ObjectPoolTest = {
	test_constructor = function ()
		Assert.throwsError(ObjectPool.new, "Calling constructor with no arguments threw no error.")
		Assert.throwsError(function ()
			ObjectPool.new(100)
		end)
	end,
	test_length = function ()
		local objectPool = ObjectPool.new(function ()
			return {}
		end)
		local createdObjects = {}

		for i = 1, 20 do
			local createdObject = objectPool:getOrCreateNext()

			Assert.isNotNil(createdObject, "Object created from pool was nil.")
			table.insert(createdObjects, createdObject)
		end

		for i = 1, 20 do
			local returningItem = table.remove(createdObjects)

			objectPool:returnToPool(returningItem)
			Assert.areEqual(objectPool:getLength(), i)
		end
	end,
	test_duplicates = function ()
		local objectPool = ObjectPool.new(function ()
			return {}
		end)
		local createdObject = objectPool:getOrCreateNext()

		Assert.isNotNil(createdObject, "Object created from pool was nil.")

		local result = objectPool:returnToPool(createdObject)

		Assert.isTrue(result, "Object could not be added to empty pool.")

		result = objectPool:returnToPool(createdObject)

		Assert.isFalse(result, "Duplicate object was accepted.")

		local secondCreatedObject = objectPool:getOrCreateNext()

		Assert.areEqual(secondCreatedObject, createdObject, "Got a different object out of pool than was put in")

		result = objectPool:returnToPool(secondCreatedObject)

		Assert.isTrue(result, "Object could not be re-added to pool.")
	end,
	test_addNil = function ()
		local objectPool = ObjectPool.new(function ()
			return {}
		end)
		local result = objectPool:returnToPool(nil)

		Assert.isFalse(result, "Object pool accepted nil value.")
	end
}
