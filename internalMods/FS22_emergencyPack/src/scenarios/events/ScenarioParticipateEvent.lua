ScenarioParticipateEvent = {}
local ScenarioParticipateEvent_mt = Class(ScenarioParticipateEvent, Event)

InitEventClass(ScenarioParticipateEvent, "ScenarioParticipateEvent")

function ScenarioParticipateEvent.emptyNew()
	return Event.new(ScenarioParticipateEvent_mt)
end

function ScenarioParticipateEvent.new(farmId, scenarioId, isStart)
	local self = ScenarioParticipateEvent.emptyNew()
	self.farmId = farmId
	self.scenarioId = scenarioId
	self.isStart = isStart

	return self
end

function ScenarioParticipateEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.scenarioId)
	streamWriteBool(streamId, self.isStart)
end

function ScenarioParticipateEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.scenarioId = streamReadInt32(streamId)
	self.isStart = streamReadBool(streamId)

	self:run(connection)
end

function ScenarioParticipateEvent:run(connection)
	if g_currentMission:getIsServer() and not connection:getIsServer() then
		g_messageCenter:publish(ScenarioMessageType.SCENARIO_START_STOP, self.farmId, self.scenarioId, self.isStart, false)
	end
end
