ScenarioAbortedEvent = {}
local ScenarioAbortedEvent_mt = Class(ScenarioAbortedEvent, Event)

InitEventClass(ScenarioAbortedEvent, "ScenarioAbortedEvent")

function ScenarioAbortedEvent.emptyNew()
	return Event.new(ScenarioAbortedEvent_mt)
end

function ScenarioAbortedEvent.new(farmId, scenarioId, reason)
	local self = ScenarioAbortedEvent.emptyNew()
	self.farmId = farmId
	self.scenarioId = scenarioId
	self.reason = reason

	return self
end

function ScenarioAbortedEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.scenarioId)
	streamWriteString(streamId, self.reason)
end

function ScenarioAbortedEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.scenarioId = streamReadInt32(streamId)
	self.reason = streamReadString(streamId)

	self:run(connection)
end

function ScenarioAbortedEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_ABORTED, self.farmId, self.scenarioId, self.reason)
end
