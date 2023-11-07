StrawHarvestCoverEvent = {}
local StrawHarvestCoverEvent_mt = Class(StrawHarvestCoverEvent, Event)

InitEventClass(StrawHarvestCoverEvent, "StrawHarvestCoverEvent")

function StrawHarvestCoverEvent.emptyNew()
	local self = Event.new(StrawHarvestCoverEvent_mt)

	return self
end

function StrawHarvestCoverEvent.new(object, state)
	local self = StrawHarvestCoverEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function StrawHarvestCoverEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function StrawHarvestCoverEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function StrawHarvestCoverEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setIsRefillCoverOpen(self.state, true)
end

function StrawHarvestCoverEvent.sendEvent(object, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(StrawHarvestCoverEvent.new(object, state), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(StrawHarvestCoverEvent.new(object, state))
		end
	end
end
