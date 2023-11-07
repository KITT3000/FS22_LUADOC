ScenarioObjectAtWorldPositionEvent = {}
local ScenarioObjectAtWorldPositionEvent_mt = Class(ScenarioObjectAtWorldPositionEvent, Event)

InitEventClass(ScenarioObjectAtWorldPositionEvent, "ScenarioObjectAtWorldPositionEvent")

function ScenarioObjectAtWorldPositionEvent.emptyNew()
	return Event.new(ScenarioObjectAtWorldPositionEvent_mt)
end

function ScenarioObjectAtWorldPositionEvent.new(scenarioId, id, filename, index, x, y, z, rotY)
	local self = ScenarioObjectAtWorldPositionEvent.emptyNew()
	self.scenarioId = scenarioId
	self.objectId = id
	self.filename = filename
	self.index = index
	self.x = x
	self.y = y
	self.z = z
	self.rotY = rotY

	return self
end

function ScenarioObjectAtWorldPositionEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.scenarioId)
	streamWriteString(streamId, self.objectId)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
	streamWriteInt32(streamId, self.index)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	streamWriteFloat32(streamId, self.rotY)
end

function ScenarioObjectAtWorldPositionEvent:readStream(streamId, connection)
	self.scenarioId = streamReadInt32(streamId)
	self.objectId = streamReadString(streamId)
	self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.index = streamReadInt32(streamId)
	self.x = streamReadFloat32(streamId)
	self.y = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)
	self.rotY = streamReadFloat32(streamId)

	self:run(connection)
end

function ScenarioObjectAtWorldPositionEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.OBJECT_PLACED, self.scenarioId, self.objectId, self.filename, self.index, self.x, self.y, self.z, self.rotY)
end
