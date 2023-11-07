ScenarioTargetPositionEvent = {}
local ScenarioTargetPositionEvent_mt = Class(ScenarioTargetPositionEvent, Event)

InitEventClass(ScenarioTargetPositionEvent, "ScenarioTargetPositionEvent")

function ScenarioTargetPositionEvent.emptyNew()
	return Event.new(ScenarioTargetPositionEvent_mt)
end

function ScenarioTargetPositionEvent.new(x, y, z)
	local self = ScenarioTargetPositionEvent.emptyNew()
	self.z = z
	self.y = y
	self.x = x

	return self
end

function ScenarioTargetPositionEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
end

function ScenarioTargetPositionEvent:readStream(streamId, connection)
	self.x = streamReadFloat32(streamId)
	self.y = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)

	self:run(connection)
end

function ScenarioTargetPositionEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_POSITION_DETERMINED, self.x, self.y, self.z)
end
