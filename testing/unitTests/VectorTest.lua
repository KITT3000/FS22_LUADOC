VectorTest = {
	test_eulerToDirection = function ()
		local directionX, directionY, directionZ = nil
		directionX, directionY, directionZ = MathUtil.eulerToDirection(0, math.pi * 0.5)

		Assert.areRoughlyEqual(directionX, 0)
		Assert.areRoughlyEqual(directionY, -1)
		Assert.areRoughlyEqual(directionZ, 0)

		directionX, directionY, directionZ = MathUtil.eulerToDirection(0, math.pi * -0.5)

		Assert.areRoughlyEqual(directionX, 0)
		Assert.areRoughlyEqual(directionY, 1)
		Assert.areRoughlyEqual(directionZ, 0)

		directionX, directionY, directionZ = MathUtil.eulerToDirection(math.pi * 0.5, 0)

		Assert.areRoughlyEqual(directionX, 1)
		Assert.areRoughlyEqual(directionY, 0)
		Assert.areRoughlyEqual(directionZ, 0)

		directionX, directionY, directionZ = MathUtil.eulerToDirection(math.pi * -0.5, 0)

		Assert.areRoughlyEqual(directionX, -1)
		Assert.areRoughlyEqual(directionY, 0)
		Assert.areRoughlyEqual(directionZ, 0)

		directionX, directionY, directionZ = MathUtil.eulerToDirection(0, 0)

		Assert.areRoughlyEqual(directionX, 0)
		Assert.areRoughlyEqual(directionY, 0)
		Assert.areRoughlyEqual(directionZ, 1)

		directionX, directionY, directionZ = MathUtil.eulerToDirection(math.pi, 0)

		Assert.areRoughlyEqual(directionX, 0)
		Assert.areRoughlyEqual(directionY, 0)
		Assert.areRoughlyEqual(directionZ, -1)

		local testNode = createTransformGroup("test")

		for pitch = -math.pi, math.pi, math.pi / 12 do
			for yaw = -math.pi, math.pi, math.pi / 12 do
				setWorldRotation(testNode, pitch, yaw, 0)

				directionX, directionY, directionZ = MathUtil.eulerToDirection(yaw, pitch)
				local nodeDirectionX, nodeDirectionY, nodeDirectionZ = localDirectionToWorld(testNode, 0, 0, 1)

				Assert.areRoughlyEqual(directionX, nodeDirectionX)
				Assert.areRoughlyEqual(directionY, nodeDirectionY)
				Assert.areRoughlyEqual(directionZ, nodeDirectionZ)
			end
		end

		delete(testNode)
	end
}
