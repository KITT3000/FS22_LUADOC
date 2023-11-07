Stack = {}
local Stack_mt = Class(Stack)

function Stack.new(list)
	return setmetatable({
		list = list or {}
	}, Stack_mt)
end

function Stack:push(value)
	self.list[#self.list + 1] = value
end

function Stack:pop()
	return table.remove(self.list, #self.list)
end

function Stack:first()
	return self.list[#self.list]
end

function Stack:size()
	return #self.list
end

function Stack:isEmpty()
	return #self.list == 0
end

function Stack:clear()
	self.list = {}
end
