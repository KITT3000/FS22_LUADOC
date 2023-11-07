ScenarioCheckPointActionEvent = {}
local ScenarioCheckPointActionEvent_mt = Class(ScenarioCheckPointActionEvent, Event)

InitEventClass(ScenarioCheckPointActionEvent, "ScenarioCheckPointActionEvent")

function ScenarioCheckPointActionEvent.emptyNew()
	return Event.new(ScenarioCheckPointActionEvent_mt)
end

function ScenarioCheckPointActionEvent.new(id, isCompleted)
	local self = ScenarioCheckPointActionEvent.emptyNew()
	self.checkPointId = id
	self.isCompleted = isCompleted

	return self
end

function ScenarioCheckPointActionEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.checkPointId)
	streamWriteBool(streamId, self.isCompleted)
end

function ScenarioCheckPointActionEvent:readStream(streamId, connection)
	self.checkPointId = streamReadInt32(streamId)
	self.isCompleted = streamReadBool(streamId)

	self:run(connection)
end

function ScenarioCheckPointActionEvent:run(connection)
	if not connection:getIsServer() then
		g_messageCenter:publish(ScenarioMessageType.SCENARIO_CHECKPOINT_ACTION_CHANGED, self.checkPointId, self.isCompleted)
	end
end
