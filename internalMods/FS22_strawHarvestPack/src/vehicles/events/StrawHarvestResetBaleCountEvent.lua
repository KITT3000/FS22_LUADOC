StrawHarvestResetBaleCountEvent = {}
local StrawHarvestResetBaleCountEvent_mt = Class(StrawHarvestResetBaleCountEvent, Event)

InitEventClass(StrawHarvestResetBaleCountEvent, "StrawHarvestResetBaleCountEvent")

function StrawHarvestResetBaleCountEvent.emptyNew()
	local self = Event.new(StrawHarvestResetBaleCountEvent_mt)

	return self
end

function StrawHarvestResetBaleCountEvent.new(object)
	local self = StrawHarvestResetBaleCountEvent.emptyNew()
	self.object = object

	return self
end

function StrawHarvestResetBaleCountEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function StrawHarvestResetBaleCountEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function StrawHarvestResetBaleCountEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:resetBalerCurrentBalesCount(true)
end
