ObjectPool = {}
local ObjectPool_mt = Class(ObjectPool)

function ObjectPool.new(objectConstructor, ...)
	local self = setmetatable({}, ObjectPool_mt)
	self.objectConstructor = objectConstructor
	self.objectConstructorArguments = table.pack(...)
	self.pool = {}
	self.poolSet = {}

	return self
end

function ObjectPool:getLength()
	return #self.pool
end

function ObjectPool:clear()
	table.clear(self.poolSet)
	table.clear(self.pool)
end

function ObjectPool:getOrCreateNext()
	local instance = table.remove(self.pool)

	if not instance then
		instance = self.objectConstructor(table.unpack(self.objectConstructorArguments, 1, self.objectConstructorArguments.n))
	else
		self.poolSet[instance] = nil
	end

	return instance
end

function ObjectPool:returnToPool(instance)
	if instance == nil then
		return false
	end

	if self.poolSet[instance] then
		return false
	end

	if instance.reset ~= nil then
		instance:reset()
	end

	table.insert(self.pool, instance)

	self.poolSet[instance] = true

	return true
end
