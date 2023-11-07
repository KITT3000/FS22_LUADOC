StrawHarvestLoadDummyBaleEvent = {}
local StrawHarvestLoadDummyBaleEvent_mt = Class(StrawHarvestLoadDummyBaleEvent, Event)

InitEventClass(StrawHarvestLoadDummyBaleEvent, "StrawHarvestLoadDummyBaleEvent")

function StrawHarvestLoadDummyBaleEvent.emptyNew()
	local self = Event.new(StrawHarvestLoadDummyBaleEvent_mt)

	return self
end

function StrawHarvestLoadDummyBaleEvent.new(object, i3dFilename, yOffset, zOffset, fillType)
	local self = StrawHarvestLoadDummyBaleEvent.emptyNew()
	self.object = object
	self.i3dFilename = i3dFilename
	self.yOffset = yOffset
	self.zOffset = zOffset
	self.fillType = fillType

	return self
end

function StrawHarvestLoadDummyBaleEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.yOffset = streamReadFloat32(streamId)
	self.zOffset = streamReadFloat32(streamId)
	self.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self.object:createDummyBaleFromBale(self.i3dFilename, self.yOffset, self.zOffset, self.fillType)
end

function StrawHarvestLoadDummyBaleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	streamWriteFloat32(streamId, self.yOffset)
	streamWriteFloat32(streamId, self.zOffset)
	streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
end
