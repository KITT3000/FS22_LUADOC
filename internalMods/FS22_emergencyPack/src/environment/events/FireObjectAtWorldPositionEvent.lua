FireObjectAtWorldPositionEvent = {}
local FireObjectAtWorldPositionEvent_mt = Class(FireObjectAtWorldPositionEvent, Event)

InitEventClass(FireObjectAtWorldPositionEvent, "FireObjectAtWorldPositionEvent")

function FireObjectAtWorldPositionEvent.emptyNew()
	return Event.new(FireObjectAtWorldPositionEvent_mt)
end

function FireObjectAtWorldPositionEvent.new(id, fireId, x, y, z, rotY)
	local self = FireObjectAtWorldPositionEvent.emptyNew()
	self.id = id
	self.fireId = fireId
	self.z = z
	self.y = y
	self.x = x
	self.rotY = rotY

	return self
end

function FireObjectAtWorldPositionEvent:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.id)
	streamWriteInt32(streamId, self.fireId)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	streamWriteFloat32(streamId, self.rotY)
end

function FireObjectAtWorldPositionEvent:readStream(streamId, connection)
	self.id = streamReadInt8(streamId)
	self.fireId = streamReadInt32(streamId)
	self.x = streamReadFloat32(streamId)
	self.y = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)
	self.rotY = streamReadFloat32(streamId)

	self:run(connection)
end

function FireObjectAtWorldPositionEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.FIRE_THRIVES, self.id, self.fireId, self.x, self.y, self.z, self.rotY)
end
