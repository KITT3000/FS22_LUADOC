Queue = {}
local Queue_mt = Class(Queue)

function Queue.new(list)
	return setmetatable({
		list = list or {}
	}, Queue_mt)
end

function Queue:push(value)
	table.insert(self.list, value)
end

function Queue:pop()
	return table.remove(self.list, 1)
end

function Queue:first()
	return self.list[1]
end

function Queue:isEmpty()
	return #self.list == 0
end

function Queue:size()
	return #self.list
end

function Queue:clear()
	self.list = {}
end
