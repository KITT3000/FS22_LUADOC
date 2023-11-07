StrawHarvestCollectModeEvent = {}
local StrawHarvestCollectModeEvent_mt = Class(StrawHarvestCollectModeEvent, Event)

InitEventClass(StrawHarvestCollectModeEvent, "StrawHarvestCollectModeEvent")

function StrawHarvestCollectModeEvent.emptyNew()
	local self = Event.new(StrawHarvestCollectModeEvent_mt)

	return self
end

function StrawHarvestCollectModeEvent.new(object, mode)
	local self = StrawHarvestCollectModeEvent.emptyNew()
	self.object = object
	self.mode = mode

	return self
end

function StrawHarvestCollectModeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.mode = streamReadInt8(streamId)

	self:run(connection)
end

function StrawHarvestCollectModeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.mode)
end

function StrawHarvestCollectModeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setCollectMode(self.mode, true)
end

function StrawHarvestCollectModeEvent.sendEvent(object, mode, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(StrawHarvestCollectModeEvent.new(object, mode), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(StrawHarvestCollectModeEvent.new(object, mode))
		end
	end
end
