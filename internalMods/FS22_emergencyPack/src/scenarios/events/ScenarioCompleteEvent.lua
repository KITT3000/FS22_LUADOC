ScenarioCompleteEvent = {}
local ScenarioCompleteEvent_mt = Class(ScenarioCompleteEvent, Event)

InitEventClass(ScenarioCompleteEvent, "ScenarioCompleteEvent")

function ScenarioCompleteEvent.emptyNew()
	return Event.new(ScenarioCompleteEvent_mt)
end

function ScenarioCompleteEvent.new(farmId, scenarioId)
	local self = ScenarioCompleteEvent.emptyNew()
	self.farmId = farmId
	self.scenarioId = scenarioId

	return self
end

function ScenarioCompleteEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.scenarioId)
end

function ScenarioCompleteEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.scenarioId = streamReadInt32(streamId)

	self:run(connection)
end

function ScenarioCompleteEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_COMPLETED, self.farmId, self.scenarioId)
end
