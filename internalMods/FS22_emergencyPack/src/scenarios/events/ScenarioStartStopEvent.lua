ScenarioStartStopEvent = {}
local ScenarioStartStopEvent_mt = Class(ScenarioStartStopEvent, Event)

InitEventClass(ScenarioStartStopEvent, "ScenarioStartStopEvent")

function ScenarioStartStopEvent.emptyNew()
	return Event.new(ScenarioStartStopEvent_mt)
end

function ScenarioStartStopEvent.new(farmId, scenarioId, isStart)
	local self = ScenarioStartStopEvent.emptyNew()
	self.farmId = farmId
	self.scenarioId = scenarioId
	self.isStart = isStart

	return self
end

function ScenarioStartStopEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.scenarioId)
	streamWriteBool(streamId, self.isStart)

	if self.isStart then
		local scenario = g_currentMission.rolePlay:getPendingScenarioForFarm(self.farmId)

		scenario:writeStream(streamId, connection)
	end
end

function ScenarioStartStopEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.scenarioId = streamReadInt32(streamId)
	self.isStart = streamReadBool(streamId)

	if self.isStart then
		local scenario = g_currentMission.rolePlay:getPendingScenarioForFarm(self.farmId)

		scenario:readStream(streamId, connection)
	end

	self:run(connection)
end

function ScenarioStartStopEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.SCENARIO_START_STOP, self.farmId, self.scenarioId, self.isStart, true)
end
