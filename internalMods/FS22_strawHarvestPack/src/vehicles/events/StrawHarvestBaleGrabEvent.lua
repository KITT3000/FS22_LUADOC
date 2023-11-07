StrawHarvestBaleGrabEvent = {}
local StrawHarvestBaleGrabEvent_mt = Class(StrawHarvestBaleGrabEvent, Event)

InitEventClass(StrawHarvestBaleGrabEvent, "StrawHarvestBaleGrabEvent")

function StrawHarvestBaleGrabEvent.emptyNew()
	local self = Event.new(StrawHarvestBaleGrabEvent_mt)

	return self
end

function StrawHarvestBaleGrabEvent.new(object, doGrab)
	local self = StrawHarvestBaleGrabEvent.emptyNew()
	self.object = object
	self.doGrab = doGrab

	return self
end

function StrawHarvestBaleGrabEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.doGrab = streamReadBool(streamId)

	self:run(connection)
end

function StrawHarvestBaleGrabEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.doGrab)
end

function StrawHarvestBaleGrabEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:operateGrab(self.doGrab, true)
end
