StrawHarvestCollectBaleEvent = {}
local StrawHarvestCollectBaleEvent_mt = Class(StrawHarvestCollectBaleEvent, Event)

InitEventClass(StrawHarvestCollectBaleEvent, "StrawHarvestCollectBaleEvent")

function StrawHarvestCollectBaleEvent.emptyNew()
	local self = Event.new(StrawHarvestCollectBaleEvent_mt)

	return self
end

function StrawHarvestCollectBaleEvent.new(object, index, baleObjectId)
	local self = StrawHarvestCollectBaleEvent.emptyNew()
	self.object = object
	self.index = index
	self.baleObjectId = baleObjectId

	return self
end

function StrawHarvestCollectBaleEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.index = streamReadInt8(streamId)
	self.baleObjectId = NetworkUtil.readNodeObjectId(streamId)

	self:run(connection)
end

function StrawHarvestCollectBaleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.index)
	NetworkUtil.writeNodeObjectId(streamId, self.baleObjectId)
end

function StrawHarvestCollectBaleEvent:run(connection)
	self.object:collectBale(self.index, self.baleObjectId)
end
