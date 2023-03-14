PlaceableObjectStorageUnloadEvent = {}
local PlaceableObjectStorageUnloadEvent_mt = Class(PlaceableObjectStorageUnloadEvent, Event)

InitStaticEventClass(PlaceableObjectStorageUnloadEvent, "PlaceableObjectStorageUnloadEvent", EventIds.EVENT_PLACEABLE_OBJECT_STORAGE_UNLOAD)

function PlaceableObjectStorageUnloadEvent.emptyNew()
	return Event.new(PlaceableObjectStorageUnloadEvent_mt)
end

function PlaceableObjectStorageUnloadEvent.new(placeable, objectInfoIndex, objectAmount)
	local self = PlaceableObjectStorageUnloadEvent.emptyNew()
	self.placeable = placeable
	self.objectInfoIndex = objectInfoIndex
	self.objectAmount = objectAmount

	return self
end

function PlaceableObjectStorageUnloadEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.objectInfoIndex = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
	self.objectAmount = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_AMOUNT)

	self:run(connection)
end

function PlaceableObjectStorageUnloadEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteUIntN(streamId, self.objectInfoIndex, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
	streamWriteUIntN(streamId, self.objectAmount, PlaceableObjectStorage.NUM_BITS_AMOUNT)
end

function PlaceableObjectStorageUnloadEvent:run(connection)
	if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.placeable.removeAbstractObjectsFromStorage ~= nil then
		self.placeable:removeAbstractObjectsFromStorage(self.objectInfoIndex, self.objectAmount, connection)
	end
end
