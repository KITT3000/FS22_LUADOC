ScenarioPendingEvent = {}
local ScenarioPendingEvent_mt = Class(ScenarioPendingEvent, Event)

InitEventClass(ScenarioPendingEvent, "ScenarioPendingEvent")

function ScenarioPendingEvent.emptyNew()
	return Event.new(ScenarioPendingEvent_mt)
end

function ScenarioPendingEvent.new(farmId, scenarioId, userId)
	local self = ScenarioPendingEvent.emptyNew()
	self.farmId = farmId
	self.scenarioId = scenarioId
	self.userId = userId or -1

	return self
end

function ScenarioPendingEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.scenarioId)
	streamWriteInt32(streamId, self.userId)
end

function ScenarioPendingEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.scenarioId = streamReadInt32(streamId)
	self.userId = streamReadInt32(streamId)

	self:run(connection)
end

function ScenarioPendingEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_DETERMINED, self.farmId, self.scenarioId, self.userId)
end
