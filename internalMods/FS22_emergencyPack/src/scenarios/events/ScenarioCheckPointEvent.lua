ScenarioCheckPointEvent = {}
local ScenarioCheckPointEvent_mt = Class(ScenarioCheckPointEvent, Event)

InitEventClass(ScenarioCheckPointEvent, "ScenarioCheckPointEvent")

function ScenarioCheckPointEvent.emptyNew()
	return Event.new(ScenarioCheckPointEvent_mt)
end

function ScenarioCheckPointEvent.new(id, isActive)
	local self = ScenarioCheckPointEvent.emptyNew()
	self.checkPointId = id
	self.isActive = isActive

	return self
end

function ScenarioCheckPointEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.checkPointId)
	streamWriteBool(streamId, self.isActive)
end

function ScenarioCheckPointEvent:readStream(streamId, connection)
	self.checkPointId = streamReadInt32(streamId)
	self.isActive = streamReadBool(streamId)

	self:run(connection)
end

function ScenarioCheckPointEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_CHECKPOINT_CHANGED, self.checkPointId, self.isActive)
end
