ScenarioCheckPointProgressEvent = {}
local ScenarioCheckPointProgressEvent_mt = Class(ScenarioCheckPointProgressEvent, Event)

InitEventClass(ScenarioCheckPointProgressEvent, "ScenarioCheckPointProgressEvent")

function ScenarioCheckPointProgressEvent.emptyNew()
	return Event.new(ScenarioCheckPointProgressEvent_mt)
end

function ScenarioCheckPointProgressEvent.new(id, progress)
	local self = ScenarioCheckPointProgressEvent.emptyNew()
	self.checkPointId = id
	self.progress = progress

	return self
end

function ScenarioCheckPointProgressEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.checkPointId)
	streamWriteFloat32(streamId, self.progress)
end

function ScenarioCheckPointProgressEvent:readStream(streamId, connection)
	self.checkPointId = streamReadInt32(streamId)
	self.progress = streamReadFloat32(streamId)

	self:run(connection)
end

function ScenarioCheckPointProgressEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_CHECKPOINT_PROGRESS, self.checkPointId, self.progress)
end
