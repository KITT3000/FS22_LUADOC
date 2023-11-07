StrawHarvestCraneToolsEvent = {}
local StrawHarvestCraneToolsEvent_mt = Class(StrawHarvestCraneToolsEvent, Event)

InitEventClass(StrawHarvestCraneToolsEvent, "StrawHarvestCraneToolsEvent")

function StrawHarvestCraneToolsEvent.emptyNew()
	return Event.new(StrawHarvestCraneToolsEvent_mt)
end

function StrawHarvestCraneToolsEvent.new(object, index)
	local self = StrawHarvestCraneToolsEvent.emptyNew()
	self.object = object
	self.index = index

	return self
end

function StrawHarvestCraneToolsEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.index = streamReadUIntN(streamId, StrawHarvestCraneTools.SEND_NUM_BITS) + 1

	self:run(connection)
end

function StrawHarvestCraneToolsEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.index - 1, StrawHarvestCraneTools.SEND_NUM_BITS)
end

function StrawHarvestCraneToolsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setCraneTool(self.index, true)
end

function StrawHarvestCraneToolsEvent.sendEvent(object, index, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(StrawHarvestCraneToolsEvent.new(object, index), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(StrawHarvestCraneToolsEvent.new(object, index))
		end
	end
end
