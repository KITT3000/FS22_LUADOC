StartStrategyMarkerNode = {
	MAX_TRIES = 10
}
local StartStrategyMarkerNode_mt = Class(StartStrategyMarkerNode, StartStrategy)

function StartStrategyMarkerNode.new(entries, custom_mt)
	local self = StartStrategyMarkerNode:superClass().new(custom_mt or StartStrategyMarkerNode_mt)
	self.entries = entries or {}

	return self
end

function StartStrategyMarkerNode:delete()
end

function StartStrategyMarkerNode:canBeUsed()
	local canBeUsed, reason = StartStrategyMarkerNode:superClass().canBeUsed(self)

	if not canBeUsed then
		return false, reason
	end

	return true, nil
end

function StartStrategyMarkerNode:isValidPosition(x, y, z)
	if not StartStrategyMarkerNode:superClass().isValidPosition(self, x, y, z) then
		return false
	end

	return true
end

function StartStrategyMarkerNode:getPosition()
	local isDebug = g_currentMission.rolePlay.isDebug
	local currentId = 1
	local x, y, z = nil

	while (x == nil or z == nil) and currentId < StartStrategyMarkerNode.MAX_TRIES do
		local entry = isDebug and self.entries[currentId] or table.getRandomElement(self.entries)
		local px, py, pz = getWorldTranslation(entry.nodeId)

		if self:isValidPosition(px, py, pz) then
			z = pz
			y = py
			x = px
		end

		currentId = currentId + 1
	end

	if currentId == StartStrategyMarkerNode.MAX_TRIES then
		return nil
	end

	return {
		x,
		y,
		z
	}
end
