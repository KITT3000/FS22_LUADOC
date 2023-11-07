StartStrategy = {
	OFFSETS = {
		{
			-1,
			-1
		},
		{
			-1,
			0
		},
		{
			-1,
			1
		},
		{
			0,
			-1
		},
		{
			0,
			0
		},
		{
			0,
			1
		},
		{
			1,
			-1
		},
		{
			1,
			0
		},
		{
			1,
			1
		}
	}
}
local StartStrategy_mt = Class(StartStrategy)

function StartStrategy.new(custom_mt)
	local self = setmetatable({}, custom_mt or StartStrategy_mt)
	self.position = nil

	return self
end

function StartStrategy:delete()
	self.position = nil
end

function StartStrategy:canBeUsed()
	return true, nil
end

function StartStrategy:setPosition(x, y, z)
	self.position = {
		x = x,
		y = y,
		z = z
	}
end

function StartStrategy:getPosition()
	return self.position
end

function StartStrategy:isValidPosition(x, y, z)
	return x ~= nil and z ~= nil
end

function StartStrategy:getTerrainLimitedYPosition(x, y, z, offset)
	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
	self.correctedY = -1

	raycastClosest(x, y + offset, z, 0, -1, 0, "groundRaycastCallback", 5, self, CollisionFlag.TERRAIN + CollisionFlag.STATIC_WORLD + CollisionFlag.STATIC_OBJECT)

	return math.max(terrainY, self.correctedY) + offset
end

function StartStrategy:groundRaycastCallback(hitObjectId, x, y, z, distance)
	if getHasTrigger(hitObjectId) then
		return true
	end

	self.correctedY = y

	return true
end

function StartStrategy:getNonBlockingPosition(x, z, dirX, dirZ, size)
	local rotY = MathUtil.getYRotationFromDirection(dirX, dirZ)
	local offsets = Utils.shuffle(StartStrategy.OFFSETS)
	local worldSizeX = g_currentMission.mapWidth
	local worldSizeZ = g_currentMission.mapHeight
	local normalizedPosX = MathUtil.clamp((x + worldSizeX * 0.5) / worldSizeX, 0, 1)
	local normalizedPosZ = MathUtil.clamp((z + worldSizeZ * 0.5) / worldSizeZ, 0, 1)
	local maxPos = 0.995
	local minPos = 0.005

	if normalizedPosX < minPos or maxPos < normalizedPosX or normalizedPosZ < minPos or maxPos < normalizedPosZ then
		return nil, nil
	end

	for _, offset in ipairs(offsets) do
		local offsetX, offsetZ = unpack(offset)
		local ox, _, oz = MathUtil.transform(x, 0, z, dirX, 0, dirZ, 0, 1, 0, size * offsetX, size, size * offsetZ)
		local oy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ox, 0, oz) + 0.05
		self.positionBlocked = false
		local e = size * 0.5

		overlapBox(ox, oy, oz, 0, rotY, 0, e, e, e, "overlapCallback", self, CollisionFlag.STATIC_WORLD + CollisionFlag.STATIC_OBJECT + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.FILLABLE + CollisionFlag.AI_DRIVABLE + CollisionFlag.WATER, true, false, true)

		if not self.positionBlocked then
			return ox, oz
		end
	end

	return nil, nil
end

function StartStrategy:overlapCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		self.positionBlocked = true

		return false
	end

	return true
end
